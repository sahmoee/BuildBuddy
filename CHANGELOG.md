# BuildBuddy — Changelog

The in-app **What's New** screen (click the version badge, or Check for Updates) shows this
same history. The running version is displayed next to the project name in the header.

## v1.6 — 2026-06-22
- **Self-update:** a **Check for Updates** button pulls the latest BuildBuddy from GitHub and
  relaunches so it rebuilds — no more applying a drop just to update the app itself.
- **Visible version** in the header (and in Doctor), so you can always tell what's running.
- **What's New screen** backed by this changelog; it pops automatically after an update.

## v1.5 — 2026-06-22
- Fixed the empty preview box so deliveries actually apply. The preview sheet is now bound
  directly to its data, removing a SwiftUI state race that left it blank with no Apply button.

## v1.4 — 2026-06-22
- Apply delivery and Add project now use the native open panel (the SwiftUI importer rendered
  blank in this unsigned app).
- A commit on an already-clean tree no longer reports a confusing failure.
- The branch reader ignores permission/fatal messages, so a folder error can't become the
  branch name.

## v1.3 — 2026-06-22
- Fixed a freeze when applying large deliveries: output is buffered and flushed a few times a
  second instead of per line, the console is capped, and the preview unzip runs quietly.

## v1.2 — 2026-06-22
- Added an Options window (~24 settings) including a global auto-commit-and-push switch and a
  default commit message.
- Downloads auto-detect: watches the Downloads folder and matches a delivery zip to the
  selected project.
- Replaced the fragile git-stash snapshot with a safe file-copy backup; added a command
  timeout and Cancel.

## v1.1 — 2026-06-21
- Auto-commit on apply, built-in delivery instructions, commit-message safety check, delivery
  preview, exit-code reporting, console search/copy/save, GitHub auth status in Doctor,
  keyboard shortcuts.

## v1.0 — 2026-06-21
- Initial BuildBuddy: per-project git loop (pull, commit & push, branch flows), apply Claude
  delivery zips, open in Xcode, deploy Cloudflare worker, Doctor dependency checks.
