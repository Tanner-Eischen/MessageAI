-- Supabase Storage Buckets Configuration
-- Creates and configures storage buckets for avatars and media uploads

-- ============================================================================
-- Bucket 1: avatars
-- ============================================================================
-- Create avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, owner, public)
VALUES ('avatars', 'avatars', auth.uid(), false)
ON CONFLICT (id) DO NOTHING;

-- Set bucket to public (files are stored with public paths, accessed via signed URLs)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'avatars';

-- Avatar bucket policy: Users can upload avatars
CREATE POLICY "Users can upload avatars"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
);

-- Avatar bucket policy: Users can read avatars
CREATE POLICY "Users can read avatars"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
);

-- Avatar bucket policy: Users can update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects
FOR UPDATE
TO public
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
);

-- Avatar bucket policy: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
);

-- ============================================================================
-- Bucket 2: media
-- ============================================================================
-- Create media bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, owner, public)
VALUES ('media', 'media', auth.uid(), false)
ON CONFLICT (id) DO NOTHING;

-- Set bucket to public (files accessed via signed URLs)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'media';

-- Media bucket policy: Users can upload media
CREATE POLICY "Users can upload media"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'media'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
);

-- Media bucket policy: Users can read media
CREATE POLICY "Users can read media"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'media'
  AND auth.role() = 'authenticated'
);

-- Media bucket policy: Users can delete their own media
CREATE POLICY "Users can delete their own media"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'media'
  AND (storage.foldername(name))[1] = auth.uid()::text
  AND auth.role() = 'authenticated'
);
