-- ============================================================
-- SHOWCASE DATA SEEDING SCRIPT
-- Populates database with realistic conversations for demo/testing
-- ============================================================

-- HOW TO RUN:
-- 1. First, get your user ID:
--    SELECT id, email FROM auth.users;
--    
-- 2. Copy your user ID and replace it in the line below
--
-- 3. Run this file:
--    cd backend
--    npx supabase db reset    (resets and runs all migrations)
--    psql $DATABASE_URL -f supabase/seed_showcase_data.sql
--
--    OR use Supabase Studio SQL Editor to run this entire file
--
-- ============================================================

DO $$
DECLARE
  -- ⚠️ REPLACE THIS WITH YOUR ACTUAL USER ID FROM auth.users ⚠️
  v_user_id UUID := '34742825-3fad-4e51-a103-ccd649806660';
  
  -- Create stable UUIDs for fake users (so we can create profiles)
  v_boss_id UUID := 'a0000000-0000-0000-0000-000000000001';
  v_friend_id UUID := 'a0000000-0000-0000-0000-000000000002';
  v_mom_id UUID := 'a0000000-0000-0000-0000-000000000003';
  v_client_id UUID := 'a0000000-0000-0000-0000-000000000004';
  
  v_conv_boss UUID;
  v_conv_friend UUID;
  v_conv_mom UUID;
  v_conv_client UUID;
  
  v_msg1 UUID;
  v_msg2 UUID;
  v_msg3 UUID;
  v_msg4 UUID;
  v_msg5 UUID;
  v_msg6 UUID;
  v_msg7 UUID;
  v_msg8 UUID;
  v_msg9 UUID;
  v_msg10 UUID;
  v_msg11 UUID;
  v_msg12 UUID;
  v_msg13 UUID;
  v_msg14 UUID;
  v_msg15 UUID;
  
  v_now TIMESTAMPTZ;
  v_yesterday TIMESTAMPTZ;
  v_last_week TIMESTAMPTZ;
  v_two_weeks TIMESTAMPTZ;
