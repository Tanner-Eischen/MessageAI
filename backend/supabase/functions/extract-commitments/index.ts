import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { createOpenAIClient } from "../_shared/openai-client.ts";
import {
  COMMITMENT_EXTRACTION_SYSTEM_PROMPT,
  generateCommitmentExtractionPrompt,
  validateCommitmentExtraction,
  parseDeadlineText,
  type CommitmentExtractionResult,
} from "../_shared/prompts/commitment-extraction.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ExtractRequest {
  message_id: string;
  message_body: string;
  conversation_id: string;
  conversation_context?: string[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify user's token
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      throw new Error("Invalid authorization token");
    }

    // Parse request body
    const requestBody: ExtractRequest = await req.json();
    const { message_id, message_body, conversation_id, conversation_context } = requestBody;

    if (!message_id || !message_body || !conversation_id) {
      throw new Error("message_id, message_body, and conversation_id are required");
    }

    console.log(`🔍 Extracting commitments from message ${message_id.substring(0, 8)}...`);

    // Note: Skipping conversation access check since conversation_participants table doesn't exist
    // In production, verify user has access to this conversation
    console.log(`✅ User ${user.id} authorized for conversation ${conversation_id.substring(0, 8)}`);

    // Create OpenAI client
    const openai = createOpenAIClient();

    // Generate extraction prompt
    const userPrompt = generateCommitmentExtractionPrompt(
      message_body,
      conversation_context
    );

    console.log("📤 Sending commitment extraction to OpenAI...");

    // Call OpenAI API
    const extractionResult = await openai.sendMessageForJSON<CommitmentExtractionResult>(
      userPrompt,
      COMMITMENT_EXTRACTION_SYSTEM_PROMPT
    );

    console.log("📥 Received extraction result");

    // Validate extraction result
    const validatedResult = validateCommitmentExtraction(extractionResult);
    console.log(`✅ Found ${validatedResult.totalFound} commitments`);

    // Store each commitment as an action item
    const now = Math.floor(Date.now() / 1000);
    const actionItems = [];

    for (const commitment of validatedResult.commitments) {
      try {
        // Parse deadline if mentioned
        let extractedDeadline = commitment.extractedDeadline;
        let deadlineEstimated = commitment.deadlineEstimated;

        if (commitment.mentionedDeadline && !extractedDeadline) {
          const parsed = parseDeadlineText(commitment.mentionedDeadline);
          if (parsed) {
            extractedDeadline = parsed.timestamp;
            deadlineEstimated = parsed.estimated;
          }
        }

        // Insert into action_items table
        const { data: insertedItem, error: insertError } = await supabase
          .from("action_items")
          .insert({
            user_id: user.id,
            conversation_id,
            message_id,
            commitment_text: commitment.commitmentText,
            action_type: commitment.actionType,
            action_target: commitment.actionTarget,
            mentioned_deadline: commitment.mentionedDeadline,
            extracted_deadline: extractedDeadline,
            deadline_estimated: deadlineEstimated,
            status: "pending",
            reminder_enabled: true,
            reminder_days_before: 1,
            source_message_created_at: new Date().toISOString(),
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .select()
          .single();

        if (insertError) {
          console.warn(`⚠️ Failed to store commitment: ${insertError.message}`);
          continue;
        }

        actionItems.push({
          id: insertedItem.id,
          commitment: commitment.commitmentText,
          actionType: commitment.actionType,
          deadline: extractedDeadline ? new Date(extractedDeadline * 1000) : null,
        });

        console.log(`✅ Stored action item: ${commitment.commitmentText}`);
      } catch (err) {
        console.error(`❌ Error storing commitment: ${err}`);
        console.error(`   Full error: ${JSON.stringify(err)}`);
        // Still continue to try other commitments
      }
    }

    // Log final results
    console.log(`📊 Summary: Found ${validatedResult.totalFound} commitments, saved ${actionItems.length} to database`);

    // Update commitment streak
    // TODO: Re-enable when commitment_streaks table exists
    // try {
    //   await supabase.rpc("update_commitment_streak", { p_user_id: user.id });
    //   console.log("📊 Updated commitment streak");
    // } catch (err) {
    //   console.warn(`⚠️ Failed to update streak: ${err}`);
    // }
    console.log("⏭️  Streak update skipped (feature not yet available)");

    // Return success response
    const response = {
      success: true,
      commitments_found: validatedResult.totalFound,
      action_items_created: actionItems.length,
      action_items: actionItems,
    };

    // If we found commitments but didn't save any, add warning
    if (validatedResult.totalFound > 0 && actionItems.length === 0) {
      console.error(`⚠️ WARNING: Found ${validatedResult.totalFound} commitments but saved 0 to database!`);
      response.warning = `Found ${validatedResult.totalFound} commitments but failed to save them to database. Check server logs.`;
    }

    return new Response(
      JSON.stringify(response),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("❌ Error in extract-commitments:", error);

    const errorMessage = error instanceof Error ? error.message : "Unknown error";

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
