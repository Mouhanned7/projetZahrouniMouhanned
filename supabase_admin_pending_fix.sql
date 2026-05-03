-- Patch: Admin can see and moderate pending resources
-- Safe to run multiple times.

-- Ensure admin select/update/delete policies exist for resources.
DROP POLICY IF EXISTS "Admins can view all resources" ON resources;
CREATE POLICY "Admins can view all resources" ON resources
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can moderate resources" ON resources;
CREATE POLICY "Admins can moderate resources" ON resources
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can delete resources" ON resources;
CREATE POLICY "Admins can delete resources" ON resources
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- SECURITY DEFINER function used by the Flutter app for stable pending reads.
CREATE OR REPLACE FUNCTION public.admin_pending_resources()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  type TEXT,
  subject TEXT,
  university TEXT,
  file_url TEXT,
  thumbnail_url TEXT,
  file_size BIGINT,
  author_id UUID,
  status TEXT,
  avg_rating REAL,
  ratings_count INT,
  downloads_count INT,
  views_count INT,
  created_at TIMESTAMPTZ,
  author_name TEXT,
  author_avatar TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.title,
    r.description,
    r.type,
    r.subject,
    r.university,
    r.file_url,
    r.thumbnail_url,
    r.file_size,
    r.author_id,
    r.status,
    r.avg_rating,
    r.ratings_count,
    r.downloads_count,
    r.views_count,
    r.created_at,
    p.full_name AS author_name,
    p.avatar_url AS author_avatar
  FROM resources r
  LEFT JOIN profiles p ON p.id = r.author_id
  WHERE r.status = 'pending'
    AND EXISTS (
      SELECT 1
      FROM profiles me
      WHERE me.id = auth.uid()
        AND me.role = 'admin'
    )
  ORDER BY r.created_at DESC;
$$;

REVOKE ALL ON FUNCTION public.admin_pending_resources() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_pending_resources() TO authenticated;
