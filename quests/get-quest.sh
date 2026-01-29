#!/bin/bash
# Get quest context + assets from Supabase
# Usage: ./get-quest.sh <quest-id>

QUEST_ID="$1"

if [ -z "$QUEST_ID" ]; then
  echo "Usage: $0 <quest-id>"
  echo ""
  echo "Available quests:"
  curl -s "https://jhpoiyhxcfxoezcbxdss.supabase.co/rest/v1/quests?select=id,title,status&status=neq.archived" \
    -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocG9peWh4Y2Z4b2V6Y2J4ZHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NDc5NTUsImV4cCI6MjA4NTIyMzk1NX0.PElgaG4p1oN5XlZMQX4wEFscXfBFj0OTcx5z3Xmfn1I" | jq -r '.[] | "  \(.id) — \(.title)"'
  exit 1
fi

SUPABASE_URL="https://jhpoiyhxcfxoezcbxdss.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocG9peWh4Y2Z4b2V6Y2J4ZHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NDc5NTUsImV4cCI6MjA4NTIyMzk1NX0.PElgaG4p1oN5XlZMQX4wEFscXfBFj0OTcx5z3Xmfn1I"

echo "═══════════════════════════════════════════════════════════════"
echo "QUEST: $QUEST_ID"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Get quest details
QUEST=$(curl -s "${SUPABASE_URL}/rest/v1/quests?id=eq.${QUEST_ID}" \
  -H "apikey: ${ANON_KEY}" | jq '.[0]')

if [ "$QUEST" = "null" ]; then
  echo "Quest not found: $QUEST_ID"
  exit 1
fi

echo "TITLE: $(echo $QUEST | jq -r '.title')"
echo "STATUS: $(echo $QUEST | jq -r '.status')"
echo "TOPIC: $(echo $QUEST | jq -r '.topic')"
echo "COLLABORATOR: $(echo $QUEST | jq -r '.collaborator // "none"')"
echo ""

if [ "$(echo $QUEST | jq -r '.pr_number')" != "null" ]; then
  echo "PR: #$(echo $QUEST | jq -r '.pr_number') ($(echo $QUEST | jq -r '.pr_state'))"
  echo "    $(echo $QUEST | jq -r '.pr_title')"
  echo "    $(echo $QUEST | jq -r '.pr_url')"
  echo ""
fi

echo "CONTEXT:"
echo "$(echo $QUEST | jq -r '.context // "No context"')"
echo ""

# Get logs
echo "───────────────────────────────────────────────────────────────"
echo "RECENT LOGS:"
LOGS=$(curl -s "${SUPABASE_URL}/rest/v1/quest_logs?quest_id=eq.${QUEST_ID}&order=logged_at.desc&limit=5" \
  -H "apikey: ${ANON_KEY}")

echo "$LOGS" | jq -r '.[] | "[\(.logged_at | split("T")[0])] \(.entry)"'
echo ""

# Get assets
echo "───────────────────────────────────────────────────────────────"
echo "ASSETS:"
ASSETS=$(curl -s "${SUPABASE_URL}/rest/v1/quest_assets?quest_id=eq.${QUEST_ID}&order=uploaded_at.desc" \
  -H "apikey: ${ANON_KEY}")

ASSET_COUNT=$(echo "$ASSETS" | jq 'length')
if [ "$ASSET_COUNT" = "0" ]; then
  echo "No assets attached"
else
  echo "$ASSETS" | jq -r '.[] | "• \(.name) (\(.mime_type))\n  \("https://jhpoiyhxcfxoezcbxdss.supabase.co/storage/v1/object/public/quest-assets/\(.storage_path)")"'
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
