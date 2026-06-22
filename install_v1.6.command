#!/usr/bin/env bash
# One-time install of BuildBuddy v1.6 (self-update + changelog) straight into your repo.
# After this, you never need this script again — use Check for Updates inside the app.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$HOME/Documents/BuildBuddy"
if [ ! -d "$REPO/.git" ]; then
  echo "No git repo at $REPO. Edit the REPO= line in this script to your BuildBuddy folder."
  read -r -p "Press return to close." _; exit 1
fi
echo "Stopping any running BuildBuddy..."
pkill -9 BuildBuddy 2>/dev/null || true
echo "Installing v1.6 source + changelog into $REPO ..."
cp "$SCRIPT_DIR/BuildBuddy.swift" "$REPO/BuildBuddy.swift"
cp "$SCRIPT_DIR/Launch BuildBuddy.command" "$REPO/Launch BuildBuddy.command"
cp "$SCRIPT_DIR/CHANGELOG.md" "$REPO/CHANGELOG.md"
cd "$REPO"
git add -A
if git diff --cached --quiet; then
  echo "Already up to date."
else
  git commit -F "$SCRIPT_DIR/COMMIT_MSG.txt" 2>/dev/null || git commit -m "BuildBuddy v1.6 self-update and changelog"
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push origin "$BRANCH" 2>/dev/null || git push -u origin "$BRANCH" || echo "(push skipped — you can push later)"
fi
echo "Rebuilding and launching v1.6 ..."
rm -rf "$REPO/.build/BuildBuddy.app" 2>/dev/null || true
open "$REPO/Launch BuildBuddy.command"
echo "Done. BuildBuddy should open showing v1.6 next to the project name."
read -r -p "Press return to close." _
