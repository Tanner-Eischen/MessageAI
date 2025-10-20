-- RLS Policies for messages table
-- Users can only read messages in conversations they are participants in
-- Users can only send messages to conversations they are participants in

-- SELECT: Users can read messages in conversations they are in
CREATE POLICY "Users can read messages in their conversations" 
  ON messages FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = messages.conversation_id 
      AND user_id = auth.uid()
    )
  );

-- INSERT: Users can send messages to conversations they are in
CREATE POLICY "Users can send messages to their conversations" 
  ON messages FOR INSERT 
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = messages.conversation_id 
      AND user_id = auth.uid()
    )
  );

-- UPDATE: Users can only edit their own messages
CREATE POLICY "Users can edit their own messages" 
  ON messages FOR UPDATE 
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

-- DELETE: Users can delete their own messages
CREATE POLICY "Users can delete their own messages" 
  ON messages FOR DELETE 
  USING (sender_id = auth.uid());
