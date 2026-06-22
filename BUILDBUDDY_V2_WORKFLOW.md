# BuildBuddy v2 — Workflow & Delivery Spec (paste into any new chat)

Give this whole file to Claude at the start of a chat so deliveries are v2-compatible.
BuildBuddy v2 is a native macOS app that manages the GitHub + Xcode + Cloudflare loop for
multiple projects (Stocked, Atlas, The Sesh) with buttons. The human applies Claude's deliveries
through it; the human's Mac does all git pushes (Keychain auth). Claude never pushes and never
takes a token.

═══════════════════════════════════════════════════════════════════════════════
## TL;DR FOR CLAUDE — the delivery contract (follow exactly)
═══════════════════════════════════════════════════════════════════════════════

Every change ships as ONE zip with this shape:

```
<project>_delivery/                  ← single top folder
├─ <ProjectName>/Foo.swift           ← files at their REAL repo-relative paths
├─ <OtherTarget>/Bar.swift           ← e.g. StockedWidgets/…, StockedShareExtension/…
├─ _worker/<worker>/index.js         ← worker files, if changed
└─ COMMIT_MSG.txt                    ← commit message, at the delivery root
```

Hard rules:
1. **Repo-relative paths, never flat.** The folder mirrors the repo so BuildBuddy's rsync lands
   each file where it belongs. (This is what killed the old "missed a file" build breaks.)
2. **Only real repo files + COMMIT_MSG.txt inside the folder.** NO READMEs, NO apply-notes, NO
   instruction files inside the applied tree — they get committed as junk. Put all instructions
   in the CHAT.
3. **COMMIT_MSG.txt** sits at the delivery root and contains the commit message (BuildBuddy reads
   it automatically and offers it at the diff-confirm step). rsync excludes it from the copy.
4. **Test files go in a SEPARATE target path** (e.g. `<Project>Tests/…`), NOT in the app source
   folder — otherwise they compile into the app target and fail on `import XCTest`.
5. **Default branch is `master`.** Branch from master, merge back into master.
6. **One change = one branch.** State the branch name.
7. **Never push. Never accept a pasted GitHub token** — if one is pasted, tell the human to
   revoke it; the Mac authenticates once via `gh auth login` (Keychain).
8. **End EVERY delivery** with: the download, the branch name, and the exact BuildBuddy steps
   (see the standard block at the bottom).

Swift correctness (Claude can't compile in-container):
- Brace/paren/bracket balance-check every Swift file before zipping
  (`count('{')==count('}')` etc.; raw-string `#"…"#` pairs must match too).
- Bump the build: `BuildConfig.swift` fallbackBuildNumber + fallbackVersion (format `07.X`).
- `AppChangelog.swift`: exactly one `isLatest: true` (newest), flip the previous to false.
- Flag any Xcode-side steps that a file can't do (adding a file to a target, new targets,
  entitlements, App Store Connect products, privacy-manifest target membership).

═══════════════════════════════════════════════════════════════════════════════
## WHAT BUILDBUDDY v2 DOES (so Claude knows what the human can click)
═══════════════════════════════════════════════════════════════════════════════

Per selected project, buttons:
- **Pull latest** — git pull (guards uncommitted changes → offers stash).
- **Apply delivery** — pick/drag a zip → shows a DIFF of every file → confirm →
  "Apply only" or "Apply + Commit + Push" (uses COMMIT_MSG.txt). Auto-detects new zips in
  ~/Downloads and offers a banner.
- **Build (sim)** — xcodebuild to the project's simulator; errors are parsed into an Errors
  panel with **Copy all** (paste to Claude).
- **Open in Xcode** — opens the workspace/project; human presses Run for device builds.
- **Commit & Push**, **Switch branch**, **New branch**, **Merge branch** — full git flow.
- **Deploy Worker** — runs the project's worker deploy command.
- **Open PR / Repo on GitHub** — jumps to the PR link after a push, or the repo page.
- **Doctor** — checks/installs git, swift, xcodebuild, gh, node, wrangler, xcbeautify, brew.
- Gear icon → **Project settings**: default branch, Xcode scheme, simulator, worker command.
- Console: timestamped sections with green/red exit badges; logs saved to disk.

═══════════════════════════════════════════════════════════════════════════════
## ONE-TIME SETUP (human, per Mac / per project)
═══════════════════════════════════════════════════════════════════════════════

A. Install BuildBuddy v2: unzip anywhere → double-click `Launch BuildBuddy.command`
   (compiles the app, opens it). If it builds but doesn't open:
   `open ~/Desktop/BuildBuddy/.build/BuildBuddy.app`. If compile fails, the launcher prints
   errors + writes `.build/build.log` → send to Claude.
