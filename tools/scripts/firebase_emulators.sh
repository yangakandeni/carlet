#!/usr/bin/env bash
set -euo pipefail

# Firebase Emulators helper for macOS/Linux (zsh/bash)
#
# Purpose:
#   Convenience wrapper to start/stop/query the Firebase Local Emulator Suite
#   for this project. It manages backgrounding (via nohup), stores a PID file
#   and logs, and provides helpers to export/import emulator data.
#
# Key features:
#   - start:  launches the selected emulators in the background and writes a
#            PID file + a logfile for inspection.
#   - stop:   stops the background emulators process referenced by the PID
#            file (attempts graceful stop, then force kills if necessary).
#   - status: prints whether the emulators appear to be running and shows
#            the commonly used local ports (Auth, Firestore, Storage, UI).
#   - logs:   tails the emulator log file.
#   - save:   exports emulator data to tools/scripts/emulator_data/ for
#            later re-import via the start command.
#
# Usage examples:
#   # start (uses DEFAULT_PROJECT_ID unless PROJECT_ID is set in env)
#   ./tools/scripts/firebase_emulators.sh start
#
#   # override project id for a one-off run
#   PROJECT_ID=my-firebase-project ./tools/scripts/firebase_emulators.sh start
#
# Notes:
#   - Requires the Firebase CLI (npm i -g firebase-tools).
#   - The emulator UI is typically available at http://127.0.0.1:4005 and
#     from an Android emulator at http://10.0.2.2:4005.
#   - This script is intentionally conservative: it only manipulates the
#     background launcher process and will not alter firebase.json.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR%/tools}"
LOG_FILE="$SCRIPT_DIR/emulators.log"
PID_FILE="$SCRIPT_DIR/emulators.pid"
DATA_DIR="$SCRIPT_DIR/emulator_data"

# Default project used for emulator runs. Override by setting the PROJECT_ID
# environment variable before invoking the script, or by using your local
# .firebaserc configuration when running the Firebase CLI directly.
DEFAULT_PROJECT_ID="carlet-dev-6be6a"
PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT_ID}"

command -v firebase >/dev/null 2>&1 || {
  echo "[ERR] firebase CLI not found. Install: npm i -g firebase-tools" >&2
  exit 1
}

ensure_dirs() {
  mkdir -p "$SCRIPT_DIR" "$DATA_DIR"
}

is_running() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || echo)"
    if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

ports_status() {
  # Use indexed arrays for compatibility with macOS / bash 3.2 (no assoc arrays)
  local ports=(9098 8085 9198 4005)
  local port_names=("Auth" "Firestore" "Storage" "Emulator UI")
  local host="127.0.0.1"
  
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Firebase Emulators Status"
  echo "═══════════════════════════════════════════════════════════"
  
  for i in "${!ports[@]}"; do
    local p="${ports[$i]}"
    local name="${port_names[$i]}"
    local status="●"
    local color_start=""
    local color_end=""
    
    # Check if port is listening (try nc first, fallback to lsof)
    if nc -z "$host" "$p" 2>/dev/null || lsof -i :"$p" >/dev/null 2>&1; then
      status="✓ RUNNING"
      color_start="\033[0;32m"  # Green
      color_end="\033[0m"
    else
      status="✗ STOPPED"
      color_start="\033[0;31m"  # Red
      color_end="\033[0m"
    fi

    printf "  ${color_start}%-12s${color_end} http://%s:%-5s [%s]\n" \
      "$name" "$host" "$p" "$status"
  done
  
  echo "═══════════════════════════════════════════════════════════"
  echo ""
}

