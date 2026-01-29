#!/bin/bash
# Upload a file to quest assets
# Usage: ./upload-asset.sh <quest_id> <file_path>

QUEST_ID="$1"
FILE_PATH="$2"

if [ -z "$QUEST_ID" ] || [ -z "$FILE_PATH" ]; then
  echo "Usage: $0 <quest_id> <file_path>"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "File not found: $FILE_PATH"
  exit 1
fi

SUPABASE_URL="https://jhpoiyhxcfxoezcbxdss.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocG9peWh4Y2Z4b2V6Y2J4ZHNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTY0Nzk1NSwiZXhwIjoyMDg1MjIzOTU1fQ.UJswoMR3_bwdON1QKjk6b2Cj-UCEHGUnn7CUnfwhfC8"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpocG9peWh4Y2Z4b2V6Y2J4ZHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NDc5NTUsImV4cCI6MjA4NTIyMzk1NX0.PElgaG4p1oN5XlZMQX4wEFscXfBFj0OTcx5z3Xmfn1I"

FILENAME=$(basename "$FILE_PATH")
TIMESTAMP=$(date +%s)
STORAGE_PATH="${QUEST_ID}/${TIMESTAMP}-${FILENAME}"
MIME_TYPE=$(file --mime-type -b "$FILE_PATH")
SIZE_BYTES=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null)

# Upload to storage
echo "Uploading to storage..."
UPLOAD_RESULT=$(curl -s -X POST "${SUPABASE_URL}/storage/v1/object/quest-assets/${STORAGE_PATH}" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: ${MIME_TYPE}" \
  --data-binary @"$FILE_PATH")

if echo "$UPLOAD_RESULT" | grep -q '"Key"'; then
  echo "✓ Uploaded to storage: $STORAGE_PATH"
else
  echo "✗ Storage upload failed: $UPLOAD_RESULT"
  exit 1
fi

# Insert metadata record
echo "Creating asset record..."
RECORD_RESULT=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/quest_assets" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"quest_id\": \"${QUEST_ID}\",
    \"name\": \"${FILENAME}\",
    \"mime_type\": \"${MIME_TYPE}\",
    \"storage_path\": \"${STORAGE_PATH}\",
    \"size_bytes\": ${SIZE_BYTES}
  }")

if echo "$RECORD_RESULT" | grep -q '"id"'; then
  echo "✓ Asset record created"
  PUBLIC_URL="${SUPABASE_URL}/storage/v1/object/public/quest-assets/${STORAGE_PATH}"
  echo ""
  echo "Public URL: $PUBLIC_URL"
else
  echo "✗ Record creation failed: $RECORD_RESULT"
  exit 1
fi
