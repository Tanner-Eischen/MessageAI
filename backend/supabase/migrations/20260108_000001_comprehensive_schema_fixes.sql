-- ============================================================
-- COMPREHENSIVE SCHEMA MIGRATION - Complete Fix
-- This migration ensures message_ai_analysis has all required columns
-- with correct types matching backend code expectations
-- ============================================================

-- Add all missing columns to message_ai_analysis
-- Using ALTER TABLE so existing data is preserved
ALTER TABLE IF EXISTS message_ai_analysis
  ADD COLUMN IF NOT EXISTS intensity TEXT,
  ADD COLUMN IF NOT EXISTS secondary_tones JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS anxiety_assessment JSONB,
  ADD COLUMN IF NOT EXISTS context_flags JSONB,
  ADD COLUMN IF NOT EXISTS rsd_triggers JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS alternative_interpretations JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS evidence JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS boundary_analysis JSONB,
  ADD COLUMN IF NOT EXISTS figurative_language_detected JSONB;

-- Create GIN indexes for JSONB columns (for performance)
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_secondary_tones 
  ON message_ai_analysis USING GIN (secondary_tones);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_anxiety_assessment 
  ON message_ai_analysis USING GIN (anxiety_assessment);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_context_flags 
  ON message_ai_analysis USING GIN (context_flags);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_rsd_triggers 
  ON message_ai_analysis USING GIN (rsd_triggers);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_alternative_interpretations 
  ON message_ai_analysis USING GIN (alternative_interpretations);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_evidence 
  ON message_ai_analysis USING GIN (evidence);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_boundary_analysis 
  ON message_ai_analysis USING GIN (boundary_analysis);
CREATE INDEX IF NOT EXISTS idx_message_ai_analysis_figurative_language_detected 
  ON message_ai_analysis USING GIN (figurative_language_detected);

-- ============================================================
-- RECREATE RPC FUNCTIONS WITH CORRECT TYPES
-- ============================================================

-- Drop old functions first
DROP FUNCTION IF EXISTS get_message_ai_analysis(TEXT);
DROP FUNCTION IF EXISTS get_conversation_ai_analysis(TEXT);

-- Function to get AI analysis for a single message
CREATE OR REPLACE FUNCTION get_message_ai_analysis(p_message_id TEXT)
RETURNS TABLE (
  id UUID,
  message_id UUID,
  tone TEXT,
  urgency_level TEXT,
  intent TEXT,
  confidence_score DOUBLE PRECISION,
  intensity TEXT,
  secondary_tones JSONB,
  context_flags JSONB,
  anxiety_assessment JSONB,
  rsd_triggers JSONB,
  alternative_interpretations JSONB,
  evidence JSONB,
  boundary_analysis JSONB,
  figurative_language_detected JSONB,
  analysis_timestamp BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    maa.id,
    maa.message_id,
    maa.tone,
    maa.urgency_level,
    maa.intent,
    maa.confidence_score,
    maa.intensity,
    COALESCE(maa.secondary_tones, '[]'::jsonb),
    maa.context_flags,
    maa.anxiety_assessment,
    COALESCE(maa.rsd_triggers, '[]'::jsonb),
    COALESCE(maa.alternative_interpretations, '[]'::jsonb),
    COALESCE(maa.evidence, '[]'::jsonb),
    maa.boundary_analysis,
    maa.figurative_language_detected,
    maa.analysis_timestamp
  FROM message_ai_analysis maa
  WHERE maa.message_id = p_message_id::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all AI analyses for a conversation
CREATE OR REPLACE FUNCTION get_conversation_ai_analysis(p_conversation_id TEXT)
RETURNS TABLE (
  id UUID,
  message_id UUID,
  tone TEXT,
  urgency_level TEXT,
  intent TEXT,
  confidence_score DOUBLE PRECISION,
  intensity TEXT,
  secondary_tones JSONB,
  context_flags JSONB,
  anxiety_assessment JSONB,
  rsd_triggers JSONB,
  alternative_interpretations JSONB,
  evidence JSONB,
  boundary_analysis JSONB,
  figurative_language_detected JSONB,
  analysis_timestamp BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    maa.id,
    maa.message_id,
    maa.tone,
    maa.urgency_level,
    maa.intent,
    maa.confidence_score,
    maa.intensity,
    COALESCE(maa.secondary_tones, '[]'::jsonb),
    maa.context_flags,
    maa.anxiety_assessment,
    COALESCE(maa.rsd_triggers, '[]'::jsonb),
    COALESCE(maa.alternative_interpretations, '[]'::jsonb),
    COALESCE(maa.evidence, '[]'::jsonb),
    maa.boundary_analysis,
    maa.figurative_language_detected,
    maa.analysis_timestamp
  FROM message_ai_analysis maa
  INNER JOIN messages m ON m.id = maa.message_id
  WHERE m.conversation_id = p_conversation_id::UUID
  ORDER BY m.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_message_ai_analysis(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_ai_analysis(TEXT) TO authenticated;

-- Add column documentation
COMMENT ON COLUMN message_ai_analysis.intensity IS 'Intensity level: very_low, low, medium, high, very_high';
COMMENT ON COLUMN message_ai_analysis.secondary_tones IS 'JSONB array of secondary emotional tones';
COMMENT ON COLUMN message_ai_analysis.anxiety_assessment IS 'Neurodivergent anxiety assessment';
COMMENT ON COLUMN message_ai_analysis.context_flags IS 'Context flags: sarcasm, figurative_language, etc';
COMMENT ON COLUMN message_ai_analysis.rsd_triggers IS 'RSD trigger analysis results';
COMMENT ON COLUMN message_ai_analysis.alternative_interpretations IS 'Alternative message interpretations';
COMMENT ON COLUMN message_ai_analysis.evidence IS 'Supporting evidence for analysis';
COMMENT ON COLUMN message_ai_analysis.boundary_analysis IS 'Boundary violation detection';
COMMENT ON COLUMN message_ai_analysis.figurative_language_detected IS 'Figurative language detection';
