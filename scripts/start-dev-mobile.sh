#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
API_DIR="$REPO_ROOT/apps/api"
REINSTALL_SCRIPT="$SCRIPT_DIR/reinstall-ios-sim.sh"
ROOT_ENV_FILE="$REPO_ROOT/.env"
PID_FILE="$REPO_ROOT/.run/backend-dev.pid"
LOG_FILE="$REPO_ROOT/.run/backend-dev.log"
DEFAULT_API_PORT=3000

usage() {
  cat <<'EOF'
Usage:
  scripts/start-dev-mobile.sh [simulator-name-or-udid]

What it does:
  - starts the NestJS backend if it is not already running
  - waits for the API health endpoint to respond
  - reinstalls and launches the iOS simulator app

Examples:
  scripts/start-dev-mobile.sh
  scripts/start-dev-mobile.sh "iPhone 16"
  scripts/start-dev-mobile.sh AAFDC068-0991-4F0A-8F43-EBCE4D872FD7
EOF
}

read_api_port() {
  if [[ -f "$ROOT_ENV_FILE" ]]; then
    local line
    line="$(grep -E '^API_PORT=' "$ROOT_ENV_FILE" | tail -n1 || true)"
    if [[ -n "$line" ]]; then
      printf '%s\n' "${line#API_PORT=}"
      return
    fi
  fi

  printf '%s\n' "$DEFAULT_API_PORT"
}

api_is_ready() {
  local api_url="$1"
  local response

  response="$(curl --silent --show-error --max-time 2 "$api_url" 2>/dev/null || true)"
  [[ "$response" == *'"status":"ok"'* ]]
}

cleanup_stale_pid_file() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE")"
    if [[ -n "$pid" ]] && ! kill -0 "$pid" >/dev/null 2>&1; then
      rm -f "$PID_FILE"
    fi
  fi
}

start_backend_if_needed() {
  local api_url="$1"

  mkdir -p "$(dirname "$PID_FILE")"
  cleanup_stale_pid_file

  if api_is_ready "$api_url"; then
    echo "Backend already responding at $api_url"
    return
  fi

  if [[ -f "$PID_FILE" ]]; then
    echo "Backend process already tracked in $PID_FILE, waiting for it to become ready..."
  else
    echo "Starting backend from $API_DIR"
    (
      cd "$API_DIR"
      nohup pnpm run start:dev >"$LOG_FILE" 2>&1 &
      echo $! >"$PID_FILE"
    )
    echo "Backend log: $LOG_FILE"
  fi

  for _ in {1..60}; do
    if api_is_ready "$api_url"; then
      echo "Backend is ready at $api_url"
      return
    fi
    sleep 1
  done

  echo "Backend did not become ready in time." >&2
  echo "Check log: $LOG_FILE" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -x "$REINSTALL_SCRIPT" ]]; then
  echo "Missing reinstall helper: $REINSTALL_SCRIPT" >&2
  exit 1
fi

API_PORT="$(read_api_port)"
API_URL="http://localhost:${API_PORT}"
SIMULATOR_TARGET="${1:-}"

start_backend_if_needed "$API_URL"

echo "Reinstalling iOS app against $API_URL"
if [[ -n "$SIMULATOR_TARGET" ]]; then
  "$REINSTALL_SCRIPT" "$SIMULATOR_TARGET"
else
  "$REINSTALL_SCRIPT"
fi
