import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface MessagePayload {
  id: string; // UUID - client-generated for idempotency
  conversation_id: string; // UUID
  body: string;
  media_url?: string | null;
}

interface MessageResponse {
  id: string;
  conversation_id: string;
  sender_id: string;
  body: string;
  media_url: string | null;
  created_at: string;
  server_time: string;
  status: "created" | "already_exists";
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
    const payload: MessagePayload = await req.json();

    // Validate required fields
    if (!payload.id || !payload.conversation_id || !payload.body) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: id, conversation_id, body",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Trim and validate body
    const body = payload.body.trim();
    if (body.length === 0) {
      return new Response(
        JSON.stringify({ error: "Message body cannot be empty" }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Verify user is participant in conversation
    const { data: participant, error: participantError } = await supabase
      .from("conversation_participants")
      .select("id")
      .eq("conversation_id", payload.conversation_id)
      .eq("user_id", user.id)
      .single();

    if (participantError || !participant) {
      return new Response(
        JSON.stringify({
          error: "Not a participant in this conversation",
        }),
        { status: 403, headers: corsHeaders }
      );
    }

    // UPSERT message (idempotent)
    // If message with this ID already exists, do nothing (returns 409 equivalent)
    const { data: message, error: messageError } = await supabase
      .from("messages")
      .upsert(
        {
          id: payload.id,
          conversation_id: payload.conversation_id,
          sender_id: user.id,
          body: body,
          media_url: payload.media_url || null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" }
      )
      .select()
      .single();

    if (messageError) {
      console.error("Error inserting message:", messageError);
      return new Response(
        JSON.stringify({ error: "Failed to send message" }),
        { status: 500, headers: corsHeaders }
      );
    }

    // Check if this was a new insert or already existed
    const { data: count, error: checkError } = await supabase
      .from("messages")
      .select("id", { count: "exact", head: true })
      .eq("id", payload.id);

    const status = count && count.length > 0 ? "created" : "already_exists";

    const response: MessageResponse = {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      body: message.body,
      media_url: message.media_url,
      created_at: message.created_at,
      server_time: new Date().toISOString(),
      status: status,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error in messages_send:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});
