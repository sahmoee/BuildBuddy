# BuildBuddy — Changelog

The in-app **What's New** screen (click the version badge, or Check for Updates) shows this
same history. The running version is displayed next to the project name in the header.

## v1.7 — 2026-06-22
- **No more re-applying:** BuildBuddy compares each file in a delivery against your repo and
  applies only the **new or changed** files, skipping identical ones.
- An already-applied delivery is detected and **skipped** instead of producing a confusing
  empty commit.
- The preview labels each file **NEW**, **CHG** (changed), or unchanged, and the Apply button
  shows how many files will actually change.

## v1.6 — 2026-06-22
- **Self-update:** a **Check for Updates** button pulls the latest BuildBuddy from GitHub and
  relaunches so it rebuilds — no more applying a drop just to update the app itself.
- **Visible version** in the header (and in Doctor).
- **What's New screen** backed by this changelog; it pops automatically after an update.

## v1.5 — 2026-06-22
- Fixed the empty preview box so deliveries actually apply (preview sheet bound directly to its
  data, removing a SwiftUI state race).

## v1.4 — 2026-06-22
- Native open panels for Apply delivery and Add project; clean-tree commit no longer reports a
  fake failure; branch reader ignores permission/fatal messages.

## v1.3 — 2026-06-22
- Fixed a freeze when applying large deliveries (buffered console output, capped console, quiet
  preview unzip).

## v1.2 — 2026-06-22
- Options window (~24 settings), Downloads auto-detect, file-copy backup, command timeout + Cancel.

## v1.1 — 2026-06-21
- Auto-commit on apply, built-in instructions, commit-message safety check, delivery preview,
  exit-code reporting, console search/copy/save, GitHub auth in Doctor, keyboard shortcuts.

## v1.0 — 2026-06-21
- Initial BuildBuddy.
