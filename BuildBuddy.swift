// BuildBuddy.swift — a native macOS control panel for your Xcode + GitHub + Cloudflare
// workflow across multiple projects (Stocked, Atlas, The Sesh, …).
//
// It is a single-file SwiftUI app, compiled into a real .app by "Launch BuildBuddy.command".
// Nothing here is project-specific: you add projects by dropping a folder or picking one.
//
// What it does, all via buttons:
//   • Add projects (drag a repo folder in, or use the picker). Stored across launches.
//   • Pull, Commit & Push, Switch / New / Merge branch — the whole git loop.
//   • Apply a Claude delivery zip (drag it in or pick it) → overlays files at the correct
//     paths, then commits (using the bundled COMMIT_MSG.txt) and pushes.
//   • Open in Xcode.
//   • Deploy the Cloudflare Worker (if the project has one).
//   • Doctor: checks git / gh / node / wrangler / swift and installs the missing ones.
// Every command it runs is printed to the console pane, so nothing is hidden.
//
// ── v1.1 improvements (see IMPROVEMENTS.md) ──────────────────────────────────
// ── v1.2 changes ─────────────────────────────────────────────────────────────
//  • FREEZE FIX: every shell command is now cancellable (⌘. or the Cancel button),
//    runs with interactive git/ssh prompts disabled so nothing can block on stdin,
//    and is killed after a configurable hard timeout. The old git-stash "snapshot"
//    that caused the hang is replaced by a safe file-copy backup.
//  • OPTIONS: a full Options/Settings window (⌘,) with ~24 settings, including a
//    global "auto commit and push" switch and a default commit message.
//  • DOWNLOADS AUTO-DETECT: watches ~/Downloads and matches a delivery zip to the
//    selected project by inner top-folder name OR filename; auto-applies when
//    auto-commit is on (otherwise opens the preview).
//
// ── v1.1 improvements (see IMPROVEMENTS.md) ──────────────────────────────────
//  1. Auto-commit on apply (with a per-project toggle) — Option A from the playbook.
//  2. Built-in delivery instructions (no loose PDF needed) — "Instructions" button.
//  3. Commit-message safety check baked in (Section 3 of the playbook) with a preview
//     sheet before anything is committed/pushed.
//  4. Dry-run preview of a delivery zip before it touches your repo.
//  5. Safe file-copy backup before applying a delivery (undo point) — see v1.2 note.
//  6. Per-command exit-code reporting + a clear ✅/❌ result line (no silent failures).
//  7. Console search, copy-all, and save-to-file.
//  8. GitHub auth status surfaced in Doctor (gh auth status) + one-click `gh auth login`.
//  9. Keyboard shortcuts for every primary action, and a persisted window-restoring guide.
// 10. Safer shell quoting helper used everywhere, plus a "Reveal in Finder" and worker-path
//     editor so misdetected worker folders can be fixed without re-adding the project.
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers

// MARK: - Version & Changelog
//
// BuildBuddyVersion is the single source of truth for "what's running". Bump it every release
// and add a matching entry at the TOP of BuildBuddyChangelog. The What's New sheet shows this,
// and the app pops it automatically the first time a new version runs.

let BuildBuddyVersion = "1.9"

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let highlights: [String]
}

let BuildBuddyChangelog: [ChangelogEntry] = [
    ChangelogEntry(version: "1.9", date: "2026-06-24", highlights: [
        "Much faster: git commands no longer launch a login shell (which re-read your full shell profile every time). Project status now reads in a single batched command and is cached, so selecting a project paints instantly.",
        "10 reliability improvements: a 'Refresh all' that updates every project at once, ahead/behind vs origin in the header, a Fetch button, stash/unstash, discard-changes, copy-current-SHA, open-on-GitHub, a busy indicator per action, safer concurrent-action guarding, and a one-click 'grant folder access' helper.",
        "10 new features: a project search box, a multi-project dashboard, a built-in diff viewer for pending changes, recent-commits history, a command palette, a favorites/pinned list, per-project notes, a global 'commit all dirty repos', a quick branch switcher menu, and a menu-bar quick actions extra.",
    ]),
    ChangelogEntry(version: "1.8", date: "2026-06-23", highlights: [
        "iPhone Remote, built in: a Remote button and a status light in the header start a small on-device agent so your phone can run Pull, Commit & Push, branch, Build (sim), Open in Xcode, Deploy Worker, and Doctor — on the same projects, with one-scan QR pairing.",
        "Reach your Mac three ways, your choice: same Wi-Fi (LAN), Tailscale (from anywhere, no open ports), or a private GitHub relay (no inbound). A public port-forward option exists but ships off behind an explicit risk acknowledgement.",
        "SMB drop-folder: point BuildBuddy at a shared folder, drop a delivery .zip into it from the iPhone Files app, and BuildBuddy applies it exactly like the Apply button — then writes a result file beside it.",
    ]),
    ChangelogEntry(version: "1.7", date: "2026-06-22", highlights: [
        "Deliveries are no longer re-applied: BuildBuddy now compares each file in a drop against your repo and applies only the new or changed ones, skipping identical files.",
        "If a delivery is already fully applied, it's detected and skipped instead of producing a confusing empty commit.",
        "The preview now labels each file NEW, CHG (changed), or unchanged, and the Apply button shows how many files will actually change.",
    ]),
    ChangelogEntry(version: "1.6", date: "2026-06-22", highlights: [
        "Self-update: a Check for Updates button pulls the latest BuildBuddy from GitHub and relaunches so it rebuilds — no more applying a drop to update the app itself.",
        "Visible version number in the header and in Doctor, so you can always tell what is running.",
        "What's New screen backed by a changelog that ships in the repo; it pops automatically after an update.",
    ]),
    ChangelogEntry(version: "1.5", date: "2026-06-22", highlights: [
        "Fixed the empty preview box so deliveries actually apply: the preview sheet is now bound directly to its data, removing a SwiftUI state race that left the sheet blank with no Apply button.",
    ]),
    ChangelogEntry(version: "1.4", date: "2026-06-22", highlights: [
        "Apply delivery and Add project now use the native open panel (the SwiftUI importer rendered blank in this unsigned app).",
        "A commit on an already-clean tree no longer reports a confusing failure; it says nothing to commit instead.",
        "The branch reader ignores permission and fatal messages so a folder error can no longer become the branch name.",
    ]),
    ChangelogEntry(version: "1.3", date: "2026-06-22", highlights: [
        "Fixed a freeze when applying large deliveries: command output is now buffered and flushed a few times per second instead of once per line, the console is capped, and the preview unzip runs quietly.",
    ]),
    ChangelogEntry(version: "1.2", date: "2026-06-22", highlights: [
        "Added an Options window (about two dozen settings) including a global auto commit and push switch and a default commit message.",
        "Downloads auto-detect: watches the Downloads folder and matches a delivery zip to the selected project.",
        "Replaced the fragile git-stash snapshot with a safe file-copy backup; added a command timeout and Cancel.",
    ]),
    ChangelogEntry(version: "1.1", date: "2026-06-21", highlights: [
        "Auto-commit on apply, built-in delivery instructions, commit-message safety check, delivery preview, exit-code reporting, console search/copy/save, GitHub auth status in Doctor, keyboard shortcuts.",
    ]),
    ChangelogEntry(version: "1.0", date: "2026-06-21", highlights: [
        "Initial BuildBuddy: per-project git loop (pull, commit and push, branch flows), apply Claude delivery zips, open in Xcode, deploy Cloudflare worker, Doctor dependency checks.",
    ]),
]

// MARK: - Settings (Options menu, persisted to UserDefaults)
//
// Every option here is exposed in the Options window. They are intentionally plain
// values so the whole thing round-trips through @AppStorage with no custom coding.

struct AppSettings {
    // — Auto commit & push —
    var autoCommitAndPush: Bool          // global master switch for commit+push on apply
    var defaultCommitMessage: String     // used when a drop has no COMMIT_MSG.txt
    var pushAfterCommit: Bool            // if false, commit only (no push)

    // — Downloads auto-detect —
    var watchDownloads: Bool             // scan ~/Downloads for matching delivery zips
    var autoApplyFound: Bool             // when auto-commit is on, apply a match automatically
    var downloadsScanSeconds: Double     // poll interval

    // — Branch / pull —
    var defaultBranch: String            // fallback base for New branch
    var autoPullBeforeApply: Bool        // pull latest before overlaying a delivery
    var autoPullOnSelect: Bool           // pull when a project is selected

    // — Confirmations & safety —
    var confirmBeforeApply: Bool         // show the preview sheet (off = apply immediately)
    var confirmBeforePush: Bool          // ask before any push
    var commandTimeoutSeconds: Double    // hard timeout so nothing can hang the UI
    var blockUnsafeCommitMessages: Bool  // enforce the playbook commit-message rule

    // — 10 more options —
    var backupBeforeApply: Bool          // copy changed files to a backup folder first
    var openXcodeAfterApply: Bool        // open Xcode once a delivery lands
    var deployWorkerAfterPush: Bool      // run wrangler deploy after a successful push
    var clearConsoleOnAction: Bool       // wipe console at the start of each action
    var verboseLogging: Bool             // echo full commands and extra detail
    var monospaceConsole: Bool           // console font style
    var soundOnFinish: Bool              // play a system sound on success/failure
    var confirmBeforeRemoveProject: Bool // guard the minus button
    var rememberLastProject: Bool        // reselect last project on launch
    var dryRunMode: Bool                 // print what WOULD happen, never write/commit/push

    static let `default` = AppSettings(
        autoCommitAndPush: true,
        defaultCommitMessage: "BuildBuddy delivery applied",
        pushAfterCommit: true,
        watchDownloads: true,
        autoApplyFound: true,
        downloadsScanSeconds: 8,
        defaultBranch: "main",
        autoPullBeforeApply: false,
        autoPullOnSelect: false,
        confirmBeforeApply: true,
        confirmBeforePush: false,
        commandTimeoutSeconds: 120,
        blockUnsafeCommitMessages: true,
        backupBeforeApply: true,
        openXcodeAfterApply: false,
        deployWorkerAfterPush: false,
        clearConsoleOnAction: false,
        verboseLogging: true,
        monospaceConsole: true,
        soundOnFinish: false,
        confirmBeforeRemoveProject: true,
        rememberLastProject: true,
        dryRunMode: false
    )
}

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("autoCommitAndPush")        var autoCommitAndPush = AppSettings.default.autoCommitAndPush
    @AppStorage("defaultCommitMessage")     var defaultCommitMessage = AppSettings.default.defaultCommitMessage
    @AppStorage("pushAfterCommit")          var pushAfterCommit = AppSettings.default.pushAfterCommit

    @AppStorage("watchDownloads")           var watchDownloads = AppSettings.default.watchDownloads
    @AppStorage("autoApplyFound")           var autoApplyFound = AppSettings.default.autoApplyFound
    @AppStorage("downloadsScanSeconds")     var downloadsScanSeconds = AppSettings.default.downloadsScanSeconds

    @AppStorage("defaultBranch")            var defaultBranch = AppSettings.default.defaultBranch
    @AppStorage("autoPullBeforeApply")      var autoPullBeforeApply = AppSettings.default.autoPullBeforeApply
    @AppStorage("autoPullOnSelect")         var autoPullOnSelect = AppSettings.default.autoPullOnSelect

    @AppStorage("confirmBeforeApply")       var confirmBeforeApply = AppSettings.default.confirmBeforeApply
    @AppStorage("confirmBeforePush")        var confirmBeforePush = AppSettings.default.confirmBeforePush
    @AppStorage("commandTimeoutSeconds")    var commandTimeoutSeconds = AppSettings.default.commandTimeoutSeconds
    @AppStorage("blockUnsafeCommitMessages") var blockUnsafeCommitMessages = AppSettings.default.blockUnsafeCommitMessages

    @AppStorage("backupBeforeApply")        var backupBeforeApply = AppSettings.default.backupBeforeApply
    @AppStorage("openXcodeAfterApply")      var openXcodeAfterApply = AppSettings.default.openXcodeAfterApply
    @AppStorage("deployWorkerAfterPush")    var deployWorkerAfterPush = AppSettings.default.deployWorkerAfterPush
    @AppStorage("clearConsoleOnAction")     var clearConsoleOnAction = AppSettings.default.clearConsoleOnAction
    @AppStorage("verboseLogging")           var verboseLogging = AppSettings.default.verboseLogging
    @AppStorage("monospaceConsole")         var monospaceConsole = AppSettings.default.monospaceConsole
    @AppStorage("soundOnFinish")            var soundOnFinish = AppSettings.default.soundOnFinish
    @AppStorage("confirmBeforeRemoveProject") var confirmBeforeRemoveProject = AppSettings.default.confirmBeforeRemoveProject
    @AppStorage("rememberLastProject")      var rememberLastProject = AppSettings.default.rememberLastProject
    @AppStorage("dryRunMode")               var dryRunMode = AppSettings.default.dryRunMode

    func resetToDefaults() {
        let d = AppSettings.default
        autoCommitAndPush = d.autoCommitAndPush; defaultCommitMessage = d.defaultCommitMessage
        pushAfterCommit = d.pushAfterCommit; watchDownloads = d.watchDownloads
        autoApplyFound = d.autoApplyFound; downloadsScanSeconds = d.downloadsScanSeconds
        defaultBranch = d.defaultBranch; autoPullBeforeApply = d.autoPullBeforeApply
        autoPullOnSelect = d.autoPullOnSelect; confirmBeforeApply = d.confirmBeforeApply
        confirmBeforePush = d.confirmBeforePush; commandTimeoutSeconds = d.commandTimeoutSeconds
        blockUnsafeCommitMessages = d.blockUnsafeCommitMessages; backupBeforeApply = d.backupBeforeApply
        openXcodeAfterApply = d.openXcodeAfterApply; deployWorkerAfterPush = d.deployWorkerAfterPush
        clearConsoleOnAction = d.clearConsoleOnAction; verboseLogging = d.verboseLogging
        monospaceConsole = d.monospaceConsole; soundOnFinish = d.soundOnFinish
        confirmBeforeRemoveProject = d.confirmBeforeRemoveProject; rememberLastProject = d.rememberLastProject
        dryRunMode = d.dryRunMode
    }
}

// MARK: - Model

struct Project: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var path: String            // absolute repo root
    var workerSubpath: String?  // optional relative path to a wrangler dir, e.g. "_worker/x"
    var autoCommitOnApply: Bool = true   // improvement #1 — per-project toggle
    var url: URL { URL(fileURLWithPath: path) }

    init(id: UUID = UUID(), name: String, path: String, workerSubpath: String? = nil, autoCommitOnApply: Bool = true) {
        self.id = id; self.name = name; self.path = path
        self.workerSubpath = workerSubpath; self.autoCommitOnApply = autoCommitOnApply
    }

    // Custom decoding so older projects.json files (saved before autoCommitOnApply existed)
    // still load instead of silently wiping the saved project list on upgrade.
    enum CodingKeys: String, CodingKey { case id, name, path, workerSubpath, autoCommitOnApply }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        path = try c.decode(String.self, forKey: .path)
        workerSubpath = try c.decodeIfPresent(String.self, forKey: .workerSubpath)
        autoCommitOnApply = try c.decodeIfPresent(Bool.self, forKey: .autoCommitOnApply) ?? true
    }
}

