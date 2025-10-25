import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { OpenAIClient } from '../_shared/openai-client.ts';
import {
  SMART_MESSAGE_INTERPRETER_PROMPT,
  generateSmartInterpretationPrompt,
  validateEnhancedToneAnalysis,
  type EnhancedToneAnalysisResult,
} from '../_shared/prompts/enhanced-tone-analysis.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      throw new Error('Unauthorized');
    }

    const body = await req.json();
    const { message_id, message_body, conversation_context } = body;

    if (!message_body) {
      throw new Error('Missing message_body');
    }

    console.log(`Interpreting message for user ${user.id}`);

    // Generate smart interpretation prompt
    const userPrompt = generateSmartInterpretationPrompt(
      message_body,
      conversation_context
    );

    // Call OpenAI with enhanced prompt
    const openai = new OpenAIClient(Deno.env.get('OPENAI_API_KEY')!);
    const analysisResult = await openai.sendMessageForJSON<EnhancedToneAnalysisResult>(
      userPrompt,
      SMART_MESSAGE_INTERPRETER_PROMPT,
      { temperature: 0.3, max_tokens: 1000 } // More tokens for detailed analysis
    );

    console.log('Analysis complete:', analysisResult);

    // Validate result
    const validatedResult = validateEnhancedToneAnalysis(analysisResult);

    // Store in database if message_id provided
    if (message_id) {
      const now = Math.floor(Date.now() / 1000);
      // 🔧 FIXED: Removed non-existent user_id column, added missing fields
      await supabase
        .from('message_ai_analysis')
        .upsert({
          message_id,
          // Core fields
          tone: validatedResult.tone,
          urgency_level: validatedResult.urgency_level,
          intent: validatedResult.intent,
          confidence_score: validatedResult.confidence_score,
          // Enhanced fields
          intensity: validatedResult.intensity,
          context_flags: validatedResult.context_flags,
          secondary_tones: validatedResult.secondary_tones,
          anxiety_assessment: validatedResult.response_anxiety_assessment,
          // Phase 1: Smart Message Interpreter fields
          rsd_triggers: validatedResult.rsd_triggers,
          alternative_interpretations: validatedResult.message_interpretations,
          evidence: validatedResult.evidence,
          figurative_language_detected: validatedResult.figurative_language_detected,
          // Metadata
          analysis_timestamp: now,
          updated_at: now,
        });
      
      console.log(`Stored analysis for message ${message_id}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        interpretation: validatedResult,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error interpreting message:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

