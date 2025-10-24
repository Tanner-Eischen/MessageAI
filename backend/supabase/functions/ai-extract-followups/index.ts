import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { ActionItemExtractor } from '../_shared/nlp/action-item-extractor.ts';
import { QuestionDetector } from '../_shared/nlp/question-detector.ts';

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
    const { conversation_id, scan_recent_messages } = body;

    if (!conversation_id) {
      throw new Error('Missing conversation_id');
    }

    console.log(`Extracting follow-ups for conversation ${conversation_id}`);

    // Get recent messages
    const messageCount = scan_recent_messages ? 50 : 10;
    const { data: messages } = await supabase
      .from('messages')
      .select('id, body, sender_id, created_at')
      .eq('conversation_id', conversation_id)
      .order('created_at', { ascending: false })
      .limit(messageCount);

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ success: true, follow_ups: [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const actionExtractor = new ActionItemExtractor();
    const questionDetector = new QuestionDetector();

    const followUps = [];
    const now = Math.floor(Date.now() / 1000);

    // Extract action items from user's messages
    for (const message of messages) {
      if (message.sender_id === user.id) {
        const actionItems = await actionExtractor.extractActionItems(
          message.body,
          message.sender_id,
          user.id
        );

        for (const action of actionItems) {
          // Create follow-up item
          const deadline = action.mentioned_deadline
            ? actionExtractor.parseDeadline(action.mentioned_deadline)
            : null;

          const { data: followUpItem } = await supabase
            .from('follow_up_items')
            .insert({
              user_id: user.id,
              conversation_id,
              message_id: message.id,
              item_type: 'action_item',
              title: `${action.action_type}: ${action.action_target}`,
              description: action.commitment_text,
              extracted_text: message.body,
              priority: 70,
              detected_at: now,
              remind_at: deadline,
              created_at: now,
              updated_at: now,
            })
            .select()
            .single();

          if (followUpItem) {
            // Store action item details
            await supabase
              .from('action_items')
              .insert({
                follow_up_item_id: followUpItem.id,
                action_type: action.action_type,
                action_target: action.action_target,
                commitment_text: action.commitment_text,
                mentioned_deadline: action.mentioned_deadline,
                extracted_deadline: deadline,
                created_at: now,
              });

            followUps.push(followUpItem);
          }
        }
      }
    }

    // Detect unanswered questions
    const unansweredQuestions = await questionDetector.findUnansweredQuestions(
      messages.reverse(),
      user.id
    );

    for (const question of unansweredQuestions) {
      // Check if user hasn't responded in 24+ hours
      const timeSinceAsked = now - question.asked_at;
      if (timeSinceAsked > 86400) { // 24 hours
        const { data: followUpItem } = await supabase
          .from('follow_up_items')
          .insert({
            user_id: user.id,
            conversation_id,
            message_id: question.message_id,
            item_type: 'unanswered_question',
            title: `Answer: ${question.question_text.substring(0, 50)}...`,
            description: question.question_text,
            extracted_text: question.question_text,
            priority: 60,
            detected_at: now,
            remind_at: now,
            created_at: now,
            updated_at: now,
          })
          .select()
          .single();

        if (followUpItem) {
          await supabase
            .from('unanswered_questions')
            .insert({
              follow_up_item_id: followUpItem.id,
              message_id: question.message_id,
              question_text: question.question_text,
              question_type: question.question_type,
              context: question.context,
              asked_at: question.asked_at,
              time_since_asked: timeSinceAsked,
              created_at: now,
            });

          followUps.push(followUpItem);
        }
      }
    }

    console.log(`Found ${followUps.length} follow-ups`);

    return new Response(
      JSON.stringify({
        success: true,
        follow_ups: followUps,
        action_items_count: followUps.filter(f => f.item_type === 'action_item').length,
        unanswered_questions_count: followUps.filter(f => f.item_type === 'unanswered_question').length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error extracting follow-ups:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

