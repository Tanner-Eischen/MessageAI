-- MessageAI Database Schema
-- Tables: profiles, conversations, conversation_participants, messages, message_receipts
-- All tables have RLS enabled

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- Table: profiles
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- Table: conversations
-- ============================================================================
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  description TEXT,
  is_group BOOLEAN NOT NULL DEFAULT false,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (created_by) REFERENCES profiles (user_id) ON DELETE CASCADE
);

-- ============================================================================
-- Table: conversation_participants
-- ============================================================================
CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  user_id UUID NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_read_at TIMESTAMPTZ,
  FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES profiles (user_id) ON DELETE CASCADE,
  UNIQUE(conversation_id, user_id)
);

-- ============================================================================
-- Table: messages
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  body TEXT NOT NULL,
  media_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES profiles (user_id) ON DELETE CASCADE
);

-- Create index on messages for efficient querying
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created 
  ON messages (conversation_id, created_at DESC);

-- ============================================================================
-- Table: message_receipts
-- ============================================================================
CREATE TABLE IF NOT EXISTS message_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL,
  user_id UUID NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('delivered', 'read')),
  at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES profiles (user_id) ON DELETE CASCADE,
  UNIQUE(message_id, user_id)
);

-- Create index on receipts
CREATE INDEX IF NOT EXISTS idx_receipts_user_message 
  ON message_receipts (user_id, message_id);

-- ============================================================================
-- Enable Row Level Security (RLS)
-- ============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_receipts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS Policies: profiles
-- ============================================================================
CREATE POLICY "Profiles are viewable by everyone" 
  ON profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Profiles created on signup" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- RLS Policies: conversations
-- ============================================================================
CREATE POLICY "Users can view conversations they are in" 
  ON conversations FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = conversations.id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create conversations" 
  ON conversations FOR INSERT 
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update conversations they created" 
  ON conversations FOR UPDATE 
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- ============================================================================
-- RLS Policies: conversation_participants
-- ============================================================================
CREATE POLICY "Users can view participant lists of conversations they are in" 
  ON conversation_participants FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants AS cp
      WHERE cp.conversation_id = conversation_participants.conversation_id 
      AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join conversations" 
  ON conversation_participants FOR INSERT 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can leave conversations" 
  ON conversation_participants FOR DELETE 
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their participation record" 
  ON conversation_participants FOR UPDATE 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- RLS Policies: messages
-- ============================================================================
CREATE POLICY "Users can read messages in conversations they are in" 
  ON messages FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = messages.conversation_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages to conversations they are in" 
  ON messages FOR INSERT 
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_id = messages.conversation_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages" 
  ON messages FOR UPDATE 
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages" 
  ON messages FOR DELETE 
  USING (sender_id = auth.uid());

-- ============================================================================
-- RLS Policies: message_receipts
-- ============================================================================
CREATE POLICY "Users can read receipts for messages in their conversations" 
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

CREATE POLICY "Users can create receipts for messages they are in conversations with" 
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

CREATE POLICY "Users can update their own receipts" 
  ON message_receipts FOR UPDATE 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
