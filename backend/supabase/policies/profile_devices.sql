-- ============================================================
-- RLS POLICIES FOR profile_devices
-- Allows users to manage their own device registrations
-- ============================================================

-- Enable RLS
ALTER TABLE profile_devices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own devices
CREATE POLICY "Users can view their own devices"
  ON profile_devices
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own devices
CREATE POLICY "Users can insert their own devices"
  ON profile_devices
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own devices
CREATE POLICY "Users can update their own devices"
  ON profile_devices
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own devices
CREATE POLICY "Users can delete their own devices"
  ON profile_devices
  FOR DELETE
  USING (auth.uid() = user_id);



