-- Create analysis_feedback table to store user feedback on AI interpretations
CREATE TABLE IF NOT EXISTS public.analysis_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID,
  message_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  user_id UUID NOT NULL,
  user_chosen_interpretation TEXT,
  was_helpful BOOLEAN,
  feedback_timestamp BIGINT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_message FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_analysis_feedback_user_id ON public.analysis_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_analysis_feedback_sender_id ON public.analysis_feedback(sender_id);
CREATE INDEX IF NOT EXISTS idx_analysis_feedback_message_id ON public.analysis_feedback(message_id);
CREATE INDEX IF NOT EXISTS idx_analysis_feedback_analysis_id ON public.analysis_feedback(analysis_id);
CREATE INDEX IF NOT EXISTS idx_analysis_feedback_timestamp ON public.analysis_feedback(feedback_timestamp);

-- Enable RLS
ALTER TABLE public.analysis_feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view feedback they own or feedback about their own messages
CREATE POLICY "Users can view their own feedback"
  ON public.analysis_feedback
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own feedback
CREATE POLICY "Users can insert their own feedback"
  ON public.analysis_feedback
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own feedback
CREATE POLICY "Users can update their own feedback"
  ON public.analysis_feedback
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE TRIGGER analysis_feedback_updated_at
BEFORE UPDATE ON public.analysis_feedback
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
