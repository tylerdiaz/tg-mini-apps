const { createClient } = require('@supabase/supabase-js');
const db = createClient(
  'https://jhpoiyhxcfxoezcbxdss.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocG9peWh4Y2Z4b2V6Y2J4ZHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgwOTcyMDMsImV4cCI6MjA1MzY3MzIwM30.nN7p43Q3FKfspMGajkfQlbaLOHWG1s5mG7JtJxa40a0'
);

async function clearDrafts() {
  // Delete all draft assets first
  const { data: drafts } = await db.from('drafts').select('id');
  if (drafts) {
    for (const draft of drafts) {
      await db.from('draft_assets').delete().eq('draft_id', draft.id);
    }
  }
  // Delete all drafts
  const { error } = await db.from('drafts').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  if (error) console.error('Error:', error);
  else console.log('Drafts cleared');
}
clearDrafts();
