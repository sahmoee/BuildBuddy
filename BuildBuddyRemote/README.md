# BuildBuddy Remote 2.0 — native, multi-transport

Drive BuildBuddy's operations from your iPhone: same Wi-Fi, over Tailscale from
anywhere, via a GitHub relay with no open ports, or by dropping a delivery zip
onto an SMB share. BuildBuddy now starts and supervises the remote itself — a
**Remote** button and a status light live in the app header.

This is a companion to BuildBuddy, not a fork. The agent reads BuildBuddy's own
project list and runs the *same* commands its buttons run, so anything you set up
in the app is instantly drivable from your phone. Your GitHub auth is untouched
(Keychain via `gh auth login`); no tokens for your code, no secrets in transit.

```
  iPhone (web remote or Shortcut)
        │   pick a reach mode ▾
        ├── LAN ─────────── same Wi-Fi, direct
        ├── Tailscale ───── from anywhere, encrypted, no open ports
        ├── Public ──────── router port-forward (OFF by default, gated)
        ├── Relay ───────── via a private GitHub repo, no inbound at all
        └── SMB drop ────── Files app copies a delivery .zip to a Mac share
                ▼
        buddyd (started by BuildBuddy) ──reads──▶ projects.json
                │  /bin/zsh -lc  (same env BuildBuddy uses)
                ▼
        git · xcodebuild · npx wrangler  ─▶  your repos
```

────────────────────────────────────────────────────────────────────────────
## Install
────────────────────────────────────────────────────────────────────────────

### 1. Update BuildBuddy (gets the native Remote panel)
This ships as a normal BuildBuddy delivery. Apply it the usual way:
- **Branch:** `feature/remote-native`
- BuildBuddy → Apply delivery → review diff → Apply + Commit + Push → it rebuilds
  on next launch (or use the launcher). You'll see **v1.8** in the header and a
  **Remote** button in the grid.

### 2. Keep the agent folder beside the app
The `BuildBuddyRemote/agent/` folder must sit next to BuildBuddy (the app looks
for `agent/buddyd.py` next to its own bundle, and stages a copy into Application
Support on first start). If you keep BuildBuddy in `~/Documents/BuildBuddy`, drop
`BuildBuddyRemote/` in there too. Python 3 ships with macOS — nothing to install.

### 3. Turn it on
BuildBuddy header → **Remote** → toggle **On**. The panel shows a QR and one
address per enabled mode. Optionally tick "Start automatically when BuildBuddy
launches."

### 4. Pair the phone
Open `remote/index.html` on the phone (AirDrop it, or keep it in iCloud Drive and
open in Safari). Pick a reach mode at the top, then either:
- **Scan the QR** in the Remote panel with the Camera app and paste the
  `buddyremote://…` string into the address box (it fills host + token), or
- type the address + token shown in the panel.
Tap **Connect**. Add to Home Screen so it opens full-screen like an app. Tap
**Auto** any time to have it try every saved mode and connect to whichever answers.

────────────────────────────────────────────────────────────────────────────
## The reach modes
────────────────────────────────────────────────────────────────────────────

**LAN** — same Wi-Fi, lowest latency. Just works. Also covers "LAN over VPN":
if you're VPN'd or mounted back to your home network, the LAN address is reachable.

**Tailscale** — the recommended way to reach your Mac from anywhere. Install the
free Tailscale app on the Mac and the phone, sign into both. BuildBuddy detects
the `100.x` address automatically and offers it as a mode. Encrypted, and your
router stays closed.

**Public** — a router port-forward to the agent's port. Off by default and gated
behind an explicit "I understand the risk" toggle, because a leaked token becomes
remote code execution on your Mac. Only enable while you need it; rotate the token
after. Most people should use Tailscale instead.

**Relay** — no inbound connection at all: the phone appends a job to a private
GitHub repo and the Mac polls it. Triggers predefined actions only (pull, deploy,
build…), with a few seconds' latency. See `shortcut/RELAY_SETUP.md`.

