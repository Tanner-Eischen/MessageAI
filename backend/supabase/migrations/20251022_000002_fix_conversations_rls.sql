-- Fix RLS policy for conversations table
-- Allow authenticated users to create conversations

-- First, check if the policy already exists and drop it if needed
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;

-- Create policy allowing authenticated users to insert conversations
CREATE POLICY "Users can create conversations"
ON conversations
FOR INSERT
TO authenticated
WITH CHECK (
  -- User must be the creator of the conversation
  created_by = auth.uid()
);

-- Also ensure users can read conversations they're participating in
DROP POLICY IF EXISTS "Users can read their conversations" ON conversations;

CREATE POLICY "Users can read their conversations"
ON conversations
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = conversations.id
    AND user_id = auth.uid()
  )
);

-- Allow users to update conversations they created
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;

CREATE POLICY "Users can update their conversations"
ON conversations
FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());


