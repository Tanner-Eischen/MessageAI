import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { createOpenAIClient } from "../_shared/openai-client.ts";
import {
  ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT,
  generateAnalysisPrompt,
  validateToneAnalysis,
  extractToneIndicators,
  detectFigurativeLanguage,
  assessResponseAnxietyRisk,
  type ToneAnalysisResult,
} from "../_shared/prompts/enhanced-tone-analysis.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeRequest {
  message_id: string;
  message_body: string;
  conversation_context?: string[]; // Optional recent messages for context
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
    const { message_id, message_body, conversation_context } = requestBody;

    if (!message_id || !message_body) {
      throw new Error("message_id and message_body are required");
    }

    console.log(`🔍 Analyzing message ${message_id.substring(0, 8)}...`);

    // Verify user has access to this message
    const { data: message, error: messageError } = await supabase
      .from("messages")
      .select("id, conversation_id")
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

    // Create OpenAI client
    const openai = createOpenAIClient();

    // Extract tone indicators and figurative language
    const toneIndicators = extractToneIndicators(message_body);
    const figurativeLanguage = detectFigurativeLanguage(message_body);
    
    console.log("🏷️  Tone indicators found:", toneIndicators);
    console.log("💭 Figurative language:", figurativeLanguage);

    // Generate the analysis prompt
    const userPrompt = generateAnalysisPrompt(
      message_body,
      conversation_context
    );

    console.log("📤 Sending request to OpenAI...");

    // Call OpenAI API with enhanced prompt
    const analysisResult = await openai.sendMessageForJSON<ToneAnalysisResult>(
      userPrompt,
      ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT
    );

    console.log("📥 Received response from OpenAI");

    // Validate the result
    const validatedResult = validateToneAnalysis(analysisResult);

    // Assess response anxiety risk for neurodivergent users
    const anxietyAssessment = assessResponseAnxietyRisk(validatedResult);
    console.log("🧠 Anxiety assessment:", anxietyAssessment);

    console.log(`✅ Analysis complete: ${validatedResult.tone} (${validatedResult.urgency_level})`);

    // Store the analysis in the database
    const now = Math.floor(Date.now() / 1000);

    const { data: storedAnalysis, error: insertError } = await supabase
      .from("message_ai_analysis")
      .insert({
        message_id,
        tone: validatedResult.tone,
        urgency_level: validatedResult.urgency_level,
        intent: validatedResult.intent,
        confidence_score: validatedResult.confidence_score,
        analysis_timestamp: now,
        // ✅ NEW ENHANCED FIELDS
        intensity: validatedResult.intensity,
        secondary_tones: validatedResult.secondary_tones,
        context_flags: validatedResult.context_flags,
        anxiety_assessment: anxietyAssessment,
      })
      .select()
      .single();

    if (insertError) {
      console.error("❌ Failed to store analysis:", insertError);
      throw new Error(`Failed to store analysis: ${insertError.message}`);
    }

    console.log("💾 Analysis stored successfully");

    // Return the analysis result
    return new Response(
      JSON.stringify({
        success: true,
        analysis: {
          id: storedAnalysis.id,
          message_id,
          tone: validatedResult.tone,
          urgency_level: validatedResult.urgency_level,
          intent: validatedResult.intent,
          confidence_score: validatedResult.confidence_score,
          reasoning: validatedResult.reasoning,
          // Enhanced fields
          intensity: validatedResult.intensity,
          secondary_tones: validatedResult.secondary_tones,
          context_flags: validatedResult.context_flags,
          anxiety_assessment: anxietyAssessment,
          figurative_language_detected: figurativeLanguage,
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

