-- RAG Features Showcase Conversation
-- This creates a rich conversation demonstrating context building, relationship memory, and safe topics
-- User: tannereischen@gmail.com (3fc05b89-5341-413d-ad5b-bcceccc6ae53)

-- First, create a second user (Sarah, a project manager colleague)
INSERT INTO public.profiles (user_id, username, email, display_name, bio)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'sarah.chen@company.com',
  'sarah.chen@company.com',
  'Sarah Chen',
  'Senior Project Manager | Tech enthusiast | Coffee addict'
) 
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  email = EXCLUDED.email,
  display_name = EXCLUDED.display_name,
  bio = EXCLUDED.bio;

-- Create the conversation
INSERT INTO public.conversations (id, title, created_by, is_group, created_at, updated_at)
VALUES (
  'aaaaaaaa-0001-0000-0000-000000000001',
  'Sarah Chen',
  '3fc05b89-5341-413d-ad5b-bcceccc6ae53',
  false,
  NOW() - INTERVAL '45 days',
  NOW()
) 
ON CONFLICT (id) DO NOTHING;

-- Add participants
INSERT INTO public.conversation_participants (conversation_id, user_id, joined_at)
VALUES 
  ('aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', NOW() - INTERVAL '45 days'),
  ('aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', NOW() - INTERVAL '45 days')
ON CONFLICT (conversation_id, user_id) DO NOTHING;

-- Create messages showing relationship development over 6 weeks
-- Week 1: Initial project kickoff (professional, getting to know each other)

INSERT INTO public.messages (id, conversation_id, sender_id, body, created_at, updated_at)
VALUES 
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Hi Tanner! I''m Sarah, I''ll be the PM for the new mobile app project. Looking forward to working with you!', 
   NOW() - INTERVAL '45 days' + INTERVAL '9 hours', NOW() - INTERVAL '45 days' + INTERVAL '9 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Hey Sarah! Great to meet you. I''m excited about this project. What''s our first step?', 
   NOW() - INTERVAL '45 days' + INTERVAL '9 hours' + INTERVAL '15 minutes', NOW() - INTERVAL '45 days' + INTERVAL '9 hours' + INTERVAL '15 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Can you review the requirements doc, set up the initial Flutter project structure, and create the authentication module? I need these by Friday for the stakeholder meeting.', 
   NOW() - INTERVAL '45 days' + INTERVAL '10 hours', NOW() - INTERVAL '45 days' + INTERVAL '10 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Sure thing! I''ll have everything ready by Thursday evening so you have time to review before the meeting.', 
   NOW() - INTERVAL '45 days' + INTERVAL '10 hours' + INTERVAL '20 minutes', NOW() - INTERVAL '45 days' + INTERVAL '10 hours' + INTERVAL '20 minutes'),

-- Week 1: Late evening message (boundary violation - after hours)
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Hey, sorry to message so late. Can you also add the user profile screen to your deliverables? The CEO just requested it.', 
   NOW() - INTERVAL '44 days' + INTERVAL '22 hours', NOW() - INTERVAL '44 days' + INTERVAL '22 hours'),

-- Week 2: Building context - discovering working styles
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'No worries! I can add that. For future reference though, I usually wrap up around 6 PM. Morning messages work better for me.', 
   NOW() - INTERVAL '44 days' + INTERVAL '22 hours' + INTERVAL '10 minutes', NOW() - INTERVAL '44 days' + INTERVAL '22 hours' + INTERVAL '10 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Totally understand! I''m a night owl but I''ll respect your schedule. Thanks for being flexible on this one!', 
   NOW() - INTERVAL '44 days' + INTERVAL '22 hours' + INTERVAL '25 minutes', NOW() - INTERVAL '44 days' + INTERVAL '22 hours' + INTERVAL '25 minutes'),

  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'BTW, the stakeholder meeting went amazing! They loved your authentication flow. Great work!', 
   NOW() - INTERVAL '41 days' + INTERVAL '14 hours', NOW() - INTERVAL '41 days' + INTERVAL '14 hours'),

-- Week 2: Discovering safe topics
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'That''s awesome! Thanks! I really enjoyed working on the UI animations. Flutter''s animation system is so powerful.', 
   NOW() - INTERVAL '41 days' + INTERVAL '14 hours' + INTERVAL '30 minutes', NOW() - INTERVAL '41 days' + INTERVAL '14 hours' + INTERVAL '30 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'I can tell you''re passionate about animations! The smooth transitions really impressed everyone. Do you have a favorite Flutter package?', 
   NOW() - INTERVAL '41 days' + INTERVAL '15 hours', NOW() - INTERVAL '41 days' + INTERVAL '15 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Definitely Riverpod for state management! It makes everything so clean. Also love the Drift package for local storage.', 
   NOW() - INTERVAL '41 days' + INTERVAL '15 hours' + INTERVAL '10 minutes', NOW() - INTERVAL '41 days' + INTERVAL '15 hours' + INTERVAL '10 minutes'),

