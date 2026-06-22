#!/usr/bin/env bash
# Installs the BuildBuddy v1.3 freeze fix DIRECTLY into your repo, then commits & pushes.
# Use this because the freeze prevents applying the fix through BuildBuddy itself.
#
# 1. Force-quit the frozen BuildBuddy first (Option-Command-Escape, or run: pkill -9 BuildBuddy)
# 2. Put this script and the new BuildBuddy.swift in the SAME folder, then double-click this.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO="$HOME/Documents/BuildBuddy"
if [ ! -d "$REPO/.git" ]; then
  echo "Can't find a git repo at $REPO."
  echo "Edit this script's REPO= line to point at your BuildBuddy folder."
  read -r -p "Press return to close." _; exit 1
fi

if [ ! -f "$SCRIPT_DIR/BuildBuddy.swift" ]; then
  echo "BuildBuddy.swift is not next to this script. Put both in the same folder."
  read -r -p "Press return to close." _; exit 1
fi

echo "Stopping any running BuildBuddy..."
pkill -9 BuildBuddy 2>/dev/null || true

echo "Copying the fixed source into $REPO ..."
cp "$SCRIPT_DIR/BuildBuddy.swift" "$REPO/BuildBuddy.swift"
[ -f "$SCRIPT_DIR/Launch BuildBuddy.command" ] && cp "$SCRIPT_DIR/Launch BuildBuddy.command" "$REPO/Launch BuildBuddy.command" || true

cd "$REPO"
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit (already up to date)."
else
  git commit -F "$SCRIPT_DIR/COMMIT_MSG.txt" 2>/dev/null || git commit -m "BuildBuddy v1.3 fix freeze when applying large deliveries"
  echo "Committed."
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push origin "$BRANCH" 2>/dev/null || git push -u origin "$BRANCH" || echo "Push skipped/failed — you can push later."
fi

echo "Rebuilding and launching BuildBuddy..."
rm -rf "$REPO/.build/BuildBuddy.app" 2>/dev/null || true
open "$REPO/Launch BuildBuddy.command"
echo "Done. BuildBuddy should rebuild from the fixed source and open."
read -r -p "Press return to close." _
