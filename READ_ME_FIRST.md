# BuildBuddy v1.3 — freeze fix (apply this directly, not through BuildBuddy)

The freeze stops you from applying a fix *inside* BuildBuddy, so this installs it directly.

## Easiest way (double-click)
1. Force-quit the frozen BuildBuddy: press Option-Command-Escape, select BuildBuddy, Force Quit.
   (Or in Terminal: `pkill -9 BuildBuddy`)
2. Double-click **install_freezefix.command** in this folder.
   It copies the fixed `BuildBuddy.swift` into `~/Documents/BuildBuddy`, commits, pushes, and
   relaunches the app (which rebuilds from the new source).
   - If your repo isn't at `~/Documents/BuildBuddy`, open the script and edit the `REPO=` line.

## Manual way (Terminal)
```bash
pkill -9 BuildBuddy 2>/dev/null
cp "BuildBuddy.swift" ~/Documents/BuildBuddy/BuildBuddy.swift
cp "Launch BuildBuddy.command" ~/Documents/BuildBuddy/"Launch BuildBuddy.command"
cd ~/Documents/BuildBuddy
git add -A
git commit -m "BuildBuddy v1.3 fix freeze when applying large deliveries"
git push origin master
rm -rf .build/BuildBuddy.app
open "Launch BuildBuddy.command"
```

## What changed
- Output is buffered and flushed ~8x/second instead of once per line, so a large delivery
  (like Stocked's many files) no longer floods and freezes the main thread.
- The console is capped to a recent window so it never rebuilds a huge string.
- The preview unzip runs quietly (no line-per-file).

After this, applying big deliveries through BuildBuddy will work normally.