// MARK: - Persistence

enum Persist {
    static var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("BuildBuddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    static var file: URL { dir.appendingPathComponent("projects.json") }

    static func load() -> [Project] {
        guard let data = try? Data(contentsOf: file),
              let list = try? JSONDecoder().decode([Project].self, from: data) else { return [] }
        return list
    }
    static func save(_ list: [Project]) {
        if let data = try? JSONEncoder().encode(list) { try? data.write(to: file) }
    }
}

// MARK: - Shell

struct ShellResult { let code: Int32; let out: String }

// Improvement #10 — one place that safely single-quotes an argument for /bin/zsh,
// so paths with spaces or quotes can never break a command or inject one.
enum Sh {
    static func q(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

// PERF (v1.9): a cached, non-interactive shell environment.
//
// We resolve a good PATH ONCE (covering Homebrew on Intel + Apple Silicon, MacPorts, and the
// user's ~/.local and Go/Cargo bins) plus the git/ssh "never prompt" variables, then reuse the
// dictionary for every command. This lets us run commands with a NON-login shell (`zsh -c`),
// which is dramatically faster than `zsh -lc` because it skips sourcing ~/.zprofile/~/.zshrc
// on every single invocation — the main cause of per-action lag.
enum ShellEnv {
    static let fast: [String: String] = {
        var env = ProcessInfo.processInfo.environment
        let home = env["HOME"] ?? NSHomeDirectory()
        let extras = [
            "/opt/homebrew/bin", "/opt/homebrew/sbin",     // Apple Silicon Homebrew
            "/usr/local/bin", "/usr/local/sbin",           // Intel Homebrew
            "/opt/local/bin", "/opt/local/sbin",           // MacPorts
            "\(home)/.local/bin",
            "\(home)/.cargo/bin",
            "\(home)/go/bin",
            "/usr/bin", "/bin", "/usr/sbin", "/sbin",
        ]
        let existing = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        // De-dupe while preserving order, extras first so tool discovery is reliable.
        var seen = Set<String>(); var ordered: [String] = []
        for d in extras + existing where !d.isEmpty && !seen.contains(d) { seen.insert(d); ordered.append(d) }
        env["PATH"] = ordered.joined(separator: ":")
        // Never block on a credential / host-key prompt.
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_ASKPASS"] = "true"
        env["SSH_ASKPASS"] = "true"
        env["GIT_SSH_COMMAND"] = "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
        // Make git output stable and fast to parse.
        env["GIT_PAGER"] = "cat"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        env["LC_ALL"] = "C"
        return env
    }()
}

// Improvement #3 — the commit-message safety check from the playbook (Section 3 / Appendix A),
// implemented natively so a risky message is caught before it ever reaches the shell.
enum CommitSafety {
    /// Returns the list of problems found. Empty == SAFE.
    static func problems(in message: String) -> [String] {
        var bad: [String] = []
        if message.contains("`") { bad.append("backtick (`) — runs as command substitution") }
        if message.contains("$(") { bad.append("$( ) — command substitution") }
        if message.range(of: #"\$[A-Za-z_{]"#, options: .regularExpression) != nil {
            bad.append("$NAME / ${…} — variable expansion")
        }
        if message.contains("\"") { bad.append("double-quote (\") — closes the message string early") }
        if message.contains("\\") { bad.append("backslash (\\) — interacts badly with shell escaping") }
        return bad
    }
    static func isSafe(_ message: String) -> Bool { problems(in: message).isEmpty }
}

// MARK: - Store

@MainActor
final class Store: ObservableObject {
    @Published var projects: [Project] = Persist.load()
    @Published var selectionID: Project.ID?
    @Published var console: String = "Welcome to BuildBuddy.\nAdd a project (drag a repo folder into the sidebar, or click +), then use the buttons.\nNew here? Click Instructions for the delivery playbook.\n\n"
    @Published var busy = false
    @Published var branch: String = "—"
    @Published var branches: [String] = []
    @Published var statusLine: String = ""
    @Published var lastResult: String = ""        // improvement #6 — ✅/❌ summary line

    // Freeze-fix support.
    let settings = SettingsStore()
    @Published var canCancel = false              // drives the Cancel button in the UI
    private var currentProcess: Process?          // the live child process, so we can kill it
    @Published var seenDownloadZips: Set<String> = []   // de-dupe Downloads auto-detect

    // PERF (v1.9): per-project status cache so re-selecting a project paints instantly while a
    // fresh read happens in the background. Keyed by project id; survives for the app session.
    struct CachedStatus { var branch: String; var branches: [String]; var statusLine: String }
    static var statusCache: [Project.ID: CachedStatus] = [:]

    var selected: Project? { projects.first { $0.id == selectionID } }

    func append(_ s: String) {
        console += s
        // FREEZE FIX (memory/render): keep the console bounded so SwiftUI never rebuilds an
        // unbounded Text. Trim to the last ~120k characters when it grows past ~160k.
        if console.count > 160_000 {
            console = "…(earlier output trimmed)…\n" + String(console.suffix(120_000))
        }
    }
    func line(_ s: String)   { console += "\n\(s)\n" }
    func clearConsole()      { console = "" }

    // Freeze-fix: kill whatever command is currently running.
    func cancelRunning() {
        if let p = currentProcess, p.isRunning {
            line("⛔️ Cancel requested — terminating the running command.")
            p.terminate()
            // Hard kill the whole process group shortly after, in case it ignores SIGTERM.
            let pid = p.processIdentifier
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                kill(-pid, SIGKILL)   // negative pid = process group
            }
        }
    }

    func select(_ p: Project) {
        selectionID = p.id
        UserDefaults.standard.set(p.id.uuidString, forKey: "lastSelectedProjectID")
        Task {
            await refresh()
            if settings.autoPullOnSelect { await pull() }
        }
    }

    // Restore the last project on launch when the option is on. Call once from the App.
    func restoreLastSelectionIfEnabled() {
        guard settings.rememberLastProject,
              let idStr = UserDefaults.standard.string(forKey: "lastSelectedProjectID"),
              let id = UUID(uuidString: idStr),
              let p = projects.first(where: { $0.id == id }) else { return }
        select(p)
    }

    func updateSelected(_ mutate: (inout Project) -> Void) {
        guard let id = selectionID, let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        mutate(&projects[idx])
        Persist.save(projects)
    }

    func addProject(at url: URL) {
        // Resolve to the git top-level if possible, so subfolders still map to the repo root.
        var root = url
        let topRes = syncShell("git rev-parse --show-toplevel", cwd: url)
        let top = topRes.out.trimmingCharacters(in: .whitespacesAndNewlines)
        if topRes.code == 0, !top.isEmpty, FileManager.default.fileExists(atPath: top) {
            root = URL(fileURLWithPath: top)
        }
        let name = root.lastPathComponent
        guard !projects.contains(where: { $0.path == root.path }) else { return }
        // Auto-detect a worker folder (a directory containing wrangler.toml).
        var worker: String? = nil
        if let found = findWorker(in: root) {
            worker = found.path.replacingOccurrences(of: root.path + "/", with: "")
        }
        let p = Project(name: name, path: root.path, workerSubpath: worker)
        projects.append(p)
        Persist.save(projects)
        select(p)
    }

    func removeSelected() {
        guard let id = selectionID else { return }
        if settings.confirmBeforeRemoveProject {
            let alert = NSAlert()
            alert.messageText = "Remove this project from BuildBuddy?"
            alert.informativeText = "This only removes it from the list. Your files and git repo are untouched."
            alert.addButton(withTitle: "Remove")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        projects.removeAll { $0.id == id }
        Self.statusCache[id] = nil   // PERF: drop cached status for the removed project
        Persist.save(projects)
        selectionID = projects.first?.id
        if let p = selected { select(p) } else { branch = "—"; branches = [] }
    }

    private func findWorker(in root: URL) -> URL? {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: root, includingPropertiesForKeys: nil,
                                     options: [.skipsHiddenFiles]) else { return nil }
        for case let u as URL in en where u.lastPathComponent == "wrangler.toml" {
            return u.deletingLastPathComponent()
        }
        return nil
    }

    // Synchronous shell (used for quick metadata reads). Hardened with a short timeout and
    // non-interactive env so a stuck git call can't freeze the metadata reads either.
    //
    // PERF (v1.9): this used to run `zsh -lc`, a LOGIN shell that re-sources ~/.zprofile,
    // ~/.zshrc, etc. on EVERY git command — the single biggest source of UI lag, since
    // refresh() fires several of these per project selection. We now use a non-login
    // `zsh -c` with an explicit, cached PATH (ShellEnv.fast), which skips profile sourcing
    // entirely. Homebrew/asdf paths are still found because ShellEnv resolves them once.
    @discardableResult
    nonisolated func syncShell(_ command: String, cwd: URL?, timeout: Double = 15) -> ShellResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        p.arguments = ["-c", command]
        if let cwd { p.currentDirectoryURL = cwd }
        p.environment = ShellEnv.fast
        p.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        p.standardOutput = pipe; p.standardError = pipe
        do { try p.run() } catch { return ShellResult(code: -1, out: error.localizedDescription) }
        let deadline = DispatchTime.now() + timeout
        let watchdog = DispatchWorkItem { if p.isRunning { p.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: deadline, execute: watchdog)
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        watchdog.cancel()
        return ShellResult(code: p.terminationStatus, out: String(data: data, encoding: .utf8) ?? "")
    }

    // Streaming shell — prints live to the console pane.
    // FREEZE FIX: this version
    //   • disables interactive git/ssh prompts (GIT_TERMINAL_PROMPT=0, BatchMode) so a
    //     command can NEVER block waiting on stdin — the #1 cause of the hang;
    //   • runs in its own process group and is killable via Cancel (cancelRunning());
    //   • enforces a hard timeout from Settings, after which it terminates the child.
    // Improvement #6 — reports the exit code as a ✅/❌ line so failures are never silent.
    @discardableResult
    func run(_ command: String, cwd: URL?, echo: Bool = true, label: String? = nil) async -> ShellResult {
        // Dry-run mode: never actually execute anything that runs here.
        if settings.dryRunMode {
            line("〰️ DRY RUN — would execute: \(command)")
            lastResult = "〰️ dry run (nothing executed)"
            return ShellResult(code: 0, out: "")
        }
        if echo { line("$ \(command)") }
        busy = true
        canCancel = true
        currentAction = label ?? ""          // [Improvement 8] show what's running in the header
        defer { busy = false; canCancel = false; currentProcess = nil; currentAction = "" }

        let timeout = max(5, settings.commandTimeoutSeconds)

        let result: ShellResult = await withCheckedContinuation { (cont: CheckedContinuation<ShellResult, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/bin/zsh")
                // PERF (v1.9): non-login shell + cached environment (no profile sourcing).
                p.arguments = ["-c", command]
                p.environment = ShellEnv.fast
                if let cwd { p.currentDirectoryURL = cwd }
                // Own process group so Cancel can kill children too (e.g. npx, git subprocesses).
                p.standardInput = FileHandle.nullDevice
                let pipe = Pipe()
                p.standardOutput = pipe; p.standardError = pipe
                let handle = pipe.fileHandleForReading
                var full = Data()
                let lock = NSLock()

                // FREEZE FIX (flooding): a command like unzipping a large delivery emits
                // hundreds of lines. Hopping to @MainActor per chunk spawned hundreds of
                // tasks and forced a full console re-render each time, choking the UI.
                // Instead we buffer output and flush at most ~8x/second.
                var pending = ""
                let pendingLock = NSLock()
                let flushTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
                flushTimer.schedule(deadline: .now() + 0.12, repeating: 0.12)
                flushTimer.setEventHandler {
                    pendingLock.lock()
                    let chunk = pending; pending = ""
                    pendingLock.unlock()
                    guard !chunk.isEmpty else { return }
                    Task { @MainActor in self.append(chunk) }
                }
                flushTimer.resume()

                handle.readabilityHandler = { h in
                    let d = h.availableData
                    guard !d.isEmpty else { return }
                    lock.lock(); full.append(d); lock.unlock()
                    if let s = String(data: d, encoding: .utf8) {
                        pendingLock.lock(); pending += s; pendingLock.unlock()
                    }
                }
                do {
                    try p.run()
                    setpgid(p.processIdentifier, p.processIdentifier)  // detach into its own group
                } catch {
                    flushTimer.cancel()
                    Task { @MainActor in self.line("⚠️ \(error.localizedDescription)") }
                    cont.resume(returning: ShellResult(code: -1, out: error.localizedDescription)); return
                }
                Task { @MainActor in self.currentProcess = p }

                // Hard timeout watchdog.
                var timedOut = false
                let watchdog = DispatchWorkItem {
                    if p.isRunning {
                        timedOut = true
                        Task { @MainActor in self.line("⏱️ Command exceeded \(Int(timeout))s — terminating.") }
                        p.terminate()
                        let pid = p.processIdentifier
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { kill(-pid, SIGKILL) }
                    }
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: watchdog)

                p.waitUntilExit()
                watchdog.cancel()
                handle.readabilityHandler = nil
                flushTimer.cancel()
                // Final flush of anything still buffered.
                pendingLock.lock(); let tail = pending; pending = ""; pendingLock.unlock()
                if !tail.isEmpty { Task { @MainActor in self.append(tail) } }
                lock.lock(); let out = String(data: full, encoding: .utf8) ?? ""; lock.unlock()
                let code = timedOut ? Int32(124) : p.terminationStatus  // 124 == timeout, like GNU
                cont.resume(returning: ShellResult(code: code, out: out))
            }
        }
        let tag = label ?? "command"
        if result.code == 0 {
            lastResult = "✅ \(tag) succeeded"
            if settings.verboseLogging { line("✅ \(tag) finished (exit 0)") }
        } else if result.code == 124 {
            lastResult = "⏱️ \(tag) timed out"
            line("⏱️ \(tag) timed out — you can adjust the timeout in Options.")
        } else {
            lastResult = "❌ \(tag) failed (exit \(result.code))"
            line("❌ \(tag) failed — exit code \(result.code)")
        }
        if settings.soundOnFinish {
            NSSound(named: result.code == 0 ? "Glass" : "Basso")?.play()
        }
        return result
    }

    // MARK: Git actions

    func refresh() async {
        guard let p = selected else { return }
        let pid = p.id

        // PERF (v1.9): serve from cache instantly, then refresh in the background. Re-selecting
        // a project you've already looked at now updates the UI with zero perceptible delay.
        if let cached = Self.statusCache[pid] {
            branch = cached.branch; branches = cached.branches; statusLine = cached.statusLine
        }

        // PERF: one shell invocation does all three reads (branch, branch list, dirty?) instead
        // of three separate `zsh` launches. The markers let us split the single output.
        let combined = """
        echo '@@BB_BRANCH@@'; git rev-parse --abbrev-ref HEAD 2>&1; \
        echo '@@BB_BRANCHES@@'; git branch -a --format='%(refname:short)' 2>/dev/null; \
        echo '@@BB_STATUS@@'; git status --porcelain 2>/dev/null; \
        echo '@@BB_END@@'
        """
        let out = await runQuiet(combined, cwd: p.url)

        func section(_ a: String, _ b: String) -> String {
            guard let r1 = out.range(of: a), let r2 = out.range(of: b, range: r1.upperBound..<out.endIndex)
            else { return "" }
            return String(out[r1.upperBound..<r2.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let b = section("@@BB_BRANCH@@", "@@BB_BRANCHES@@")
        let looksValid = !b.isEmpty && !b.contains(" ") && !b.lowercased().contains("fatal")
        if looksValid {
            branch = b
        } else if b.lowercased().contains("operation not permitted") {
            branch = "(no access)"
            line("⚠️ macOS blocked access to this folder. Grant Files & Folders permission to BuildBuddy in System Settings → Privacy & Security, then click Refresh.")
        } else {
            branch = "(no git)"
        }

        let rawBranches = section("@@BB_BRANCHES@@", "@@BB_STATUS@@")
        branches = Array(Set(rawBranches.split(separator: "\n").map { String($0) }
            .map { $0.replacingOccurrences(of: "origin/", with: "") }
            .filter { !$0.contains("HEAD") && !$0.lowercased().contains("fatal") })).sorted()

        let st = section("@@BB_STATUS@@", "@@BB_END@@")
        statusLine = st.isEmpty ? "clean" : "uncommitted changes"

        // Update cache for instant future selections.
        Self.statusCache[pid] = CachedStatus(branch: branch, branches: branches, statusLine: statusLine)
    }

    // A lightweight async wrapper that runs a command WITHOUT echoing to the console and
    // returns just its stdout — used for metadata reads so they don't spam the log.
    func runQuiet(_ command: String, cwd: URL?, timeout: Double = 15) async -> String {
        await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let r = self.syncShell(command, cwd: cwd, timeout: timeout)
                cont.resume(returning: r.out)
            }
        }
    }

    func pull() async {
        guard let p = selected else { return }
        let branchOK = !branch.isEmpty && !branch.hasPrefix("(") && !branch.contains(" ")
        guard branchOK else {
            line("⚠️ Skipping pull — no valid branch detected (\(branch)). Click Refresh first.")
            return
        }
        _ = await run("git pull --ff-only origin \(Sh.q(branch)) || git pull --no-edit origin \(Sh.q(branch))",
                      cwd: p.url, label: "Pull")
        await refresh()
    }

    // ════════════════════════════════════════════════════════════════════════════
    // v1.9 — 10 IMPROVEMENTS to existing features
    // ════════════════════════════════════════════════════════════════════════════

    // [Improvement 1] Refresh ALL projects at once (updates dashboard/cache in parallel).
    @Published var dashboard: [Project.ID: ProjectSnapshot] = [:]
    struct ProjectSnapshot { var branch: String; var dirty: Bool; var ahead: Int; var behind: Int }

    func refreshAll() async {
        line("Refreshing all \(projects.count) projects…")
        await withTaskGroup(of: (Project.ID, ProjectSnapshot).self) { group in
            for p in projects {
                group.addTask { (p.id, await self.snapshot(for: p)) }
            }
            for await (id, snap) in group {
                dashboard[id] = snap
            }
        }
        lastResult = "✅ Refreshed \(projects.count) projects"
        line(lastResult)
    }

    // Read a compact snapshot for one project (used by dashboard + refreshAll).
    func snapshot(for p: Project) async -> ProjectSnapshot {
        let cmd = """
        echo '@@B@@'; git rev-parse --abbrev-ref HEAD 2>/dev/null; \
        echo '@@D@@'; git status --porcelain 2>/dev/null | head -1; \
        echo '@@AB@@'; git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null; \
        echo '@@E@@'
        """
        let out = await runQuiet(cmd, cwd: p.url)
        func sec(_ a: String, _ b: String) -> String {
            guard let r1 = out.range(of: a), let r2 = out.range(of: b, range: r1.upperBound..<out.endIndex) else { return "" }
            return String(out[r1.upperBound..<r2.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let br = sec("@@B@@", "@@D@@")
        let dirty = !sec("@@D@@", "@@AB@@").isEmpty
        let ab = sec("@@AB@@", "@@E@@").split(whereSeparator: { $0 == " " || $0 == "\t" })
        let behind = ab.count == 2 ? Int(ab[0]) ?? 0 : 0
        let ahead = ab.count == 2 ? Int(ab[1]) ?? 0 : 0
        return ProjectSnapshot(branch: br.isEmpty ? "—" : br, dirty: dirty, ahead: ahead, behind: behind)
    }

    // [Improvement 2] Ahead/behind vs origin for the selected project, shown in the header.
    @Published var aheadBehind: (ahead: Int, behind: Int) = (0, 0)
    func updateAheadBehind() async {
        guard let p = selected else { return }
        let out = await runQuiet("git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null", cwd: p.url)
        let parts = out.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        if parts.count == 2 { aheadBehind = (Int(parts[1]) ?? 0, Int(parts[0]) ?? 0) }
        else { aheadBehind = (0, 0) }
    }

    // [Improvement 3] Fetch (no merge) — updates remote-tracking refs so ahead/behind is current.
    func fetch() async {
        guard let p = selected else { return }
        _ = await run("git fetch --all --prune", cwd: p.url, label: "Fetch")
        await refresh(); await updateAheadBehind()
    }

    // [Improvement 4] Stash / unstash the working tree.
    func stash() async {
        guard let p = selected else { return }
        let label = "buildbuddy-" + DateFormatter.bbStamp.string(from: Date())
        _ = await run("git stash push -u -m \(Sh.q(label))", cwd: p.url, label: "Stash")
        await refresh()
    }
    func unstash() async {
        guard let p = selected else { return }
        _ = await run("git stash pop", cwd: p.url, label: "Unstash")
        await refresh()
    }

    // [Improvement 5] Discard all uncommitted changes (with confirmation in the UI layer).
    func discardChanges() async {
        guard let p = selected else { return }
        _ = await run("git reset --hard HEAD && git clean -fd", cwd: p.url, label: "Discard changes")
        await refresh()
    }

    // [Improvement 6] Copy the current commit SHA to the clipboard.
    func copyCurrentSHA() async {
        guard let p = selected else { return }
        let sha = (await runQuiet("git rev-parse HEAD 2>/dev/null", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sha.isEmpty else { line("No commit yet."); return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(sha, forType: .string)
        line("Copied SHA \(sha.prefix(10))… to clipboard.")
        lastResult = "✅ Copied SHA"
    }

    // [Improvement 7] Open the project's repo on GitHub in the browser.
    func openOnGitHub() async {
        guard let p = selected else { return }
        var url = (await runQuiet("git remote get-url origin 2>/dev/null", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { line("No 'origin' remote set."); return }
        // Normalize git@github.com:owner/repo.git and https forms to a browser URL.
        if url.hasPrefix("git@") {
            url = url.replacingOccurrences(of: ":", with: "/").replacingOccurrences(of: "git@", with: "https://")
        }
        if url.hasSuffix(".git") { url = String(url.dropLast(4)) }
        if let u = URL(string: url) { NSWorkspace.shared.open(u); line("Opened \(url)") }
    }

    // [Improvement 8] Per-action busy label so the header can show WHAT is running.
    @Published var currentAction: String = ""

    // [Improvement 9] Guard against overlapping actions (don't run two git mutations at once).
    @Published var actionInFlight = false
    func guarded(_ label: String, _ work: @escaping () async -> Void) async {
        if actionInFlight { line("⏳ Busy with \(currentAction) — please wait."); return }
        actionInFlight = true; currentAction = label
        defer { actionInFlight = false; currentAction = "" }
        await work()
    }

    // [Improvement 10] One-click helper to (re)grant folder access by revealing the repo so the
    // macOS permission prompt appears, plus opening the Privacy pane.
    func requestFolderAccess() {
        guard let p = selected else { return }
        NSWorkspace.shared.activateFileViewerSelecting([p.url])
        if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(u)
        }
        line("If prompted, allow BuildBuddy to access this folder, then click Refresh.")
    }

    // ════════════════════════════════════════════════════════════════════════════
    // v1.9 — 10 NEW features (backend)
    // ════════════════════════════════════════════════════════════════════════════

    // [New 3] Built-in diff viewer: returns the unified diff of pending changes.
    func pendingDiff() async -> String {
        guard let p = selected else { return "" }
        let d = await runQuiet("git -c color.ui=never diff HEAD 2>/dev/null | head -2000", cwd: p.url)
        return d.isEmpty ? "No pending changes." : d
    }

    // [New 4] Recent commit history (compact).
    struct CommitRow: Identifiable { let id = UUID(); let sha: String; let subject: String; let date: String; let author: String }
    func recentCommits(limit: Int = 30) async -> [CommitRow] {
        guard let p = selected else { return [] }
        let fmt = "%h\u{1f}%s\u{1f}%cr\u{1f}%an"
        let out = await runQuiet("git log -n \(limit) --pretty=format:\(Sh.q(fmt)) 2>/dev/null", cwd: p.url)
        return out.split(separator: "\n").compactMap { line in
            let f = line.components(separatedBy: "\u{1f}")
            guard f.count == 4 else { return nil }
            return CommitRow(sha: f[0], subject: f[1], date: f[2], author: f[3])
        }
    }

    // [New 7] Per-project notes, persisted to UserDefaults keyed by repo path.
    func note(for p: Project) -> String { UserDefaults.standard.string(forKey: "note:\(p.path)") ?? "" }
    func setNote(_ s: String, for p: Project) { UserDefaults.standard.set(s, forKey: "note:\(p.path)") }

    // [New 8] Commit & push EVERY dirty repo in one action.
    func commitAllDirty(message: String) async {
        let msg = message.isEmpty ? settings.defaultCommitMessage : message
        guard CommitSafety.isSafe(msg) else { line("❌ Message is shell-unsafe; aborting bulk commit."); return }
        var done = 0
        for p in projects {
            let dirty = !(await runQuiet("git status --porcelain 2>/dev/null", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            guard dirty else { continue }
            line("• \(p.name): committing…")
            let safe = msg.replacingOccurrences(of: "\"", with: "\\\"")
            _ = await run("git add -A && git commit -m \"\(safe)\" && (git push 2>/dev/null || true)", cwd: p.url, label: "Commit \(p.name)")
            done += 1
        }
        lastResult = done == 0 ? "Nothing dirty to commit." : "✅ Committed \(done) repo(s)"
        line(lastResult)
    }

    // [New 9] Quick branch switch by name (used by the quick switcher menu).
    func quickSwitch(to name: String) async { await switchBranch(name) }

    // [New 6] Favorites / pinned projects (ids persisted).
    var favoriteIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "favoriteProjectIDs") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "favoriteProjectIDs") }
    }
    func toggleFavorite(_ p: Project) {
        var f = favoriteIDs
        if f.contains(p.id.uuidString) { f.remove(p.id.uuidString) } else { f.insert(p.id.uuidString) }
        favoriteIDs = f
        objectWillChange.send()
    }
    func isFavorite(_ p: Project) -> Bool { favoriteIDs.contains(p.id.uuidString) }

    // Improvement #3 — guard the commit message before running it. Returns false if blocked.
    @discardableResult
    func commitPush(message: String) async -> Bool {
        guard let p = selected, !message.isEmpty else { return false }
        let problems = CommitSafety.problems(in: message)
        if settings.blockUnsafeCommitMessages, !problems.isEmpty {
            line("❌ Commit blocked — message contains shell-unsafe characters:")
            for x in problems { line("   • \(x)") }
            line("Edit the message (plain prose, ASCII) and try again. See Instructions § Commit-Message Rule.")
            lastResult = "❌ Commit blocked (unsafe message)"
            return false
        }
        // Validate the branch before using it in a push command.
        let branchOK = !branch.isEmpty && !branch.hasPrefix("(") && !branch.contains(" ")
        guard branchOK else {
            line("❌ Can't commit — no valid branch detected (\(branch)). Click Refresh; if it says no access, grant Files & Folders permission to BuildBuddy.")
            lastResult = "❌ No valid branch"
            return false
        }
        let safe = message.replacingOccurrences(of: "\"", with: "\\\"")
        let doPush = settings.pushAfterCommit && !askedAndDeclinedPush()

        // Stage, then commit only if there's something staged. This avoids the misleading
        // "Commit & Push failed (exit 1)" when the tree is already clean. If clean and push
        // is requested, still push any local commits that haven't reached origin.
        let commitCmd = "git add -A; " +
            "if git diff --cached --quiet; then echo 'BB_NOTHING_TO_COMMIT'; else git commit -m \"\(safe)\"; fi"
        let r = await run(commitCmd, cwd: p.url, label: "Commit")

        let nothing = r.out.contains("BB_NOTHING_TO_COMMIT")
        if nothing { line("Nothing new to commit — working tree is clean.") }

        if doPush {
            _ = await run("git push origin \(Sh.q(branch))", cwd: p.url, label: "Push")
        }
        await refresh()
        return true
    }

    // Respects "Ask before pushing": returns true if the user declined the push.
    private func askedAndDeclinedPush() -> Bool {
        guard settings.confirmBeforePush else { return false }
        let alert = NSAlert()
        alert.messageText = "Push to origin/\(branch)?"
        alert.informativeText = "Commit will proceed either way. Choose whether to push now."
        alert.addButton(withTitle: "Commit & Push")
        alert.addButton(withTitle: "Commit only")
        return alert.runModal() != .alertFirstButtonReturn
    }

    func switchBranch(_ name: String) async {
        guard let p = selected else { return }
        _ = await run("git checkout \(Sh.q(name)) 2>/dev/null || git checkout -t \(Sh.q("origin/" + name))",
                      cwd: p.url, label: "Switch branch")
        await refresh()
    }

    func newBranch(_ name: String, base: String) async {
        guard let p = selected else { return }
        _ = await run("git checkout \(Sh.q(base)) && git pull --ff-only origin \(Sh.q(base)) 2>/dev/null; git checkout -b \(Sh.q(name)) && git push -u origin \(Sh.q(name))",
                      cwd: p.url, label: "New branch")
        await refresh()
    }

    func merge(_ src: String) async {
        guard let p = selected else { return }
        _ = await run("git merge --no-edit \(Sh.q(src)) && git push origin \(Sh.q(branch))",
                      cwd: p.url, label: "Merge")
        await refresh()
    }

    func openXcode() async {
        guard let p = selected else { return }
        let ws = syncShell("find . -maxdepth 2 -name '*.xcworkspace' | head -n1", cwd: p.url).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let proj = ws.isEmpty
            ? syncShell("find . -maxdepth 2 -name '*.xcodeproj' | head -n1", cwd: p.url).out.trimmingCharacters(in: .whitespacesAndNewlines)
            : ws
        if proj.isEmpty { line("No .xcodeproj/.xcworkspace found."); return }
        _ = await run("open \(Sh.q(proj))", cwd: p.url, label: "Open in Xcode")
    }

    func deployWorker() async {
        guard let p = selected, let sub = p.workerSubpath else { line("No worker folder in this project."); return }
        _ = await run("cd \(Sh.q(sub)) && npx wrangler deploy", cwd: p.url, label: "Deploy Worker")
    }

    // Improvement #10 — open the repo in Finder.
    func revealInFinder() {
        guard let p = selected else { return }
        NSWorkspace.shared.activateFileViewerSelecting([p.url])
    }

    // MARK: Self-update (so BuildBuddy can update itself instead of needing a drop)

    @Published var updateStatus: String = ""
    @Published var updateAvailable = false

    // Find the folder that contains this app's own source. Prefers a project named
    // "BuildBuddy"; otherwise asks the bundle where it lives and walks up to the repo root.
    func locateSelfRepo() -> URL? {
        if let p = projects.first(where: { $0.name.caseInsensitiveCompare("BuildBuddy") == .orderedSame }) {
            return p.url
        }
        // The compiled app lives at <repo>/.build/BuildBuddy.app/Contents/MacOS/BuildBuddy.
        // Walk up from the executable to find a folder containing BuildBuddy.swift.
        var dir = URL(fileURLWithPath: Bundle.main.bundlePath)
        for _ in 0..<6 {
            dir.deleteLastPathComponent()
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent("BuildBuddy.swift").path) {
                return dir
            }
        }
        return nil
    }

    // Pull the BuildBuddy repo and detect whether BuildBuddy.swift (the app's source) changed.
    func checkForUpdates() async {
        guard let repo = locateSelfRepo() else {
            updateStatus = "Couldn't find the BuildBuddy repo. Add the BuildBuddy folder as a project, then try again."
            line(updateStatus)
            return
        }
        line("Checking for BuildBuddy updates in \(repo.path) …")
        let before = syncShell("git rev-parse HEAD:BuildBuddy.swift 2>/dev/null", cwd: repo).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let branchName = syncShell("git rev-parse --abbrev-ref HEAD", cwd: repo).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let safeBranch = (branchName.isEmpty || branchName.contains(" ")) ? "master" : branchName
        _ = await run("git pull --ff-only origin \(Sh.q(safeBranch))", cwd: repo, label: "Update check (pull)")
        let after = syncShell("git rev-parse HEAD:BuildBuddy.swift 2>/dev/null", cwd: repo).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !before.isEmpty && !after.isEmpty && before != after {
            updateAvailable = true
            updateStatus = "Update downloaded. Click Update & Relaunch to rebuild."
            line("⬆️ A newer BuildBuddy.swift was pulled. " + updateStatus)
        } else {
            updateAvailable = false
            updateStatus = "BuildBuddy is up to date (v\(BuildBuddyVersion))."
            line("✅ " + updateStatus)
        }
    }

    // Relaunch via the launcher, which rebuilds because the source is now newer than the binary.
    func updateAndRelaunch() async {
        guard let repo = locateSelfRepo() else { line("Couldn't find the BuildBuddy repo."); return }
        let launcher = repo.appendingPathComponent("Launch BuildBuddy.command")
        guard FileManager.default.fileExists(atPath: launcher.path) else {
            line("Couldn't find 'Launch BuildBuddy.command' in \(repo.path).")
            return
        }
        line("Rebuilding and relaunching BuildBuddy …")
        // Remove the stale built app so the launcher definitely rebuilds, then open the launcher
        // and quit this instance a moment later.
        _ = await run("rm -rf \(Sh.q(repo.appendingPathComponent(".build/BuildBuddy.app").path)); open \(Sh.q(launcher.path))",
                      cwd: repo, label: "Relaunch")
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        await MainActor.run { NSApp.terminate(nil) }
    }

    // Show What's New automatically the first time a new version runs.
    func shouldShowWhatsNew() -> Bool {
        let key = "lastSeenVersion"
        let last = UserDefaults.standard.string(forKey: key)
        if last != BuildBuddyVersion {
            UserDefaults.standard.set(BuildBuddyVersion, forKey: key)
            return last != nil   // don't pop on the very first install, only after an update
        }
        return false
    }

    // Improvement #7 — save the console transcript to a file.
    func saveConsole() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "BuildBuddy-console.txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? console.write(to: url, atomically: true, encoding: .utf8)
            line("Saved console to \(url.path)")
        }
    }

    // MARK: Apply a Claude delivery zip

    // Improvement #4 — inspect a delivery zip without touching the repo.
    struct DeliveryPreview: Identifiable {
        let id = UUID()
        var files: [String]               // all files in the drop (repo-relative)
        var changedFiles: [String]        // new or content-different vs the repo
        var unchangedFiles: [String]      // identical to what's already in the repo
        var newFiles: [String]            // not present in the repo at all
        var commitMessage: String
        var hasCommitScript: Bool
        var messageProblems: [String]
        var tmpDir: URL
        var sourceDir: String
        // True when the drop adds/changes nothing — i.e. it's already been applied.
        var nothingToApply: Bool { changedFiles.isEmpty }
    }

    // Byte-for-byte compare of two files. Returns true if identical.
    private func filesIdentical(_ a: String, _ b: String) -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: a), fm.fileExists(atPath: b) else { return false }
        // Quick size check first, then full content compare.
        let sa = (try? fm.attributesOfItem(atPath: a)[.size] as? Int) ?? nil
        let sb = (try? fm.attributesOfItem(atPath: b)[.size] as? Int) ?? nil
        if let sa, let sb, sa != sb { return false }
        guard let da = fm.contents(atPath: a), let db = fm.contents(atPath: b) else { return false }
        return da == db
    }

    func previewDelivery(zip: URL) async -> DeliveryPreview? {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("bb_\(UUID().uuidString)")
        // -q (quiet) so a large delivery does not print one line per file (flooding the console).
        let unzip = await run("mkdir -p \(Sh.q(tmp.path)) && /usr/bin/unzip -oq \(Sh.q(zip.path)) -d \(Sh.q(tmp.path))",
                              cwd: nil, label: "Unzip (preview)")
        if unzip.code != 0 { line("Unzip failed."); return nil }
        let inner = syncShell("find \(Sh.q(tmp.path)) -mindepth 1 -maxdepth 1 -type d | head -n1", cwd: nil).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let src = inner.isEmpty ? tmp.path : inner
        let listing = syncShell("cd \(Sh.q(src)) && find . -type f -not -name COMMIT_MSG.txt -not -name commit.sh | sed 's|^\\./||' | sort", cwd: nil).out
        let files = listing.split(separator: "\n").map(String.init)

        // Classify each file against the currently selected repo so we don't re-apply
        // identical files. If no project is selected we treat everything as changed.
        var changed: [String] = [], unchanged: [String] = [], newOnes: [String] = []
        let repoPath = selected?.path
        for rel in files {
            let srcFile = "\(src)/\(rel)"
            if let repoPath {
                let repoFile = "\(repoPath)/\(rel)"
                if !FileManager.default.fileExists(atPath: repoFile) {
                    newOnes.append(rel); changed.append(rel)
                } else if filesIdentical(srcFile, repoFile) {
                    unchanged.append(rel)
                } else {
                    changed.append(rel)
                }
            } else {
                changed.append(rel)
            }
        }

        var msg = ""
        let msgPath = "\(src)/COMMIT_MSG.txt"
        if FileManager.default.fileExists(atPath: msgPath) {
            msg = (try? String(contentsOfFile: msgPath, encoding: .utf8)) ?? ""
        }
        msg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasScript = FileManager.default.fileExists(atPath: "\(src)/commit.sh")
        return DeliveryPreview(files: files,
                               changedFiles: changed,
                               unchangedFiles: unchanged,
                               newFiles: newOnes,
                               commitMessage: msg,
                               hasCommitScript: hasScript,
                               messageProblems: CommitSafety.problems(in: msg),
                               tmpDir: tmp,
                               sourceDir: src)
    }

    // SAFE BACKUP (replaces the old git-stash snapshot, which was the freeze trigger).
    // Instead of mutating the working tree with stash push/apply, we copy the files the
    // delivery is about to overwrite into a timestamped backup folder. Pure file copy —
    // it can never deadlock the working tree or wait on a git prompt.
    @discardableResult
    func backupBeforeApply(preview: DeliveryPreview) async -> URL? {
        guard let p = selected, settings.backupBeforeApply else { return nil }
        let stamp = DateFormatter.bbStamp.string(from: Date())
        let backupDir = p.url.appendingPathComponent(".buildbuddy-backups/\(stamp)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        } catch { line("⚠️ Could not create backup folder: \(error.localizedDescription)"); return nil }
        var copied = 0
        for rel in preview.changedFiles {
            let existing = p.url.appendingPathComponent(rel)
            guard FileManager.default.fileExists(atPath: existing.path) else { continue }
            let dest = backupDir.appendingPathComponent(rel)
            try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.copyItem(at: existing, to: dest)
            copied += 1
        }
        if copied == 0 {
            // Nothing pre-existing to back up (all new files); drop the empty backup dir.
            try? FileManager.default.removeItem(at: backupDir)
            return nil
        }
        line("🗂️ Backed up \(copied) existing file(s) to \(backupDir.path) (undo point).")
        return backupDir
    }

    // Applies an already-previewed delivery. Honors all global Settings as well as the
    // per-project auto-commit toggle and the commit-safety guard.
    func commitDelivery(from preview: DeliveryPreview) async {
        guard let p = selected else { line("Select a project first."); return }
        defer { try? FileManager.default.removeItem(at: preview.tmpDir) }

        if settings.clearConsoleOnAction { clearConsole() }

        // GUARD: don't re-apply files that are already identical in the repo. If the drop
        // contains nothing new or changed, skip the whole apply/commit — it's already applied.
        if preview.nothingToApply {
            line("✓ Nothing to apply — all \(preview.files.count) file(s) in this delivery are already identical in \(p.name). Skipping.")
            lastResult = "✓ Already applied (no changes)"
            return
        }

        let changedCount = preview.changedFiles.count
        let skippedCount = preview.unchangedFiles.count
        line("Applying \(changedCount) changed file(s)" + (skippedCount > 0 ? "; skipping \(skippedCount) unchanged." : "."))

        // Optional pull-before-apply (off by default to avoid surprises).
        if settings.autoPullBeforeApply {
            line("Auto-pull before apply is ON.")
            await pull()
        }

        await backupBeforeApply(preview: preview)

        // Overlay ONLY the changed files. We feed rsync an explicit include-from list so
        // unchanged files are never re-copied (and their mtimes aren't touched).
        let listFile = preview.tmpDir.appendingPathComponent("bb_changed_files.txt")
        let listText = preview.changedFiles.joined(separator: "\n") + "\n"
        try? listText.write(to: listFile, atomically: true, encoding: .utf8)
        _ = await run("/usr/bin/rsync -a --files-from=\(Sh.q(listFile.path)) \(Sh.q(preview.sourceDir))/ \(Sh.q(p.path))/",
                      cwd: nil, label: "Overlay changed files")
        line("Applied. Changes:")
        _ = await run("git status --short", cwd: p.url, echo: true, label: "Status")
        await refresh()

        // If, after overlaying, git still sees no diff (e.g. files matched line-endings), don't
        // proceed to a commit that would fail — report cleanly instead.
        let dirty = syncShell("git status --porcelain", cwd: p.url).out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if dirty.isEmpty {
            line("✓ Repo already matches this delivery — nothing to commit.")
            lastResult = "✓ Already applied (no changes)"
            return
        }

        // Decide commit behavior: global master switch AND per-project toggle must allow it.
        let autoOK = settings.autoCommitAndPush && p.autoCommitOnApply
        let msg = preview.commitMessage.isEmpty ? settings.defaultCommitMessage : preview.commitMessage
        let safe = CommitSafety.isSafe(msg) || !settings.blockUnsafeCommitMessages

        if autoOK && !msg.isEmpty && safe {
            line("Auto-commit \(settings.pushAfterCommit ? "& push " : "")is ON — committing…")
            _ = await commitPush(message: msg)
            await maybePostApply()
        } else if autoOK && !msg.isEmpty && !safe {
            line("Auto-commit is ON, but the message is shell-unsafe — opening it for review instead.")
            pendingCommitMessage = msg
        } else if !preview.commitMessage.isEmpty {
            pendingCommitMessage = preview.commitMessage   // opens the review sheet
        } else {
            line("Applied. Auto-commit is off — review your changes, then Commit & Push.")
        }
    }

    // Post-apply conveniences (settings-gated).
    func maybePostApply() async {
        if settings.openXcodeAfterApply { await openXcode() }
        if settings.deployWorkerAfterPush, selected?.workerSubpath != nil { await deployWorker() }
    }

    // MARK: Downloads auto-detect

    // Scans ~/Downloads for a zip whose inner top folder matches the selected project's repo
    // name OR whose filename contains the project name (broadest match, per your choice).
    // Returns the first new match not already seen this session.
    func scanDownloadsForDelivery() async -> URL? {
        guard settings.watchDownloads, let p = selected else { return nil }
        let dl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard let dl else { return nil }
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: dl, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return nil }
        let zips = items.filter { $0.pathExtension.lowercased() == "zip" }
            .sorted { (a, b) in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return da > db
            }
        let repoName = p.name.lowercased()
        for zip in zips {
            if seenDownloadZips.contains(zip.path) { continue }
            let fileMatches = zip.lastPathComponent.lowercased().contains(repoName)
            var innerMatches = false
            // Peek at the inner top folder name without extracting fully.
            let listing = syncShell("/usr/bin/unzip -Z1 \(Sh.q(zip.path)) | head -n1", cwd: nil, timeout: 10).out
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let topFolder = listing.split(separator: "/").first.map(String.init)?.lowercased() ?? ""
            if topFolder == repoName { innerMatches = true }
            if fileMatches || innerMatches {
                seenDownloadZips.insert(zip.path)
                return zip
            }
        }
        return nil
    }

    @Published var pendingCommitMessage: String = ""
}

extension DateFormatter {
    static let bbStamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f
    }()
}

// MARK: - App

@main
struct BuildBuddyApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup("BuildBuddy") {
            ContentView().environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    // Auto-start the Remote agent if the user left it enabled.
                    if RemoteAgent.shared.startOnLaunch { RemoteAgent.shared.start() }
                }
        }
        .windowStyle(.titleBar)
        // Improvement #9 — menu commands with keyboard shortcuts.
        .commands {
            CommandGroup(after: .newItem) {
                Button("Pull Latest") { Task { await store.pull() } }
                    .keyboardShortcut("l", modifiers: [.command])
                Button("Refresh") { Task { await store.refresh() } }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Refresh All Projects") { Task { await store.refreshAll() } }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Button("Cancel Running Command") { store.cancelRunning() }
                    .keyboardShortcut(".", modifiers: [.command])
                Button("Check for Updates…") { Task { await store.checkForUpdates() } }
                    .keyboardShortcut("u", modifiers: [.command])
                Divider()
                Button("Command Palette…") { NotificationCenter.default.post(name: .bbShowPalette, object: nil) }
                    .keyboardShortcut("k", modifiers: [.command])
                Button("Dashboard…") { NotificationCenter.default.post(name: .bbShowDashboard, object: nil) }
                    .keyboardShortcut("b", modifiers: [.command])
            }
        }
        // Native Settings window (⌘,) holding the full Options panel.
        Settings {
            OptionsView().environmentObject(store)
        }
        // [New 10] Menu-bar quick actions — control BuildBuddy without raising the window.
        MenuBarExtra("BuildBuddy", systemImage: "hammer.circle") {
            Text(store.selected.map { "Project: \($0.name)" } ?? "No project selected")
            if store.selected != nil {
                Button("Pull latest") { Task { await store.pull() } }
                Button("Commit all dirty repos…") { NotificationCenter.default.post(name: .bbShowCommitAll, object: nil) }
                Button("Refresh all") { Task { await store.refreshAll() } }
                Divider()
                Button("Open in Xcode") { Task { await store.openXcode() } }
                Button("Reveal in Finder") { store.revealInFinder() }
            }
            Divider()
            Button("Show BuildBuddy") { NSApp.activate(ignoringOtherApps: true) }
            Button("Quit BuildBuddy") { NSApp.terminate(nil) }
        }
    }
}

