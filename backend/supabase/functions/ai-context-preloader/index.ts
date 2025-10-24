import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { OpenAIClient } from '../_shared/openai-client.ts';

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
    const { conversation_id } = body;

    if (!conversation_id) {
      throw new Error('Missing conversation_id');
    }

    console.log(`📋 Loading context for conversation ${conversation_id}, user ${user.id}`);

    // Check cache first
    const { data: cachedContextArray } = await supabase.rpc('get_conversation_context', {
      p_user_id: user.id,
      p_conversation_id: conversation_id,
    });

    if (cachedContextArray && cachedContextArray.length > 0) {
      const cache = cachedContextArray[0];
      // If cache is less than 1 hour old, return it
      if (cache.cache_age < 3600) {
        console.log('✅ Returning cached context');
        return new Response(
          JSON.stringify({
            success: true,
            context: {
              last_discussed: cache.last_discussed,
              key_points: cache.key_points,
              pending_questions: cache.pending_questions,
            },
            from_cache: true,
            cache_age: cache.cache_age,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Generate fresh context
    console.log('🔄 Generating fresh context');

    // Get recent messages
    const { data: recentMessages } = await supabase
      .from('messages')
      .select('body, created_at, sender_id')
      .eq('conversation_id', conversation_id)
      .order('created_at', { ascending: false })
      .limit(20);

    if (!recentMessages || recentMessages.length === 0) {
      throw new Error('No messages found');
    }

    console.log(`Found ${recentMessages.length} recent messages`);

    // Use AI to extract context
    const openai = new OpenAIClient();
    
    const prompt = `Analyze these recent messages and extract:
1. What was last discussed (1 sentence)
2. 3-5 key points from the conversation
3. Any pending questions that need answers

**Recent Messages (newest first):**
${recentMessages.map((m, i) => `${i + 1}. ${m.body}`).join('\n')}

**Response Format (JSON):**
{
  "last_discussed": "brief summary of last topic",
  "key_points": [
    "key point 1",
    "key point 2",
    "key point 3"
  ],
  "pending_questions": [
    "unanswered question 1",
    "unanswered question 2"
  ]
}`;

    const result = await openai.sendMessageForJSON(
      prompt,
      'You are extracting conversation context. Be concise and helpful.',
      { temperature: 0.3, max_tokens: 500 }
    );

    const context = {
      last_discussed: result.last_discussed || 'Recent conversation',
      key_points: Array.isArray(result.key_points) ? result.key_points : [],
      pending_questions: Array.isArray(result.pending_questions) ? result.pending_questions : [],
    };

    console.log('✅ Context generated');

    // Cache the result
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 3600 * 1000); // 1 hour

    const { error: cacheError } = await supabase
      .from('conversation_context_cache')
      .upsert({
        user_id: user.id,
        conversation_id: conversation_id,
        last_discussed: context.last_discussed,
        key_points: context.key_points,
        pending_questions: context.pending_questions,
        generated_at: now.toISOString(),
        expires_at: expiresAt.toISOString(),
      }, {
        onConflict: 'user_id,conversation_id',
      });

    if (cacheError) {
      console.error('Error caching context:', cacheError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        context,
        from_cache: false,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ Error loading context:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

