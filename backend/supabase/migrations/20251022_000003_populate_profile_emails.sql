-- Populate emails in profiles table and create trigger for new users
-- This ensures email lookups work when adding participants

-- Step 1: Update existing profiles with emails from auth.users
UPDATE profiles
SET email = auth.users.email
FROM auth.users
WHERE profiles.user_id = auth.users.id
AND (profiles.email IS NULL OR profiles.email = '');

-- Step 2: Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 3: Create function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, username, email)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    NEW.email
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    email = NEW.email,
    username = COALESCE(profiles.username, SPLIT_PART(NEW.email, '@', 1));
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Verify the update
DO $$
DECLARE
  missing_emails INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing_emails
  FROM profiles
  WHERE email IS NULL OR email = '';
  
  IF missing_emails > 0 THEN
    RAISE NOTICE 'Warning: % profiles still have missing emails', missing_emails;
  ELSE
    RAISE NOTICE 'Success: All profiles have emails populated';
  END IF;
END $$;


