-- Add email column to profiles table for easier lookups
-- This allows searching for users by email when adding participants

-- Add email column if it doesn't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Create unique index on email for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_email ON profiles (email);

-- Create function to lookup user_id by email
CREATE OR REPLACE FUNCTION public.get_user_id_by_email(p_email TEXT)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT user_id INTO v_user_id
  FROM profiles
  WHERE email = LOWER(TRIM(p_email));
  
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to add participant by email
CREATE OR REPLACE FUNCTION public.add_participant_by_email(
  p_conversation_id UUID,
  p_email TEXT
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_participant_id UUID;
  v_result JSON;
BEGIN
  -- Look up user by email
  SELECT user_id INTO v_user_id
  FROM profiles
  WHERE email = LOWER(TRIM(p_email));
  
  -- Check if user exists
  IF v_user_id IS NULL THEN
    RETURN JSON_BUILD_OBJECT(
      'success', false,
      'error', 'User not found with email: ' || p_email
    );
  END IF;
  
  -- Check if user is already a participant
  IF EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id
    AND user_id = v_user_id
  ) THEN
    RETURN JSON_BUILD_OBJECT(
      'success', false,
      'error', 'User is already a participant'
    );
  END IF;
  
  -- Check if requesting user is a participant in the conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id
    AND user_id = auth.uid()
  ) THEN
    RETURN JSON_BUILD_OBJECT(
      'success', false,
      'error', 'You are not a participant in this conversation'
    );
  END IF;
  
  -- Add participant
  INSERT INTO conversation_participants (conversation_id, user_id)
  VALUES (p_conversation_id, v_user_id)
  RETURNING id INTO v_participant_id;
  
  RETURN JSON_BUILD_OBJECT(
    'success', true,
    'participant_id', v_participant_id,
    'user_id', v_user_id,
    'email', p_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_user_id_by_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_participant_by_email(UUID, TEXT) TO authenticated;

