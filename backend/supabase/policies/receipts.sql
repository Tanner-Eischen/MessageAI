-- RLS Policies for message_receipts table
-- Users can only see receipts for messages in conversations they are in
-- Users can only create receipts for themselves

-- SELECT: Users can read receipts for messages in their conversations
CREATE POLICY "Users can read receipts from their conversations" 
  ON message_receipts FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM messages 
      WHERE messages.id = message_receipts.message_id
      AND EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = messages.conversation_id 
        AND user_id = auth.uid()
      )
    )
  );

-- INSERT: Users can create receipts for messages in conversations they are in
CREATE POLICY "Users can create receipts in their conversations" 
  ON message_receipts FOR INSERT 
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM messages 
      WHERE messages.id = message_receipts.message_id
      AND EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = messages.conversation_id 
        AND user_id = auth.uid()
      )
    )
  );

-- UPDATE: Users can update their own receipts (e.g., marking as read)
CREATE POLICY "Users can update their own receipts" 
  ON message_receipts FOR UPDATE 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: Users can delete their own receipts
CREATE POLICY "Users can delete their own receipts" 
  ON message_receipts FOR DELETE 
  USING (user_id = auth.uid());