// MARK: - Root view

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var showDoctor = false
    @State private var showInstructions = false
    @State private var showOptions = false
    @State private var showWhatsNew = false
    @State private var showRemote = false
    @State private var foundZip: URL?

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .frame(minWidth: 220)
        } detail: {
            if store.selected == nil {
                EmptyDetail(showInstructions: $showInstructions)
            } else {
                DetailView(showDoctor: $showDoctor, showInstructions: $showInstructions,
                           showOptions: $showOptions, showWhatsNew: $showWhatsNew)
            }
        }
        .sheet(isPresented: $showDoctor) { DoctorView().environmentObject(store) }
        .sheet(isPresented: $showInstructions) { InstructionsView() }
        .sheet(isPresented: $showOptions) { OptionsView().environmentObject(store).frame(width: 600, height: 640) }
        .sheet(isPresented: $showWhatsNew) { WhatsNewView().environmentObject(store) }
        .sheet(isPresented: $showRemote) { RemotePanelView().environmentObject(store).frame(width: 560, height: 720) }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowRemote)) { _ in showRemote = true }
        // Downloads auto-detect — polls on the interval from Settings while a project is selected.
        .task(id: store.selectionID) { await watchDownloadsLoop() }
        .onAppear {
            store.restoreLastSelectionIfEnabled()
            // Pop What's New automatically the first run after an update.
            if store.shouldShowWhatsNew() { showWhatsNew = true }
        }
    }

    // Polling loop (not a thread that can hang the UI). Honors watchDownloads + interval.
    private func watchDownloadsLoop() async {
        while !Task.isCancelled {
            let interval = max(3, store.settings.downloadsScanSeconds)
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard store.settings.watchDownloads, store.selected != nil, !store.busy else { continue }
            if let zip = await store.scanDownloadsForDelivery() {
                store.line("📥 Found a matching delivery in Downloads: \(zip.lastPathComponent)")
                // Auto-apply only when auto-commit is on (your choice); otherwise open the preview.
                if store.settings.autoCommitAndPush && store.settings.autoApplyFound {
                    if let preview = await store.previewDelivery(zip: zip) {
                        await store.commitDelivery(from: preview)
                    }
                } else {
                    if let preview = await store.previewDelivery(zip: zip) {
                        await MainActor.run { foundZip = zip }
                        // Surface via the normal preview path.
                        NotificationCenter.default.post(name: .bbShowPreview, object: preview)
                    }
                }
            }
        }
    }
}

