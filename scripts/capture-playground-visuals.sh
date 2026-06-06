#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-4002}"
OUT_DIR="${OUT_DIR:-tmp/visual-regression}"
BASE_URL="http://localhost:${PORT}"
mkdir -p "$OUT_DIR"

if ! curl -fsS "${BASE_URL}/" >/dev/null 2>&1; then
  echo "Playground is not reachable at ${BASE_URL}. Start it with:" >&2
  echo "  cd examples/playground && PORT=${PORT} mix phx.server" >&2
  exit 1
fi

osascript <<EOF
set baseUrl to "${BASE_URL}"
tell application "Safari"
  activate
  if (count of windows) = 0 then make new document
  set URL of front document to baseUrl & "/admin"
end tell
EOF

sleep 1

capture() {
  local path="$1"
  local name="$2"

  osascript <<EOF
set targetUrl to "${BASE_URL}${path}"
tell application "Safari"
  activate
  set URL of front document to targetUrl
end tell
EOF

  sleep 1
  screencapture -x "${OUT_DIR}/${name}.png"
  echo "Captured ${OUT_DIR}/${name}.png"
}

capture "/admin" "dashboard"
capture "/admin/resources/product" "product-table"
capture "/admin/resources/product/1" "product-detail"
capture "/admin/resources/ticket/new" "ticket-new"
capture "/admin/resources/ticket/99/edit" "ticket-edit"
