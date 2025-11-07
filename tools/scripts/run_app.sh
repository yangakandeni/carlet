#!/usr/bin/env bash
set -euo pipefail

# Run the Flutter app from the command line with environment flags.
#
# Usage examples:
#   # Default (DEV environment, debug mode, let flutter pick device)
#   ./tools/scripts/run_app.sh
#
#   # Run on a specific device (e.g., macos, ios, chrome, emulator id)
#   ./tools/scripts/run_app.sh --device macos
#
#   # Use a different environment and run in release mode
#   ./tools/scripts/run_app.sh --env STAGING --release
#
#   # Specify a flavor if your project uses flavors
#   ./tools/scripts/run_app.sh --env PROD --flavor production --device android
#
# The script sets a Dart define named APP_ENV (default: DEV) which you can
# read in Dart via const String.fromEnvironment('APP_ENV'). This approach is
# intentionally simple and avoids requiring specific flavor setups.

PROGNAME="$(basename "$0")"

DEFAULT_ENV="DEV"
DART_DEFINE_NAME="APP_ENV"

show_help() {
  cat <<-EOF
Usage: $PROGNAME [options]

Options:
  -e, --env <ENV>       Environment to run (DEV, STAGING, PROD). Default: $DEFAULT_ENV
  -d, --device <ID>     Flutter device id (e.g. macos, ios, chrome, emulator-5554). Default: none (flutter chooses)
  -f, --flavor <NAME>   Flutter flavor to use (if your project defines flavors)
  -r, --release         Run in release mode (default: debug)
  -h, --help            Show this help and exit

This script forwards the selected options to 'flutter run' and sets a
--dart-define $DART_DEFINE_NAME=<ENV> so your Dart code can adapt to the
chosen environment.
EOF
}

ENV="$DEFAULT_ENV"
DEVICE=""
FLAVOR=""
MODE="debug"

if [[ $# -eq 0 ]]; then
  # No args -> run with defaults
  true
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      ENV="${2:-}"
      shift 2
      ;;
    -d|--device)
      DEVICE="${2:-}"
      shift 2
      ;;
    -f|--flavor)
      FLAVOR="${2:-}"
      shift 2
      ;;
    -r|--release)
      MODE="release"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unknown argument: $1"
      show_help
      exit 1
      ;;
  esac
done

# Normalize and accept common aliases (case-insensitive) so users can type
# friendly values like "dev", "development", "prod", or "production".
raw_env="$ENV"
lc_env="$(echo "$raw_env" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
case "$lc_env" in
  dev|development)
    ENV="DEV" ;;
  staging|stage|stg|qa)
    ENV="STAGING" ;;
  prod|production|prd)
    ENV="PROD" ;;
  "")
    ENV="${DEFAULT_ENV}" ;;
  *)
    # If the input didn't match any alias, normalize to uppercase and validate below
    ENV="$(echo "$raw_env" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')"
    ;;
esac

# Validate allowed environment names to avoid accidental typos.
allowed_envs=("DEV" "STAGING" "PROD")
valid_env=false
for v in "${allowed_envs[@]}"; do
  if [[ "$ENV" == "$v" ]]; then
    valid_env=true
    break
  fi
done
if [[ "$valid_env" != true ]]; then
  echo "[ERR] Unknown environment: '$ENV'"
  echo "Allowed environments (aliases accepted): dev/development -> DEV, staging/stage -> STAGING, prod/production -> PROD"
  echo
  show_help
  exit 1
fi

echo "Running Flutter app"
echo "  Environment: $ENV"
echo "  Mode: $MODE"
if [[ -n "$DEVICE" ]]; then echo "  Device: $DEVICE"; fi
if [[ -n "$FLAVOR" ]]; then echo "  Flavor: $FLAVOR"; fi

# Build flutter command
cmd=(flutter run)

if [[ -n "$DEVICE" ]]; then
  cmd+=( -d "$DEVICE" )
fi

if [[ -n "$FLAVOR" ]]; then
  cmd+=( --flavor "$FLAVOR" )
fi

if [[ "$MODE" == "release" ]]; then
  cmd+=( --release )
fi

# Add dart define for environment
cmd+=( --dart-define "$DART_DEFINE_NAME=$ENV" )

# If running in DEV environment, also enable emulator flag at compile/runtime
# so the Flutter code compiled in this run will see USE_EMULATORS=true.
if [[ "$ENV" == "DEV" ]]; then
  cmd+=( --dart-define "USE_EMULATORS=true" )
fi

# For Android debug builds the Google Services Gradle plugin requires a
# `google-services.json` to be present. Create a lightweight placeholder
# under android/app/src/debug/ when running DEV so local emulator/debug
# builds don't fail the Gradle check. We try to infer projectId and
# applicationId; fallback to sensible defaults if extraction fails.
if [[ "$ENV" == "DEV" ]]; then
  GS_PATH="android/app/src/debug/google-services.json"
  if [[ ! -f "$GS_PATH" ]]; then
  # Try to extract projectId from generated firebase_options.dart (take first match)
  project_id=$(grep -o "projectId: '[^']*'" lib/firebase_options.dart | head -n1 || true)
  project_id=${project_id#projectId: }
  project_id=${project_id//\'/}
  project_id=${project_id:-carlet-dev-6be6a}

    # Try to extract applicationId from android/app/build.gradle.kts
    app_id=$(grep -o 'applicationId *= *"[^"]*"' android/app/build.gradle.kts 2>/dev/null || true)
    app_id=${app_id#applicationId = }
    app_id=${app_id//\"/}
    app_id=${app_id:-com.techolosh.carletdev}

    mkdir -p "$(dirname "$GS_PATH")"
  cat >"$GS_PATH" <<EOF
{
  "project_info": {
    "project_number": "0",
    "project_id": "$project_id",
    "storage_bucket": ""
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:0:android:0",
        "android_client_info": {
          "package_name": "$app_id"
        }
      },
      "api_key": [
        {
          "current_key": "placeholder_api_key"
        }
      ]
    }
  ],
  "configuration_version": "1"
}
EOF
    echo "[INFO] Created placeholder $GS_PATH for DEV build (project_id=$project_id, app_id=$app_id)"
    CREATED_GS=1
  fi
fi

echo
echo "+ ${cmd[*]}"

# Execute the command and preserve exit code. If we created a temporary
# debug google-services.json placeholder, remove it after the run so the
# workspace isn't polluted.
"${cmd[@]}"
EXIT_CODE=$?
if [[ -n "${CREATED_GS:-}" && -f "$GS_PATH" ]]; then
  rm -f "$GS_PATH" && echo "[INFO] Removed placeholder $GS_PATH"
fi
exit $EXIT_CODE
