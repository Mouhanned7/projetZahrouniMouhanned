-- Setup: Supabase Storage for resources files
-- Safe to run multiple times.

-- 1) Create (or update) public bucket used by resource uploads.
INSERT INTO storage.buckets (id, name, public)
VALUES ('resources', 'resources', true)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    public = true;

-- 2) Policies on storage.objects for this bucket.
DROP POLICY IF EXISTS "Public can read resources files" ON storage.objects;
CREATE POLICY "Public can read resources files"
ON storage.objects
FOR SELECT
USING (bucket_id = 'resources');

DROP POLICY IF EXISTS "Authenticated can upload resources files" ON storage.objects;
CREATE POLICY "Authenticated can upload resources files"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'resources'
  AND auth.uid() IS NOT NULL
);

DROP POLICY IF EXISTS "Owners can update resources files" ON storage.objects;
CREATE POLICY "Owners can update resources files"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'resources'
  AND owner = auth.uid()
)
WITH CHECK (
  bucket_id = 'resources'
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "Owners can delete resources files" ON storage.objects;
CREATE POLICY "Owners can delete resources files"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'resources'
  AND owner = auth.uid()
);

DROP POLICY IF EXISTS "Admins can delete any resources files" ON storage.objects;
CREATE POLICY "Admins can delete any resources files"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'resources'
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