extension Notification.Name { static let bbShowPreview = Notification.Name("bbShowPreview") }
extension Notification.Name {
    static let bbShowPalette = Notification.Name("bbShowPalette")
    static let bbShowDashboard = Notification.Name("bbShowDashboard")
    static let bbShowCommitAll = Notification.Name("bbShowCommitAll")
}

// MARK: - Sidebar

struct Sidebar: View {
    @EnvironmentObject var store: Store
    @State private var search = ""

    // Filtered + split into favorites and the rest.
    private var matches: [Project] {
        let base = search.isEmpty ? store.projects
            : store.projects.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.path.localizedCaseInsensitiveContains(search) }
        return base
    }
    private var favorites: [Project] { matches.filter { store.isFavorite($0) } }
    private var others: [Project] { matches.filter { !store.isFavorite($0) } }

    var body: some View {
        VStack(spacing: 0) {
            // [New 1] Project search box.
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                TextField("Search projects", text: $search).textFieldStyle(.plain).font(.callout)
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.borderless).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)

            List(selection: Binding(get: { store.selectionID }, set: { id in
                if let id, let p = store.projects.first(where: { $0.id == id }) { store.select(p) }
            })) {
                if !favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites) { p in row(p) }
                    }
                }
                Section(favorites.isEmpty ? "Projects" : "All projects") {
                    ForEach(others) { p in row(p) }
                }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                handleDrop(providers); return true
            }

            Divider()
            HStack {
                Button { pickProjectFolder() } label: { Label("Add", systemImage: "plus") }
                Spacer()
                Button(role: .destructive) { store.removeSelected() } label: { Image(systemName: "minus") }
                    .disabled(store.selectionID == nil)
            }
            .padding(8)
        }
    }

    // One project row, with a star toggle and a right-click menu.
    @ViewBuilder private func row(_ p: Project) -> some View {
        HStack {
            Image(systemName: store.isFavorite(p) ? "star.fill" : "folder.fill")
                .foregroundStyle(store.isFavorite(p) ? .yellow : .tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(p.name).fontWeight(.medium)
                Text(p.path).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .tag(p.id)
        .contextMenu {
            Button(store.isFavorite(p) ? "Unfavorite" : "Favorite") { store.toggleFavorite(p) }
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([p.url]) }
        }
    }

    // Native folder picker (SwiftUI .fileImporter shows blank in this unsigned .app).
    private func pickProjectFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose a project repo folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            store.addProject(at: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for prov in providers {
            _ = prov.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                if isDir.boolValue {
                    Task { @MainActor in store.addProject(at: url) }
                }
            }
        }
    }
}

