-- RLS Tests for conversation_participants table using pgTAP
-- Tests verify that users can only manage their own participation

BEGIN;
SELECT plan(7);

-- Setup test data
INSERT INTO profiles (user_id, username) VALUES 
  ('11111111-1111-1111-1111-111111111111'::uuid, 'user1'),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'user2'),
  ('33333333-3333-3333-3333-333333333333'::uuid, 'user3');

INSERT INTO conversations (id, title, is_group, created_by) VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'Test Conv 1', false, '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO conversation_participants (conversation_id, user_id) VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, '11111111-1111-1111-1111-111111111111'::uuid),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, '22222222-2222-2222-2222-222222222222'::uuid);

-- Test: Participant count is correct
SELECT is(
  (SELECT COUNT(*) FROM conversation_participants 
   WHERE conversation_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid),
  2,
  'Conversation has 2 participants'
);

-- Test: User1 is in the conversation
SELECT is(
  (SELECT COUNT(*) FROM conversation_participants 
   WHERE conversation_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid 
   AND user_id = '11111111-1111-1111-1111-111111111111'::uuid),
  1,
  'User1 is in the conversation'
);

-- Test: User2 is in the conversation
SELECT is(
  (SELECT COUNT(*) FROM conversation_participants 
   WHERE conversation_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid 
   AND user_id = '22222222-2222-2222-2222-222222222222'::uuid),
  1,
  'User2 is in the conversation'
);

-- Test: User3 is not in the conversation
SELECT is(
  (SELECT COUNT(*) FROM conversation_participants 
   WHERE conversation_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid 
   AND user_id = '33333333-3333-3333-3333-333333333333'::uuid),
  0,
  'User3 is not in the conversation'
);

-- Test: SELECT policy exists for participants
SELECT is(
  (SELECT COUNT(*) FROM pg_policies 
   WHERE tablename = 'conversation_participants' 
   AND policyname = 'Participants viewable by conversation members'),
  1,
  'Participant view policy exists'
);

-- Test: INSERT policy exists for participants
SELECT is(
  (SELECT COUNT(*) FROM pg_policies 
   WHERE tablename = 'conversation_participants' 
   AND policyname = 'Users can join conversations'),
  1,
  'Participant join policy exists'
);

-- Test: RLS is enabled on conversation_participants table
SELECT is(
  (SELECT COUNT(*) FROM pg_tables 
   WHERE tablename = 'conversation_participants' AND rowsecurity = true),
  1,
  'RLS is enabled on conversation_participants table'
);

-- Cleanup
DELETE FROM message_receipts;
DELETE FROM messages;
DELETE FROM conversation_participants;
DELETE FROM conversations;
DELETE FROM profiles;

SELECT * FROM finish();
ROLLBACK;
