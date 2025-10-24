-- ============================================================
-- SMART INBOX CONTEXT SYSTEM - Phase 3
-- Adds conversation context, relationship profiles, and semantic search
-- ============================================================

-- Enable pgvector extension for semantic search
CREATE EXTENSION IF NOT EXISTS vector;

-- Message embeddings for semantic search
CREATE TABLE IF NOT EXISTS message_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- OpenAI embedding (1536 dimensions for text-embedding-ada-002)
  embedding vector(1536) NOT NULL,
  
  -- Metadata for search optimization
  message_length INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(message_id)
);

-- Index for fast similarity search
CREATE INDEX IF NOT EXISTS idx_message_embeddings_vector ON message_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_message_embeddings_user ON message_embeddings(user_id);
CREATE INDEX IF NOT EXISTS idx_message_embeddings_message ON message_embeddings(message_id);

-- Relationship profiles
CREATE TABLE IF NOT EXISTS relationship_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  
  -- Profile data
  participant_name TEXT NOT NULL,
  participant_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Relationship metadata
  relationship_type TEXT, -- boss, colleague, friend, family, client, other
  relationship_notes TEXT, -- User-added notes
  
  -- Auto-generated context
  conversation_summary TEXT, -- AI-generated summary
  safe_topics JSONB DEFAULT '[]'::jsonb, -- Topics that went well
  topics_to_avoid JSONB DEFAULT '[]'::jsonb, -- Topics that caused issues
  communication_style TEXT, -- How they prefer to communicate
  typical_response_time INTEGER, -- Average response time in seconds
  
  -- Stats
  total_messages INTEGER DEFAULT 0,
  first_message_at TIMESTAMPTZ,
  last_message_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, conversation_id)
);

CREATE INDEX IF NOT EXISTS idx_relationship_profiles_user ON relationship_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_relationship_profiles_conversation ON relationship_profiles(conversation_id);

-- Conversation context cache
CREATE TABLE IF NOT EXISTS conversation_context_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  
  -- Cached context
  last_discussed TEXT, -- "Last talked about project deadline"
  key_points JSONB DEFAULT '[]'::jsonb, -- Important points from recent messages
  pending_questions JSONB DEFAULT '[]'::jsonb, -- Unanswered questions
  
  -- Cache metadata
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  
  UNIQUE(user_id, conversation_id)
);

CREATE INDEX IF NOT EXISTS idx_context_cache_user ON conversation_context_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_context_cache_expires ON conversation_context_cache(expires_at);

-- Safe topics tracking
CREATE TABLE IF NOT EXISTS safe_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  
  -- Topic data
  topic_name TEXT NOT NULL, -- "work projects", "weekend plans", etc.
  topic_keywords JSONB DEFAULT '[]'::jsonb, -- Related keywords
  
  -- Engagement metrics
  message_count INTEGER DEFAULT 1,
  avg_response_time INTEGER, -- How fast user responds to this topic (seconds)
  positive_tone_rate REAL, -- % of messages with positive tone
  
  -- Status
  is_safe BOOLEAN DEFAULT true, -- Safe to discuss
  last_discussed TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, conversation_id, topic_name)
);

CREATE INDEX IF NOT EXISTS idx_safe_topics_user ON safe_topics(user_id);
CREATE INDEX IF NOT EXISTS idx_safe_topics_conversation ON safe_topics(conversation_id);
CREATE INDEX IF NOT EXISTS idx_safe_topics_discussed ON safe_topics(last_discussed);

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE message_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_context_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE safe_topics ENABLE ROW LEVEL SECURITY;

-- Message embeddings: users can only access their own
CREATE POLICY "Users can view their own message embeddings"
  ON message_embeddings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own message embeddings"
  ON message_embeddings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Relationship profiles: users can manage their own
CREATE POLICY "Users can view their own relationship profiles"
  ON relationship_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own relationship profiles"
  ON relationship_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own relationship profiles"
  ON relationship_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Context cache: users can access their own
CREATE POLICY "Users can view their own context cache"
  ON conversation_context_cache FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own context cache"
  ON conversation_context_cache FOR ALL
  USING (auth.uid() = user_id);

-- Safe topics: users can manage their own
CREATE POLICY "Users can manage their own safe topics"
  ON safe_topics FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Semantic search for similar messages
