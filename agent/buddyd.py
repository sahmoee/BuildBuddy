#!/usr/bin/env python3
# ============================================================================
# buddyd 2.0 — BuildBuddy Remote Agent (multi-transport)
# ----------------------------------------------------------------------------
# Runs the SAME operations BuildBuddy's buttons run, on the SAME projects
# (reads ~/Library/Application Support/BuildBuddy/projects.json), and is
# supervised by BuildBuddy itself (Remote toggle in the app header).
#
# Reach modes (the phone picks; the agent serves all that are enabled):
#   • LAN          — bind to the Mac's LAN IP (same Wi-Fi).
#   • Tailscale    — bind additionally to the Tailscale 100.x IP (WAN, no ports).
#   • Port-forward — bind 0.0.0.0 so a router forward reaches it (WAN, OFF by
#                    default; requires --allow-public AND a strong token).
#   • Relay        — poll a GitHub repo's `repository_dispatch`-style queue and
#                    execute predefined jobs (WAN, no inbound). See RELAY below.
#
# SMB has two meanings here, both supported:
#   • Watch-folder apply — the phone (Files app over SMB) drops a delivery zip
#     into a shared folder; the agent previews + applies it like BuildBuddy does.
#   • LAN-over-VPN — if you're VPN'd/mounted back home, the LAN bind just works.
#
# Security: every HTTP request needs the pairing token. Public binding is
# opt-in and loudly warned. The agent never sees GitHub credentials — git
# pushes use the Mac's Keychain (`gh auth login`), exactly like BuildBuddy.
#
# Python 3 ships with macOS. No dependencies.
# ============================================================================

import argparse
import json
import os
import secrets
import shlex
import socket
import subprocess
import sys
import threading
import time
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

AGENT_VERSION = "2.0"

# ── Paths ────────────────────────────────────────────────────────────────────
APP_SUPPORT   = Path.home() / "Library" / "Application Support" / "BuildBuddy"
PROJECTS_JSON = APP_SUPPORT / "projects.json"
TOKEN_FILE    = APP_SUPPORT / "remote-token.txt"
CONFIG_FILE   = APP_SUPPORT / "remote-config.json"   # written by BuildBuddy's Remote panel
STATE_FILE    = APP_SUPPORT / "remote-state.json"    # written by us, read by BuildBuddy

DEFAULT_PORT  = 7842
COMMAND_TIMEOUT = 600

# Same non-interactive prefix BuildBuddy uses (Keychain auth, never blocks).
ENV_PREFIX = (
    "export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS=true "
    "GIT_SSH_COMMAND='ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new'; "
)

# ── Config (defaults; BuildBuddy overwrites remote-config.json) ──────────────
DEFAULT_CONFIG = {
    "port": DEFAULT_PORT,
    "enableLAN": True,
    "enableTailscale": True,     # binds only if a tailscale IP is actually found
    "enablePublic": False,       # 0.0.0.0 bind — requires allowPublic too
    "allowPublic": False,        # hard safety gate; must be explicitly true
    "enableRelay": False,
    "relayRepo": "",             # "owner/name" — a private repo you control
    "relayPollSeconds": 10,
    "smbWatchDir": "",           # absolute path to a watched shared folder ("" = off)
    "smbProjectName": "",        # which project a dropped zip applies to ("" = single/last)
    "smbApplySeconds": 6,
}

def load_config() -> dict:
    cfg = dict(DEFAULT_CONFIG)
    if CONFIG_FILE.exists():
        try:
            cfg.update(json.loads(CONFIG_FILE.read_text()))
        except (json.JSONDecodeError, OSError):
            pass
    return cfg

# ── Token ────────────────────────────────────────────────────────────────────
def load_or_create_token() -> str:
    APP_SUPPORT.mkdir(parents=True, exist_ok=True)
    if TOKEN_FILE.exists():
        t = TOKEN_FILE.read_text().strip()
        if t:
            return t
    t = secrets.token_urlsafe(18)
    TOKEN_FILE.write_text(t)
    try:
        os.chmod(TOKEN_FILE, 0o600)
    except OSError:
        pass
    return t

