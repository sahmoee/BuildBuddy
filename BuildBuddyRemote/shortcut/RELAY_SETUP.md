# Relay setup — trigger builds from anywhere, with no inbound connection

The relay is the "no open ports, no Tailscale, works from any network" option.
It uses a **private GitHub repo you own** as a one-slot job queue. Your phone
appends a job to a file in that repo; the agent on your Mac polls the file and
runs the job. Nothing connects *into* your Mac.

Tradeoffs, honestly: it only runs **predefined actions** (pull, commit_push,
build_sim, deploy_worker, etc.) and has up-to-`relayPollSeconds` latency. It
can't do live round-trips like "show me git status right now." For that, use
LAN or Tailscale. The relay is for fire-and-forget ("pull Stocked", "deploy the
worker") when you're off-network.

────────────────────────────────────────────────────────────────────────────
## One-time setup
────────────────────────────────────────────────────────────────────────────

### 1. Make a private queue repo (once)
On GitHub, create a **private** repo, e.g. `yourname/buildbuddy-queue`. It needs
exactly one file:

`remote-queue.json`
```json
{ "jobs": [] }
```
Commit it. That's the whole repo.

### 2. Point BuildBuddy at it
BuildBuddy → header **Remote** → "Relay via a private GitHub repo" → enter
`yourname/buildbuddy-queue` → toggle the remote Off then On. The Mac reads the
queue with its own `gh` auth (Keychain) — no token travels anywhere.

### 3. Build a phone Shortcut that appends a job
The Shortcut overwrites `remote-queue.json` with the job you want to run, using
the GitHub Contents API. You need a **fine-grained Personal Access Token** scoped
to *only that one repo* with **Contents: Read and write** — nothing else. Store
it in the Shortcut.

Shortcut steps (build one per action, or one that asks):
1. **Text** → your fine-grained PAT.
2. **Text** → the JSON body. To run "pull on Stocked":
   ```
   {"jobs":[{"action":"pull","project":"Stocked"}]}
   ```
   (Base64-encode it in the next step — the API wants base64 content.)
3. **Base64 Encode** the JSON text.
4. **Get Contents of URL**:
   - URL: `https://api.github.com/repos/yourname/buildbuddy-queue/contents/remote-queue.json`
   - Method: **PUT**
   - Headers:
     - `Authorization` = `Bearer ` + your PAT
     - `Accept` = `application/vnd.github+json`
   - Request Body **JSON**:
     - `message` (Text): `job`
     - `content` (Text): the **Base64** from step 3
     - `sha` (Text): the current file's SHA — see note below
5. **Show Notification** → "Queued."

**The `sha` requirement:** GitHub's Contents API needs the existing file's SHA to
overwrite it. Add a first **Get Contents of URL** (GET, same URL, same auth) →
**Get Dictionary Value** `sha` → feed that into the PUT. (A ready-made two-call
Shortcut is fiddly to describe in text but takes ~5 minutes to assemble.)

Within `relayPollSeconds`, the Mac picks up the job and runs it. The agent only
acts on each new SHA once, so the same job won't double-run.

────────────────────────────────────────────────────────────────────────────
## Security notes
────────────────────────────────────────────────────────────────────────────
- The PAT in the Shortcut can write to **only the queue repo** — give it nothing
  else. It cannot touch your code repos or push anything; it just edits one JSON
  file.
- The agent executes only actions in its known list, on projects already in
  BuildBuddy. A malformed or unknown action is ignored.
- Your code pushes still happen with the Mac's Keychain auth, never the PAT.
- If you ever suspect the PAT leaked, delete it on GitHub; the queue repo holds
  no secrets and the worst case is someone queueing a `pull` you didn't ask for.

LAN and Tailscale are simpler and lower-latency — reach for the relay only when
you're on a network where neither works.