**SMB drop-folder** — point BuildBuddy at a shared folder (Remote panel → SMB),
share it over SMB (System Settings → General → Sharing → File Sharing). Drop a
Claude delivery `.zip` into it from the iPhone Files app; BuildBuddy applies it
exactly like the Apply button — preview-equivalent overlay of only changed files,
commit via `COMMIT_MSG.txt`, push — then writes a `…​.result.txt` beside it so you
can see the outcome from the phone. This is the clean answer to "apply a delivery
from my phone" that the LAN-only v1 deliberately left out.

────────────────────────────────────────────────────────────────────────────
## What the buttons do (identical to BuildBuddy)
────────────────────────────────────────────────────────────────────────────
Status · Pull latest · Commit & Push · New/Switch/Merge branch · Build (sim) ·
Open in Xcode · Deploy Worker · Doctor. Same command strings, same project list,
same Keychain auth.

**Live "apply delivery" over HTTP is intentionally not a phone button.** Applying
new code should show a per-file diff first, which belongs on the Mac. The SMB
drop-folder is the phone path for that — you can see the result file, and the
commit is driven by the delivery's own `COMMIT_MSG.txt`.

────────────────────────────────────────────────────────────────────────────
## Security
────────────────────────────────────────────────────────────────────────────
- Every HTTP request needs the pairing token (401 without it).
- LAN/Tailscale bind to private networks; Public binding is opt-in and warned.
- The agent never sees your GitHub credentials; pushes use the Mac's Keychain.
- Rotate the token any time from the Remote panel (or delete
  `~/Library/Application Support/BuildBuddy/remote-token.txt` and restart).

────────────────────────────────────────────────────────────────────────────
## Files in this delivery
────────────────────────────────────────────────────────────────────────────
- `BuildBuddy/BuildBuddy.swift` — the app, now v1.8 with the native Remote panel,
  header status light, QR pairing, and agent supervision. (Repo-relative so
  BuildBuddy applies it in place.)
- `BuildBuddyRemote/agent/buddyd.py` — the multi-transport agent (LAN, Tailscale,
  Public, relay poller, SMB watch-folder, apply-delivery).
- `BuildBuddyRemote/agent/Start BuildBuddy Remote.command` — optional manual
  launcher (you normally just use the app's Remote toggle).
- `BuildBuddyRemote/remote/index.html` — the iPhone web remote with the mode
  switcher and QR/pair-URL ingest.
- `BuildBuddyRemote/shortcut/HOW_TO_BUILD_THE_SHORTCUT.md` — optional native
  Shortcut for Action Button / Siri / Back Tap.
- `BuildBuddyRemote/shortcut/RELAY_SETUP.md` — how to wire the no-inbound relay.

────────────────────────────────────────────────────────────────────────────
## Troubleshooting
────────────────────────────────────────────────────────────────────────────
- **"Remote off" won't turn on / "couldn't find buddyd.py"** — keep
  `BuildBuddyRemote/` next to the BuildBuddy app. The app stages a copy on first
  start; if it can't find the script at all, it tells you in the panel.
- **Tailscale mode missing** — make sure Tailscale is running and signed in on the
  Mac; the panel shows "connected ✓" when detected. Toggle the remote Off/On.
- **Mode changes didn't take** — reach-mode, relay, and SMB changes apply after you
  toggle the remote Off then On (or hit Restart in the panel).
- **Can't reach Mac on LAN** — same Wi-Fi? Some routers block device-to-device
  ("AP isolation"); use Tailscale instead.
- **SMB drop didn't apply** — confirm the watch path matches the share, the zip is
  repo-relative, and a project name is set (or there's exactly one project). Check
  the `…​.result.txt` the agent writes beside the zip.
- **Build can't find a scheme** — set the scheme in BuildBuddy's project settings;
  the remote falls back to the project name.