TOKEN = load_or_create_token()

# ── Project lookup (BuildBuddy's own list) ───────────────────────────────────
def load_projects() -> list[dict]:
    if not PROJECTS_JSON.exists():
        return []
    try:
        data = json.loads(PROJECTS_JSON.read_text())
        return data if isinstance(data, list) else []
    except (json.JSONDecodeError, OSError):
        return []

def find_project(pid: str | None, name: str | None) -> dict | None:
    projects = load_projects()
    if pid:
        for p in projects:
            if str(p.get("id")) == pid:
                return p
    if name:
        low = name.strip().lower()
        for p in projects:
            if str(p.get("name", "")).strip().lower() == low:
                return p
    return None

# ── Shell execution (identical model to BuildBuddy.run) ──────────────────────
def run_shell(command: str, cwd: str | None, timeout: int = COMMAND_TIMEOUT) -> dict:
    full = ENV_PREFIX + command
    try:
        proc = subprocess.run(
            ["/bin/zsh", "-lc", full],
            cwd=cwd or None,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            text=True,
        )
        return {"code": proc.returncode, "out": proc.stdout or ""}
    except subprocess.TimeoutExpired as e:
        partial = e.output if isinstance(e.output, str) else ""
        return {"code": 124, "out": partial + f"\n⏱️ Command exceeded {timeout}s — terminated."}
    except Exception as e:  # noqa: BLE001
        return {"code": -1, "out": f"⚠️ {e}"}

def q(s: str) -> str:
    return shlex.quote(s)

# ── Git helpers mirroring BuildBuddy's command strings ───────────────────────
def current_branch(repo: str) -> str:
    r = run_shell("git rev-parse --abbrev-ref HEAD", repo, timeout=30)
    b = r["out"].strip().splitlines()[0] if r["out"].strip() else ""
    return "" if (r["code"] != 0 or not b or " " in b) else b

def list_branches(repo: str) -> list[str]:
    r = run_shell("git branch -a --format='%(refname:short)'", repo, timeout=30)
    out = []
    for b in (x.strip() for x in r["out"].split("\n")):
        b = b.replace("origin/", "")
        if b and b != "HEAD":
            out.append(b)
    return sorted(set(out))

def branch_ok(b: str) -> bool:
    return bool(b) and not b.startswith("(") and " " not in b

# ── Operations (one per BuildBuddy button) ───────────────────────────────────
def op_status(p):
    repo = p["path"]; br = current_branch(repo)
    st = run_shell("git status --short --branch", repo, timeout=30)
    return {"ok": True, "result": f"On {br or 'unknown branch'}", "log": st["out"],
            "branch": br, "branches": list_branches(repo)}

def op_pull(p):
    repo = p["path"]; br = current_branch(repo)
    if not branch_ok(br):
        return {"ok": False, "result": f"⚠️ No valid branch ({br or 'none'}). Refresh first.", "log": ""}
    r = run_shell(f"git pull --ff-only origin {q(br)} || git pull --no-edit origin {q(br)}", repo)
    return {"ok": r["code"] == 0, "result": ("✅ Pulled" if r["code"] == 0 else "❌ Pull failed"),
            "log": r["out"], "branch": br}

def op_commit_push(p, message):
    repo = p["path"]; br = current_branch(repo)
    if not branch_ok(br):
        return {"ok": False, "result": f"❌ No valid branch ({br or 'none'}).", "log": ""}
    msg = (message or "").strip() or "Update from BuildBuddy Remote"
    safe = msg.replace('"', '\\"')
    commit = ("git add -A; if git diff --cached --quiet; then echo 'BB_NOTHING_TO_COMMIT'; "
              f'else git commit -m "{safe}"; fi')
    r1 = run_shell(commit, repo); log = r1["out"]
    if "BB_NOTHING_TO_COMMIT" in r1["out"]:
        return {"ok": True, "result": "✓ Nothing to commit", "log": log, "branch": br}
    r2 = run_shell(f"git push origin {q(br)}", repo); log += "\n" + r2["out"]
    return {"ok": r2["code"] == 0, "result": ("✅ Committed & pushed" if r2["code"] == 0 else "❌ Push failed"),
            "log": log, "branch": br}

