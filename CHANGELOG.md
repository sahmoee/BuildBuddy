# BuildBuddy — Changelog

The in-app **What's New** screen (click the version badge, or Check for Updates) shows this
same history. The running version is displayed next to the project name in the header.

## v1.10 — 2026-06-26
- **Apply history & undo log.** Every applied delivery is recorded (files, commit SHA,
  timestamp). Open **Apply history** to review them; one-click **Undo** restores the files a
  delivery overwrote, from the backup taken at apply time.
- **Scheduled auto-pull.** Optionally pull the selected project — or every project — on a timer.
  It only fast-forwards and is skipped while another action is running.
- **Multi-zip queue.** Drop several delivery zips on the console at once (or add them in the
  **Delivery queue**) and apply them in sequence.
- **UI/UX pass.** Sidebar status dots, a collapsible and drag-resizable console, toast
  notifications, accent-color theming, grouped action buttons (Git / Delivery / Tools), a
  colorized diff viewer, and a richer welcome screen.

## v1.9.1 — 2026-06-25
- **Auto-cleanup after a delivery.** Once a delivery actually applies, BuildBuddy deletes the
  extracted temp folder **and** the original `.zip`. Skipped or already-applied deliveries keep
  their zip so you can retry. Two options (both on by default) control this; dry-run never
  deletes anything.

## v1.9 — 2026-06-24
- **Much faster.** Git commands no longer launch a *login* shell (which re-read your entire
  shell profile — nvm, pyenv, brew shellenv — on every call). They now use a non-login shell
  with a pre-resolved PATH. Project status reads in a **single batched git command** and is
  **cached per project**, so selecting a project you've seen before paints instantly.
- **10 reliability improvements:** Refresh-all, ahead/behind vs origin in the header, a Fetch
  button, Stash / Unstash, Discard-changes (guarded), Copy-current-SHA, Open-on-GitHub, a
  per-action busy label (shows *what's* running), overlapping-action guarding, and a one-click
  "grant folder access" helper.
- **10 new features:** project **search** box, a multi-project **Dashboard**, a built-in
  **Diff viewer** for pending changes, **recent-commit history**, a **Command palette** (⌘K),
  **favorites/pinned** projects, per-project **notes**, **Commit-all-dirty-repos**, a quick
  branch switcher, and a **menu-bar** quick-actions extra.

## v1.8 — 2026-06-23
- iPhone Remote (on-device agent, QR pairing), three reach options (LAN / Tailscale / GitHub
  relay), and an SMB drop-folder that applies delivery zips dropped from the iPhone Files app.

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