-- Week 3: More complex multi-action requests
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'For this week, can you implement the messaging screen, add the real-time sync feature, and update the database schema?', 
   NOW() - INTERVAL '38 days' + INTERVAL '10 hours', NOW() - INTERVAL '38 days' + INTERVAL '10 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'That''s a lot for one week! I can definitely do the messaging screen and real-time sync. The schema update might need to wait until next week to do it properly.', 
   NOW() - INTERVAL '38 days' + INTERVAL '10 hours' + INTERVAL '45 minutes', NOW() - INTERVAL '38 days' + INTERVAL '10 hours' + INTERVAL '45 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Good call - quality over speed! Let''s prioritize the messaging screen then. That''s the most critical feature right now.', 
   NOW() - INTERVAL '38 days' + INTERVAL '11 hours', NOW() - INTERVAL '38 days' + INTERVAL '11 hours'),

-- Week 3: Building trust and context
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'I really appreciate how you push back when timelines are unrealistic. A lot of devs just say yes and then burn out.', 
   NOW() - INTERVAL '37 days' + INTERVAL '13 hours', NOW() - INTERVAL '37 days' + INTERVAL '13 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Thanks! I learned that the hard way early in my career. Setting realistic expectations helps everyone in the long run.', 
   NOW() - INTERVAL '37 days' + INTERVAL '13 hours' + INTERVAL '20 minutes', NOW() - INTERVAL '37 days' + INTERVAL '13 hours' + INTERVAL '20 minutes'),

-- Week 4: Project challenge - potential RSD trigger moment
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'The backend team is saying the API endpoints you requested aren''t aligned with their architecture. We might need to redesign the data layer.', 
   NOW() - INTERVAL '31 days' + INTERVAL '11 hours', NOW() - INTERVAL '31 days' + INTERVAL '11 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Oh no, I thought I followed their spec! Should I have checked with them first? I can rebuild it however they need.', 
   NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '15 minutes', NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '15 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'No no, this isn''t on you at all! Their spec was outdated - I just found out. You did everything perfectly. I''ll set up a meeting with them to sort this out.', 
   NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '25 minutes', NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '25 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Phew! Thanks for having my back. Let me know what we decide in the meeting and I''ll adjust accordingly.', 
   NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '35 minutes', NOW() - INTERVAL '31 days' + INTERVAL '11 hours' + INTERVAL '35 minutes'),

-- Week 4: Resolution and positive reinforcement
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Update: Meeting went well! Backend team will adapt to your approach. They actually said your design is cleaner than their original plan.', 
   NOW() - INTERVAL '30 days' + INTERVAL '14 hours', NOW() - INTERVAL '30 days' + INTERVAL '14 hours'),

-- Week 5: More safe topics - team bonding
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'That''s such a relief! This project is really coming together. I''m loving how collaborative this team is.', 
   NOW() - INTERVAL '24 days' + INTERVAL '10 hours', NOW() - INTERVAL '24 days' + INTERVAL '10 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Same! You''re a big part of why it''s going so well. Quick question - are you going to the company tech conference next month?', 
   NOW() - INTERVAL '24 days' + INTERVAL '10 hours' + INTERVAL '30 minutes', NOW() - INTERVAL '24 days' + INTERVAL '10 hours' + INTERVAL '30 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'I''m planning to! There''s a Flutter workshop I really want to attend. Are you going?', 
   NOW() - INTERVAL '24 days' + INTERVAL '10 hours' + INTERVAL '45 minutes', NOW() - INTERVAL '24 days' + INTERVAL '10 hours' + INTERVAL '45 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Yes! We should grab coffee there and talk about mobile development trends. I''ve been wanting to learn more about Flutter.', 
   NOW() - INTERVAL '24 days' + INTERVAL '11 hours', NOW() - INTERVAL '24 days' + INTERVAL '11 hours'),

-- Week 5: Complex action items again
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'For the demo next week, can you polish the animations, fix the login bug that QA found, and add the dark mode toggle?', 
   NOW() - INTERVAL '17 days' + INTERVAL '9 hours', NOW() - INTERVAL '17 days' + INTERVAL '9 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Login bug is priority #1, animations are already smooth but I can add some polish. Dark mode might be tight - is that a must-have for the demo?', 
   NOW() - INTERVAL '17 days' + INTERVAL '9 hours' + INTERVAL '30 minutes', NOW() - INTERVAL '17 days' + INTERVAL '9 hours' + INTERVAL '30 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Good point - let''s drop dark mode for now. The animations already look great anyway! Focus on squashing that bug.', 
   NOW() - INTERVAL '17 days' + INTERVAL '10 hours', NOW() - INTERVAL '17 days' + INTERVAL '10 hours'),

-- Week 6: Demo success and personal touch
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'DEMO WAS AMAZING! The executives loved everything. They specifically called out the smooth UX. You absolutely crushed it!', 
   NOW() - INTERVAL '10 days' + INTERVAL '16 hours', NOW() - INTERVAL '10 days' + INTERVAL '16 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Thank you so much! This has been one of my favorite projects. Working with you made it so much better.', 
   NOW() - INTERVAL '10 days' + INTERVAL '16 hours' + INTERVAL '20 minutes', NOW() - INTERVAL '10 days' + INTERVAL '16 hours' + INTERVAL '20 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Likewise! I hope we get to work together on more projects. You really understand how to balance quality with deadlines.', 
   NOW() - INTERVAL '10 days' + INTERVAL '16 hours' + INTERVAL '35 minutes', NOW() - INTERVAL '10 days' + INTERVAL '16 hours' + INTERVAL '35 minutes'),