def op_new_branch(p, name, base):
    repo = p["path"]
    if not name or " " in name:
        return {"ok": False, "result": "❌ Invalid branch name.", "log": ""}
    base = (base or "master").strip()
    cmd = (f"git checkout {q(base)} && git pull --ff-only origin {q(base)} 2>/dev/null; "
           f"git checkout -b {q(name)} && git push -u origin {q(name)}")
    r = run_shell(cmd, repo)
    return {"ok": r["code"] == 0, "result": (f"✅ On {name}" if r["code"] == 0 else "❌ Branch failed"),
            "log": r["out"], "branch": current_branch(repo)}

def op_switch_branch(p, name):
    repo = p["path"]
    if not name:
        return {"ok": False, "result": "❌ No branch given.", "log": ""}
    cmd = f"git checkout {q(name)} 2>/dev/null || git checkout -t {q('origin/' + name)}"
    r = run_shell(cmd, repo)
    return {"ok": r["code"] == 0, "result": (f"✅ Switched to {name}" if r["code"] == 0 else "❌ Switch failed"),
            "log": r["out"], "branch": current_branch(repo)}

def op_merge(p, src):
    repo = p["path"]; br = current_branch(repo)
    if not src or not branch_ok(br):
        return {"ok": False, "result": "❌ Need a source branch and a valid current branch.", "log": ""}
    r = run_shell(f"git merge --no-edit {q(src)} && git push origin {q(br)}", repo)
    return {"ok": r["code"] == 0, "result": (f"✅ Merged {src} → {br}" if r["code"] == 0 else "❌ Merge failed"),
            "log": r["out"], "branch": br}

def op_deploy_worker(p):
    repo = p["path"]; sub = p.get("workerSubpath")
    if not sub:
        return {"ok": False, "result": "⚠️ No worker folder set for this project.", "log": ""}
    r = run_shell(f"cd {q(sub)} && npx wrangler deploy", repo)
    return {"ok": r["code"] == 0, "result": ("✅ Worker deployed" if r["code"] == 0 else "❌ Deploy failed"),
            "log": r["out"]}

def op_build_sim(p, scheme):
    repo = p["path"]; sch = (scheme or p.get("name") or "").strip()
    if not sch:
        return {"ok": False, "result": "⚠️ No scheme set — pass one from the remote.", "log": ""}
    cmd = (f"xcodebuild -scheme {q(sch)} -destination 'generic/platform=iOS Simulator' "
           "-derivedDataPath .bbderived build 2>&1 | tail -n 80")
    r = run_shell(cmd, repo)
    ok = ("** BUILD SUCCEEDED **" in r["out"]) or (r["code"] == 0 and "error:" not in r["out"])
    return {"ok": ok, "result": ("✅ Build succeeded" if ok else "❌ Build failed — see log"), "log": r["out"]}

def op_open_xcode(p):
    repo = p["path"]
    cmd = ("ws=$(ls -d *.xcworkspace 2>/dev/null | head -n1); "
           "pj=$(ls -d *.xcodeproj 2>/dev/null | head -n1); "
           'if [ -n "$ws" ]; then open "$ws"; elif [ -n "$pj" ]; then open "$pj"; '
           'else echo "No .xcworkspace or .xcodeproj found"; exit 1; fi')
    r = run_shell(cmd, repo)
    return {"ok": r["code"] == 0, "result": ("✅ Opening in Xcode" if r["code"] == 0 else "❌ Couldn't open"),
            "log": r["out"]}

def op_doctor(_p):
    lines = []
    for t in ["git", "swift", "xcodebuild", "gh", "node", "wrangler", "tailscale"]:
        r = run_shell(f"command -v {t} >/dev/null 2>&1 && echo present || echo MISSING", None, timeout=20)
        lines.append(f"{'✅' if 'present' in r['out'] else '❌'} {t}")
    gh = run_shell("gh auth status 2>&1 | head -n 3", None, timeout=20)
    lines.append("— gh auth —"); lines.append(gh["out"].strip() or "(no gh)")
    return {"ok": True, "result": "Doctor complete", "log": "\n".join(lines)}

