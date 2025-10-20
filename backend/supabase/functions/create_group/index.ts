import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface CreateGroupPayload {
  title: string;
  description?: string;
  member_ids: string[]; // Array of user IDs to add to group
}

interface CreateGroupResponse {
  id: string;
  title: string;
  description: string | null;
  is_group: boolean;
  created_by: string;
  created_at: string;
  member_count: number;
  members: Array<{
    user_id: string;
    joined_at: string;
  }>;
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
    const payload: CreateGroupPayload = await req.json();

    // Validate required fields
    if (!payload.title || !payload.member_ids) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: title, member_ids",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Validate title
    const title = payload.title.trim();
    if (title.length === 0) {
      return new Response(
        JSON.stringify({ error: "Group title cannot be empty" }),
        { status: 400, headers: corsHeaders }
      );
    }

    if (title.length > 255) {
      return new Response(
        JSON.stringify({ error: "Group title too long (max 255 characters)" }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Validate member_ids
    if (!Array.isArray(payload.member_ids) || payload.member_ids.length === 0) {
      return new Response(
        JSON.stringify({
          error: "member_ids must be a non-empty array",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Limit group size
    if (payload.member_ids.length > 500) {
      return new Response(
        JSON.stringify({
          error: "Too many members: maximum 500 per group",
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Ensure creator is included in members
    const memberSet = new Set(payload.member_ids);
    memberSet.add(user.id);
    const uniqueMemberIds = Array.from(memberSet);

    // Validate all members exist in profiles table
    const { data: existingProfiles, error: profileError } = await supabase
      .from("profiles")
      .select("user_id")
      .in("user_id", uniqueMemberIds);

    if (profileError) {
      console.error("Error checking profiles:", profileError);
      return new Response(
        JSON.stringify({ error: "Failed to validate members" }),
        { status: 500, headers: corsHeaders }
      );
    }

    const existingUserIds = new Set(
      existingProfiles?.map((p) => p.user_id) || []
    );
    const invalidMembers = uniqueMemberIds.filter(
      (id) => !existingUserIds.has(id)
    );

    if (invalidMembers.length > 0) {
      return new Response(
        JSON.stringify({
          error: `Invalid member IDs: ${invalidMembers.join(", ")}`,
        }),
        { status: 400, headers: corsHeaders }
      );
    }

    // Create conversation
    const { data: conversation, error: conversationError } = await supabase
      .from("conversations")
      .insert({
        title: title,
        description: payload.description || null,
        is_group: true,
        created_by: user.id,
      })
      .select()
      .single();

    if (conversationError || !conversation) {
      console.error("Error creating conversation:", conversationError);
      return new Response(
        JSON.stringify({ error: "Failed to create group" }),
        { status: 500, headers: corsHeaders }
      );
    }

    // Add all members to conversation
    const participantRecords = uniqueMemberIds.map((userId) => ({
      conversation_id: conversation.id,
      user_id: userId,
      joined_at: new Date().toISOString(),
    }));

    const { data: participants, error: participantError } = await supabase
      .from("conversation_participants")
      .insert(participantRecords)
      .select();

    if (participantError) {
      console.error("Error adding participants:", participantError);
      // Log error but don't fail - group is created
    }

    const response: CreateGroupResponse = {
      id: conversation.id,
      title: conversation.title,
      description: conversation.description,
      is_group: conversation.is_group,
      created_by: conversation.created_by,
      created_at: conversation.created_at,
      member_count: uniqueMemberIds.length,
      members: (participants || []).map((p) => ({
        user_id: p.user_id,
        joined_at: p.joined_at,
      })),
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error("Error in create_group:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders }
    );
  }
});
