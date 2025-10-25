-- ============================================================
-- FIX FOLLOW-UP SYSTEM FOREIGN KEY CONSTRAINTS
-- Changes user_id references to point to profiles.user_id instead of profiles.id
-- ============================================================

-- Fix follow_up_items.user_id FK
ALTER TABLE follow_up_items 
DROP CONSTRAINT IF EXISTS follow_up_items_user_id_fkey;

ALTER TABLE follow_up_items 
ADD CONSTRAINT follow_up_items_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles (user_id) 
ON DELETE CASCADE;

-- Fix context_triggers.user_id FK
ALTER TABLE context_triggers 
DROP CONSTRAINT IF EXISTS context_triggers_user_id_fkey;

ALTER TABLE context_triggers 
ADD CONSTRAINT context_triggers_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles (user_id) 
ON DELETE CASCADE;

-- Add comments
COMMENT ON CONSTRAINT follow_up_items_user_id_fkey ON follow_up_items IS 
  'References profiles.user_id which maps to auth.users.id';

COMMENT ON CONSTRAINT context_triggers_user_id_fkey ON context_triggers IS 
  'References profiles.user_id which maps to auth.users.id';