BEGIN
  v_now := NOW();
  v_yesterday := v_now - INTERVAL '1 day';
  v_last_week := v_now - INTERVAL '7 days';
  v_two_weeks := v_now - INTERVAL '14 days';

  -- ============================================================
  -- CLEANUP: Remove existing seed data to prevent duplicates
  -- ============================================================
  -- Delete conversations created by this user (these are the showcase conversations)
  DELETE FROM conversations 
  WHERE created_by = v_user_id 
    AND title IN ('Sarah Chen (Manager)', 'Alex Thompson', 'Mom', 'Marcus Williams (TechCorp)');
  
  -- ============================================================
  -- CREATE FAKE USER PROFILES
  -- ============================================================
  -- These fake users need to exist in profiles table for foreign key constraints
  
  INSERT INTO profiles (user_id, username)
  VALUES 
    (v_boss_id, 'Sarah Chen'),
    (v_friend_id, 'Alex Thompson'),
    (v_mom_id, 'Mom'),
    (v_client_id, 'Marcus Williams')
  ON CONFLICT (user_id) DO NOTHING;

  -- ============================================================
  -- 1. BOSS CONVERSATION - Formal, stressful, RSD triggers
  -- ============================================================
  v_conv_boss := gen_random_uuid();
  
  INSERT INTO conversations (id, title, description, created_by, created_at, updated_at, is_group)
  VALUES (
    v_conv_boss,
    'Sarah Chen (Manager)',
    'Work - Project Manager',
    v_user_id,
    v_two_weeks,
    v_now - INTERVAL '1 hour',
    false
  );
  
  INSERT INTO conversation_participants (id, conversation_id, user_id, joined_at)
  VALUES 
    (gen_random_uuid(), v_conv_boss, v_user_id, v_two_weeks),
    (gen_random_uuid(), v_conv_boss, v_boss_id, v_two_weeks);
  
  -- Long conversation history (for RAG context - 15+ messages)
  -- Week 2: Initial onboarding
  v_msg1 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg1, v_conv_boss, v_boss_id, 
    'Hi! Welcome to the team. I wanted to touch base about the Q1 project timeline. Can you have the initial designs ready by Friday?',
    v_two_weeks, v_two_weeks);
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Thanks! Yes, I should be able to get those done by Friday.',
    v_two_weeks + INTERVAL '30 minutes', v_two_weeks + INTERVAL '30 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'Perfect. Also, remember we have team standup every morning at 9am. It''s pretty casual, just a quick check-in.',
    v_two_weeks + INTERVAL '45 minutes', v_two_weeks + INTERVAL '45 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Got it, I''ll be there!',
    v_two_weeks + INTERVAL '50 minutes', v_two_weeks + INTERVAL '50 minutes');
  
  -- Week 2: Missed standup incident
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'Great. Also, I noticed you missed the team standup yesterday. Everything okay?',
    v_two_weeks + INTERVAL '2 days', v_two_weeks + INTERVAL '2 days');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Oh I''m so sorry! I completely forgot. It won''t happen again.',
    v_two_weeks + INTERVAL '2 days 5 minutes', v_two_weeks + INTERVAL '2 days 5 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'No worries, it happens. Just try to let me know in advance if you can''t make it.',
    v_two_weeks + INTERVAL '2 days 10 minutes', v_two_weeks + INTERVAL '2 days 10 minutes');
  
  -- Week 2: Design review
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Hi Sarah, I have the initial designs ready for your review. Should I send them now or wait until our meeting tomorrow?',
    v_two_weeks + INTERVAL '5 days', v_two_weeks + INTERVAL '5 days');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'Great! Send them now so I can review before our meeting. That way we can discuss any changes tomorrow.',
    v_two_weeks + INTERVAL '5 days 15 minutes', v_two_weeks + INTERVAL '5 days 15 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Just sent! Let me know if you have any questions.',
    v_two_weeks + INTERVAL '5 days 30 minutes', v_two_weeks + INTERVAL '5 days 30 minutes');
  
  -- Week 1: Client presentation success
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'The client really liked your presentation last week. Nice work on the animations.',
    v_last_week, v_last_week);
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Thank you! I spent a lot of time on those.',
    v_last_week + INTERVAL '10 minutes', v_last_week + INTERVAL '10 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'It shows. They specifically mentioned the loading animations. Keep up the good work!',
    v_last_week + INTERVAL '15 minutes', v_last_week + INTERVAL '15 minutes');
  
  -- Week 1: Question about vacation days
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_user_id,
    'Quick question - what''s the process for requesting time off? I''d like to take a few days in March.',
    v_last_week + INTERVAL '3 days', v_last_week + INTERVAL '3 days');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_boss, v_boss_id,
    'Just put it in the HR system and cc me. As long as it doesn''t conflict with major deadlines, should be fine!',
    v_last_week + INTERVAL '3 days 20 minutes', v_last_week + INTERVAL '3 days 20 minutes');
  
  -- Recent concerning message (RSD trigger)
  v_msg2 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg2, v_conv_boss, v_boss_id,
    'We need to talk about the project status. I expected this to be further along by now. Can we meet tomorrow at 10am?',
    v_now - INTERVAL '2 hours', v_now - INTERVAL '2 hours');
  
  -- Unanswered question (follow-up)
  v_msg3 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg3, v_conv_boss, v_boss_id,
    'Also, did you get a chance to review the updated requirements doc I sent on Monday?',
    v_now - INTERVAL '1 hour', v_now - INTERVAL '1 hour');
  
  -- AI Analysis for RSD trigger message
  INSERT INTO message_ai_analysis (
    message_id,
    tone, intent, urgency_level, confidence_score,
    intensity,
    rsd_triggers, alternative_interpretations, evidence,
    analysis_timestamp
  ) VALUES (
    v_msg2,
    'Critical/Disappointed', 'Criticism', 'high', 0.82,
    7,
    '[{"trigger": "I expected this to be further along", "severity": "high", "explanation": "Implies disappointment with your progress"}]'::jsonb,
    '[{"interpretation": "Boss is genuinely concerned about timeline", "likelihood": "high"}, {"interpretation": "Boss is under pressure from higher-ups", "likelihood": "medium"}]'::jsonb,
    '["We need to talk", "expected this to be further along"]'::jsonb,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '2 hours'))::INTEGER
  );
  
  -- AI Analysis for unanswered question
  INSERT INTO message_ai_analysis (
    message_id,
    tone, intent, urgency_level, confidence_score,
    intensity,
    analysis_timestamp
  ) VALUES (
    v_msg3,
    'Neutral/Inquiring', 'Follow-up', 'medium', 0.75,
    5,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '1 hour'))::INTEGER
  );
  
  -- Follow-up items
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_boss, v_msg2,
    'pending_response', 'Meeting request from Sarah',
    'Boss wants to meet tomorrow at 10am to discuss project status',
    'Can we meet tomorrow at 10am?',
    'pending', 85,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '2 hours'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '1 hour'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '2 hours'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '2 hours'))::INTEGER
  );
  
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_boss, v_msg3,
    'unanswered_question', 'Did you review the requirements doc?',
    'Boss asked if you reviewed the requirements document from Monday',
    'did you get a chance to review the updated requirements doc',
    'pending', 75,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '1 hour'))::INTEGER,
    EXTRACT(EPOCH FROM v_now)::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '1 hour'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '1 hour'))::INTEGER
  );
  
  -- Relationship profile
  INSERT INTO relationship_profiles (
    id, user_id, conversation_id,
    participant_name, relationship_type, relationship_notes,
    conversation_summary, communication_style,
    safe_topics, topics_to_avoid,
    typical_response_time, total_messages,
    first_message_at, last_message_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_boss,
    'Sarah Chen', 'boss', 'Project Manager - Direct but fair',
    'Work conversation focused on Q1 project. Boss has high expectations but gives credit when deserved. Be responsive and proactive.',
    'Direct and professional. Appreciates quick responses and proactive updates.',
    '["project updates", "completed work", "design feedback", "time off requests", "standup meetings"]'::jsonb,
    '["excuses", "missed meetings"]'::jsonb,
    7200, 19,
    v_two_weeks, v_now - INTERVAL '1 hour',
    NOW(), NOW()
  );
  
  -- ============================================================
  -- 2. BEST FRIEND CONVERSATION - Casual, supportive, long history
  -- ============================================================
  v_conv_friend := gen_random_uuid();
  
  INSERT INTO conversations (id, title, description, created_by, created_at, updated_at, is_group)
  VALUES (
    v_conv_friend,
    'Alex Thompson',
    'Best Friend',
    v_user_id,
    v_two_weeks - INTERVAL '1 day',
    v_now - INTERVAL '10 minutes',
    false
  );
  
  INSERT INTO conversation_participants (id, conversation_id, user_id, joined_at)
  VALUES 
    (gen_random_uuid(), v_conv_friend, v_user_id, v_two_weeks - INTERVAL '1 day'),
    (gen_random_uuid(), v_conv_friend, v_friend_id, v_two_weeks - INTERVAL '1 day');
  
  -- Long conversation with various topics (RAG showcase - 25+ messages)
  -- Week 2: TV show discussion
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'omg did you see the new episode last night?? 🤯',
    v_two_weeks, v_two_weeks);
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'YES! That plot twist was insane!',
    v_two_weeks + INTERVAL '3 minutes', v_two_weeks + INTERVAL '3 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Right?! I did NOT see that coming. Want to meet up this weekend to watch the next one together?',
    v_two_weeks + INTERVAL '6 minutes', v_two_weeks + INTERVAL '6 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'Absolutely! Saturday work for you?',
    v_two_weeks + INTERVAL '9 minutes', v_two_weeks + INTERVAL '9 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Perfect! Come over around 7? I''ll order pizza from that place on Main Street you love',
    v_two_weeks + INTERVAL '12 minutes', v_two_weeks + INTERVAL '12 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'Omg yes! The one with the garlic knots? You''re the best 🍕',
    v_two_weeks + INTERVAL '14 minutes', v_two_weeks + INTERVAL '14 minutes');
  
  -- Week 2: Later that day - checking in
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Hey how did that presentation go today? The one you were stressing about?',
    v_two_weeks + INTERVAL '8 hours', v_two_weeks + INTERVAL '8 hours');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'It went okay! I definitely rambled a bit but nobody seemed to mind',
    v_two_weeks + INTERVAL '8 hours 20 minutes', v_two_weeks + INTERVAL '8 hours 20 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'That''s great! You always think you did worse than you actually did. I bet they loved it',
    v_two_weeks + INTERVAL '8 hours 22 minutes', v_two_weeks + INTERVAL '8 hours 22 minutes');
  
  -- Week 2: Weekend plans discussion
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'Thanks for believing in me. Also, random question - do you remember the name of that book you recommended last month? The one about neurodivergence?',
    v_two_weeks + INTERVAL '1 day', v_two_weeks + INTERVAL '1 day');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Oh! "Divergent Mind" by Jenara Nerenberg? That one really helped me understand ADHD better',
    v_two_weeks + INTERVAL '1 day 5 minutes', v_two_weeks + INTERVAL '1 day 5 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'Yes that''s the one! I want to read it. I''ve been thinking a lot about why I get so overwhelmed by criticism',
    v_two_weeks + INTERVAL '1 day 8 minutes', v_two_weeks + INTERVAL '1 day 8 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'The RSD chapter is really eye-opening. It helped me understand why you shut down sometimes when you think someone''s upset with you',
    v_two_weeks + INTERVAL '1 day 10 minutes', v_two_weeks + INTERVAL '1 day 10 minutes');
  
  -- Week 1: Work stress deepens
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Saturday is perfect! How''s work going btw? You seemed stressed last week.',
    v_last_week, v_last_week);
  
  v_msg4 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg4, v_conv_friend, v_user_id,
    'Ugh yeah, my boss has been on my case about this project. I feel like I''m not doing enough even though I''m working really hard.',
    v_last_week + INTERVAL '5 minutes', v_last_week + INTERVAL '5 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Hey, I know you. You''re doing amazing. Your boss literally praised your work last month. Don''t let the RSD brain lie to you ❤️',
    v_last_week + INTERVAL '8 minutes', v_last_week + INTERVAL '8 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'I know you''re right. It''s just hard to remember that when Sarah sends me those "we need to talk" messages',
    v_last_week + INTERVAL '12 minutes', v_last_week + INTERVAL '12 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Sarah needs to learn that "we need to talk" is literally the worst possible phrase for someone with RSD. Like, just SAY what you need to say!',
    v_last_week + INTERVAL '14 minutes', v_last_week + INTERVAL '14 minutes');
  
  -- Week 1: Coffee shop incident (for context testing)
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'Remember that coffee shop we went to last time? The one near the park?',
    v_last_week + INTERVAL '2 days', v_last_week + INTERVAL '2 days');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Brew Haven? Yeah why?',
    v_last_week + INTERVAL '2 days 3 minutes', v_last_week + INTERVAL '2 days 3 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'I think they''re closed now 😢 I tried to go there this morning and there was a "for lease" sign',
    v_last_week + INTERVAL '2 days 5 minutes', v_last_week + INTERVAL '2 days 5 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'NOOO! That was our spot! Their lavender latte was literally the best thing ever',
    v_last_week + INTERVAL '2 days 7 minutes', v_last_week + INTERVAL '2 days 7 minutes');
  
  -- Mid-week: Gaming discussion
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Hey did you end up buying that game you were obsessing over?',
    v_last_week + INTERVAL '4 days', v_last_week + INTERVAL '4 days');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'YES and I stayed up until 3am playing it 😅 My sleep schedule is destroyed',
    v_last_week + INTERVAL '4 days 5 minutes', v_last_week + INTERVAL '4 days 5 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Classic hyperfocus moment lol. Was it worth it though?',
    v_last_week + INTERVAL '4 days 8 minutes', v_last_week + INTERVAL '4 days 8 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_user_id,
    'SO worth it. The storyline is incredible. Want to come over this weekend and I can show you?',
    v_last_week + INTERVAL '4 days 10 minutes', v_last_week + INTERVAL '4 days 10 minutes');
  
  -- Recent info-dump message (needs formatting support)
  v_msg5 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg5, v_conv_friend, v_user_id,
    'So I''ve been thinking about this problem with the authentication system and I realized we could use JWT tokens instead of session cookies which would make it stateless and then we could scale horizontally more easily plus it would work better with our mobile app and we wouldn''t have to worry about CORS issues anymore and also I found this really cool library that handles token refresh automatically so users won''t get logged out in the middle of using the app which was super annoying before',
    v_yesterday, v_yesterday);
  
  v_msg6 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg6, v_conv_friend, v_friend_id,
    'Haha there''s the hyperfocus! That actually sounds really smart though. You should pitch it to your team.',
    v_yesterday + INTERVAL '10 minutes', v_yesterday + INTERVAL '10 minutes');
  
  -- Recent supportive message
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_friend, v_friend_id,
    'Hey! Hope your meeting with Sarah went okay today. Remember, you got this! 💪',
    v_now - INTERVAL '10 minutes', v_now - INTERVAL '10 minutes');
  
  -- AI Analysis for info-dump
  INSERT INTO message_ai_analysis (
    message_id,
    tone, intent, urgency_level, confidence_score,
    intensity,
    analysis_timestamp
  ) VALUES (
    v_msg5,
    'Enthusiastic/Excited', 'Sharing', 'low', 0.88,
    8,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER
  );
  
  -- Relationship profile
  INSERT INTO relationship_profiles (
    id, user_id, conversation_id,
    participant_name, relationship_type, relationship_notes,
    conversation_summary, communication_style,
    safe_topics, topics_to_avoid,
    typical_response_time, total_messages,
    first_message_at, last_message_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_friend,
    'Alex Thompson', 'friend', 'Best friend since college - very supportive',
    'Long-time friend who understands ADHD/RSD. Very supportive and encouraging. Safe to share work stress and hyperfocus interests.',
    'Casual, supportive, uses emojis. Responds quickly. Very understanding.',
    '["TV shows", "work venting", "tech deep-dives", "mental health", "gaming", "coffee shops", "books"]'::jsonb,
    '[]'::jsonb,
    600, 30,
    v_two_weeks, v_now - INTERVAL '10 minutes',
    NOW(), NOW()
  );
  
  -- ============================================================
  -- 3. MOM CONVERSATION - Caring but can trigger anxiety
  -- ============================================================
  v_conv_mom := gen_random_uuid();
  
  INSERT INTO conversations (id, title, description, created_by, created_at, updated_at, is_group)
  VALUES (
    v_conv_mom,
    'Mom',
    'Family',
    v_user_id,
    v_two_weeks - INTERVAL '5 days',
    v_now - INTERVAL '30 minutes',
    false
  );
  
  INSERT INTO conversation_participants (id, conversation_id, user_id, joined_at)
  VALUES 
    (gen_random_uuid(), v_conv_mom, v_user_id, v_two_weeks - INTERVAL '5 days'),
    (gen_random_uuid(), v_conv_mom, v_mom_id, v_two_weeks - INTERVAL '5 days');
  
  -- Messages with caring but potentially anxiety-inducing content
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_mom, v_mom_id,
    'Hi honey! Just checking in. How are you doing?',
    v_last_week, v_last_week);
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_mom, v_user_id,
    'Hey Mom! I''m good, just busy with work.',
    v_last_week + INTERVAL '1 hour', v_last_week + INTERVAL '1 hour');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_mom, v_mom_id,
    'That''s good! Are you eating properly? Getting enough sleep? You know how you get when you''re stressed.',
    v_last_week + INTERVAL '65 minutes', v_last_week + INTERVAL '65 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_mom, v_user_id,
    'Yes Mom, I''m taking care of myself. 😊',
    v_last_week + INTERVAL '70 minutes', v_last_week + INTERVAL '70 minutes');
  
  -- Multiple questions (follow-up items)
  v_msg7 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg7, v_conv_mom, v_mom_id,
    'Your aunt Linda''s birthday is next month. Are you going to be able to make it to the party? It would mean a lot to her.',
    v_yesterday, v_yesterday);
  
  v_msg8 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg8, v_conv_mom, v_mom_id,
    'Also, have you scheduled your dentist appointment yet? I know you''ve been putting it off.',
    v_now - INTERVAL '30 minutes', v_now - INTERVAL '30 minutes');
  
  -- Follow-up items
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_mom, v_msg7,
    'unanswered_question', 'Aunt Linda''s birthday party',
    'Mom asking if you can attend Aunt Linda''s birthday party next month',
    'Are you going to be able to make it to the party?',
    'pending', 60,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '12 hours'))::INTEGER,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER
  );
  
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_mom, v_msg8,
    'action_item', 'Schedule dentist appointment',
    'Mom reminding you to schedule dentist appointment',
    'have you scheduled your dentist appointment yet',
    'pending', 65,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '30 minutes'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '1 day'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '30 minutes'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '30 minutes'))::INTEGER
  );
  
  -- Relationship profile
  INSERT INTO relationship_profiles (
    id, user_id, conversation_id,
    participant_name, relationship_type, relationship_notes,
    conversation_summary, communication_style,
    safe_topics, topics_to_avoid,
    typical_response_time, total_messages,
    first_message_at, last_message_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_mom,
    'Mom', 'family', 'Mother - very caring, can be a bit much sometimes',
    'Mom checks in regularly. Very caring but can ask a lot of questions at once. Means well but can trigger anxiety about adulting tasks.',
    'Caring but can be overwhelming. Asks multiple questions. Appreciates updates.',
    '["work achievements", "positive life updates", "family events"]'::jsonb,
    '["detailed health info", "relationship drama"]'::jsonb,
    7200, 7,
    v_two_weeks - INTERVAL '5 days', v_now - INTERVAL '30 minutes',
    NOW(), NOW()
  );
  
  -- ============================================================
  -- 4. CLIENT CONVERSATION - Professional, needs careful responses
  -- ============================================================
  v_conv_client := gen_random_uuid();
  
  INSERT INTO conversations (id, title, description, created_by, created_at, updated_at, is_group)
  VALUES (
    v_conv_client,
    'Marcus Williams (TechCorp)',
    'Client - Lead Developer',
    v_user_id,
    v_last_week,
    v_now - INTERVAL '15 minutes',
    false
  );
  
  INSERT INTO conversation_participants (id, conversation_id, user_id, joined_at)
  VALUES 
    (gen_random_uuid(), v_conv_client, v_user_id, v_last_week),
    (gen_random_uuid(), v_conv_client, v_client_id, v_last_week);
  
  -- Professional conversation
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_client, v_client_id,
    'Hi! Thanks for taking on this project. We''re excited to work with you.',
    v_last_week, v_last_week);
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_client, v_user_id,
    'Thank you! I''m excited too. Looking forward to seeing the requirements.',
    v_last_week + INTERVAL '30 minutes', v_last_week + INTERVAL '30 minutes');
  
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (gen_random_uuid(), v_conv_client, v_client_id,
    'I''ve sent over the initial specs. Let me know if you have any questions.',
    v_last_week + INTERVAL '2 hours', v_last_week + INTERVAL '2 hours');
  
  -- Boundary-testing request
  v_msg9 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg9, v_conv_client, v_client_id,
    'Quick question - would it be possible to have the beta ready by end of this week instead of next week? Our stakeholders are getting antsy.',
    v_yesterday, v_yesterday);
  
  -- Action item with deadline
  v_msg10 := gen_random_uuid();
  INSERT INTO messages (id, conversation_id, sender_id, body, created_at, updated_at)
  VALUES (v_msg10, v_conv_client, v_client_id,
    'Also, I''ll need you to join our team meeting next Tuesday at 2pm to present the progress so far.',
    v_now - INTERVAL '15 minutes', v_now - INTERVAL '15 minutes');
  
  -- AI Analysis
  INSERT INTO message_ai_analysis (
    message_id,
    tone, intent, urgency_level, confidence_score,
    intensity,
    rsd_triggers,
    analysis_timestamp
  ) VALUES (
    v_msg9,
    'Polite/Urgent', 'Request', 'high', 0.79,
    6,
    '[{"trigger": "stakeholders are getting antsy", "severity": "medium", "explanation": "Implies external pressure and urgency"}]'::jsonb,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER
  );
  
  -- Follow-up items
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, due_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_client, v_msg9,
    'pending_response', 'Early beta deadline request',
    'Client asking if beta can be ready by end of this week (earlier than planned)',
    'would it be possible to have the beta ready by end of this week',
    'pending', 80,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '3 days'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '12 hours'))::INTEGER,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER,
    EXTRACT(EPOCH FROM v_yesterday)::INTEGER
  );
  
  INSERT INTO follow_up_items (
    id, user_id, conversation_id, message_id,
    item_type, title, description, extracted_text,
    status, priority,
    detected_at, due_at, remind_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_client, v_msg10,
    'action_item', 'Team meeting presentation - Tuesday 2pm',
    'Need to prepare and present project progress at client team meeting',
    'I''ll need you to join our team meeting next Tuesday at 2pm',
    'pending', 90,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '15 minutes'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '5 days 14 hours'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now + INTERVAL '4 days'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '15 minutes'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '15 minutes'))::INTEGER
  );
  
  -- Action item details
  INSERT INTO action_items (
    id, follow_up_item_id,
    action_type, action_target, commitment_text,
    mentioned_deadline, extracted_deadline,
    created_at
  ) VALUES (
    gen_random_uuid(),
    (SELECT id FROM follow_up_items WHERE message_id = v_msg10),
    'meet', 'Team presentation',
    'join our team meeting next Tuesday at 2pm to present the progress',
    'next Tuesday at 2pm',
    EXTRACT(EPOCH FROM (v_now + INTERVAL '5 days 14 hours'))::INTEGER,
    EXTRACT(EPOCH FROM (v_now - INTERVAL '15 minutes'))::INTEGER
  );
  
  -- Relationship profile
  INSERT INTO relationship_profiles (
    id, user_id, conversation_id,
    participant_name, relationship_type, relationship_notes,
    conversation_summary, communication_style,
    safe_topics, topics_to_avoid,
    typical_response_time, total_messages,
    first_message_at, last_message_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_client,
    'Marcus Williams', 'client', 'TechCorp Lead Developer - Professional client',
    'New client project. Professional and polite. Can be pushy about deadlines due to stakeholder pressure. Important to set clear boundaries.',
    'Professional and direct. Responds during business hours. Expects timely responses to requests.',
    '["project updates", "technical discussions", "timeline clarifications"]'::jsonb,
    '["personal topics", "negative feedback about stakeholders"]'::jsonb,
    14400, 5,
    v_last_week, v_now - INTERVAL '15 minutes',
    NOW(), NOW()
  );
  
  -- ============================================================
  -- CONTEXT CACHE (for quick context loading)
  -- ============================================================
  
  INSERT INTO conversation_context_cache (
    id, user_id, conversation_id,
    last_discussed, key_points, pending_questions,
    generated_at, expires_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_boss,
    'Project timeline and progress concerns',
    '["Boss wants meeting tomorrow at 10am", "Missed standup incident resolved", "Client loved animations presentation", "Requesting time off in March", "Q1 project designs approved"]'::jsonb,
    '["Did you review the requirements doc from Monday?"]'::jsonb,
    NOW(), NOW() + INTERVAL '24 hours'
  );
  
  INSERT INTO conversation_context_cache (
    id, user_id, conversation_id,
    last_discussed, key_points, pending_questions,
    generated_at, expires_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_friend,
    'Work stress, gaming, and supportive friendship',
    '["Watching TV show together Saturday at 7pm", "Pizza from Main Street place", "Brew Haven coffee shop closed", "Gaming hyperfocus session until 3am", "Book recommendation: Divergent Mind", "Friend understands RSD and ADHD", "JWT authentication idea excited about", "Presentation went well despite rambling"]'::jsonb,
    '[]'::jsonb,
    NOW(), NOW() + INTERVAL '24 hours'
  );
  
  INSERT INTO conversation_context_cache (
    id, user_id, conversation_id,
    last_discussed, key_points, pending_questions,
    generated_at, expires_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_client,
    'Project deadlines and presentation request',
    '["Client wants beta earlier than planned", "Presentation needed Tuesday 2pm", "Stakeholders getting impatient"]'::jsonb,
    '["Can you deliver beta by end of this week?"]'::jsonb,
    NOW(), NOW() + INTERVAL '24 hours'
  );
  
  -- ============================================================
  -- SAFE TOPICS TRACKING
  -- ============================================================
  
  INSERT INTO safe_topics (
    id, user_id, conversation_id,
    topic_name, topic_keywords,
    message_count, avg_response_time, positive_tone_rate,
    is_safe, last_discussed,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_boss,
    'design work', '["animations", "presentation", "designs"]'::jsonb,
    3, 1800, 0.85,
    true, v_last_week,
    NOW(), NOW()
  );
  
  INSERT INTO safe_topics (
    id, user_id, conversation_id,
    topic_name, topic_keywords,
    message_count, avg_response_time, positive_tone_rate,
    is_safe, last_discussed,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_friend,
    'TV shows', '["episode", "plot twist", "watching"]'::jsonb,
    4, 300, 0.95,
    true, v_two_weeks,
    NOW(), NOW()
  );
  
  INSERT INTO safe_topics (
    id, user_id, conversation_id,
    topic_name, topic_keywords,
    message_count, avg_response_time, positive_tone_rate,
    is_safe, last_discussed,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id, v_conv_friend,
    'tech deep-dives', '["authentication", "JWT", "library", "hyperfocus"]'::jsonb,
    2, 600, 0.90,
    true, v_yesterday,
    NOW(), NOW()
  );
  
  RAISE NOTICE '✅ Showcase data seeded successfully!';
  RAISE NOTICE '📊 Created:';
  RAISE NOTICE '   • 4 fake user profiles (Sarah Chen, Alex Thompson, Mom, Marcus Williams)';
  RAISE NOTICE '   • 4 conversations with 70+ messages (enhanced for RAG)';
  RAISE NOTICE '   • 6 follow-up items (action items, questions)';
  RAISE NOTICE '   • 4 relationship profiles with context';
  RAISE NOTICE '   • 3 conversation context caches';
  RAISE NOTICE '   • 3 safe topic entries';
  RAISE NOTICE '';
  RAISE NOTICE '🤖 RAG Feature Showcase:';
  RAISE NOTICE '   • Boss conversation: 19 messages over 2 weeks';
  RAISE NOTICE '   • Friend conversation: 30 messages with rich context';
  RAISE NOTICE '   • Multiple topics: work, gaming, coffee shops, books, mental health';
  RAISE NOTICE '   • Relationship details for context retrieval';
  RAISE NOTICE '';
  RAISE NOTICE '🧹 To clean up: DELETE FROM profiles WHERE user_id IN (';
  RAISE NOTICE '     ''a0000000-0000-0000-0000-000000000001'',';
  RAISE NOTICE '     ''a0000000-0000-0000-0000-000000000002'',';
  RAISE NOTICE '     ''a0000000-0000-0000-0000-000000000003'',';
  RAISE NOTICE '     ''a0000000-0000-0000-0000-000000000004''';
  RAISE NOTICE '   );';
  
END $$;

