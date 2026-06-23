#!/bin/bash
# ============================================================================
# Start BuildBuddy Remote — double-click this to run the agent on your Mac.
# It prints your Mac's address + a pairing token for the iPhone remote, then
# stays open and listens. Close the window (or Ctrl-C) to stop.
# ============================================================================
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# macOS ships Python 3; prefer python3, fall back to python.
PY="$(command -v python3 || command -v python)"
if [ -z "$PY" ]; then
  echo "Python 3 wasn't found. It normally ships with macOS."
  echo "Open Terminal and run:  xcode-select --install   then try again."
  exit 1
fi

# First double-click of a .command may be Gatekeeper-blocked: right-click → Open once.
xattr -d com.apple.quarantine "$DIR/buddyd.py" 2>/dev/null || true

echo "Starting BuildBuddy Remote agent…"
exec "$PY" "$DIR/buddyd.py"