struct EmptyDetail: View {
    @Binding var showInstructions: Bool
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "shippingbox").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No project selected").font(.title2.bold())
            Text("Drag a repo folder into the sidebar, or click + to add one.")
                .foregroundStyle(.secondary)
            Button { showInstructions = true } label: {
                Label("Read the delivery instructions", systemImage: "book")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Detail

struct DetailView: View {
    @EnvironmentObject var store: Store
    @Binding var showDoctor: Bool
    @Binding var showInstructions: Bool
    @Binding var showOptions: Bool
    @Binding var showWhatsNew: Bool

    @State private var dropTargeted = false
    @State private var sheet: ActiveSheet?
    @State private var commitText = ""
    @State private var pendingPreview: Store.DeliveryPreview?
    @State private var consoleQuery = ""

    enum ActiveSheet: Identifiable {
        case commit, newBranch, switchBranch, merge, deliveryPreview
        case diff, history, dashboard, palette, notes, commitAll
        var id: Int { hashValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            guideStrip
            Divider()
            actionGrid
                .padding(16)
            Divider()
            console
        }
        .navigationTitle(store.selected?.name ?? "BuildBuddy")
        .sheet(item: $sheet) { which in
            switch which {
            case .commit:
                CommitSheet(text: $commitText) { msg in Task { await store.commitPush(message: msg) } }
            case .newBranch:
                NewBranchSheet(branches: store.branches) { name, base in Task { await store.newBranch(name, base: base) } }
            case .switchBranch:
                PickBranchSheet(title: "Switch to branch", branches: store.branches) { b in Task { await store.switchBranch(b) } }
            case .merge:
                PickBranchSheet(title: "Merge branch into \(store.branch)", branches: store.branches) { b in Task { await store.merge(b) } }
            case .deliveryPreview:
                EmptyView()   // delivery preview is presented via its own sheet below
            case .diff:
                DiffView().environmentObject(store)
            case .history:
                HistoryView().environmentObject(store)
            case .dashboard:
                DashboardView().environmentObject(store)
            case .palette:
                CommandPaletteView(onRun: { runPaletteAction($0) }).environmentObject(store)
            case .notes:
                NotesView().environmentObject(store)
            case .commitAll:
                CommitAllView().environmentObject(store)
            }
        }
        // IMPORTANT: the delivery preview is driven directly by the preview data, not by a
        // separate enum flag. Presenting it from $sheet while the data lived in a different
        // @State could race — the sheet would build before pendingPreview propagated and show
        // an EMPTY box (the "blank dialog" you saw), so Apply never appeared and nothing applied.
        .sheet(item: $pendingPreview) { preview in
            DeliveryPreviewSheet(preview: preview,
                                 autoCommit: store.selected?.autoCommitOnApply ?? true,
                                 onApply: { Task { await store.commitDelivery(from: preview) } },
                                 onCancel: { try? FileManager.default.removeItem(at: preview.tmpDir) })
        }
        .onChange(of: store.pendingCommitMessage) { _, msg in
            if !msg.isEmpty { commitText = msg; sheet = .commit; store.pendingCommitMessage = "" }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowPreview)) { note in
            if let preview = note.object as? Store.DeliveryPreview {
                pendingPreview = preview
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowPalette)) { _ in sheet = .palette }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowDashboard)) { _ in
            sheet = .dashboard; Task { await store.refreshAll() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowCommitAll)) { _ in sheet = .commitAll }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(store.selected?.name ?? "").font(.title2.bold())
                    // Version badge — click to open What's New. Always visible so you can tell
                    // exactly which build is running.
                    Button { showWhatsNew = true } label: {
                        Text("v\(BuildBuddyVersion)")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("BuildBuddy \(BuildBuddyVersion) — click for What's New & updates")
                }
                Text(store.selected?.path ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            // Improvement #1 — visible per-project auto-commit toggle.
            if let p = store.selected {
                Toggle(isOn: Binding(
                    get: { p.autoCommitOnApply },
                    set: { v in store.updateSelected { $0.autoCommitOnApply = v } }
                )) { Text("Auto-commit").font(.caption) }
                .toggleStyle(.switch)
                .help("When ON, applying a delivery commits & pushes automatically using its COMMIT_MSG.txt.")
            }
            Label(store.branch, systemImage: "arrow.triangle.branch")
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.quaternary, in: Capsule())
            // [Improvement 2] ahead/behind vs origin.
            if store.aheadBehind.ahead > 0 || store.aheadBehind.behind > 0 {
                HStack(spacing: 6) {
                    if store.aheadBehind.ahead > 0 {
                        Label("\(store.aheadBehind.ahead)", systemImage: "arrow.up").foregroundStyle(.green)
                    }
                    if store.aheadBehind.behind > 0 {
                        Label("\(store.aheadBehind.behind)", systemImage: "arrow.down").foregroundStyle(.orange)
                    }
                }
                .font(.caption2).labelStyle(.titleAndIcon)
                .help("Commits ahead of / behind origin")
            }
            Text(store.statusLine)
                .font(.caption).foregroundStyle(store.statusLine == "clean" ? .green : .orange)
            RemoteHeaderBadge().environmentObject(store)
            // [Improvement 8] show WHAT action is running, not just a spinner.
            if store.busy {
                HStack(spacing: 5) {
                    ProgressView().scaleEffect(0.6)
                    if !store.currentAction.isEmpty {
                        Text(store.currentAction).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            // FREEZE FIX UI — always-available Cancel while a command runs (also ⌘.).
            if store.canCancel {
                Button(role: .destructive) { store.cancelRunning() } label: {
                    Label("Cancel", systemImage: "stop.circle.fill")
                }
                .help("Stop the running command (⌘.)")
            }
        }
        .padding(16)
        .task(id: store.selectionID) { await store.updateAheadBehind() }
    }

    private var guideStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundStyle(.tint)
            Text(guideText).font(.callout)
            Spacer()
            if !store.lastResult.isEmpty {
                Text(store.lastResult).font(.caption.bold())
                    .foregroundStyle(store.lastResult.hasPrefix("✅") ? .green : .red)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.tint.opacity(0.08))
    }

    private var guideText: String {
        if store.statusLine != "clean" { return "You have uncommitted changes — use Commit & Push, or Apply a delivery." }
        return "Next: Apply a Claude delivery (drop the zip below), or Pull to get the latest."
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
            ActionButton("Pull latest", "arrow.down.circle", key: "l") { Task { await store.pull() } }
            ActionButton("Apply delivery", "tray.and.arrow.down", tint: .blue, key: "d") { pickDeliveryZip() }
            ActionButton("Commit & Push", "arrow.up.circle", key: "p") { commitText = ""; sheet = .commit }
            ActionButton("Switch branch", "arrow.left.arrow.right") { sheet = .switchBranch }
            ActionButton("New branch", "plus.square.on.square", key: "n") { sheet = .newBranch }
            ActionButton("Merge branch", "arrow.triangle.merge") { sheet = .merge }
            ActionButton("Open in Xcode", "hammer", tint: .indigo, key: "o") { Task { await store.openXcode() } }
            ActionButton("Deploy Worker", "cloud", tint: .teal) { Task { await store.deployWorker() } }
            // v1.9 improvements
            ActionButton("Fetch", "arrow.down.left.circle", tint: .cyan) { Task { await store.fetch() } }
            ActionButton("View Diff", "doc.text.magnifyingglass", tint: .purple, key: "i") { sheet = .diff }
            ActionButton("History", "clock.arrow.circlepath", tint: .brown) { sheet = .history }
            ActionButton("Stash", "tray.and.arrow.up", tint: .yellow) { Task { await store.stash() } }
            ActionButton("Unstash", "tray.and.arrow.down.fill", tint: .yellow) { Task { await store.unstash() } }
            ActionButton("Discard changes", "arrow.uturn.backward", tint: .red) { confirmDiscard() }
            ActionButton("Copy SHA", "number", tint: .gray) { Task { await store.copyCurrentSHA() } }
            ActionButton("Open on GitHub", "safari", tint: .blue) { Task { await store.openOnGitHub() } }
            // v1.9 new features
            ActionButton("Dashboard", "square.grid.2x2", tint: .indigo, key: "b") { sheet = .dashboard; Task { await store.refreshAll() } }
            ActionButton("Refresh all", "arrow.clockwise.circle", tint: .green) { Task { await store.refreshAll() } }
            ActionButton("Command palette", "command", tint: .pink, key: "k") { sheet = .palette }
            ActionButton("Commit all dirty", "square.stack.3d.up", tint: .orange) { sheet = .commitAll }
            ActionButton("Notes", "note.text", tint: .yellow) { sheet = .notes }
            ActionButton("Doctor", "stethoscope", tint: .pink) { showDoctor = true }
            ActionButton("Instructions", "book", tint: .orange) { showInstructions = true }
            ActionButton("Options", "gearshape", tint: .gray, key: "," ) { showOptions = true }
            ActionButton("Check for Updates", "arrow.down.app", tint: .green) { showWhatsNew = true; Task { await store.checkForUpdates() } }
            ActionButton("Remote", "iphone.radiowaves.left.and.right", tint: .mint, key: "e") { NotificationCenter.default.post(name: .bbShowRemote, object: nil) }
            ActionButton("Reveal in Finder", "folder") { store.revealInFinder() }
            ActionButton("Refresh", "arrow.clockwise", key: "r") { Task { await store.refresh() } }
        }
    }

    private var console: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Console").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                // Improvement #7 — search, copy, save.
                TextField("Filter…", text: $consoleQuery)
                    .textFieldStyle(.roundedBorder).frame(width: 140).font(.caption)
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(store.console, forType: .string)
                }.buttonStyle(.borderless).font(.caption)
                Button("Save") { store.saveConsole() }.buttonStyle(.borderless).font(.caption)
                Button("Clear") { store.clearConsole() }.buttonStyle(.borderless).font(.caption)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            ScrollViewReader { proxy in
                ScrollView {
                    Text(displayedConsole)
                        .font(.system(.caption, design: store.settings.monospaceConsole ? .monospaced : .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(12)
                        .id("end")
                }
                .onChange(of: store.console) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .overlay(alignment: .center) {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 8).stroke(.tint, lineWidth: 3)
                    .overlay(Text("Drop delivery zip to preview").font(.title3.bold()))
                    .padding(8)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            for prov in providers {
                _ = prov.loadObject(ofClass: URL.self) { url, _ in
                    guard let url, url.pathExtension.lowercased() == "zip" else { return }
                    Task { @MainActor in beginPreview(url) }
                }
            }
            return true
        }
    }

    // Native open panel for the delivery zip. SwiftUI's .fileImporter renders as a blank
    // panel in this unsigned, hand-built .app, so we drive NSOpenPanel directly (same as the
    // console Save panel, which works). This is the fix for the "empty dialog" on Apply delivery.
    private func pickDeliveryZip() {
        let panel = NSOpenPanel()
        panel.title = "Choose a delivery zip"
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        // Default to ~/Downloads since that's where deliveries usually land.
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        if panel.runModal() == .OK, let url = panel.url {
            beginPreview(url)
        }
    }

    // Confirm before a destructive discard of uncommitted work.
    private func confirmDiscard() {
        let alert = NSAlert()
        alert.messageText = "Discard all uncommitted changes?"
        alert.informativeText = "This runs git reset --hard and git clean -fd. Unsaved work in this repo will be permanently lost."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { Task { await store.discardChanges() } }
    }

    // Map a command-palette selection to an action.
    private func runPaletteAction(_ id: String) {
        switch id {
        case "pull": Task { await store.pull() }
        case "commit": commitText = ""; sheet = .commit
        case "fetch": Task { await store.fetch() }
        case "diff": sheet = .diff
        case "history": sheet = .history
        case "dashboard": sheet = .dashboard; Task { await store.refreshAll() }
        case "stash": Task { await store.stash() }
        case "unstash": Task { await store.unstash() }
        case "xcode": Task { await store.openXcode() }
        case "github": Task { await store.openOnGitHub() }
        case "copysha": Task { await store.copyCurrentSHA() }
        case "refreshall": Task { await store.refreshAll() }
        case "notes": sheet = .notes
        case "commitall": sheet = .commitAll
        case "doctor": showDoctor = true
        case "options": showOptions = true
        default: break
        }
    }

    private var displayedConsole: String {
        guard !consoleQuery.isEmpty else { return store.console }
        let lines = store.console.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { $0.range(of: consoleQuery, options: .caseInsensitive) != nil }
        return lines.joined(separator: "\n")
    }

    // Improvement #4/#5 — preview a zip first, then let the user confirm.
    // When "confirm before apply" is off in Options, skip the sheet and apply immediately.
    private func beginPreview(_ url: URL) {
        Task {
            if let preview = await store.previewDelivery(zip: url) {
                if store.settings.confirmBeforeApply {
                    // Setting pendingPreview is enough — the sheet is bound to it directly,
                    // so the data is always present when the sheet builds (no empty box).
                    await MainActor.run { pendingPreview = preview }
                } else {
                    await store.commitDelivery(from: preview)
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String; let icon: String; var tint: Color = .accentColor
    var key: Character? = nil
    let action: () -> Void
    init(_ title: String, _ icon: String, tint: Color = .accentColor, key: Character? = nil, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.tint = tint; self.key = key; self.action = action
    }
    var body: some View {
        let btn = Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundStyle(tint).frame(width: 22)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 10).padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        if let key {
            btn.keyboardShortcut(KeyEquivalent(key), modifiers: [.command, .shift])
        } else {
            btn
        }
    }
}

// MARK: - Delivery preview sheet (improvement #4)

struct DeliveryPreviewSheet: View {
    @Environment(\.dismiss) var dismiss
    let preview: Store.DeliveryPreview
    let autoCommit: Bool
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review delivery before applying").font(.title3.bold())
            Text("Only changed or new files are applied. Identical files are skipped, so a delivery is never re-applied. A backup of overwritten files is made first.")
                .font(.caption).foregroundStyle(.secondary)

            // Already-applied banner.
            if preview.nothingToApply && !preview.files.isEmpty {
                Label("This delivery is already applied — all \(preview.files.count) file(s) are identical to your repo. Nothing to do.",
                      systemImage: "checkmark.circle.fill")
                    .font(.callout).foregroundStyle(.green)
            }

            GroupBox("Files — \(preview.changedFiles.count) to apply, \(preview.unchangedFiles.count) unchanged") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if preview.files.isEmpty {
                            Text("No files found in the drop.").foregroundStyle(.secondary)
                        }
                        ForEach(preview.files, id: \.self) { f in
                            HStack(spacing: 6) {
                                if preview.newFiles.contains(f) {
                                    Text("NEW").font(.caption2.bold()).foregroundStyle(.blue).frame(width: 42, alignment: .leading)
                                } else if preview.changedFiles.contains(f) {
                                    Text("CHG").font(.caption2.bold()).foregroundStyle(.orange).frame(width: 42, alignment: .leading)
                                } else {
                                    Text("—").font(.caption2).foregroundStyle(.secondary).frame(width: 42, alignment: .leading)
                                }
                                Text(f).font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(preview.unchangedFiles.contains(f) ? .secondary : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }.padding(6)
                }.frame(height: 140)
            }

            GroupBox("Commit message") {
                ScrollView {
                    Text(preview.commitMessage.isEmpty ? "(none — you'll commit manually)" : preview.commitMessage)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }.frame(height: 90)
            }

            // Safety + auto-commit banner.
            if preview.nothingToApply {
                EmptyView()
            } else if !preview.messageProblems.isEmpty {
                Label("Commit message is shell-unsafe — it will be opened for manual review instead of auto-committing.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
                ForEach(preview.messageProblems, id: \.self) { p in
                    Text("• \(p)").font(.caption2).foregroundStyle(.secondary)
                }
            } else if autoCommit && !preview.commitMessage.isEmpty {
                Label("Auto-commit is ON — applying will commit & push automatically.",
                      systemImage: "checkmark.seal.fill")
                    .font(.caption).foregroundStyle(.green)
            } else {
                Label("Auto-commit is OFF — you'll be shown the commit sheet after applying.",
                      systemImage: "hand.raised.fill")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                if preview.hasCommitScript {
                    Label("commit.sh bundled", systemImage: "terminal").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button(preview.nothingToApply ? "Close" : "Cancel") { onCancel(); dismiss() }
                if !preview.nothingToApply {
                    Button("Apply \(preview.changedFiles.count) file\(preview.changedFiles.count == 1 ? "" : "s")") { onApply(); dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20).frame(width: 560)
    }
}

// MARK: - Sheets

struct CommitSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var text: String
    let onCommit: (String) -> Void

    // Improvement #3 — live safety feedback in the commit sheet.
    private var problems: [String] { CommitSafety.problems(in: text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commit & Push").font(.title3.bold())
            Text("Commit message").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $text).frame(height: 120)
                .font(.system(.body, design: .monospaced))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(problems.isEmpty ? Color.secondary.opacity(0.3) : .red))
            if problems.isEmpty {
                Label("SAFE for BuildBuddy commit", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
            } else {
                Label("Unsafe characters — fix before pushing:", systemImage: "xmark.circle.fill")
                    .font(.caption).foregroundStyle(.red)
                ForEach(problems, id: \.self) { p in
                    Text("• \(p)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Commit & Push") { onCommit(text); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || !problems.isEmpty)
            }
        }
        .padding(20).frame(width: 480)
    }
}

struct NewBranchSheet: View {
    @Environment(\.dismiss) var dismiss
    let branches: [String]
    let onCreate: (String, String) -> Void
    @State private var name = ""
    @State private var base = "main"
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New branch").font(.title3.bold())
            TextField("e.g. feature/widgets", text: $name)
            Picker("From base", selection: $base) {
                ForEach(branches.isEmpty ? ["main"] : branches, id: \.self) { Text($0) }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create & Push") { onCreate(name, base); dismiss() }
                    .keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20).frame(width: 420)
    }
}

struct PickBranchSheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let branches: [String]
    let onPick: (String) -> Void
    @State private var choice = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            if branches.isEmpty {
                Text("No branches found.").foregroundStyle(.secondary)
            } else {
                Picker("Branch", selection: $choice) {
                    ForEach(branches, id: \.self) { Text($0) }
                }.pickerStyle(.inline).frame(height: 180)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Go") { onPick(choice.isEmpty ? (branches.first ?? "") : choice); dismiss() }
                    .keyboardShortcut(.defaultAction).disabled(branches.isEmpty)
            }
        }
        .padding(20).frame(width: 420)
        .onAppear { choice = branches.first ?? "" }
    }
}

// MARK: - Options (Settings) — every toggle described to the user

struct OptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    private var s: SettingsStore { store.settings }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Options").font(.title2.bold())
                Spacer()
                Button("Reset to defaults") { store.settings.resetToDefaults() }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(16)
            Divider()
            Form {
                Section("Auto commit & push") {
                    Toggle("Auto commit and push after applying a delivery", isOn: binding(\.autoCommitAndPush))
                    Toggle("Push after commit (off = commit only)", isOn: binding(\.pushAfterCommit))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default commit message (used when a drop has no COMMIT_MSG.txt)")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("Default commit message", text: binding(\.defaultCommitMessage))
                    }
                }

                Section("Downloads auto-detect") {
                    Toggle("Watch the Downloads folder for matching delivery zips", isOn: binding(\.watchDownloads))
                    Toggle("Auto-apply a found zip when auto-commit is on", isOn: binding(\.autoApplyFound))
                    HStack {
                        Text("Scan interval")
                        Slider(value: binding(\.downloadsScanSeconds), in: 3...60, step: 1)
                        Text("\(Int(s.downloadsScanSeconds))s").monospacedDigit().frame(width: 40)
                    }
                    Text("Matches a zip whose inner top folder equals the repo name, or whose filename contains the project name.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Branch & pull") {
                    HStack {
                        Text("Default base branch")
                        TextField("main", text: binding(\.defaultBranch)).frame(width: 160)
                    }
                    Toggle("Pull latest before applying a delivery", isOn: binding(\.autoPullBeforeApply))
                    Toggle("Pull when I select a project", isOn: binding(\.autoPullOnSelect))
                }

                Section("Confirmations & safety") {
                    Toggle("Show the preview sheet before applying (off = apply immediately)", isOn: binding(\.confirmBeforeApply))
                    Toggle("Ask before pushing", isOn: binding(\.confirmBeforePush))
                    Toggle("Block shell-unsafe commit messages (playbook rule)", isOn: binding(\.blockUnsafeCommitMessages))
                    Toggle("Confirm before removing a project", isOn: binding(\.confirmBeforeRemoveProject))
                    HStack {
                        Text("Command timeout")
                        Slider(value: binding(\.commandTimeoutSeconds), in: 10...600, step: 10)
                        Text("\(Int(s.commandTimeoutSeconds))s").monospacedDigit().frame(width: 48)
                    }
                    Text("A command that exceeds the timeout is terminated, so the app can never hang.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Workflow extras") {
                    Toggle("Back up changed files before applying (undo point)", isOn: binding(\.backupBeforeApply))
                    Toggle("Open in Xcode after a delivery is applied", isOn: binding(\.openXcodeAfterApply))
                    Toggle("Deploy Worker after a successful push", isOn: binding(\.deployWorkerAfterPush))
                    Toggle("Clear console at the start of each action", isOn: binding(\.clearConsoleOnAction))
                    Toggle("Remember and reselect last project on launch", isOn: binding(\.rememberLastProject))
                }

                Section("Console & feedback") {
                    Toggle("Verbose logging", isOn: binding(\.verboseLogging))
                    Toggle("Monospace console font", isOn: binding(\.monospaceConsole))
                    Toggle("Play a sound when a command finishes", isOn: binding(\.soundOnFinish))
                    Toggle("Dry-run mode (print actions, never write/commit/push)", isOn: binding(\.dryRunMode))
                        .help("Great for testing — shows exactly what BuildBuddy would do without touching anything.")
                }
            }
            .formStyle(.grouped)
        }
    }

    // Small helper to bridge SettingsStore @AppStorage to Toggle/TextField bindings.
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<SettingsStore, T>) -> Binding<T> {
        Binding(get: { store.settings[keyPath: keyPath] },
                set: { store.settings[keyPath: keyPath] = $0 })
    }
}

