import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface ReceiptPayload {
  message_ids: string[]; // Array of message UUIDs
  status: "delivered" | "read";
}

interface ReceiptResponse {
  success: boolean;
  count: number;
  status: string;
  server_time: string;
}

interface ErrorResponse {
  error: string;
  status: number;
}

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authenticated user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: corsHeaders }
      );
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get user ID from JWT token
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: corsHeaders }
      );
    }

    // Parse request body
    const payload: ReceiptPayload = await req.json();

    // Validate required fields
    if (!payload.message_ids || !Array.isArray(payload.message_ids) || payload.message_ids.length === 0) {
      return new Response(
        JSON.stringify({
          error: "Invalid message_ids: must be a non-empty array of UUIDs",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (!payload.status || !["delivered", "read"].includes(payload.status)) {
      return new Response(
        JSON.stringify({
          error: "Invalid status: must be 'delivered' or 'read'",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Limit batch size to prevent abuse
    if (payload.message_ids.length > 1000) {
      return new Response(
        JSON.stringify({
          error: "Too many message IDs: maximum 1000 per request",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Prepare receipt records (batch insert with conflict handling)
    const now = new Date().toISOString();
    const receipts = payload.message_ids.map((messageId) => ({
      id: crypto.randomUUID(), // Generate unique receipt ID
      message_id: messageId,
      user_id: user.id,
      status: payload.status,
      at: now,
    }));

    // Insert receipts with "on conflict do nothing" to handle duplicates gracefully
    const { error: insertError, data: insertedReceipts } = await supabase
      .from("message_receipts")
      .insert(receipts, { onConflict: "message_id,user_id" })
      .select("id");

    if (insertError) {
      console.error("Error inserting receipts:", insertError);
      // Log but don't fail - some receipts may have already existed
      // This is expected for idempotent operations
    }

    // Count successful inserts
    const successCount = insertedReceipts?.length || 0;

    // Also try to update existing receipts if they have a lower status
    // (e.g., "delivered" → "read")
    if (payload.status === "read") {
      const { error: updateError, data: updatedReceipts } = await supabase
        .from("message_receipts")
        .update({ status: "read", at: now })
        .in("message_id", payload.message_ids)
        .eq("user_id", user.id)
        .eq("status", "delivered")
        .select("id");

      if (updateError) {
        console.error("Error updating receipts:", updateError);
      } else if (updatedReceipts) {
        // Log update count for debugging
        console.log(`Updated ${updatedReceipts.length} receipts from delivered to read`);
      }
    }

    const response: ReceiptResponse = {
      success: true,
      count: successCount,
      status: payload.status,
      server_time: now,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error in receipts_ack:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});