-- Recent: Weekend message (boundary)
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Hey! I know it''s Sunday, but just got word that we need to prepare a technical presentation for the board meeting tomorrow. Can you create the slides and walk through the architecture?', 
   NOW() - INTERVAL '2 days' + INTERVAL '14 hours', NOW() - INTERVAL '2 days' + INTERVAL '14 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'I appreciate the heads up, but I''m actually out hiking today (trying to unplug on weekends). Can we chat tomorrow morning at 8 AM to plan this?', 
   NOW() - INTERVAL '2 days' + INTERVAL '15 hours', NOW() - INTERVAL '2 days' + INTERVAL '15 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Of course! Sorry for the weekend intrusion. Enjoy your hike! 8 AM tomorrow works perfectly. I will have coffee ready.', 
   NOW() - INTERVAL '2 days' + INTERVAL '15 hours' + INTERVAL '15 minutes', NOW() - INTERVAL '2 days' + INTERVAL '15 hours' + INTERVAL '15 minutes'),

-- Recent: Continued collaboration
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Perfect! See you tomorrow. Thanks for understanding about weekends - work-life balance is important to me.', 
   NOW() - INTERVAL '2 days' + INTERVAL '15 hours' + INTERVAL '25 minutes', NOW() - INTERVAL '2 days' + INTERVAL '15 hours' + INTERVAL '25 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Totally respect that! I''m trying to get better at it myself. Your boundaries have been a good reminder for me.', 
   NOW() - INTERVAL '2 days' + INTERVAL '16 hours', NOW() - INTERVAL '2 days' + INTERVAL '16 hours'),

-- Most recent: Latest planning
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Quick update: Board meeting was moved to Wednesday, so we have more time. Can you review the API documentation, update the readme file, and test the offline mode?', 
   NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'Great! That gives us breathing room. I''ll knock out all three today and have them ready for your review by 5 PM.', 
   NOW() - INTERVAL '5 hours' + INTERVAL '45 minutes', NOW() - INTERVAL '5 hours' + INTERVAL '45 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'You''re the best! Also, random question - do you like working on AI features? We just got approved for a new AI messaging assistant project.', 
   NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', '3fc05b89-5341-413d-ad5b-bcceccc6ae53', 
   'AI features are fascinating! I''ve been experimenting with integrating OpenAI APIs into Flutter apps. I''d love to be part of that project!', 
   NOW() - INTERVAL '2 hours' + INTERVAL '30 minutes', NOW() - INTERVAL '2 hours' + INTERVAL '30 minutes'),
  
  (gen_random_uuid(), 'aaaaaaaa-0001-0000-0000-000000000001', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 
   'Perfect! I''ll make sure you''re on the team. This could be really exciting - think smart message interpretation, sentiment analysis, all that good stuff.', 
   NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour');

-- Add read receipts for all messages from Sarah (showing engagement)
INSERT INTO public.message_receipts (id, message_id, user_id, status)
SELECT 
  gen_random_uuid(),
  m.id,
  '3fc05b89-5341-413d-ad5b-bcceccc6ae53',
  'read'
FROM public.messages m
WHERE m.conversation_id = 'aaaaaaaa-0001-0000-0000-000000000001'
  AND m.sender_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
ON CONFLICT (message_id, user_id) DO NOTHING;

-- Add read receipts for Tanner's messages
INSERT INTO public.message_receipts (id, message_id, user_id, status)
SELECT 
  gen_random_uuid(),
  m.id,
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'read'
FROM public.messages m
WHERE m.conversation_id = 'aaaaaaaa-0001-0000-0000-000000000001'
  AND m.sender_id = '3fc05b89-5341-413d-ad5b-bcceccc6ae53'
ON CONFLICT (message_id, user_id) DO NOTHING;

-- Summary of what this conversation demonstrates:
-- 1. RELATIONSHIP DEVELOPMENT: Professional to friendly working relationship over 6 weeks
-- 2. SAFE TOPICS: Flutter, animations, state management, work-life balance, conferences
-- 3. BOUNDARY ESTABLISHMENT: Tanner sets clear boundaries about after-hours and weekends
-- 4. MULTI-ACTION ITEMS: Multiple messages with compound action requests
-- 5. RSD TRIGGER MOMENTS: Self-doubt moment that gets resolved with reassurance
-- 6. POSITIVE PATTERNS: Sarah learns and respects boundaries, gives positive feedback
-- 7. CONTEXT BUILDING: Rich history of successful collaboration
-- 8. AFTER-HOURS MESSAGES: Several boundary violation examples
-- 9. TRUST BUILDING: Both parties show vulnerability and support
-- 10. SHARED INTERESTS: Technology, quality work, professional development
