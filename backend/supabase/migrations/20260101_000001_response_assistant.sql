-- =====================================================
-- Phase 2: Adaptive Response Assistant Migration
-- Adds support for template suggestions and message formatting
-- =====================================================

-- Note: This phase doesn't require new database tables
-- Template data is stored in code (backend/supabase/functions/_shared/templates/)
-- Situation detection happens via AI analysis (no persistence needed)
-- Formatted messages are returned to client without storage

-- However, we can add optional user preferences for templates
CREATE TABLE IF NOT EXISTS user_template_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Favorite templates (user can star templates for quick access)
  favorite_template_ids TEXT[] DEFAULT '{}',
  
  -- Custom templates (user can create their own)
  custom_templates JSONB DEFAULT '[]'::jsonb,
  
  -- Template usage history (for smart suggestions)
  template_usage_history JSONB DEFAULT '[]'::jsonb,
  
  -- Preferences
  show_template_suggestions BOOLEAN DEFAULT true,
  auto_detect_situation BOOLEAN DEFAULT true,
  preferred_tone TEXT, -- 'polite', 'casual', 'direct', 'apologetic'
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Index for quick user lookups
CREATE INDEX IF NOT EXISTS idx_template_prefs_user_id 
  ON user_template_preferences(user_id);

-- RLS Policies
ALTER TABLE user_template_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only access their own preferences
CREATE POLICY "Users can view their own template preferences"
  ON user_template_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own template preferences"
  ON user_template_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own template preferences"
  ON user_template_preferences
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own template preferences"
  ON user_template_preferences
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_template_preferences_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_template_preferences_timestamp ON user_template_preferences;
CREATE TRIGGER update_template_preferences_timestamp
  BEFORE UPDATE ON user_template_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_template_preferences_timestamp();

-- Helper function to get or create user template preferences
CREATE OR REPLACE FUNCTION get_user_template_preferences(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  favorite_template_ids TEXT[],
  custom_templates JSONB,
  template_usage_history JSONB,
  show_template_suggestions BOOLEAN,
  auto_detect_situation BOOLEAN,
  preferred_tone TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check authorization
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;
  
  -- Get or create preferences
  INSERT INTO user_template_preferences (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN QUERY
  SELECT 
    prefs.id,
    prefs.user_id,
    prefs.favorite_template_ids,
    prefs.custom_templates,
    prefs.template_usage_history,
    prefs.show_template_suggestions,
    prefs.auto_detect_situation,
    prefs.preferred_tone,
    prefs.created_at,
    prefs.updated_at
  FROM user_template_preferences prefs
  WHERE prefs.user_id = p_user_id;
END;
$$;

-- Function to record template usage (for smart suggestions)
CREATE OR REPLACE FUNCTION record_template_usage(
  p_user_id UUID,
  p_template_id TEXT,
  p_situation_type TEXT
)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_usage_entry JSONB;
BEGIN
  -- Check authorization
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;
  
  -- Create usage entry
  v_usage_entry := jsonb_build_object(
    'template_id', p_template_id,
    'situation_type', p_situation_type,
    'used_at', EXTRACT(EPOCH FROM NOW())::INTEGER
  );
  
  -- Ensure preferences exist
  INSERT INTO user_template_preferences (user_id)
  VALUES (p_user_id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Append to usage history (keep last 100 entries)
  UPDATE user_template_preferences
  SET 
    template_usage_history = (
      SELECT jsonb_agg(entry)
      FROM (
        SELECT entry
        FROM jsonb_array_elements(
          template_usage_history || v_usage_entry
        ) entry
        ORDER BY (entry->>'used_at')::INTEGER DESC
        LIMIT 100
      ) recent
    ),
    updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;

-- Comments for documentation
COMMENT ON TABLE user_template_preferences IS 'User preferences for response templates and message formatting';
COMMENT ON FUNCTION get_user_template_preferences(UUID) IS 'Gets or creates user template preferences';
COMMENT ON FUNCTION record_template_usage(UUID, TEXT, TEXT) IS 'Records template usage for smart suggestions';

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON user_template_preferences TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_template_preferences(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION record_template_usage(UUID, TEXT, TEXT) TO authenticated;

