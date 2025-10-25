import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { OpenAIClient } from '../_shared/openai-client.ts';
import {
  MESSAGE_FORMATTING_PROMPT,
  generateFormattingPrompt,
  calculateReadTime,
  type FormattingOptions,
  type FormattedMessage,
} from '../_shared/prompts/message-formatter.ts';

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
    const { message, options } = body as { 
      message: string; 
      options: FormattingOptions 
    };

    if (!message) {
      throw new Error('Missing message');
    }

    console.log(`Formatting message for user ${user.id}`);
    console.log('Options:', options);

    // Generate the formatting prompt
    const userPrompt = generateFormattingPrompt(message, options);

    // Call OpenAI
    const openai = new OpenAIClient();
    const result = await openai.sendMessageForJSON<FormattedMessage>(
      userPrompt,
      MESSAGE_FORMATTING_PROMPT,
      { temperature: 0.3, max_tokens: 2000 }
    );

    // Ensure we have proper values
    const originalLength = message.length;
    const formattedLength = result.formatted_message?.length || 0;
    const readTime = calculateReadTime(formattedLength);

    const formattedResult: FormattedMessage = {
      original_length: originalLength,
      formatted_message: result.formatted_message || message,
      formatting_applied: result.formatting_applied || [],
      character_count: formattedLength,
      estimated_read_time: readTime,
    };

    console.log('Formatting complete');
    console.log(`Original: ${originalLength} chars -> Formatted: ${formattedLength} chars`);

    return new Response(
      JSON.stringify({
        success: true,
        formatted: formattedResult,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    console.error('Error formatting message:', error);
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

