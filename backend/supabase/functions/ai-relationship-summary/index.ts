import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { RelationshipBuilder } from '../_shared/rag/relationship-builder.ts';

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
    const { conversation_id, force_regenerate } = body;

    if (!conversation_id) {
      throw new Error('Missing conversation_id');
    }

    console.log(`👤 Building relationship profile for conversation ${conversation_id}`);

    // Check if profile already exists
    if (!force_regenerate) {
      const { data: existingProfile } = await supabase.rpc('get_relationship_profile', {
        p_user_id: user.id,
        p_conversation_id: conversation_id,
      });

      if (existingProfile && existingProfile.length > 0) {
        console.log('✅ Returning existing profile');
        return new Response(
          JSON.stringify({
            success: true,
            profile: existingProfile[0],
            regenerated: false,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Get conversation participants
    const { data: participants } = await supabase
      .from('conversation_participants')
      .select('user_id')
      .eq('conversation_id', conversation_id)
      .neq('user_id', user.id);

    if (!participants || participants.length === 0) {
      throw new Error('No other participants found');
    }

    const participantId = participants[0].user_id;

    // Get participant name
    const { data: profile } = await supabase
      .from('profiles')
      .select('username, full_name')
      .eq('id', participantId)
      .single();

    const participantName = profile?.full_name || profile?.username || 'Unknown';

    // Get conversation history
    const { data: messages } = await supabase
      .from('messages')
      .select('body, sender_id, created_at')
      .eq('conversation_id', conversation_id)
      .order('created_at', { ascending: true })
      .limit(100);

    if (!messages || messages.length === 0) {
      throw new Error('No messages found');
    }

    console.log(`Analyzing ${messages.length} messages`);

    // Format messages for AI
    const formattedMessages = messages.map(m => ({
      body: m.body,
      sender: m.sender_id === user.id ? 'self' : 'other',
      created_at: new Date(m.created_at).getTime() / 1000,
    }));

    // Build profile
    const builder = new RelationshipBuilder();
    const relationshipProfile = await builder.buildProfile(
      formattedMessages,
      participantName
    );

    // Calculate response time
    const typicalResponseTime = builder.calculateResponseTime(formattedMessages);

    console.log('✅ Profile generated');

    // Store in database
    const now = new Date();
    const { data: storedProfile, error: insertError } = await supabase
      .from('relationship_profiles')
      .upsert({
        user_id: user.id,
        conversation_id: conversation_id,
        participant_name: participantName,
        participant_user_id: participantId,
        relationship_type: relationshipProfile.relationship_type,
        conversation_summary: relationshipProfile.conversation_summary,
        safe_topics: relationshipProfile.safe_topics,
        topics_to_avoid: relationshipProfile.topics_to_avoid,
        communication_style: relationshipProfile.communication_style,
        typical_response_time: typicalResponseTime,
        total_messages: messages.length,
        first_message_at: new Date(messages[0].created_at),
        last_message_at: new Date(messages[messages.length - 1].created_at),
        updated_at: now.toISOString(),
      }, {
        onConflict: 'user_id,conversation_id',
      })
      .select()
      .single();

    if (insertError) {
      console.error('Error storing profile:', insertError);
      throw insertError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        profile: storedProfile,
        regenerated: true,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ Error building relationship profile:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

