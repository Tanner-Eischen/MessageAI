-- Fix infinite recursion in RLS policies
-- This migration drops problematic policies and replaces them with functions

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view conversations they are in" ON conversations;
DROP POLICY IF EXISTS "Users can view participant lists of conversations they are in" ON conversation_participants;
DROP POLICY IF EXISTS "Users can read messages in conversations they are in" ON messages;
DROP POLICY IF EXISTS "Users can send messages to conversations they are in" ON messages;
DROP POLICY IF EXISTS "Users can mark receipts for messages in their conversations" ON message_receipts;

-- ============================================================================
-- Helper function to check if user is conversation participant
-- ============================================================================
CREATE OR REPLACE FUNCTION is_conversation_participant(conv_id UUID, check_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER  -- Run with elevated privileges to bypass RLS
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM conversation_participants 
    WHERE conversation_id = conv_id 
    AND user_id = check_user_id
  );
END;
$$;

-- ============================================================================
-- RLS Policies: conversations (FIXED)
-- ============================================================================
CREATE POLICY "Users can view conversations they are in" 
  ON conversations FOR SELECT 
  USING (is_conversation_participant(id, auth.uid()));

-- ============================================================================
-- RLS Policies: conversation_participants (FIXED)
-- ============================================================================
CREATE POLICY "Users can view participant lists of conversations they are in" 
  ON conversation_participants FOR SELECT 
  USING (is_conversation_participant(conversation_id, auth.uid()));

-- ============================================================================
-- RLS Policies: messages (FIXED)
-- ============================================================================
CREATE POLICY "Users can read messages in conversations they are in" 
  ON messages FOR SELECT 
  USING (is_conversation_participant(conversation_id, auth.uid()));

CREATE POLICY "Users can send messages to conversations they are in" 
  ON messages FOR INSERT 
  WITH CHECK (
    is_conversation_participant(conversation_id, auth.uid()) 
    AND sender_id = auth.uid()
  );

-- ============================================================================
-- RLS Policies: message_receipts (FIXED)
-- ============================================================================
CREATE POLICY "Users can view receipts for messages in their conversations" 
  ON message_receipts FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_receipts.message_id
      AND is_conversation_participant(m.conversation_id, auth.uid())
    )
  );

CREATE POLICY "Users can mark receipts for messages in their conversations" 
  ON message_receipts FOR INSERT 
  WITH CHECK (
    user_id = auth.uid() 
    AND EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_receipts.message_id
      AND is_conversation_participant(m.conversation_id, auth.uid())
    )
  );

CREATE POLICY "Users can update their own receipts" 
  ON message_receipts FOR UPDATE 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

