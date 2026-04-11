#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/apps/mobile"
WORKSPACE_PATH="$APP_DIR/ios/Runner.xcworkspace"
SCHEME="Runner"
BUNDLE_ID="com.sercesync.sercesyncMobile"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$APP_DIR/build/ios-sim-derived-data}"
DEFAULT_SIMULATOR_NAME="${DEFAULT_SIMULATOR_NAME:-iPhone 16}"

usage() {
  cat <<'EOF'
Usage:
  scripts/reinstall-ios-sim.sh [simulator-name-or-udid]

Examples:
  scripts/reinstall-ios-sim.sh
  scripts/reinstall-ios-sim.sh "iPhone 16"
  scripts/reinstall-ios-sim.sh AAFDC068-0991-4F0A-8F43-EBCE4D872FD7

Behavior:
  - uses the currently booted simulator if one exists
  - otherwise falls back to DEFAULT_SIMULATOR_NAME (default: iPhone 16)
  - builds the iOS simulator app
  - uninstalls the existing app if present
  - reinstalls and launches a fresh build
EOF
}

find_booted_simulator_udid() {
  xcrun simctl list devices | awk -F '[()]' '/Booted/{print $2; exit}'
}

resolve_simulator_udid() {
  local requested="${1:-}"

  if [[ -z "$requested" ]]; then
    local booted
    booted="$(find_booted_simulator_udid)"
    if [[ -n "$booted" ]]; then
      printf '%s\n' "$booted"
      return
    fi
    requested="$DEFAULT_SIMULATOR_NAME"
  fi

  if [[ "$requested" =~ ^[0-9A-F-]{36}$ ]]; then
    printf '%s\n' "$requested"
    return
  fi

  local match
  match="$(xcrun simctl list devices available | grep -F "$requested" | head -n1 || true)"
  if [[ -z "$match" ]]; then
    echo "Could not find an available simulator matching: $requested" >&2
    exit 1
  fi

  printf '%s\n' "$match" | awk -F '[()]' '{print $2}'
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SIMULATOR_UDID="$(resolve_simulator_udid "${1:-}")"
DESTINATION="id=$SIMULATOR_UDID"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/Runner.app"

echo "Using simulator: $SIMULATOR_UDID"
echo "Building workspace: $WORKSPACE_PATH"

open -a Simulator >/dev/null 2>&1 || true
xcrun simctl boot "$SIMULATOR_UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIMULATOR_UDID" -b

xcodebuild \
  -workspace "$WORKSPACE_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app not found at: $APP_PATH" >&2
  exit 1
fi

echo "Reinstalling $BUNDLE_ID ..."
xcrun simctl terminate "$SIMULATOR_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$SIMULATOR_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo
echo "Fresh install complete."
echo "App: $BUNDLE_ID"
echo "Simulator: $SIMULATOR_UDID"