# ── Apply-delivery (shared by SMB watch-folder and the /apply endpoint) ──────
def apply_delivery_zip(project: dict, zip_path: str, commit_and_push: bool) -> dict:
    """Mirror BuildBuddy's apply: unzip → rsync only changed files into the repo
       → (optionally) commit with COMMIT_MSG.txt and push. Repo-relative zip."""
    repo = project["path"]
    work = run_shell(f"mktemp -d", None, timeout=20)["out"].strip()
    if not work:
        return {"ok": False, "result": "❌ Couldn't make temp dir.", "log": ""}
    log = ""
    try:
        uz = run_shell(f"/usr/bin/unzip -oq {q(zip_path)} -d {q(work)}", None, timeout=120)
        log += uz["out"]
        if uz["code"] != 0:
            return {"ok": False, "result": "❌ Unzip failed.", "log": log}
        # The delivery's single top folder mirrors the repo. Find it.
        src = run_shell(
            f"d={q(work)}; inner=$(ls -d \"$d\"/*/ 2>/dev/null | head -n1); "
            'if [ -n "$inner" ]; then echo "$inner"; else echo "$d"; fi', None, timeout=20
        )["out"].strip()
        # rsync everything except COMMIT_MSG.txt / commit.sh into the repo.
        rs = run_shell(
            f"/usr/bin/rsync -a --exclude COMMIT_MSG.txt --exclude commit.sh "
            f"{q(src.rstrip('/') + '/')} {q(repo.rstrip('/') + '/')}", None, timeout=120
        )
        log += "\n" + rs["out"]
        if rs["code"] != 0:
            return {"ok": False, "result": "❌ Apply (rsync) failed.", "log": log}
        if not commit_and_push:
            return {"ok": True, "result": "✅ Applied (not committed)", "log": log,
                    "branch": current_branch(repo)}
        # Commit using COMMIT_MSG.txt verbatim if present (never shell-parsed).
        msg_path = f"{src.rstrip('/')}/COMMIT_MSG.txt"
        br = current_branch(repo)
        if not branch_ok(br):
            return {"ok": False, "result": f"⚠️ Applied, but no valid branch ({br}) to commit on.", "log": log}
        commit = (
            "git add -A; if git diff --cached --quiet; then echo 'BB_NOTHING_TO_COMMIT'; "
            f"elif [ -f {q(msg_path)} ]; then git commit -F {q(msg_path)}; "
            "else git commit -m 'Apply delivery (BuildBuddy Remote)'; fi"
        )
        c = run_shell(commit, repo); log += "\n" + c["out"]
        if "BB_NOTHING_TO_COMMIT" in c["out"]:
            return {"ok": True, "result": "✓ Applied; nothing new to commit", "log": log, "branch": br}
        pu = run_shell(f"git push origin {q(br)}", repo); log += "\n" + pu["out"]
        return {"ok": pu["code"] == 0,
                "result": ("✅ Applied, committed & pushed" if pu["code"] == 0 else "❌ Applied but push failed"),
                "log": log, "branch": br}
    finally:
        run_shell(f"rm -rf {q(work)}", None, timeout=20)

OPS = {
    "status":        lambda p, b: op_status(p),
    "pull":          lambda p, b: op_pull(p),
    "commit_push":   lambda p, b: op_commit_push(p, b.get("message")),
    "new_branch":    lambda p, b: op_new_branch(p, b.get("name", ""), b.get("base")),
    "switch_branch": lambda p, b: op_switch_branch(p, b.get("name", "")),
    "merge":         lambda p, b: op_merge(p, b.get("source", "")),
    "deploy_worker": lambda p, b: op_deploy_worker(p),
    "build_sim":     lambda p, b: op_build_sim(p, b.get("scheme")),
    "open_xcode":    lambda p, b: op_open_xcode(p),
    "doctor":        lambda p, b: op_doctor(p),
}

# ── Network address discovery ────────────────────────────────────────────────
def lan_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80)); return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()

