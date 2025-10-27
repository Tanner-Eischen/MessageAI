import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface FeedbackRequest {
  analysisId: string;
  messageId: string;
  senderId: string;
  userChosenInterpretation?: string;
  wasHelpful?: boolean;
  feedbackTimestamp: number;
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

    const body = (await req.json()) as FeedbackRequest;
    const userId = req.headers.get("x-user-id");

    if (!userId) {
      return new Response("Unauthorized - User ID required", { status: 401 });
    }

    // Validate request body
    if (!body.analysisId || !body.messageId || !body.senderId) {
      return new Response("Missing required fields", { status: 400 });
    }

    if (body.userChosenInterpretation === undefined && body.wasHelpful === undefined) {
      return new Response(
        "At least one of userChosenInterpretation or wasHelpful must be provided",
        { status: 400 }
      );
    }

    // Save feedback to database
    const { data, error } = await supabase
      .from("analysis_feedback")
      .insert([
        {
          analysis_id: body.analysisId,
          message_id: body.messageId,
          sender_id: body.senderId,
          user_id: userId,
          user_chosen_interpretation: body.userChosenInterpretation || null,
          was_helpful: body.wasHelpful ?? null,
          feedback_timestamp: body.feedbackTimestamp,
        },
      ])
      .select();

    if (error) {
      console.error("Error saving feedback:", error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log("✅ Feedback saved:", {
      feedbackId: data?.[0]?.id,
      analysisId: body.analysisId,
      interpretation: body.userChosenInterpretation,
      helpful: body.wasHelpful,
    });

    return new Response(
      JSON.stringify({
        success: true,
        feedbackId: data?.[0]?.id,
        message: "Feedback saved successfully",
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("❌ Error in ai-save-interpretation-feedback:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