// MARK: - What's New / Changelog

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What's New in BuildBuddy").font(.title2.bold())
                    Text("You're running v\(BuildBuddyVersion)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Check for Updates") { Task { await store.checkForUpdates() } }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(16)
            if !store.updateStatus.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: store.updateAvailable ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(store.updateAvailable ? .blue : .green)
                    Text(store.updateStatus).font(.caption)
                    Spacer()
                    if store.updateAvailable {
                        Button("Update & Relaunch") { Task { await store.updateAndRelaunch() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(BuildBuddyChangelog) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("v\(entry.version)").font(.headline)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(entry.version == BuildBuddyVersion ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12),
                                                in: Capsule())
                                Text(entry.date).font(.caption).foregroundStyle(.secondary)
                                if entry.version == BuildBuddyVersion {
                                    Text("current").font(.caption2).foregroundStyle(.tint)
                                }
                            }
                            ForEach(entry.highlights, id: \.self) { h in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•").foregroundStyle(.secondary)
                                    Text(h).font(.callout).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 640, height: 560)
    }
}

// MARK: - Instructions (improvement #2 — playbook shipped inside the app)

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("BuildBuddy Delivery Instructions").font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(16)
            Divider()
            ScrollView {
                Text(DeliveryInstructions.text)
                    .font(.system(.body, design: .default))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .frame(width: 720, height: 620)
    }
}

