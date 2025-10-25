import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { createOpenAIClient } from "../_shared/openai-client.ts";
import {
  DRAFT_ANALYSIS_SYSTEM_PROMPT,
  generateDraftAnalysisPrompt,
  validateDraftAnalysis,
  getSuggestedTemplates,
  findMatchingTemplates,
  type DraftAnalysisContext,
  type DraftAnalysisResult,
} from "../_shared/prompts/draft_analysis.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeRequest {
  draft_message: string;
  conversation_id?: string;
  relationship_type?: 'boss' | 'colleague' | 'friend' | 'family' | 'client' | 'none';
  conversation_history?: string[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authorization
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verify user
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
    const { 
      draft_message,
      conversation_id,
      relationship_type,
      conversation_history,
    } = requestBody;

    if (!draft_message || typeof draft_message !== 'string') {
      throw new Error("draft_message is required");
    }

    console.log(`🔍 Analyzing draft for user ${user.id.substring(0, 8)}...`);

    // Get conversation context if conversation_id provided
    let conversationTone: string | undefined;
    let recipientInfo: { name?: string; role?: string } | undefined;
    let detectedRelationshipType = relationship_type;

    if (conversation_id) {
      // Get recent tone analysis for this conversation
      const { data: recentAnalysis } = await supabase
        .rpc('get_conversation_ai_analysis', { p_conversation_id: conversation_id })
        .limit(1)
        .single();

      if (recentAnalysis) {
        conversationTone = recentAnalysis.tone;
      }

      // Get conversation metadata
      const { data: conversation } = await supabase
        .from('conversations')
        .select('title, relationship_type')
        .eq('id', conversation_id)
        .single();

      // Use stored relationship type if not provided
      if (!detectedRelationshipType && conversation?.relationship_type) {
        detectedRelationshipType = conversation.relationship_type;
      }

      // Get recipient info
      const { data: participants } = await supabase
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', conversation_id)
        .neq('user_id', user.id)
        .limit(1);

      if (participants && participants.length > 0) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('username, full_name, email')
          .eq('id', participants[0].user_id)
          .single();

        if (profile) {
          recipientInfo = {
            name: profile.full_name || profile.username,
          };
        }
      }
    }

    // Build context
    const context: DraftAnalysisContext = {
      draftMessage: draft_message,
      conversationHistory: conversation_history || [],
      relationshipType: detectedRelationshipType || 'none',
      conversationTone,
      recipientInfo,
    };

    // Generate prompt
    const userPrompt = generateDraftAnalysisPrompt(context);

    console.log('📤 Calling OpenAI for draft analysis...');

    // Call OpenAI
    const openai = createOpenAIClient();
    const analysisResult = await openai.sendMessageForJSON<DraftAnalysisResult>(
      userPrompt,
      DRAFT_ANALYSIS_SYSTEM_PROMPT
    );

    console.log('📥 OpenAI response received');

    // Validate result
    const validatedResult = validateDraftAnalysis(analysisResult);

    console.log(`✅ Draft analysis complete. Confidence: ${validatedResult.confidence_score}%`);

    // Get template suggestions based on situation detection
    let suggestedTemplates = [];
    if (validatedResult.situation_detection) {
      const situationType = validatedResult.situation_detection.situation_type;
      console.log(`📝 Detected situation: ${situationType}`);
      
      // Get templates for this situation type
      const templatesBySituation = getSuggestedTemplates(situationType);
      
      // Also find templates matching keywords in the draft
      const templatesByKeyword = findMatchingTemplates(draft_message, 3);
      
      // Combine and deduplicate (prefer situation-based templates)
      const templateIds = new Set();
      suggestedTemplates = [
        ...templatesBySituation,
        ...templatesByKeyword,
      ].filter(template => {
        if (templateIds.has(template.id)) {
          return false;
        }
        templateIds.add(template.id);
        return true;
      }).slice(0, 5); // Return max 5 templates
      
      console.log(`📋 Found ${suggestedTemplates.length} suggested templates`);
    }

    // Return analysis (no database storage for drafts - they're ephemeral)
    return new Response(
      JSON.stringify({
        success: true,
        analysis: {
          // Tone analysis fields
          tone: validatedResult.tone,
          intensity: validatedResult.intensity,
          urgency_level: validatedResult.urgency_level,
          intent: validatedResult.intent,
          context_flags: validatedResult.context_flags,
          reasoning: validatedResult.reasoning,
          
          // Draft-specific fields
          confidence_score: validatedResult.confidence_score,
          appropriateness: validatedResult.appropriateness,
          suggestions: validatedResult.suggestions,
          warnings: validatedResult.warnings,
          strengths: validatedResult.strengths,
          
          // NEW: Situation detection and templates
          situation_detection: validatedResult.situation_detection,
          suggested_templates: suggestedTemplates,
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("❌ Error analyzing draft:", error);

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