CREATE OR REPLACE FUNCTION search_similar_messages(
  p_user_id UUID,
  p_query_embedding vector(1536),
  p_limit INTEGER DEFAULT 5,
  p_conversation_id UUID DEFAULT NULL
)
RETURNS TABLE (
  message_id UUID,
  similarity REAL,
  message_body TEXT,
  created_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verify user access
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    m.id AS message_id,
    1 - (me.embedding <=> p_query_embedding) AS similarity,
    m.body AS message_body,
    m.created_at
  FROM message_embeddings me
  JOIN messages m ON me.message_id = m.id
  WHERE me.user_id = p_user_id
    AND (p_conversation_id IS NULL OR m.conversation_id = p_conversation_id)
  ORDER BY me.embedding <=> p_query_embedding
  LIMIT p_limit;
END;
$$;

-- Get relationship profile
CREATE OR REPLACE FUNCTION get_relationship_profile(
  p_user_id UUID,
  p_conversation_id UUID
)
RETURNS TABLE (
  profile_id UUID,
  participant_name TEXT,
  relationship_type TEXT,
  conversation_summary TEXT,
  safe_topics JSONB,
  topics_to_avoid JSONB,
  communication_style TEXT,
  typical_response_time INTEGER,
  total_messages INTEGER
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verify user access
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Verify user is participant
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied to conversation';
  END IF;

  RETURN QUERY
  SELECT 
    rp.id AS profile_id,
    rp.participant_name,
    rp.relationship_type,
    rp.conversation_summary,
    rp.safe_topics,
    rp.topics_to_avoid,
    rp.communication_style,
    rp.typical_response_time,
    rp.total_messages
  FROM relationship_profiles rp
  WHERE rp.user_id = p_user_id
    AND rp.conversation_id = p_conversation_id
  LIMIT 1;
END;
$$;

-- Get cached conversation context
CREATE OR REPLACE FUNCTION get_conversation_context(
  p_user_id UUID,
  p_conversation_id UUID
)
RETURNS TABLE (
  last_discussed TEXT,
  key_points JSONB,
  pending_questions JSONB,
  cache_age INTEGER
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_now TIMESTAMPTZ;
BEGIN
  v_now := NOW();

  -- Verify access
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied to conversation';
  END IF;

  RETURN QUERY
  SELECT 
    ccc.last_discussed,
    ccc.key_points,
    ccc.pending_questions,
    EXTRACT(EPOCH FROM (v_now - ccc.generated_at))::INTEGER AS cache_age
  FROM conversation_context_cache ccc
  WHERE ccc.user_id = p_user_id
    AND ccc.conversation_id = p_conversation_id
    AND ccc.expires_at > v_now
  LIMIT 1;
END;
$$;

-- Get safe topics for conversation
CREATE OR REPLACE FUNCTION get_safe_topics(
  p_user_id UUID,
  p_conversation_id UUID
)
RETURNS TABLE (
  topic_name TEXT,
  message_count INTEGER,
  positive_tone_rate REAL,
  last_discussed TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Verify access
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    st.topic_name,
    st.message_count,
    st.positive_tone_rate,
    st.last_discussed
  FROM safe_topics st
  WHERE st.user_id = p_user_id
    AND st.conversation_id = p_conversation_id
    AND st.is_safe = true
  ORDER BY st.positive_tone_rate DESC, st.message_count DESC
  LIMIT 10;
END;
$$;

-- Comments
COMMENT ON TABLE message_embeddings IS 'Vector embeddings for semantic search of messages';
COMMENT ON TABLE relationship_profiles IS 'AI-generated relationship profiles for conversations';
COMMENT ON TABLE conversation_context_cache IS 'Cached conversation context for quick loading';
COMMENT ON TABLE safe_topics IS 'Topics that have led to positive engagement';

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON message_embeddings TO authenticated;
GRANT ALL ON relationship_profiles TO authenticated;
GRANT ALL ON conversation_context_cache TO authenticated;
GRANT ALL ON safe_topics TO authenticated;
GRANT EXECUTE ON FUNCTION search_similar_messages(UUID, vector, INTEGER, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_relationship_profile(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_context(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_safe_topics(UUID, UUID) TO authenticated;

