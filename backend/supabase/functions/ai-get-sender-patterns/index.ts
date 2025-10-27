import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import {
  buildSenderProfile,
  generateSenderContext,
  type SenderProfile,
} from "../_shared/sender-pattern-builder.ts";

interface PatternRequest {
  senderId: string;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = (await req.json()) as PatternRequest;
    const userId = req.headers.get("x-user-id");

    if (!userId || !body.senderId) {
      return new Response("Missing required fields", { status: 400 });
    }

    console.log(`📊 Querying patterns for sender ${body.senderId}`);

    // Query feedback for this sender in the last 90 days
    const ninetyDaysAgo = Math.floor(Date.now() / 1000) - 90 * 24 * 60 * 60;

    const { data: feedbackData, error: feedbackError } = await supabase
      .from("analysis_feedback")
      .select(
        `
        id,
        user_chosen_interpretation,
        was_helpful,
        feedback_timestamp,
        ai_analysis (
          rsd_triggers
        )
      `
      )
      .eq("sender_id", body.senderId)
      .eq("user_id", userId)
      .gte("feedback_timestamp", ninetyDaysAgo)
      .order("feedback_timestamp", { ascending: false });

    if (feedbackError) {
      console.error("Error querying feedback:", feedbackError);
      return new Response(JSON.stringify({ error: feedbackError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Process feedback into patterns
    const processedFeedback = (feedbackData || []).map((row: any) => ({
      user_chosen_interpretation: row.user_chosen_interpretation,
      was_helpful: row.was_helpful,
      trigger_pattern:
        row.ai_analysis?.rsd_triggers?.[0] || "unknown",
    }));

    // Build sender profile
    const profile: SenderProfile = await buildSenderProfile(
      body.senderId,
      processedFeedback
    );

    // Generate context for AI prompt
    const context = generateSenderContext(profile);

    console.log(`✅ Generated pattern context for sender:`, {
      senderId: body.senderId,
      totalMessages: profile.totalMessages,
      patterns: profile.patterns.length,
      contextLength: context.length,
    });

    return new Response(
      JSON.stringify({
        success: true,
        profile,
        context,
        hasData: profile.totalMessages >= 3,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in ai-get-sender-patterns:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
