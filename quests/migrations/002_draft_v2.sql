-- Draft v2 Migration
-- Run this in Supabase SQL Editor
-- https://jhpoiyhxcfxoezcbxdss.supabase.co

-- 1. Add context column to quest_drafts
ALTER TABLE quest_drafts 
ADD COLUMN IF NOT EXISTS context TEXT;

-- 2. Create draft_logs table for activity tracking
CREATE TABLE IF NOT EXISTS draft_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  draft_id UUID NOT NULL REFERENCES quest_drafts(id) ON DELETE CASCADE,
  entry TEXT NOT NULL,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups by draft
CREATE INDEX IF NOT EXISTS idx_draft_logs_draft_id ON draft_logs(draft_id);
CREATE INDEX IF NOT EXISTS idx_draft_logs_logged_at ON draft_logs(logged_at DESC);

-- 3. Create draft_assets table for file attachments
CREATE TABLE IF NOT EXISTS draft_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  draft_id UUID NOT NULL REFERENCES quest_drafts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups by draft
CREATE INDEX IF NOT EXISTS idx_draft_assets_draft_id ON draft_assets(draft_id);

-- 4. Create storage bucket for draft assets (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('draft-assets', 'draft-assets', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Storage policies for draft-assets bucket
-- Allow public read
CREATE POLICY "Public read access for draft-assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'draft-assets');

-- Allow anon insert
CREATE POLICY "Allow anon insert for draft-assets"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'draft-assets');

-- Allow anon delete (for cleanup when promoting)
CREATE POLICY "Allow anon delete for draft-assets"
ON storage.objects FOR DELETE
USING (bucket_id = 'draft-assets');

-- 6. Enable RLS on new tables
ALTER TABLE draft_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE draft_assets ENABLE ROW LEVEL SECURITY;

-- Allow anon access to draft_logs
CREATE POLICY "Allow anon read draft_logs" ON draft_logs FOR SELECT USING (true);
CREATE POLICY "Allow anon insert draft_logs" ON draft_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon delete draft_logs" ON draft_logs FOR DELETE USING (true);

-- Allow anon access to draft_assets
CREATE POLICY "Allow anon read draft_assets" ON draft_assets FOR SELECT USING (true);
CREATE POLICY "Allow anon insert draft_assets" ON draft_assets FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon delete draft_assets" ON draft_assets FOR DELETE USING (true);

-- 7. Enable realtime for new tables
ALTER PUBLICATION supabase_realtime ADD TABLE draft_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE draft_assets;

-- Done! 
-- Tables created: draft_logs, draft_assets
-- Column added: quest_drafts.context
-- Storage bucket: draft-assets
