-- Quest Drafts table migration
-- Run this via Supabase Dashboard > SQL Editor

CREATE TABLE IF NOT EXISTS quest_drafts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  description text,
  status text DEFAULT 'idea' CHECK (status IN ('idea', 'backlog', 'specced', 'ready', 'paused')),
  source_file text,
  source_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_quest_drafts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS quest_drafts_updated_at ON quest_drafts;
CREATE TRIGGER quest_drafts_updated_at
  BEFORE UPDATE ON quest_drafts
  FOR EACH ROW
  EXECUTE FUNCTION update_quest_drafts_updated_at();

-- Enable RLS (Row Level Security)
ALTER TABLE quest_drafts ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read/write (same as quests table)
CREATE POLICY "Allow anonymous read on quest_drafts" ON quest_drafts
  FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on quest_drafts" ON quest_drafts
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on quest_drafts" ON quest_drafts
  FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on quest_drafts" ON quest_drafts
  FOR DELETE USING (true);

-- Enable realtime for this table
ALTER PUBLICATION supabase_realtime ADD TABLE quest_drafts;
