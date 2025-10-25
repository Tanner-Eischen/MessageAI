-- ============================================================
-- SMART MESSAGE INTERPRETER - Phase 1 Enhancements
-- Adds RSD detection, alternative interpretations, and evidence
-- ============================================================

-- Add enhanced fields to message_ai_analysis table
ALTER TABLE message_ai_analysis
  ADD COLUMN IF NOT EXISTS rsd_triggers JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS alternative_interpretations JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS evidence JSONB DEFAULT '[]'::jsonb;

-- Add indexes for the new JSONB fields (optional, for performance)
CREATE INDEX IF NOT EXISTS idx_ai_analysis_rsd_triggers 
  ON message_ai_analysis USING GIN (rsd_triggers);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_alternatives 
  ON message_ai_analysis USING GIN (alternative_interpretations);
CREATE INDEX IF NOT EXISTS idx_ai_analysis_evidence 
  ON message_ai_analysis USING GIN (evidence);

-- Add helpful comment
COMMENT ON COLUMN message_ai_analysis.rsd_triggers IS 
  'RSD (Rejection Sensitive Dysphoria) triggers detected in message';
COMMENT ON COLUMN message_ai_analysis.alternative_interpretations IS 
  'Multiple possible interpretations for ambiguous messages';
COMMENT ON COLUMN message_ai_analysis.evidence IS 
  'Specific evidence supporting the tone analysis';

