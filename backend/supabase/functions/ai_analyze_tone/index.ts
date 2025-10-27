import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { createOpenAIClient } from "../_shared/openai-client.ts";
import {
  generateRSDAnalysisPrompt,
  validateEnhancedAnalysis,
  type EnhancedToneAnalysisResult,
} from "../_shared/prompts/enhanced-tone-analysis.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeRequest {
  message_id: string;
  message_body: string;
  conversation_context?: string[];
  skipDatabaseStorage?: boolean;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify the user's token
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      throw new Error("Invalid authorization token");
    }

    // Parse request body
    const requestBody: AnalyzeRequest = await req.json();
    const { message_id, message_body, conversation_context, skipDatabaseStorage } = requestBody;

    if (!message_id || !message_body) {
      throw new Error("message_id and message_body are required");
    }

    console.log(`🧠 RSD Analysis: Message ${message_id.substring(0, 8)}...`);

    // Verify user has access to this message
    const { data: message, error: messageError } = await supabase
      .from("messages")
      .select("id, conversation_id, sender_id, created_at")
      .eq("id", message_id)
      .single();

    if (messageError || !message) {
      throw new Error("Message not found");
    }

    // Verify user is a participant in the conversation
    const { data: participant, error: participantError } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", message.conversation_id)
      .eq("user_id", user.id)
      .single();

    if (participantError || !participant) {
      throw new Error("Access denied to this conversation");
    }

    // Get sender pattern context if available
    let senderPatternContext: string | undefined;
    try {
      const { data: senderMessages } = await supabase
        .from("messages")
        .select("body")
        .eq("sender_id", message.sender_id)
        .eq("conversation_id", message.conversation_id)
        .order("created_at", { ascending: false })
        .limit(10);

      if (senderMessages && senderMessages.length > 0) {
        const messageCount = senderMessages.length;
        const avgLength = Math.round(
          senderMessages.reduce((sum, m) => sum + (m.body?.length || 0), 0) / messageCount
        );
        senderPatternContext = `This sender usually writes ${messageCount > 5 ? 'frequently' : 'occasionally'}, average message length: ${avgLength} characters. Recent communication style: ${senderMessages[0].body?.substring(0, 50)}...`;
      }
    } catch (e) {
      console.warn("⚠️ Could not fetch sender context:", e);
    }

    // Create OpenAI client
    const openai = createOpenAIClient();

    // Generate RSD-focused analysis prompt
    const userPrompt = generateRSDAnalysisPrompt(
      message_body,
      conversation_context,
      senderPatternContext
    );

    console.log("📤 Sending to OpenAI for RSD analysis...");

    // Call OpenAI API
    const analysisResult = await openai.sendMessageForJSON<EnhancedToneAnalysisResult>(
      userPrompt,
      "You are an expert in neurodivergent communication. Return ONLY valid JSON, no markdown."
    );

    console.log("📥 Received analysis from OpenAI");

    // Validate the result
    console.log("🔍 Validating analysis result...");
    const validatedResult = validateEnhancedAnalysis(analysisResult);
    console.log("✅ Validation successful");

    console.log(
      `✅ Analysis complete: ${validatedResult.tone} (${validatedResult.urgencyLevel || 'N/A'})`
    );

    // Store analysis if requested
    let storedAnalysis: any = null;
    if (!skipDatabaseStorage) {
      const now = Math.floor(Date.now() / 1000);

      const { data: insertedData, error: insertError } = await supabase
        .from("message_ai_analysis")
        .insert({
          message_id,
          tone: validatedResult.tone,
          urgency_level: validatedResult.urgencyLevel,
          intent: validatedResult.intent,
          confidence_score: validatedResult.confidenceScore,
          analysis_timestamp: now,
          // ✅ Store RSD features
          rsd_triggers: validatedResult.rsdTriggers || [],
          alternative_interpretations: validatedResult.alternativeInterpretations || [],
          evidence: validatedResult.evidence || [],
        })
        .select()
        .single();

      if (insertError) {
        console.error("❌ Failed to store analysis:", insertError);
        throw new Error(`Failed to store analysis: ${insertError.message}`);
      }

      storedAnalysis = insertedData;
      console.log("💾 Analysis stored successfully");
    } else {
      console.log("⏭️ Skipping database storage (auto-analysis mode)");
    }

    // Return the analysis result
    return new Response(
      JSON.stringify({
        success: true,
        analysis: {
          id: storedAnalysis?.id,
          message_id,
          tone: validatedResult.tone,
          urgency_level: validatedResult.urgencyLevel,
          intent: validatedResult.intent,
          confidence_score: validatedResult.confidenceScore,
          reasoning: validatedResult.reasoning,
          // ✅ Return RSD features to frontend
          rsd_triggers: validatedResult.rsdTriggers,
          alternative_interpretations: validatedResult.alternativeInterpretations,
          evidence: validatedResult.evidence,
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("❌ Error in ai_analyze_tone:", error);

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