B. Tools: Doctor → Install missing (Homebrew guided, then gh / node / xcbeautify).
C. GitHub auth (replaces tokens): `gh auth login` → GitHub.com → HTTPS → browser. Keychain.
D. Create the repo (if none) from the project root (folder with the .xcodeproj), AFTER adding a
   `.gitignore` (template below):
     git init && git add . && git commit -m "Initial commit"
     gh repo create <RepoName> --private --source=. --remote=origin --push
   Verify on GitHub that `Secrets.xcconfig` and key files are ABSENT (gitignored).
E. Add the project to BuildBuddy: drag its repo folder into the sidebar (or +). Then open the
   gear and set the Xcode **scheme** and **simulator** so Build (sim) works.

Converting an existing project: do A–C if needed, add `.gitignore`, run D + E, then tell Claude
"this project uses BuildBuddy v2 — deliver repo-relative with COMMIT_MSG.txt and a branch name."

═══════════════════════════════════════════════════════════════════════════════
## .gitignore TEMPLATE (root, before first push)
═══════════════════════════════════════════════════════════════════════════════
```
# Secrets — NEVER commit
Secrets.xcconfig
*.secret.xcconfig
.env
.env.*
.dev.vars
*.p8
*.p12
*.cer
*.mobileprovision
# Cloudflare worker local state (secrets live in Cloudflare)
_worker/**/.wrangler/
# Xcode
build/
DerivedData/
.bbderived/
*.xcuserstate
xcuserdata/
*.xcscmblueprint
*.xccheckout
*.moved-aside
*.hmap
*.ipa
*.dSYM
# SwiftPM
.build/
.swiftpm/
# Node
node_modules/
# macOS
.DS_Store
```
(`.bbderived/` is BuildBuddy's xcodebuild output folder — keep it out of git.)

═══════════════════════════════════════════════════════════════════════════════
## STANDARD CLOSING BLOCK — Claude pastes this (filled in) at the end of EVERY delivery
═══════════════════════════════════════════════════════════════════════════════

> **Branch:** `feature/<name>`
>
> **BuildBuddy:**
> 1. Select <Project> in the sidebar.
> 2. **New branch** → `feature/<name>` (base: master).   *(or: use existing branch X)*
> 3. **Apply delivery** → drop the zip → review the diff → **Apply + Commit + Push**.
> 4. **Build (sim)** (or **Open in Xcode** → Run) to confirm it builds.
> 5. Builds clean? **Merge branch** → `feature/<name>` → master.
> 6. *(if worker changed)* **Deploy Worker**.
> 7. *(if Xcode-side steps)* list them explicitly — add file to target, new target,
>    entitlement, App Store Connect product, etc.

Skip/annotate any step that doesn't apply (worker-only change skips Xcode; a tiny fix may say
"use existing branch / commit straight to master").

═══════════════════════════════════════════════════════════════════════════════
## SECURITY (non-negotiable)
═══════════════════════════════════════════════════════════════════════════════
- No GitHub tokens in chat — ever. `gh auth login` (Keychain) only.
- Secrets never in git: API keys in `Secrets.xcconfig` (gitignored); worker secrets via
  `wrangler secret put` (Cloudflare), not files.

═══════════════════════════════════════════════════════════════════════════════
## TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════════
- Launcher says "Built" then a bash error: app compiled; just open it
  (`open ~/Desktop/BuildBuddy/.build/BuildBuddy.app`).
- First compile fails: paste `.build/build.log` to Claude.
- Apply put files in the wrong place: the zip wasn't repo-relative — ask Claude to re-cut.
- "No change" on a delivered file: on-disk copy was already identical; the build confirms
  correctness, not the diff.
- Build (sim) can't find a scheme: set it in the gear → Project settings.
- Push auth error: re-run `gh auth login`.
- Can't see `.build`/app in Finder: it's hidden — press ⌘⇧. to reveal.

═══════════════════════════════════════════════════════════════════════════════
## QUICK PRIMER (shortest paste for a new chat)
═══════════════════════════════════════════════════════════════════════════════
> I use BuildBuddy v2. Deliver every change as ONE zip whose top folder mirrors my repo layout
> (e.g. `Stocked/BuildConfig.swift`, `StockedTests/Foo.swift`) plus a top-level `COMMIT_MSG.txt`,
> and NOTHING else inside that folder (no READMEs — put instructions in chat). Test files go in a
> separate `<Project>Tests/` path, not the app folder. Default branch is `master`. Don't push and
> don't take a token — I apply via BuildBuddy (Keychain auth). Brace-check every Swift file, bump
> BuildConfig + add one `isLatest:true` AppChangelog entry (version 07.X), and flag any Xcode-side
> steps. END every delivery with the branch name and the exact BuildBuddy button order
> (Select project → New branch → Apply delivery [review diff → Apply+Commit+Push] → Build (sim)
> or Open in Xcode → Merge), skipping steps that don't apply.