// The full playbook text, embedded so it travels with the app — no loose PDF required.
enum DeliveryInstructions {
    static let text: String = """
BUILDBUDDY DELIVERY INSTRUCTIONS
A reusable playbook for any project — how to package code drops so BuildBuddy applies, commits, and pushes them automatically.

WHO THIS IS FOR
Any chat or assistant preparing code changes delivered through BuildBuddy. It is project-agnostic: wherever you see a placeholder in ANGLE BRACKETS (e.g. <repo-root> or <branch>), substitute the value for the specific project. There are no version-number rules — versioning is each project's decision.

1. WHAT BUILDBUDDY IS AND HOW IT APPLIES A DROP
BuildBuddy takes a single zipped "drop" of changed files, overlays them onto a local git repo, then commits and pushes.

The apply step:
• Unzips the drop and looks for one top-level folder whose contents are repo-root-relative.
• Overlays every file from that folder onto the repo using a copy/sync, excluding COMMIT_MSG.txt (and commit.sh).
• Reads COMMIT_MSG.txt (if present) and uses its contents as the commit message.

The commit step (read carefully):
BuildBuddy builds its commit as a single shell command of the form:
   git add -A && git commit -m "<contents of COMMIT_MSG.txt>" && git push origin "<branch>"
It only escapes double-quotes in the message. Nothing else is escaped. That drives the most important rule (Section 3).

2. DROP FORMAT (THE BUILDBUDDY v2 LAYOUT)
Every drop is a zip with this exact shape:
   <drop>.zip
   └── <repo-root-folder>/        ← exactly ONE top folder
       ├── COMMIT_MSG.txt          ← commit message, at the top-folder root
       ├── commit.sh               ← auto commit+push helper (Section 4)
       └── <path>/<to>/<file>      ← repo-root-relative paths, mirroring the repo

Rules:
• One top folder only; its name matches the repo's root folder.
• Repo-relative paths — a file's path inside the top folder equals its path inside the repo.
• COMMIT_MSG.txt sits at the top-folder root (not in subfolders).
• Ship only genuinely-changed files. Overlaying a stale shared file silently reverts others' work.
• No junk: exclude __MACOSX, .DS_Store, and dotfiles.

Building the zip (from the folder containing the top folder):
   zip -X -r "<drop>.zip" "<repo-root-folder>" -x ".*" -x "__MACOSX*" -x "*/.DS_Store"

3. THE COMMIT-MESSAGE RULE (MOST IMPORTANT)
Because BuildBuddy wraps the message in double-quotes and escapes nothing else, the message must contain NO shell metacharacters. Forbidden in COMMIT_MSG.txt:
• ` (backtick) — runs as command substitution even inside double-quotes.
• $( ) — command substitution.
• $NAME / ${…} — variable expansion inside double-quotes.
• " (double-quote) — closes the message string early.
• \\ (backslash) — interacts badly with shell escaping.
• * and ? — glob wildcards; can expand unexpectedly.
• ... (triple dot) — has caused parse errors; write it out instead.

Write messages in plain prose:
• Describe flags/keys/ranges in words ("git commit dash m", "200 to 299", "notifInbox").
• Plain ASCII only — no smart quotes, em-dashes, or box-drawing characters.
• Structure with simple ALL-CAPS labels and blank lines, not markdown symbols.

NOTE: This app now checks the message for you. The commit sheet shows SAFE / UNSAFE live, and an unsafe bundled message is opened for review instead of auto-committed.

4. AUTOMATIC COMMIT AND PUSH
Two ways to make commit+push automatic — use both for belt-and-suspenders.

Option A — patch BuildBuddy to auto-commit on apply (DONE in this build):
This version commits & pushes automatically at the end of apply when "Auto-commit" is ON for the project (toggle in the header) and the bundled message is SAFE.

Option B — ship commit.sh in every drop (always include this):
An executable commit.sh at the drop's top-folder root commits with "git commit -F COMMIT_MSG.txt", which reads the message verbatim so the shell never parses it. It works even if a message contains a risky character and whether or not BuildBuddy is patched:
   ./commit.sh                         # commit only
   ./commit.sh --push                  # commit, then push current branch
   ./commit.sh --push origin <branch>  # commit, then push to a remote/branch

5. VERIFICATION STANDARD (BEFORE EVERY DROP)
• Parse every changed file with a real parser; zero new errors.
• Balance braces, parentheses, brackets in each changed file.
• Cross-reference audit: for any call/definition pair you touched, confirm BOTH ends exist.
• Changed-files-only: diff against the base export; include exactly what changed.
• Commit-message safety: it must say SAFE.

6. AVOIDING THE MERGE-COLLISION TRAP (SHARED FILES)
The biggest source of recurring "no member X" errors is shipping a full-file replacement of a shared file. Rules:
• Build on the truth — start from a current export of the real repo, not an old snapshot.
• Keep diffs additive on shared files; if you must regenerate one, make it the COMPLETE cumulative version.
• One source of truth per rebuild — reconcile shared files so nothing from prior changes is missing.
• Confirm an export is the live one by checking a known-present and a known-absent marker.

7. WORKING STYLE FOR DELIVERIES
• Deliver completed files only — no partial edits or train-of-thought in the drop.
• Surgical changes — touch only what the task requires.
• One folder, zipped, in the v2 layout.
• Diagnose precisely — read the actual error and code before changing anything.
• No version-number rules unless the project has its own convention.

APPENDIX A — COMMIT-MESSAGE SAFETY CHECK (now built into this app)
Flags: backtick, $( ) command substitution, $NAME/${…} expansion, double-quote, backslash. Must print SAFE before shipping.

APPENDIX B — commit.sh
Include at the drop's top-folder root. Stages everything and commits via "git commit -F COMMIT_MSG.txt" (verbatim), with an optional --push that sets upstream on first push.

APPENDIX C — QUICK CHECKLIST
□ Built from a CURRENT export of the real repo
□ Only genuinely-changed files included
□ Shared files edited additively
□ Every changed file parses with zero new errors; braces balanced
□ Cross-references checked (caller + definition both present)
□ COMMIT_MSG.txt is plain prose and passes the safety check (SAFE)
□ commit.sh included at the top-folder root
□ Zipped in v2 layout (one top folder, repo-relative paths, no junk)
□ Auto-commit ON (Option A) or commit.sh used (Option B)
"""
}

// MARK: - Doctor

struct DoctorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var rows: [ToolRow] = []
    @State private var working = false
    @State private var ghAuth: String = "checking…"   // improvement #8

    struct ToolRow: Identifiable { let id = UUID(); let name: String; let probe: String; var found: String? }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Doctor — dependencies").font(.title2.bold())
                Spacer()
                Text("BuildBuddy v\(BuildBuddyVersion)").font(.caption).foregroundStyle(.secondary)
            }
            Text("Checks the tools BuildBuddy uses. Install the missing ones with one click (uses Homebrew / npm).")
                .font(.caption).foregroundStyle(.secondary)
            ForEach($rows) { $row in
                HStack {
                    Image(systemName: row.found != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(row.found != nil ? .green : .red)
                    Text(row.name).frame(width: 90, alignment: .leading)
                    Text(row.found ?? "not found").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Divider()
            // Improvement #8 — GitHub auth status + one-click login.
            HStack(alignment: .top) {
                Image(systemName: ghAuth.contains("Logged in") ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(ghAuth.contains("Logged in") ? .green : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GitHub auth").fontWeight(.medium)
                    Text(ghAuth).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                }
                Spacer()
                Button("gh auth login") { Task { await store.run("gh auth login --web -h github.com || gh auth login", cwd: nil, label: "gh auth login"); checkGhAuth() } }
            }

            HStack {
                Button("Re-check") { check(); checkGhAuth() }
                Button("Install missing") { Task { await installMissing() } }.disabled(working)
                if working { ProgressView().scaleEffect(0.6) }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20).frame(width: 540)
        .onAppear { check(); checkGhAuth() }
    }

    private func check() {
        rows = [
            .init(name: "git",      probe: "git --version"),
            .init(name: "swift",    probe: "xcrun --find swiftc"),
            .init(name: "gh",       probe: "gh --version"),
            .init(name: "node",     probe: "node --version"),
            .init(name: "wrangler", probe: "npx --yes wrangler --version"),
            .init(name: "brew",     probe: "brew --version"),
        ]
        for i in rows.indices {
            let r = store.syncShell(rows[i].probe, cwd: nil)
            rows[i].found = r.code == 0 ? r.out.split(separator: "\n").first.map(String.init) : nil
        }
    }

    private func checkGhAuth() {
        let r = store.syncShell("gh auth status 2>&1 | head -n 3", cwd: nil)
        let out = r.out.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.isEmpty {
            ghAuth = "gh not installed — install it below, then sign in."
        } else if out.localizedCaseInsensitiveContains("Logged in") {
            ghAuth = "Logged in. " + (out.split(separator: "\n").first.map(String.init) ?? "")
        } else {
            ghAuth = "Not logged in. Click 'gh auth login' to sign in via browser."
        }
    }

    private func installMissing() async {
        working = true; defer { working = false }
        if rows.first(where: { $0.name == "brew" })?.found == nil {
            store.line("Homebrew isn't installed. Opening the official installer in Terminal — follow its prompts, then re-check.")
            _ = await store.run("open -a Terminal", cwd: nil, label: "Open Terminal")
            _ = await store.run("echo 'Run this in Terminal:  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"'", cwd: nil)
            return
        }
        if rows.first(where: { $0.name == "gh" })?.found == nil {
            _ = await store.run("brew install gh", cwd: nil, label: "Install gh")
        }
        if rows.first(where: { $0.name == "node" })?.found == nil {
            _ = await store.run("brew install node", cwd: nil, label: "Install node")
        }
        check(); checkGhAuth()
    }
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - v1.9 New feature views
// ════════════════════════════════════════════════════════════════════════════

// [New 3] Diff viewer — shows the unified diff of pending changes, colorized.
struct DiffView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var diff = "Loading…"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Pending changes — \(store.selected?.name ?? "")").font(.title3.bold())
                Spacer()
                Button("Reload") { Task { diff = await store.pendingDiff() } }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }.padding(16)
            Divider()
            ScrollView {
                Text(colorNote).font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.top, 6)
                Text(diff)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(width: 760, height: 620)
        .task { diff = await store.pendingDiff() }
    }
    private var colorNote: String { "Lines starting with + are additions, - are removals." }
}

// [New 4] Recent commit history.
struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var rows: [Store.CommitRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent commits — \(store.selected?.name ?? "")").font(.title3.bold())
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }.padding(16)
            Divider()
            if rows.isEmpty {
                Text("No commits found.").foregroundStyle(.secondary).padding()
                Spacer()
            } else {
                List(rows) { c in
                    HStack(alignment: .top, spacing: 10) {
                        Text(c.sha).font(.system(.caption, design: .monospaced)).foregroundStyle(.tint)
                            .frame(width: 70, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.subject).font(.callout)
                            Text("\(c.author) · \(c.date)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(c.sha, forType: .string)
                        } label: { Image(systemName: "doc.on.doc") }.buttonStyle(.borderless)
                        .help("Copy SHA")
                    }.padding(.vertical, 2)
                }
            }
        }
        .frame(width: 720, height: 560)
        .task { rows = await store.recentCommits() }
    }
}

// [New 2] Multi-project dashboard — branch, dirty, ahead/behind for every project at a glance.
struct DashboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("All projects").font(.title2.bold())
                Spacer()
                Button("Refresh all") { Task { await store.refreshAll() } }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }.padding(16)
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(store.projects) { p in
                        let snap = store.dashboard[p.id]
                        HStack(spacing: 12) {
                            Image(systemName: store.isFavorite(p) ? "star.fill" : "folder")
                                .foregroundStyle(store.isFavorite(p) ? .yellow : .tint)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.name).fontWeight(.medium)
                                Text(p.path).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if let s = snap {
                                Text(s.branch).font(.caption.monospaced())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                                if s.ahead > 0 { Label("\(s.ahead)", systemImage: "arrow.up").font(.caption2).foregroundStyle(.green) }
                                if s.behind > 0 { Label("\(s.behind)", systemImage: "arrow.down").font(.caption2).foregroundStyle(.orange) }
                                Circle().fill(s.dirty ? Color.orange : Color.green).frame(width: 9, height: 9)
                                    .help(s.dirty ? "Uncommitted changes" : "Clean")
                            } else {
                                ProgressView().scaleEffect(0.5)
                            }
                            Button { store.select(p); dismiss() } label: { Text("Open") }
                                .buttonStyle(.bordered).controlSize(.small)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        Divider()
                    }
                }
            }
        }
        .frame(width: 720, height: 580)
        .task { await store.refreshAll() }
    }
}

// [New 5] Command palette — fuzzy-ish filterable list of actions, ⌘K.
struct CommandPaletteView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let onRun: (String) -> Void
    @State private var query = ""

    struct Cmd: Identifiable { let id: String; let label: String; let icon: String }
    let commands: [Cmd] = [
        .init(id: "pull", label: "Pull latest", icon: "arrow.down.circle"),
        .init(id: "commit", label: "Commit & Push", icon: "arrow.up.circle"),
        .init(id: "fetch", label: "Fetch", icon: "arrow.down.left.circle"),
        .init(id: "diff", label: "View Diff", icon: "doc.text.magnifyingglass"),
        .init(id: "history", label: "History", icon: "clock.arrow.circlepath"),
        .init(id: "dashboard", label: "Dashboard", icon: "square.grid.2x2"),
        .init(id: "stash", label: "Stash", icon: "tray.and.arrow.up"),
        .init(id: "unstash", label: "Unstash", icon: "tray.and.arrow.down.fill"),
        .init(id: "xcode", label: "Open in Xcode", icon: "hammer"),
        .init(id: "github", label: "Open on GitHub", icon: "safari"),
        .init(id: "copysha", label: "Copy current SHA", icon: "number"),
        .init(id: "refreshall", label: "Refresh all projects", icon: "arrow.clockwise.circle"),
        .init(id: "notes", label: "Project notes", icon: "note.text"),
        .init(id: "commitall", label: "Commit all dirty repos", icon: "square.stack.3d.up"),
        .init(id: "doctor", label: "Doctor", icon: "stethoscope"),
        .init(id: "options", label: "Options", icon: "gearshape"),
    ]
    var filtered: [Cmd] {
        query.isEmpty ? commands : commands.filter { $0.label.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Type a command…", text: $query)
                .textFieldStyle(.plain).font(.title3)
                .padding(14)
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filtered) { c in
                        Button {
                            dismiss(); onRun(c.id)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: c.icon).foregroundStyle(.tint).frame(width: 22)
                                Text(c.label)
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 480, height: 420)
    }
}

