# Install BuildBuddy v1.6 (one time) — then it updates itself

This version adds **self-update** and a **changelog**, so after this you never hand-install
again. Because the older apply flow was unreliable, install this one directly:

## Easiest (double-click)
1. Force-quit BuildBuddy: Option-Command-Escape → BuildBuddy → Force Quit (or `pkill -9 BuildBuddy`).
2. Double-click **install_v1.6.command**. It copies v1.6 into `~/Documents/BuildBuddy`, commits,
   pushes, rebuilds, and opens the app. (If your repo isn't there, edit the `REPO=` line.)
3. The app opens showing **v1.6** next to the project name, and a What's New window.

## From now on
- Click the **v1.6** badge (or **Check for Updates**, or ⌘U) → it pulls the latest BuildBuddy
  from GitHub. If there's a new version it offers **Update & Relaunch**, which rebuilds.
- I deliver future BuildBuddy updates by pushing to your `sahmoee/BuildBuddy` repo; you just
  click Check for Updates.

## How to tell what's running
The version badge in the header always shows the current version. Doctor shows it too.
