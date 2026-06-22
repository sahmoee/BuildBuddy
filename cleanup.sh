#!/usr/bin/env bash
# One-time cleanup: stop tracking build output / metadata that were committed before
# .gitignore existed, then commit and push. Safe to run more than once.
#
# Usage:
#   ./cleanup.sh            # clean up, commit (no push)
#   ./cleanup.sh --push     # clean up, commit, and push to origin/<current branch>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Must be inside a git repo.
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "error: not inside a git repository. cd into your repo and run again." >&2
  exit 1
fi
cd "$REPO_ROOT"
echo "Repo: $REPO_ROOT"

# Make sure .gitignore exists with the right rules (the overlay should have placed it,
# but write it here too so this script works standalone).
if [ ! -f .gitignore ] || ! grep -q '^\.build/$' .gitignore 2>/dev/null; then
  printf '.build/\n.buildbuddy-backups/\n.DS_Store\n__MACOSX/\n*.swp\n.vscode/\n' > .gitignore
  echo "Wrote .gitignore"
else
  echo ".gitignore already present"
fi

# Untrack the junk if it is currently tracked. --cached keeps the files on disk;
# it only removes them from git. The '|| true' avoids errors when already untracked.
echo "Untracking build output and metadata (files stay on disk)..."
git rm -r --cached --ignore-unmatch .build              >/dev/null 2>&1 || true
git rm    --cached --ignore-unmatch .DS_Store            >/dev/null 2>&1 || true
git rm -r --cached --ignore-unmatch .buildbuddy-backups  >/dev/null 2>&1 || true
# Remove any nested .DS_Store that slipped in.
git ls-files -z | grep -zE '(^|/)\.DS_Store$' | xargs -0 -r git rm --cached --ignore-unmatch >/dev/null 2>&1 || true

# Stage everything. Because .gitignore now exists, the build output will NOT be re-added.
git add -A

if git diff --cached --quiet; then
  echo "Nothing to clean up — working tree already clean. Done."
  exit 0
fi

echo "Changes to be committed:"
git status --short

git commit -m "Add gitignore and stop tracking build output"
echo "Committed cleanup."

if [ "${1:-}" = "--push" ]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  echo "Pushing to origin/$BRANCH ..."
  git push origin "$BRANCH" 2>/dev/null || git push -u origin "$BRANCH"
  echo "Push complete."
else
  echo "Skipped push. Run './cleanup.sh --push' or use BuildBuddy's Commit & Push."
fi
