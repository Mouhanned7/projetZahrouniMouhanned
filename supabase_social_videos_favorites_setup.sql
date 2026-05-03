-- ============================================================
-- Supabase add-on schema: social posts, favorites, video seeds
-- A executer apres supabase_schema.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Table: social_posts
-- ============================================================
CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  external_url TEXT DEFAULT '',
  linked_resource_id UUID REFERENCES public.resources(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_social_posts_author_id
  ON public.social_posts(author_id);

CREATE INDEX IF NOT EXISTS idx_social_posts_created_at
  ON public.social_posts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_posts_linked_resource_id
  ON public.social_posts(linked_resource_id);

-- ============================================================
-- Table: social_post_likes
-- ============================================================
CREATE TABLE IF NOT EXISTS public.social_post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT social_post_likes_unique UNIQUE (post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_social_post_likes_post_id
  ON public.social_post_likes(post_id);

CREATE INDEX IF NOT EXISTS idx_social_post_likes_user_id
  ON public.social_post_likes(user_id);

-- ============================================================
-- Table: social_post_comments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.social_post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_social_post_comments_post_id
  ON public.social_post_comments(post_id);

CREATE INDEX IF NOT EXISTS idx_social_post_comments_user_id
  ON public.social_post_comments(user_id);

CREATE INDEX IF NOT EXISTS idx_social_post_comments_created_at
  ON public.social_post_comments(created_at ASC);

-- ============================================================
-- Table: resource_favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS public.resource_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  resource_id UUID NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT resource_favorites_unique UNIQUE (user_id, resource_id)
);

CREATE INDEX IF NOT EXISTS idx_resource_favorites_user_id
  ON public.resource_favorites(user_id);

CREATE INDEX IF NOT EXISTS idx_resource_favorites_resource_id
  ON public.resource_favorites(resource_id);

-- ============================================================
-- Table: video_favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS public.video_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_id UUID NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT video_favorites_unique UNIQUE (user_id, video_id)
);

CREATE INDEX IF NOT EXISTS idx_video_favorites_user_id
  ON public.video_favorites(user_id);

CREATE INDEX IF NOT EXISTS idx_video_favorites_video_id
  ON public.video_favorites(video_id);

-- ============================================================
-- Trigger helpers
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_social_posts_set_updated_at ON public.social_posts;
CREATE TRIGGER trg_social_posts_set_updated_at
BEFORE UPDATE ON public.social_posts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_social_post_comments_set_updated_at ON public.social_post_comments;
CREATE TRIGGER trg_social_post_comments_set_updated_at
BEFORE UPDATE ON public.social_post_comments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Social posts are viewable by everyone" ON public.social_posts;
CREATE POLICY "Social posts are viewable by everyone"
  ON public.social_posts
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can create social posts" ON public.social_posts;
CREATE POLICY "Authenticated users can create social posts"
  ON public.social_posts
  FOR INSERT
  WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can update own social posts" ON public.social_posts;
CREATE POLICY "Authors can update own social posts"
  ON public.social_posts
  FOR UPDATE
  USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Authors can delete own social posts" ON public.social_posts;
CREATE POLICY "Authors can delete own social posts"
  ON public.social_posts
  FOR DELETE
  USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Social likes are viewable by everyone" ON public.social_post_likes;
CREATE POLICY "Social likes are viewable by everyone"
  ON public.social_post_likes
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can like posts" ON public.social_post_likes;
CREATE POLICY "Users can like posts"
  ON public.social_post_likes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike own likes" ON public.social_post_likes;
CREATE POLICY "Users can unlike own likes"
  ON public.social_post_likes
  FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.social_post_comments;
CREATE POLICY "Comments are viewable by everyone"
  ON public.social_post_comments
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can add comments" ON public.social_post_comments;
CREATE POLICY "Users can add comments"
  ON public.social_post_comments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own comments" ON public.social_post_comments;
