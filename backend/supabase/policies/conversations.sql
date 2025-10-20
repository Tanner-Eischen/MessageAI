-- RLS Policies for conversations table
-- Users can only view and interact with conversations they are members of

-- SELECT: Users can view conversations they are participants in
CREATE POLICY "Conversations are viewable by participants" 
  ON conversations FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = conversations.id 
      AND user_id = auth.uid()
    )
  );

-- INSERT: Users can create new conversations
CREATE POLICY "Users can create conversations" 
  ON conversations FOR INSERT 
  WITH CHECK (auth.uid() = created_by);

-- UPDATE: Users can update conversations they created
CREATE POLICY "Conversation creators can update conversations" 
  ON conversations FOR UPDATE 
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- DELETE: Conversation creators can delete conversations
CREATE POLICY "Conversation creators can delete conversations" 
  ON conversations FOR DELETE 
  USING (auth.uid() = created_by);