kill_port_processes() {
  # Kill processes using Firebase emulator ports (from firebase.json)
  # Use indexed arrays for compatibility with older bash (macOS)
  local ports=(9098 8085 9198 4005)
  local port_names=("Auth" "Firestore" "Storage" "Emulator UI")
  local killed=0

  echo "[INFO] Checking for processes on emulator ports..."
  for i in "${!ports[@]}"; do
    local p="${ports[$i]}"
    local name="${port_names[$i]}"
    local pids
    # Collect PIDs and normalize newlines to spaces so printing stays on one line
    pids=$(lsof -ti :"$p" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
      # Convert newline-separated pid list into a single space-separated string
      pids_single=$(printf '%s' "$pids" | tr '\n' ' ' | sed -E 's/[[:space:]]+$//')
      echo "[INFO] $name (127.0.0.1:$p) is in use by PID(s): $pids_single - terminating..."
      printf '%s\n' "$pids" | xargs kill -9 2>/dev/null || true
      killed=1
      sleep 0.5
    fi
  done
  
  if [[ $killed -eq 1 ]]; then
    echo "[INFO] Cleaned up existing processes on emulator ports"
    sleep 1
  else
    echo "[INFO] All emulator ports are free"
  fi
}

start_emulators() {
  if is_running; then
    echo "[INFO] Emulators already running (PID $(cat "$PID_FILE"))"
    exit 0
  fi
  ensure_dirs
  
  # Kill any processes on emulator ports before starting
  kill_port_processes

  # Start emulators; UI is controlled via firebase.json (ui.enabled: true)
  local cmd=(firebase emulators:start --only auth,firestore,storage --project "$PROJECT_ID")
  if [[ -d "$DATA_DIR" && -n "$(ls -A "$DATA_DIR" 2>/dev/null || true)" ]]; then
    cmd+=(--import "$DATA_DIR")
  fi

  echo "[INFO] Starting Firebase emulators in background... (logs: $LOG_FILE)"
  nohup bash -lc "cd '$PROJECT_ROOT' && ${cmd[*]}" >"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  sleep 3
  echo "[INFO] PID $(cat "$PID_FILE")"
  echo ""
  echo "[INFO] Emulators starting up..."
  echo "[INFO] View logs: ./tools/scripts/firebase_emulators.sh logs"
  echo "[INFO] Local access: http://127.0.0.1:4005"
  echo "[INFO] Android emulator access: http://10.0.2.2:4005"
  ports_status
}

stop_emulators() {
  if ! is_running; then
    echo "[INFO] Emulators are not running."
    exit 0
  fi
  local pid
  pid="$(cat "$PID_FILE")"
  echo "[INFO] Stopping emulators (PID $pid)..."
  kill "$pid" 2>/dev/null || true
  # Graceful wait
  for i in {1..20}; do
    if ps -p "$pid" >/dev/null 2>&1; then
      sleep 0.5
    else
      break
    fi
  done
  if ps -p "$pid" >/dev/null 2>&1; then
    echo "[WARN] Force killing PID $pid"
    kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
  echo "[INFO] Stopped."
}

save_snapshot() {
  echo "[INFO] Exporting emulator data to $DATA_DIR ..."
  mkdir -p "$DATA_DIR"
  firebase emulators:export "$DATA_DIR" --project "$PROJECT_ID"
  echo "[INFO] Export complete."
}

tail_logs() {
  if [[ -f "$LOG_FILE" ]]; then
    tail -n +1 -f "$LOG_FILE"
  else
    echo "[INFO] No logs yet at $LOG_FILE"
  fi
}

show_status() {
  if is_running; then
    echo "[INFO] Emulators are running (PID $(cat "$PID_FILE"))"
  else
    echo "[INFO] Emulators are stopped"
  fi
  ports_status
}

case "${1:-}" in
  start) start_emulators ;;
  stop) stop_emulators ;;
  status) show_status ;;
  logs) tail_logs ;;
  save) save_snapshot ;;
  *)
    echo "Firebase Emulators helper"
    echo "Usage: $0 {start|stop|status|logs|save}"
    echo "Commands:"
    echo "  start   - start emulators in background (creates PID/log files)"
    echo "  stop    - stop background emulators process referenced by PID file"
    echo "  status  - show emulator ports and process status"
    echo "  logs    - tail emulator log file"
    echo "  save    - export emulator data to tools/scripts/emulator_data/"
    echo "Env: PROJECT_ID (default: $DEFAULT_PROJECT_ID)"
    exit 1
    ;;
esac
