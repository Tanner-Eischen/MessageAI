-- Phase 06: Push Notifications
-- Add profile_devices table for FCM token registration

-- ============================================================================
-- Table: profile_devices
-- ============================================================================
-- Tracks user devices and Firebase Cloud Messaging (FCM) tokens for push notifications

CREATE TABLE IF NOT EXISTS profile_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  last_seen TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Foreign key reference
  FOREIGN KEY (user_id) REFERENCES profiles (user_id) ON DELETE CASCADE,
  
  -- Unique constraint: one token per device (token can only be registered once)
  UNIQUE(fcm_token),
  
  -- Index for finding devices by user
  CONSTRAINT devices_pkey PRIMARY KEY (id)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_profile_devices_user_id 
  ON profile_devices (user_id);

CREATE INDEX IF NOT EXISTS idx_profile_devices_platform 
  ON profile_devices (platform);

CREATE INDEX IF NOT EXISTS idx_profile_devices_last_seen 
  ON profile_devices (last_seen DESC);

-- ============================================================================
-- Enable Row Level Security (RLS)
-- ============================================================================
ALTER TABLE profile_devices ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS Policies: profile_devices
-- ============================================================================

-- SELECT: Users can view their own devices
CREATE POLICY "Users can view their own devices"
  ON profile_devices FOR SELECT
  USING (user_id = auth.uid());

-- INSERT: Users can register their own devices
CREATE POLICY "Users can register their own devices"
  ON profile_devices FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE: Users can update their own device records (last_seen)
CREATE POLICY "Users can update their own device records"
  ON profile_devices FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: Users can unregister their own devices
CREATE POLICY "Users can unregister their own devices"
  ON profile_devices FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- Functions for device management
-- ============================================================================

-- Update device last_seen timestamp
CREATE OR REPLACE FUNCTION public.update_device_last_seen(
  p_fcm_token TEXT
)
RETURNS void AS $$
BEGIN
  UPDATE profile_devices
  SET last_seen = now()
  WHERE fcm_token = p_fcm_token;
END;
$$ LANGUAGE plpgsql;

-- Get active devices for a user (seen in last 30 days)
CREATE OR REPLACE FUNCTION public.get_user_active_devices(
  p_user_id UUID
)
RETURNS TABLE (
  device_id UUID,
  fcm_token TEXT,
  platform TEXT,
  last_seen TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id,
    devices.fcm_token,
    devices.platform,
    devices.last_seen
  FROM profile_devices devices
  WHERE devices.user_id = p_user_id
    AND devices.last_seen > now() - INTERVAL '30 days'
  ORDER BY devices.last_seen DESC;
END;
$$ LANGUAGE plpgsql;
