# BuildBuddy — your one-window dev control panel

A native macOS app (real window, real buttons) that runs the whole
GitHub + Xcode + Cloudflare loop for **all** your projects — Stocked, Atlas, The Sesh,
anything. No more steps to remember; click buttons.

## First launch (one time)
1. Unzip this folder anywhere (e.g. `~/Developer/BuildBuddy/`).
2. Double-click **`Launch BuildBuddy.command`**.
   - It compiles the app into a real `.app` and opens it. (First run takes a few seconds;
     after that it launches instantly and only rebuilds if the source changes.)
   - If macOS says the Swift compiler is missing, it triggers the Command Line Tools
     installer — click Install, wait, then double-click the launcher again.
   - If a folder/Gatekeeper prompt appears for the `.command`, right-click it → Open, once.

## Using it
- **Add a project:** drag its repo folder into the sidebar, or click **+**. It auto-finds the
  git root and any Cloudflare worker folder. Your projects are remembered between launches.
- **Buttons** (per selected project):
  - **Pull latest** — `git pull` the current branch.
  - **Apply delivery** — drop a Claude delivery zip on the console (or use the button). It
    first shows a **preview** (the exact files and commit message) so you can confirm, takes
    an automatic undo snapshot, overlays the files at the correct paths, then commits (using
    the bundled message) and pushes — automatically if Auto-commit is on, otherwise on click.
  - **Commit & Push** — commit your changes and push.
  - **Switch / New / Merge branch** — full branch flow via dialogs.
  - **Open in Xcode** — opens the workspace/project; you press Run.
  - **Deploy Worker** — `npx wrangler deploy` in the project's worker folder.
  - **Doctor** — checks git / swift / gh / node / wrangler / brew and installs the missing
    ones (Homebrew + npm). Also shows your GitHub auth status with a one-click `gh auth login`.
  - **Instructions** — opens the full delivery playbook, now built into the app (no separate
    PDF needed). It travels with BuildBuddy so it's always available.
- **Auto-commit** — a per-project toggle in the header. When ON, applying a delivery commits
  and pushes automatically using the bundled `COMMIT_MSG.txt` (the playbook's Option A).
- **Console** shows every command it runs — nothing hidden — with a ✅/❌ result for each,
  plus Filter / Copy / Save.

## First-time GitHub auth (per machine, once)
The app pushes using your Mac's own git credentials. If you've never authenticated:
open **Doctor → Install missing** to get `gh`, then in Terminal run `gh auth login` once
(browser sign-in, stored in Keychain). After that, push/pull "just works" — no tokens.

## How Claude deliveries work with this
Claude hands you a zip whose folders mirror your repo (e.g. `Stocked/BuildConfig.swift`) plus
a `COMMIT_MSG.txt`. You pick the project, click/drag **Apply delivery**, and it lands the files
in the right place and pushes. Claude will tell you the branch name to make first (New branch)
and that's it.

## If the first build fails
The launcher prints the compiler errors and writes them to `.build/build.log`. Copy them to
Claude and it'll patch `BuildBuddy.swift`. (The app is untested against a live compiler on the
build side, so a small fix or two on first run is expected — that's the only rough edge.)
