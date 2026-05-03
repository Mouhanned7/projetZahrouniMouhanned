-- ============================================================
-- Supabase Schema — Hub de Ressources Académiques
-- Exécuter ce SQL dans le SQL Editor de votre dashboard Supabase
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Table: profiles
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL DEFAULT '',
  university TEXT DEFAULT '',
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  avatar_url TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  resources_uploaded INT DEFAULT 0,
  credits INT DEFAULT 0,
  is_vip BOOLEAN DEFAULT false,
  vip_downloads_left INT DEFAULT 0,
  free_views_used INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Table: resources
-- ============================================================
CREATE TABLE IF NOT EXISTS resources (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  type TEXT NOT NULL CHECK (type IN ('presentation', 'report', 'code', 'video')),
  subject TEXT DEFAULT '',
  university TEXT DEFAULT '',
  file_url TEXT NOT NULL,
  thumbnail_url TEXT DEFAULT '',
  file_size BIGINT DEFAULT 0,
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  avg_rating REAL DEFAULT 0,
  ratings_count INT DEFAULT 0,
  downloads_count INT DEFAULT 0,
  views_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: resource_ratings
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_ratings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  resource_id UUID REFERENCES resources(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(resource_id, user_id)
);

-- ============================================================
-- Table: admin_settings
-- ============================================================
CREATE TABLE IF NOT EXISTS admin_settings (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  free_resource_limit_enabled BOOLEAN DEFAULT false,
  free_resource_limit INT DEFAULT 10,
  partial_view_enabled BOOLEAN DEFAULT false,
  partial_view_percentage INT DEFAULT 30,
  exchange_required BOOLEAN DEFAULT false,
  allow_user_uploads BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings row
INSERT INTO admin_settings (
  free_resource_limit_enabled,
  free_resource_limit,
  partial_view_enabled,
  partial_view_percentage,
  exchange_required,
  allow_user_uploads
) VALUES (false, 10, false, 30, false, true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Table: videos
-- ============================================================
CREATE TABLE IF NOT EXISTS videos (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  video_url TEXT NOT NULL,
  thumbnail_url TEXT DEFAULT '',
  category TEXT DEFAULT '',
  is_public BOOLEAN DEFAULT true,
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  views_count INT DEFAULT 0,
  duration TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: social_posts
-- ============================================================
CREATE TABLE IF NOT EXISTS social_posts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  external_url TEXT DEFAULT '',
  linked_resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
  linked_video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: social_post_likes
-- ============================================================
CREATE TABLE IF NOT EXISTS social_post_likes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES social_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ============================================================
-- Table: social_post_comments
-- ============================================================
CREATE TABLE IF NOT EXISTS social_post_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES social_posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: social_post_resources
-- ============================================================
CREATE TABLE IF NOT EXISTS social_post_resources (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES social_posts(id) ON DELETE CASCADE NOT NULL,
  resource_id UUID REFERENCES resources(id) ON DELETE CASCADE NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: social_messages
-- ============================================================
CREATE TABLE IF NOT EXISTS social_messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: resource_exchanges
-- ============================================================
CREATE TABLE IF NOT EXISTS resource_exchanges (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  given_resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
  received_resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Table: packs
-- ============================================================
CREATE TABLE IF NOT EXISTS packs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  price_tnd NUMERIC(10, 2) NOT NULL,
  credits_given INT DEFAULT 0,
  is_vip BOOLEAN DEFAULT false,
  vip_downloads INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default packs
INSERT INTO packs (name, description, price_tnd, credits_given, is_vip, vip_downloads) VALUES
('Pack Petit', '100 crédits (environ 8-12 ressources)', 10.00, 100, false, 0),
('Pack Moyen', '250 crédits pro', 20.00, 250, false, 0),
('Pack VIP', 'Débloquer et voir toutes les ressources en illimité + 30 téléchargements max', 50.00, 0, true, 30)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Table: transactions
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  pack_id UUID REFERENCES packs(id) ON DELETE SET NULL,
  amount_tnd NUMERIC(10, 2) NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('D17', 'edinar', 'carte_bancaire')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Resources
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Approved resources are viewable by everyone" ON resources
  FOR SELECT USING (status = 'approved' OR author_id = auth.uid());
CREATE POLICY "Authenticated users can insert resources" ON resources
  FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can update own resources" ON resources
  FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete own resources" ON resources
  FOR DELETE USING (auth.uid() = author_id);

-- Admin resource moderation policies
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

-- Resource Ratings
ALTER TABLE resource_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ratings are viewable by everyone" ON resource_ratings
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can rate" ON resource_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own rating" ON resource_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- Admin Settings
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin settings viewable by everyone" ON admin_settings
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Only admins can insert settings" ON admin_settings;
CREATE POLICY "Only admins can insert settings" ON admin_settings
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "Only admins can update settings" ON admin_settings
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Videos
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public videos viewable by everyone" ON videos
  FOR SELECT USING (is_public = true OR author_id = auth.uid() OR target_user_id = auth.uid());
CREATE POLICY "Authenticated users can insert videos" ON videos
  FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can update own videos" ON videos
  FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete own videos" ON videos
  FOR DELETE USING (auth.uid() = author_id);

-- Social Posts
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Social posts viewable by everyone" ON social_posts
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert social posts" ON social_posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can update own social posts" ON social_posts
  FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete own social posts" ON social_posts
  FOR DELETE USING (auth.uid() = author_id);

-- Social Likes
ALTER TABLE social_post_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Social likes viewable by everyone" ON social_post_likes
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can like posts" ON social_post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove own likes" ON social_post_likes
  FOR DELETE USING (auth.uid() = user_id);

-- Social Comments
ALTER TABLE social_post_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Social comments viewable by everyone" ON social_post_comments
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add comments" ON social_post_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON social_post_comments
  FOR DELETE USING (auth.uid() = user_id);

-- Social Post Resources
ALTER TABLE social_post_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Social post resources viewable by everyone" ON social_post_resources
  FOR SELECT USING (true);
CREATE POLICY "Post authors can attach resources" ON social_post_resources
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1
      FROM social_posts sp
      WHERE sp.id = post_id
        AND sp.author_id = auth.uid()
    )
  );
CREATE POLICY "Post authors can delete attached resources" ON social_post_resources
  FOR DELETE USING (
    EXISTS (
      SELECT 1
      FROM social_posts sp
      WHERE sp.id = post_id
        AND sp.author_id = auth.uid()
    )
  );

-- Social Messages
ALTER TABLE social_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their messages" ON social_messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);
CREATE POLICY "Users can send messages" ON social_messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Resource Exchanges
ALTER TABLE resource_exchanges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own exchanges" ON resource_exchanges
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create exchanges" ON resource_exchanges
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Packs
ALTER TABLE packs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Active packs viewable by everyone" ON packs
  FOR SELECT USING (is_active = true);
CREATE POLICY "Only admins can manage packs" ON packs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Authenticated users can create transactions" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Only admins can update transactions" ON transactions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- Function: Update avg_rating on resource_ratings change
-- ============================================================
CREATE OR REPLACE FUNCTION update_resource_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE resources SET
    avg_rating = (SELECT COALESCE(AVG(rating), 0) FROM resource_ratings WHERE resource_id = COALESCE(NEW.resource_id, OLD.resource_id)),
    ratings_count = (SELECT COUNT(*) FROM resource_ratings WHERE resource_id = COALESCE(NEW.resource_id, OLD.resource_id))
  WHERE id = COALESCE(NEW.resource_id, OLD.resource_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Function: Admin pending resources (RLS-safe)
-- ============================================================
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

CREATE OR REPLACE TRIGGER on_rating_change
  AFTER INSERT OR UPDATE OR DELETE ON resource_ratings
  FOR EACH ROW EXECUTE FUNCTION update_resource_rating();
