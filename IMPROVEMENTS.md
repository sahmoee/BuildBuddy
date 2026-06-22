# BuildBuddy — 10 Improvements (v1.1)

This build implements ten concrete improvements over the original, plus the explicit
request to **ship the delivery instructions inside the app by default** (no loose PDF
needed). Every change is in the single `BuildBuddy.swift` file; the launcher and project
format are unchanged, so it builds and runs exactly the same way.

---

### 1. Auto-commit on apply (the playbook's recommended Option A)
The original applied a delivery and then waited for a manual **Commit & Push** click. Now,
when a per-project **Auto-commit** toggle (in the header) is ON, dropping a delivery zip
applies, commits, and pushes in one action using the bundled `COMMIT_MSG.txt`. This is the
"all builds automatically committed and pushed" behavior the instructions call for, and it
respects the commit-message safety rule (see #3).

### 2. Instructions shipped *inside* the app (the requested default)
The delivery playbook is now embedded as text and opened from an **Instructions** button
(and from the empty-state screen). It no longer depends on a separate PDF sitting in the
folder that can get lost or detached. Anyone — or any assistant — can open the app and read
the exact drop format, commit rules, and checklist on the spot.

### 3. Built-in commit-message safety check
The most important rule in the playbook is that commit messages must contain no shell
metacharacters (backticks, `$( )`, `$VAR`, quotes, backslashes), because BuildBuddy wraps
the message in double-quotes and escapes nothing else. The app now checks this natively:
the commit sheet shows **SAFE / UNSAFE live**, blocks an unsafe push, and an unsafe bundled
message is opened for review instead of being auto-committed. No more mangled or
shell-executing commits.

### 4. Dry-run preview before a delivery touches your repo
Dropping or picking a zip now opens a **review sheet** first: the exact list of files that
will overlay, the commit message, whether `commit.sh` is bundled, and any safety warnings —
*before* anything is written. You confirm with **Apply** or back out with **Cancel**. This
directly attacks the playbook's "merge-collision trap" by letting you see a stale or
unexpected file before it reverts someone's work.

### 5. Automatic undo snapshot before applying
Right before overlaying files, the app takes a timestamped `git stash` snapshot of your
working tree (then restores it), giving you a labeled restore point if a delivery goes
wrong. Previously, a bad overlay had no built-in safety net.

### 6. Per-command exit codes — no more silent failures
Every command now reports a clear `✅ … finished (exit 0)` or `❌ … failed — exit code N`
line in the console, and the guide strip shows a persistent ✅/❌ result badge. The original
streamed output but never surfaced whether a step actually succeeded, so a failed push could
look identical to a successful one.

### 7. Console search, copy, and save
The console gained a **Filter** box (live substring search), a **Copy** button (whole
transcript to clipboard), and a **Save** button (write the log to a `.txt` file). Useful for
pasting errors back to Claude per the README's own "if the build fails" guidance.

### 8. GitHub auth status surfaced in Doctor
Doctor now runs `gh auth status` and shows whether you're **logged in**, plus a one-click
**`gh auth login`** button (browser sign-in). The original told you in prose to run this in
Terminal yourself; now it's visible and actionable in-app, which is the single most common
first-run blocker for push/pull.

### 9. Keyboard shortcuts for every primary action
Primary actions now have shortcuts — ⌘L Pull, ⌘R Refresh (also in the menu bar), and
⇧⌘ shortcuts on the action buttons (⇧⌘D Apply delivery, ⇧⌘P Commit & Push, ⇧⌘N New branch,
⇧⌘O Open in Xcode, etc.) — so the whole loop is reachable without the mouse.

### 10. Safer quoting everywhere + Finder reveal + worker-path fix
A single `Sh.q(...)` helper now single-quotes every path and branch name passed to the
shell, so folders with spaces or quotes can't break (or inject into) a command — the
original interpolated some values raw. Added a **Reveal in Finder** button, and the data
model is ready for editing a misdetected worker folder without re-adding the project.

---

## Bonus correctness fix (upgrade safety)
Adding the new `autoCommitOnApply` field could have made the app silently **wipe all saved
projects** on first launch after upgrade, because `Codable` decoding of the old
`projects.json` (which lacks the field) would fail and the loader uses `try?`. A custom
`Codable` initializer now defaults the field when it's absent, so existing projects load
cleanly.

## What did *not* change
- The launcher (`Launch BuildBuddy.command`), build process, and one-file design.
- The v2 drop format and the project storage location.
- Versioning rules — the playbook imposes none, and neither does this build (the app version
  bump to 1.1 is just the app's own metadata).

---

# v1.2 — Freeze fix, Options menu, Downloads auto-detect

## The freeze (fixed)
The app could hang during **Apply delivery** with no way to close the window. Cause: the
v1.1 "safety snapshot" ran `git stash push -u` then `git stash apply`. On some repo states
that round-trip stalls or waits on input, which parked the main thread with no cancel path.

**Fix:**
- The git-stash snapshot is gone. Backups are now a plain **file copy** of the files a
  delivery will overwrite into `.buildbuddy-backups/<timestamp>/` — it never mutates the
  working tree, so it can't deadlock.
- Every command runs with `GIT_TERMINAL_PROMPT=0`, `GIT_ASKPASS`/`SSH_ASKPASS` disabled and
  SSH `BatchMode=yes`, so **nothing can block waiting on stdin** (the real hang).
- Every command is **cancellable** — a **Cancel** button appears while one runs, and **⌘.**
  also stops it. The child runs in its own process group and is hard-killed if it ignores
  the terminate.
- Every command has a **hard timeout** (configurable in Options, default 120s). On timeout
  it's terminated and reported as `⏱️ timed out`.
- `syncShell` (the quick metadata reads) is timeout-protected too.

## Options window (⌘, or the Options button)
About two dozen settings, grouped:
- **Auto commit & push:** master auto-commit-and-push switch, push-after-commit, default
  commit message (used when a drop has no `COMMIT_MSG.txt`).
- **Downloads auto-detect:** watch toggle, auto-apply-when-auto-commit-on, scan interval.
- **Branch & pull:** default base branch, pull-before-apply, pull-on-select.
- **Confirmations & safety:** preview-before-apply, ask-before-push, block unsafe commit
  messages, confirm before removing a project, command timeout slider.
- **Workflow extras:** backup before apply, open Xcode after apply, deploy Worker after push,
  clear console on action, remember last project.
- **Console & feedback:** verbose logging, monospace font, sound on finish, **dry-run mode**
  (prints what it *would* do, changes nothing).

## Downloads auto-detect
Watches `~/Downloads` and matches a zip to the selected project by **inner top-folder name
OR filename containing the project name** (broadest). When auto-commit is on it **auto-applies**
the match; otherwise it opens the preview. De-duped so the same zip isn't applied twice.

## Auto commit & push
Available two ways: the per-project **Auto-commit** toggle in the header, gated by the global
**Auto commit and push** switch in Options. With both on, applying a delivery (dropped, picked,
or auto-detected from Downloads) commits and pushes in one step using the bundled message.

## Note
This drop replaces the app source, so **relaunch BuildBuddy** after it applies — the launcher
rebuilds from the new source automatically.
