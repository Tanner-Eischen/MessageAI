-- RLS Policies for conversation_participants table
-- Users can manage their own participation in conversations

-- SELECT: Users can view participant lists of conversations they are in
CREATE POLICY "Participants viewable by conversation members" 
  ON conversation_participants FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants AS cp
      WHERE cp.conversation_id = conversation_participants.conversation_id 
      AND cp.user_id = auth.uid()
    )
  );

-- INSERT: Users can join conversations
CREATE POLICY "Users can join conversations" 
  ON conversation_participants FOR INSERT 
  WITH CHECK (user_id = auth.uid());

-- UPDATE: Users can update their own participation record (e.g., last_read_at)
CREATE POLICY "Users can update their own participation" 
  ON conversation_participants FOR UPDATE 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: Users can leave conversations
CREATE POLICY "Users can leave conversations" 
  ON conversation_participants FOR DELETE 
  USING (user_id = auth.uid());