CREATE POLICY "Users can update own comments"
  ON public.social_post_comments
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own comments" ON public.social_post_comments;
CREATE POLICY "Users can delete own comments"
  ON public.social_post_comments
  FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own resource favorites" ON public.resource_favorites;
CREATE POLICY "Users can view own resource favorites"
  ON public.resource_favorites
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can save own resource favorites" ON public.resource_favorites;
CREATE POLICY "Users can save own resource favorites"
  ON public.resource_favorites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own resource favorites" ON public.resource_favorites;
CREATE POLICY "Users can delete own resource favorites"
  ON public.resource_favorites
  FOR DELETE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own video favorites" ON public.video_favorites;
CREATE POLICY "Users can view own video favorites"
  ON public.video_favorites
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can save own video favorites" ON public.video_favorites;
CREATE POLICY "Users can save own video favorites"
  ON public.video_favorites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own video favorites" ON public.video_favorites;
CREATE POLICY "Users can delete own video favorites"
  ON public.video_favorites
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- Seed data: example videos
-- These inserts use the first available profile as author.
-- If there is no profile yet, they insert nothing.
-- ============================================================
INSERT INTO public.videos (
  title,
  description,
  video_url,
  thumbnail_url,
  category,
  is_public,
  author_id,
  duration
)
SELECT
  'Introduction a Flutter',
  'Video de demarrage pour comprendre widgets, navigation et structure du projet.',
  'https://www.youtube.com/watch?v=VPvVD8t02U8',
  'https://img.youtube.com/vi/VPvVD8t02U8/hqdefault.jpg',
  'Programmation',
  true,
  p.id,
  '12:40'
FROM public.profiles p
WHERE NOT EXISTS (
  SELECT 1 FROM public.videos v
  WHERE v.video_url = 'https://www.youtube.com/watch?v=VPvVD8t02U8'
)
LIMIT 1;

INSERT INTO public.videos (
  title,
  description,
  video_url,
  thumbnail_url,
  category,
  is_public,
  author_id,
  duration
)
SELECT
  'Cours SQL pour debutants',
  'Requetes SELECT, INSERT, UPDATE et bonnes pratiques de modelisation.',
  'https://www.youtube.com/watch?v=HXV3zeQKqGY',
  'https://img.youtube.com/vi/HXV3zeQKqGY/hqdefault.jpg',
  'Programmation',
  true,
  p.id,
  '18:22'
FROM public.profiles p
WHERE NOT EXISTS (
  SELECT 1 FROM public.videos v
  WHERE v.video_url = 'https://www.youtube.com/watch?v=HXV3zeQKqGY'
)
LIMIT 1;

INSERT INTO public.videos (
  title,
  description,
  video_url,
  thumbnail_url,
  category,
  is_public,
  author_id,
  duration
)
SELECT
  'Algebre lineaire resume',
  'Une video courte sur matrices, vecteurs et applications classiques.',
  'https://www.youtube.com/watch?v=fNk_zzaMoSs',
  'https://img.youtube.com/vi/fNk_zzaMoSs/hqdefault.jpg',
  'Mathematiques',
  true,
  p.id,
  '10:05'
FROM public.profiles p
WHERE NOT EXISTS (
  SELECT 1 FROM public.videos v
  WHERE v.video_url = 'https://www.youtube.com/watch?v=fNk_zzaMoSs'
)
LIMIT 1;

-- ============================================================
-- Optional seed: one demo post linked to an approved resource
-- ============================================================
INSERT INTO public.social_posts (
  author_id,
  content,
  external_url,
  linked_resource_id
)
SELECT
  p.id,
  'Bienvenue dans le fil social. Vous pouvez partager une idee, un lien utile ou une ressource du workspace.',
  '',
  r.id
FROM public.profiles p
LEFT JOIN public.resources r
  ON r.author_id = p.id
 AND r.status = 'approved'
WHERE NOT EXISTS (
  SELECT 1
  FROM public.social_posts sp
  WHERE sp.content = 'Bienvenue dans le fil social. Vous pouvez partager une idee, un lien utile ou une ressource du workspace.'
)
LIMIT 1;