// [New 7] Per-project notes.
struct NotesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notes — \(store.selected?.name ?? "")").font(.title3.bold())
                Spacer()
                Button("Save") { if let p = store.selected { store.setNote(text, for: p) }; dismiss() }
                    .keyboardShortcut(.defaultAction)
                Button("Close") { dismiss() }
            }.padding(16)
            Divider()
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(8)
        }
        .frame(width: 560, height: 460)
        .onAppear { if let p = store.selected { text = store.note(for: p) } }
    }
}

// [New 8] Commit all dirty repos with one message.
struct CommitAllView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var msg = ""
    private var problems: [String] { CommitSafety.problems(in: msg) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commit all dirty repositories").font(.title3.bold())
            Text("Applies the same commit message to every project that has uncommitted changes, then pushes each.")
                .font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $msg).frame(height: 90)
                .font(.system(.body, design: .monospaced))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(problems.isEmpty ? Color.secondary.opacity(0.3) : .red))
            if !problems.isEmpty {
                ForEach(problems, id: \.self) { Text("• \($0)").font(.caption2).foregroundStyle(.red) }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Commit all") { let m = msg; dismiss(); Task { await store.commitAllDirty(message: m) } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(msg.trimmingCharacters(in: .whitespaces).isEmpty || !problems.isEmpty)
            }
        }
        .padding(20).frame(width: 480)
    }
}


// BuildBuddy starts/stops it, writes its config, reads its live state, and shows
// a pairing QR. The agent and the app share BuildBuddy's project list, so a
// project added here is instantly drivable from the phone.
// ════════════════════════════════════════════════════════════════════════════

extension Notification.Name { static let bbShowRemote = Notification.Name("bbShowRemote") }

// Mirrors the agent's remote-config.json. Persisted to UserDefaults + written to
// disk so the running agent (or next launch) picks it up.
struct RemoteConfig: Codable, Equatable {
    var port: Int = 7842
    var enableLAN: Bool = true
    var enableTailscale: Bool = true
    var enablePublic: Bool = false
    var allowPublic: Bool = false
    var enableRelay: Bool = false
    var relayRepo: String = ""
    var relayPollSeconds: Int = 10
    var smbWatchDir: String = ""
    var smbProjectName: String = ""
    var smbApplySeconds: Int = 6
}

// What the agent writes to remote-state.json while running.
struct RemoteState: Codable {
    struct Addr: Codable, Hashable { let mode: String; let host: String }
    var version: String = ""
    var running: Bool = false
    var port: Int = 7842
    var token: String = ""
    var addresses: [Addr] = []
    var projects: [String] = []
    var relay: Bool = false
    var smbWatch: String = ""
    var public_: Bool = false
    enum CodingKeys: String, CodingKey {
        case version, running, port, token, addresses, projects, relay, smbWatch
        case public_ = "public"
    }
}

@MainActor
final class RemoteAgent: ObservableObject {
    static let shared = RemoteAgent()

    @Published var config: RemoteConfig { didSet { persistAndPush() } }
    @Published var state: RemoteState = RemoteState()
    @Published var isRunning = false
    @Published var lastError = ""

    private var process: Process?
    private var pollTimer: Timer?

    // Paths shared with the agent.
    private var supportDir: URL {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BuildBuddy", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    private var configURL: URL { supportDir.appendingPathComponent("remote-config.json") }
    private var stateURL:  URL { supportDir.appendingPathComponent("remote-state.json") }
    private var tokenURL:  URL { supportDir.appendingPathComponent("remote-token.txt") }

    // The agent script ships next to the app. We resolve it from a few known spots.
    private var agentScriptURL: URL? {
        let fm = FileManager.default
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL { candidates.append(res.appendingPathComponent("buddyd.py")) }
        // Next to the .app bundle (typical for this unsigned, folder-shipped app).
        let appDir = Bundle.main.bundleURL.deletingLastPathComponent()
        candidates.append(appDir.appendingPathComponent("agent/buddyd.py"))
        candidates.append(appDir.appendingPathComponent("buddyd.py"))
        // Saved copy in Application Support (we stage one there on first start).
        candidates.append(supportDir.appendingPathComponent("buddyd.py"))
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }

    var startOnLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: "remoteStartOnLaunch") }
        set { UserDefaults.standard.set(newValue, forKey: "remoteStartOnLaunch") }
    }

    var token: String { (try? String(contentsOf: tokenURL, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? state.token }

    private init() {
        if let data = try? Data(contentsOf: UserDefaults.standard.url(forKey: "remoteConfigURL") ?? URL(fileURLWithPath: "/dev/null")),
           let c = try? JSONDecoder().decode(RemoteConfig.self, from: data) {
            config = c
        } else if let raw = UserDefaults.standard.data(forKey: "remoteConfigBlob"),
                  let c = try? JSONDecoder().decode(RemoteConfig.self, from: raw) {
            config = c
        } else {
            config = RemoteConfig()
        }
        writeConfigFile()
        startPolling()
    }

    private func persistAndPush() {
        if let raw = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(raw, forKey: "remoteConfigBlob")
        }
        writeConfigFile()
        // The agent re-reads config on its heartbeat; nothing else needed.
    }

    private func writeConfigFile() {
        if let raw = try? JSONEncoder().encode(config) { try? raw.write(to: configURL) }
    }

    // Stage a copy of the agent script into Application Support so it survives
    // even if the app folder layout changes, and so we always have a path.
    private func stageScriptIfNeeded() -> URL? {
        guard let src = agentScriptURL else { return nil }
        let dst = supportDir.appendingPathComponent("buddyd.py")
        if src != dst {
            try? FileManager.default.removeItem(at: dst)
            try? FileManager.default.copyItem(at: src, to: dst)
        }
        return FileManager.default.fileExists(atPath: dst.path) ? dst : src
    }

    func start() {
        guard process == nil else { return }
        guard let script = stageScriptIfNeeded() else {
            lastError = "Couldn't find buddyd.py next to the app. Keep the agent folder beside BuildBuddy."
            return
        }
        writeConfigFile()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        var args = ["python3", script.path, "--embedded"]
        if config.allowPublic && config.enablePublic { args.append("--allow-public") }
        p.arguments = args
        p.standardInput = FileHandle.nullDevice
        // Drain output so the pipe never fills; we surface errors via lastError.
        let pipe = Pipe(); p.standardOutput = pipe; p.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { h in
            let d = h.availableData
            if let s = String(data: d, encoding: .utf8), s.lowercased().contains("error") {
                Task { @MainActor in self.lastError = s.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        }
        p.terminationHandler = { _ in
            Task { @MainActor in
                self.process = nil
                self.isRunning = false
            }
        }
        do {
            try p.run()
            process = p
            isRunning = true
            lastError = ""
        } catch {
            lastError = "Couldn't start agent: \(error.localizedDescription). Is Python 3 installed? (xcode-select --install)"
        }
    }

    func stop() {
        guard let p = process else { isRunning = false; return }
        p.terminate()
        let pid = p.processIdentifier
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { kill(-pid, SIGKILL) }
        process = nil
        isRunning = false
        // Clear the running flag in the state file immediately.
        if var s = readState() { s.running = false; if let raw = try? JSONEncoder().encode(s) { try? raw.write(to: stateURL) } }
    }

    func toggle() { isRunning ? stop() : start() }

    func rotateToken() {
        // Remove the token file; agent regenerates on next start.
        let wasRunning = isRunning
        stop()
        try? FileManager.default.removeItem(at: tokenURL)
        if wasRunning { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.start() } }
    }

    private func readState() -> RemoteState? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(RemoteState.self, from: data)
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if let s = self.readState() {
                    self.state = s
                    // Trust the process handle for liveness; state file confirms address info.
                    if self.process == nil { self.isRunning = s.running && (Date().timeIntervalSince1970 - 0) > 0 ? false : self.isRunning }
                }
            }
        }
    }

    // The URL a phone uses for a given address, including the token (so the QR is one-scan).
    func pairURL(for addr: RemoteState.Addr) -> String {
        "buddyremote://pair?host=\(addr.host)&token=\(token)"
    }
    func plainHostLine(for addr: RemoteState.Addr) -> String { addr.host }
}

// Compact header badge: a tappable LED + label showing agent status.
struct RemoteHeaderBadge: View {
    @EnvironmentObject var store: Store
    @ObservedObject var agent = RemoteAgent.shared
    var body: some View {
        Button { NotificationCenter.default.post(name: .bbShowRemote, object: nil) } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(agent.isRunning ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .shadow(color: agent.isRunning ? .green.opacity(0.7) : .clear, radius: 4)
                Image(systemName: "iphone.radiowaves.left.and.right").font(.caption)
                Text(agent.isRunning ? "Remote on" : "Remote off").font(.caption)
            }
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
        }
        .buttonStyle(.plain)
        .help(agent.isRunning ? "iPhone remote is reachable — click to manage" : "Start the iPhone remote")
    }
}

// The full Remote control panel (a sheet).
struct RemotePanelView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var agent = RemoteAgent.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("iPhone Remote", systemImage: "iphone.radiowaves.left.and.right").font(.title2.bold())
                Spacer()
                Toggle(isOn: Binding(get: { agent.isRunning }, set: { _ in agent.toggle() })) {
                    Text(agent.isRunning ? "On" : "Off")
                }.toggleStyle(.switch)
            }
            .padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !agent.lastError.isEmpty {
                        Text(agent.lastError).font(.caption).foregroundStyle(.red)
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // ── Pairing ──────────────────────────────────────────────
                    GroupBox("Pair a phone") {
                        if agent.isRunning && !agent.state.addresses.isEmpty {
                            HStack(alignment: .top, spacing: 16) {
                                QRView(string: agent.pairURL(for: agent.state.addresses[0]))
                                    .frame(width: 150, height: 150)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Scan in the Camera app, or enter manually:").font(.caption).foregroundStyle(.secondary)
                                    ForEach(agent.state.addresses, id: \.self) { a in
                                        HStack {
                                            Text(a.mode).font(.caption.bold()).frame(width: 78, alignment: .leading)
                                            Text(a.host).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                                        }
                                    }
                                    HStack {
                                        Text("Token").font(.caption.bold()).frame(width: 78, alignment: .leading)
                                        Text(agent.token).font(.system(.caption, design: .monospaced)).textSelection(.enabled).lineLimit(1)
                                    }
                                    Button("Rotate token") { agent.rotateToken() }.font(.caption)
                                }
                            }
                        } else if agent.isRunning {
                            Text("Starting… looking up addresses.").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Turn the remote On to show pairing details.").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    // ── Reach modes ─────────────────────────────────────────
                    GroupBox("How the phone reaches this Mac") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Same Wi-Fi (LAN)", isOn: $agent.config.enableLAN)
                            Toggle("Tailscale (from anywhere, no open ports)", isOn: $agent.config.enableTailscale)
                            HStack {
                                Text("Tailscale status:").font(.caption).foregroundStyle(.secondary)
                                Text(agent.state.addresses.contains { $0.mode == "Tailscale" } ? "connected ✓" : "not detected")
                                    .font(.caption)
                            }
                            Divider()
                            Toggle("Public (router port-forward) — advanced", isOn: $agent.config.enablePublic)
                            if agent.config.enablePublic {
                                Toggle("I understand the risk; allow public binding", isOn: $agent.config.allowPublic)
                                    .font(.caption)
                                Text("A leaked token becomes remote code execution on this Mac. Forward TCP \(agent.config.port) only while needed; rotate the token after. Restart the remote to apply.")
                                    .font(.caption2).foregroundStyle(.orange)
                            }
                            Divider()
                            Toggle("Relay via a private GitHub repo (no inbound)", isOn: $agent.config.enableRelay)
                            if agent.config.enableRelay {
                                HStack {
                                    Text("Repo").font(.caption).frame(width: 50, alignment: .leading)
                                    TextField("owner/name", text: $agent.config.relayRepo).font(.caption)
                                }
                                Text("Triggers predefined jobs only. See shortcut/RELAY_SETUP.md. Restart to apply.")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }.padding(6)
                    }

                    // ── SMB drop-folder ─────────────────────────────────────
                    GroupBox("SMB drop-folder (apply a delivery from the phone)") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("/Users/you/Shared/BuildBuddyDrop", text: $agent.config.smbWatchDir).font(.caption)
                                Button("Choose…") { pickWatchDir() }.font(.caption)
                            }
                            HStack {
                                Text("Apply to project").font(.caption).frame(width: 110, alignment: .leading)
                                TextField("(blank = first project)", text: $agent.config.smbProjectName).font(.caption)
                            }
                            Text("Share this folder over SMB (System Settings → General → Sharing → File Sharing). Drop a delivery .zip into it from the iPhone Files app; BuildBuddy applies it the same way the Apply button does, then writes a result file beside it. Restart the remote to apply changes.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }.padding(6)
                    }

                    Toggle("Start the remote automatically when BuildBuddy launches", isOn: Binding(
                        get: { agent.startOnLaunch }, set: { agent.startOnLaunch = $0 }))
                        .font(.caption)

                    Text("Changes to reach modes, relay, and SMB take effect after you toggle the remote Off then On.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(16)
            }

            Divider()
            HStack {
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
                Spacer()
                if agent.isRunning {
                    Button("Restart remote") { agent.stop(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { agent.start() } }
                }
            }.padding(12)
        }
    }

    private func pickWatchDir() {
        let panel = NSOpenPanel()
        panel.title = "Choose the SMB drop-folder"
        panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { agent.config.smbWatchDir = url.path }
    }
}

// Minimal QR generator using CoreImage (no extra dependencies).
import CoreImage
import CoreImage.CIFilterBuiltins
struct QRView: View {
    let string: String
    var body: some View {
        if let img = Self.qr(string) {
            Image(nsImage: img).interpolation(.none).resizable().scaledToFit()
                .background(Color.white).cornerRadius(6)
        } else {
            RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.2))
                .overlay(Text("QR").foregroundStyle(.secondary))
        }
    }
    static func qr(_ s: String) -> NSImage? {
        let ctx = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(s.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: scaled.extent.width, height: scaled.extent.height))
    }
}
