-- Create commitment_streaks table to track user's action item completion streaks
CREATE TABLE IF NOT EXISTS public.commitment_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  current_streak_count INTEGER DEFAULT 0,
  best_streak_count INTEGER DEFAULT 0,
  total_completed INTEGER DEFAULT 0,
  total_commitments INTEGER DEFAULT 0,
  completion_rate DECIMAL(5, 2) DEFAULT 0.0,
  last_completion_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT unique_user_streak UNIQUE (user_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_commitment_streaks_user_id ON public.commitment_streaks(user_id);

-- Enable RLS
ALTER TABLE public.commitment_streaks ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own streak
CREATE POLICY "Users can view their own commitment streaks"
  ON public.commitment_streaks
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only update their own streak
CREATE POLICY "Users can update their own commitment streaks"
  ON public.commitment_streaks
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own streak
CREATE POLICY "Users can insert their own commitment streaks"
  ON public.commitment_streaks
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE TRIGGER commitment_streaks_updated_at
BEFORE UPDATE ON public.commitment_streaks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