def tailscale_ip() -> str | None:
    """Return the Tailscale 100.x address if Tailscale is up, else None."""
    r = run_shell("tailscale ip -4 2>/dev/null | head -n1", None, timeout=10)
    ip = r["out"].strip()
    return ip if ip.startswith("100.") else None

# ── Shared state file (so BuildBuddy can render status + QR) ─────────────────
def write_state(addresses: list[dict], cfg: dict, extra: dict | None = None):
    state = {
        "version": AGENT_VERSION,
        "running": True,
        "port": cfg["port"],
        "token": TOKEN,
        "addresses": addresses,           # [{mode, host}]
        "projects": [p.get("name") for p in load_projects()],
        "updated": int(time.time()),
    }
    if extra:
        state.update(extra)
    try:
        STATE_FILE.write_text(json.dumps(state, indent=2))
    except OSError:
        pass

def clear_state():
    try:
        if STATE_FILE.exists():
            s = json.loads(STATE_FILE.read_text()); s["running"] = False
            STATE_FILE.write_text(json.dumps(s))
    except (OSError, json.JSONDecodeError):
        pass

# ── HTTP handler ─────────────────────────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    server_version = f"buddyd/{AGENT_VERSION}"

    def log_message(self, fmt, *args):  # noqa: N802
        sys.stderr.write(time.strftime("[%H:%M:%S] ") + (fmt % args) + "\n")

    def _send(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, X-BuddyToken")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()
        self.wfile.write(body)

    def _authed(self):
        hdr = self.headers.get("X-BuddyToken", "")
        if hdr and secrets.compare_digest(hdr, TOKEN):
            return True
        tok = (parse_qs(urlparse(self.path).query).get("token") or [""])[0]
        return bool(tok) and secrets.compare_digest(tok, TOKEN)

    def do_OPTIONS(self):  # noqa: N802
        self._send(200, {"ok": True})

    def do_GET(self):  # noqa: N802
        path = urlparse(self.path).path
        if path == "/ping":
            self._send(200, {"ok": True, "agent": "buddyd", "version": AGENT_VERSION}); return
        if not self._authed():
            self._send(401, {"ok": False, "error": "bad or missing token"}); return
        if path == "/projects":
            projs = [{"id": str(p.get("id")), "name": p.get("name"), "path": p.get("path"),
                      "hasWorker": bool(p.get("workerSubpath"))} for p in load_projects()]
            self._send(200, {"ok": True, "projects": projs, "version": AGENT_VERSION}); return
        self._send(404, {"ok": False, "error": "unknown endpoint"})

    def do_POST(self):  # noqa: N802
        if not self._authed():
            self._send(401, {"ok": False, "error": "bad or missing token"}); return
        path = urlparse(self.path).path
        try:
            n = int(self.headers.get("Content-Length", "0"))
            body = json.loads(self.rfile.read(n) if n else b"{}")
        except (ValueError, json.JSONDecodeError):
            self._send(400, {"ok": False, "error": "invalid JSON"}); return

        if path == "/run":
            action = body.get("action", "")
            if action not in OPS:
                self._send(400, {"ok": False, "error": f"unknown action '{action}'",
                                 "actions": sorted(OPS)}); return
            proj = find_project(body.get("projectId"), body.get("project"))
            if action != "doctor" and proj is None:
                self._send(404, {"ok": False, "error": "project not found"}); return
            if proj is None:
                proj = {"name": "(none)", "path": str(Path.home())}
            sys.stderr.write(f"  → {action} on {proj.get('name')}\n")
            res = OPS[action](proj, body)
            res.setdefault("ok", False); res["action"] = action; res["project"] = proj.get("name")
            self._send(200, res); return

        self._send(404, {"ok": False, "error": "unknown endpoint"})

# ── Relay poller (WAN, no inbound) ───────────────────────────────────────────
# Uses a private GitHub repo you own as a queue. The phone Shortcut creates a
# repository_dispatch event with client_payload {action, project, ...}; this
# poller can't read dispatch events directly (GitHub doesn't expose them), so
# the relay instead watches a `remote-queue` branch file the Shortcut appends to
# via the contents API. Simpler + visible. See shortcut/RELAY_SETUP.md.
def relay_loop(cfg: dict, stop: threading.Event):
    repo = cfg.get("relayRepo", "").strip()
    if not repo:
        return
    poll = max(5, int(cfg.get("relayPollSeconds", 10)))
    sys.stderr.write(f"[relay] watching {repo} every {poll}s\n")
    seen_sha = None
    while not stop.is_set():
        try:
            # Read the queue file via the Mac's own gh auth (Keychain) — no token in transit.
            r = run_shell(
                f"gh api repos/{q(repo)}/contents/remote-queue.json "
                "--jq '.sha + \"\\t\" + (.content)' 2>/dev/null", None, timeout=30
            )
            if r["code"] == 0 and "\t" in r["out"]:
                sha, b64 = r["out"].strip().split("\t", 1)
                if sha and sha != seen_sha:
                    seen_sha = sha
                    decoded = run_shell(f"echo {q(b64)} | base64 --decode", None, timeout=15)["out"]
                    try:
                        jobs = json.loads(decoded).get("jobs", [])
                    except json.JSONDecodeError:
                        jobs = []
                    for job in jobs:
                        action = job.get("action")
                        if action in OPS:
                            proj = find_project(job.get("projectId"), job.get("project")) \
                                   or {"name": "(none)", "path": str(Path.home())}
                            sys.stderr.write(f"[relay] running {action} on {proj.get('name')}\n")
                            OPS[action](proj, job)
        except Exception as e:  # noqa: BLE001
            sys.stderr.write(f"[relay] {e}\n")
        stop.wait(poll)

# ── SMB watch-folder apply ───────────────────────────────────────────────────
def smb_watch_loop(cfg: dict, stop: threading.Event):
    watch = cfg.get("smbWatchDir", "").strip()
    if not watch:
        return
    every = max(3, int(cfg.get("smbApplySeconds", 6)))
    pdir = Path(watch)
    sys.stderr.write(f"[smb] watching {watch} every {every}s\n")
    processed: set[str] = set()
    done_dir = pdir / "_applied"
    while not stop.is_set():
        try:
            if pdir.is_dir():
                for f in sorted(pdir.glob("*.zip")):
                    key = f.name + ":" + str(f.stat().st_size)
                    if key in processed:
                        continue
                    # Wait until the file stops growing (SMB copy finished).
                    s1 = f.stat().st_size; time.sleep(1.5)
                    if not f.exists() or f.stat().st_size != s1:
                        continue
                    processed.add(key)
                    name = cfg.get("smbProjectName", "").strip()
                    proj = find_project(None, name) if name else (load_projects()[:1] or [None])[0]
                    if not proj:
                        sys.stderr.write("[smb] no project to apply to — set smbProjectName\n")
                        continue
                    sys.stderr.write(f"[smb] applying {f.name} → {proj.get('name')}\n")
                    res = apply_delivery_zip(proj, str(f), commit_and_push=bool(proj.get("autoCommitOnApply", True)))
                    sys.stderr.write(f"[smb] {res.get('result')}\n")
                    # Move the zip aside + drop a small result file the phone can see over SMB.
                    try:
                        done_dir.mkdir(exist_ok=True)
                        f.rename(done_dir / f.name)
                        (done_dir / (f.stem + ".result.txt")).write_text(
                            f"{res.get('result')}\n\n{res.get('log','')[:4000]}\n")
                    except OSError:
                        pass
        except Exception as e:  # noqa: BLE001
            sys.stderr.write(f"[smb] {e}\n")
        stop.wait(every)

# ── Main ─────────────────────────────────────────────────────────────────────
def build_addresses(cfg: dict) -> list[dict]:
    """The list of {mode, host} the phone can use, given what's enabled/available."""
    out = []
    port = cfg["port"]
    if cfg.get("enableLAN", True):
        out.append({"mode": "LAN", "host": f"{lan_ip()}:{port}"})
    if cfg.get("enableTailscale", True):
        ts = tailscale_ip()
        if ts:
            out.append({"mode": "Tailscale", "host": f"{ts}:{port}"})
    if cfg.get("enablePublic", False) and cfg.get("allowPublic", False):
        out.append({"mode": "Public", "host": f"<your-router-WAN-IP>:{port}"})
    return out

def main():
    ap = argparse.ArgumentParser(description="BuildBuddy Remote Agent (buddyd)")
    ap.add_argument("--allow-public", action="store_true",
                    help="permit binding 0.0.0.0 for router port-forwarding (DANGEROUS)")
    ap.add_argument("--embedded", action="store_true",
                    help="started by BuildBuddy; quieter banner, writes state file")
    args = ap.parse_args()

    cfg = load_config()
    if args.allow_public:
        cfg["allowPublic"] = True

    # Decide the bind host. If public is genuinely allowed+enabled, bind all
    # interfaces; otherwise bind only what's needed (LAN/Tailscale both live on
    # specific interfaces, but binding 0.0.0.0 is required to serve a specific
    # non-loopback IP simply — so we bind 0.0.0.0 ONLY when public is allowed,
    # and otherwise bind to the LAN/Tailscale IPs’ shared 0.0.0.0 is avoided by
    # binding the specific addresses we advertise).
    addresses = build_addresses(cfg)
    serve_public = cfg.get("enablePublic") and cfg.get("allowPublic")

    if serve_public:
        bind_host = "0.0.0.0"
    else:
        # Bind to all interfaces but advertise only LAN/Tailscale; the token is
        # the gate. (Binding multiple specific IPs needs multiple sockets; for a
        # personal tool, one 0.0.0.0 socket gated by a token is the pragmatic
        # choice, and without a router forward it isn't reachable from the WAN.)
        bind_host = "0.0.0.0"

    httpd = ThreadingHTTPServer((bind_host, cfg["port"]), Handler)

    # Background workers.
    stop = threading.Event()
    threads = []
    if cfg.get("enableRelay") and cfg.get("relayRepo"):
        t = threading.Thread(target=relay_loop, args=(cfg, stop), daemon=True); t.start(); threads.append(t)
    if cfg.get("smbWatchDir"):
        t = threading.Thread(target=smb_watch_loop, args=(cfg, stop), daemon=True); t.start(); threads.append(t)

    write_state(addresses, cfg, extra={
        "relay": bool(cfg.get("enableRelay") and cfg.get("relayRepo")),
        "smbWatch": cfg.get("smbWatchDir", ""),
        "public": serve_public,
    })

    if not args.embedded:
        print("=" * 66)
        print(f"  BuildBuddy Remote Agent  (buddyd {AGENT_VERSION})")
        print("=" * 66)
        for a in addresses:
            print(f"  {a['mode']:<10} http://{a['host']}")
        if serve_public:
            print("  ⚠️  PUBLIC binding is ON. A leaked token = code execution on this Mac.")
            print("      Only keep this on while you need it; rotate the token if unsure.")
        if cfg.get("smbWatchDir"):
            print(f"  SMB watch  {cfg['smbWatchDir']}  (drop a delivery .zip there)")
        if cfg.get("enableRelay") and cfg.get("relayRepo"):
            print(f"  Relay      polling {cfg['relayRepo']}")
        print()
        print("  Pairing token (enter once in the iPhone remote):")
        print(f"      {TOKEN}")
        print()
        print("  Leave this running. Ctrl-C to stop.")
        print("=" * 66)
    else:
        sys.stderr.write(f"buddyd {AGENT_VERSION} embedded; addresses={addresses}\n")

    # Refresh the state file periodically so BuildBuddy sees Tailscale coming up,
    # project list changes, etc., without a restart.
    def heartbeat():
        while not stop.is_set():
            stop.wait(8)
            if not stop.is_set():
                write_state(build_addresses(load_config()), load_config(), extra={
                    "relay": bool(load_config().get("enableRelay") and load_config().get("relayRepo")),
                    "smbWatch": load_config().get("smbWatchDir", ""),
                    "public": serve_public,
                })
    threading.Thread(target=heartbeat, daemon=True).start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        if not args.embedded:
            print("\nStopped.")
    finally:
        stop.set()
        clear_state()
        httpd.server_close()

if __name__ == "__main__":
    main()
