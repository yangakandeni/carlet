#!/usr/bin/env bash
# Insert a test report document into the Firestore emulator
set -euo pipefail

# Defaults - change via env or flags
PROJECT_ID="${PROJECT_ID:-carlet-dev-6be6a}"
EMULATOR_HOST="${EMULATOR_HOST:-127.0.0.1}"
EMULATOR_PORT="${EMULATOR_PORT:-8085}"
# When talking to the Firestore emulator over REST, sending Authorization: Bearer owner
# allows bypassing emulator security rules (useful for local testing). Override via
# EMULATOR_AUTH_HEADER env var if needed.
EMULATOR_AUTH_HEADER="${EMULATOR_AUTH_HEADER:-Authorization: Bearer owner}"

usage() {
  cat <<EOF
Usage: $(basename "$0") --reporter-id REPORTER_ID [--report-id REPORT_ID] [--title TITLE] [--description TEXT] [--severity SEVERITY] [--collection COLLECTION]

Inserts a test report into the Firestore emulator under:
  <collection>/{reportId}

Environment variables:
  PROJECT_ID      (default: ${PROJECT_ID})
  EMULATOR_HOST   (default: ${EMULATOR_HOST})
  EMULATOR_PORT   (default: ${EMULATOR_PORT})

Examples:
  # insert with generated id and defaults
  $(basename "$0") --reporter-id user123 --title "Broken traffic light" --severity high

  # insert into custom collection
  $(basename "$0") --reporter-id user123 --collection site_reports --title "Pothole"

EOF
}

if [[ ${#@} -eq 0 ]]; then
  usage
  exit 1
fi

# CLI args and defaults (fields required by your report schema)
REPORT_ID=""
REPORTER_ID=""
ANONYMOUS="false"
LICENSE_PLATE=""
LAT="37.4219983"
LNG="-122.084"
MESSAGE="Dear in the headlights"
PHOTO_URL="https://images.unsplash.com/photo-1441148345475-03a2e82f9719?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8Y2FyJTIwZnJvbnR8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&q=60&w=900"
TIMESTAMP=""
COLLECTION="reports"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report-id) REPORT_ID="$2"; shift 2;;
    --reporter-id) REPORTER_ID="$2"; shift 2;;
    --anonymous) ANONYMOUS="$2"; shift 2;;
    --license-plate) LICENSE_PLATE="$2"; shift 2;;
    --lat) LAT="$2"; shift 2;;
    --lng) LNG="$2"; shift 2;;
    --message) MESSAGE="$2"; shift 2;;
    --photo-url) PHOTO_URL="$2"; shift 2;;
    --timestamp) TIMESTAMP="$2"; shift 2;;
    --collection) COLLECTION="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [[ -z "$REPORTER_ID" ]]; then
  echo "ERROR: --reporter-id is required" >&2
  usage
  exit 2
fi

if [[ -z "$REPORT_ID" ]]; then
  REPORT_ID="report_$(date +%s)_$((RANDOM%10000))"
fi

BASE_URL="http://${EMULATOR_HOST}:${EMULATOR_PORT}/v1/projects/${PROJECT_ID}/databases/(default)/documents"
TARGET_PATH="${COLLECTION}"

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# If TIMESTAMP not provided, use NOW_ISO
if [[ -z "$TIMESTAMP" ]]; then
  TIMESTAMP="$NOW_ISO"
fi

echo "Inserting test report -> project=${PROJECT_ID} host=${EMULATOR_HOST}:${EMULATOR_PORT}"
echo " Document: ${TARGET_PATH}/${REPORT_ID}"

# Normalize boolean value for Firestore booleanValue
if [[ "$ANONYMOUS" == "true" || "$ANONYMOUS" == "1" ]]; then
  ANONYMOUS_BOOL="true"
else
  ANONYMOUS_BOOL="false"
fi

# Build Firestore REST payload. Firestore wants typed values.
read -r -d '' PAYLOAD <<JSON || true
{
  "fields": {
    "anonymous": {"booleanValue": ${ANONYMOUS_BOOL}},
    "licensePlate": {"stringValue": "${LICENSE_PLATE}"},
    "location": {
      "mapValue": {
        "fields": {
          "lat": {"doubleValue": ${LAT}},
          "lng": {"doubleValue": ${LNG}}
        }
      }
    },
    "message": {"stringValue": "${MESSAGE}"},
    "photoUrl": {"stringValue": "${PHOTO_URL}"},
    "reporterId": {"stringValue": "${REPORTER_ID}"},
    "status": {"stringValue": "open"},
    "timestamp": {"timestampValue": "${TIMESTAMP}"}
  }
}
JSON

URL="${BASE_URL}/${TARGET_PATH}?documentId=${REPORT_ID}"

echo "POST $URL"
HTTP_RESPONSE=$(curl -sS -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "$EMULATOR_AUTH_HEADER" --data "$PAYLOAD" "$URL")
# Safely split curl's response+http_code into body and code. Some shells
# (or failure cases) may produce a shorter response; avoid negative
# substring offsets which cause errors like "substring expression < 0".
len=${#HTTP_RESPONSE}
if [[ $len -ge 3 ]]; then
  HTTP_CODE=${HTTP_RESPONSE:$((len - 3)):3}
  BODY=${HTTP_RESPONSE:0:$((len - 3))}
else
  # Fallback if response shorter than 3 chars (unexpected)
  HTTP_CODE="000"
  BODY="$HTTP_RESPONSE"
fi

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
  echo "Successfully created report: ${REPORT_ID}"
else
  echo "Failed to create document (HTTP ${HTTP_CODE}):" >&2
  echo "$BODY" >&2
  exit 3
fi

echo "Fetching document to verify..."
GET_URL="${BASE_URL}/${TARGET_PATH}/${REPORT_ID}"
# Fetch the document body and pretty-print JSON if possible. Don't require
# `jq` to be installed; fall back to python's json.tool or raw output.
GET_BODY=$(curl -sS -H "$EMULATOR_AUTH_HEADER" "$GET_URL" || true)
if command -v jq >/dev/null 2>&1; then
  printf '%s\n' "$GET_BODY" | jq . || true
elif command -v python3 >/dev/null 2>&1; then
  printf '%s\n' "$GET_BODY" | python3 -m json.tool || true
else
  # Last resort: print raw body
  printf '%s\n' "$GET_BODY"
fi

echo "Done. Report id: ${REPORT_ID} inserted by reporter ${REPORTER_ID}."
