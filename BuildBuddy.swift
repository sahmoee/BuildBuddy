// BuildBuddy.swift — v2.0 "Aurora" — a native macOS control panel for your
// Xcode + GitHub workflow across multiple projects.
//
// Single-file SwiftUI app, compiled into a real .app by the build/launch commands.
// v2.0 is a ground-up redesign: an all-new glass interface with fluid animations,
// light & dark themes, project-scoped commits with automatic cache clearing,
// a per-project Clean tool, and a Sync & Learn engine that snapshots every good
// build so new files are never missed and regressions are caught before commit.

import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers


// ===== Models =====

let BuildBuddyVersion = "2.0"

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let highlights: [String]
}

let BuildBuddyChangelog: [ChangelogEntry] = [
    ChangelogEntry(version: "2.0", date: "2026-07-25", highlights: [
        "Complete redesign - Aurora. Nothing looks the same: a new glass interface with a soft aurora backdrop, monogram project avatars, a redesigned flow card, tile actions with gentle hover lift, a refreshed console drawer, and smooth spring transitions throughout. Full light and dark themes with an in-app switcher, plus a Reduce motion option.",
        "Project-scoped commits: BuildBuddy now verifies it is at the selected project's repo root before staging, and automatically excludes any other registered project nested inside it - files from other projects can never ride along in a commit.",
        "Commits auto-clear caches: after every commit the project's status cache is invalidated and re-read fresh, stale delivery temp folders are removed, and old apply backups are pruned to the most recent ten.",
        "New Clean Project tool: one click scans the selected project for build artifacts (.build, build, DerivedData, object files, logs, .DS_Store and friends) with a dry-run preview before anything is deleted. Clean folder, Clean Downloads and Clean build files all remain.",
        "New Sync and Learn engine: BuildBuddy keeps a per-project manifest of every file. Sync scan surfaces new files and folders since the last good build so nothing is forgotten; the regression guard warns before a commit if previously present files went missing or a source file shrank drastically; and every successful commit teaches the baseline, so the app learns from each build.",
        "Recipe Studio removed - BuildBuddy is 100 percent focused on the build workflow.",
    ]),
    ChangelogEntry(version: "1.19", date: "2026-07-16", highlights: [
        "New Deploy website instructions: Instructions now has a third document, Deploy website, covering the whole path for a static site (like sowensstudios.com) from creating a GitHub repo, to connecting Netlify so pushes auto-publish, to pointing the domain and getting HTTPS — then the everyday update loop where BuildBuddy itself is the deploy button (edit files, click Next, the site goes live). Includes verification steps, troubleshooting, and quick checklists.",
        "The new document is fully exportable: Copy and Save .md / .txt now include all three playbooks (Delivery format, Build & Version standard, and Deploy website).",
        "No change to commit, apply, or push behavior — deploying a website is just BuildBuddy's normal commit-and-push against a Netlify-connected site repo, and this build documents how to set that up and use it.",
    ]),
    ChangelogEntry(version: "1.18", date: "2026-07-03", highlights: [
        "Streamlined the main flow: the pop-up Commit and Commit & Push buttons are gone. Instead there's a single Next button beside the progress bar that does the next sensible thing — apply a detected delivery, then commit (and push if connected) — and shows Finished when there's nothing left to do.",
        "The progress bar now lives in the footer beside Next and is always there while the console is collapsed, so you can see activity at a glance without opening the console.",
        "New Clean Downloads button: erase the delivery zips (and their extracted folders) that pile up in your Downloads folder, with a choice of zips-only or zips-plus-folders.",
        "New Check Stale Files scan: flags stale builds (compiled artifacts older than your latest source), duplicate filenames whose contents differ, and untracked files you may have missed — with a one-click commit for the untracked ones.",
        "Continued the Apple-style refresh: refined the commit field and footer, cleaner cards and spacing throughout.",
    ]),
    ChangelogEntry(version: "1.17", date: "2026-06-29", highlights: [
        "Offline and local-only repos are now first-class: local git (commit, branch, history, diff) always works, with no GitHub required. When a repo has no remote, BuildBuddy hides the push/pull actions and shows a Local only badge instead.",
        "New Connect to GitHub helper: when a repo has no remote, a guided sheet walks you through connecting it — pick the GitHub CLI path (with Run for me buttons if gh is installed) or the browser path (open github.com/new, paste the URL, and BuildBuddy wires up the remote and first push). Every command is copyable if you'd rather run it yourself.",
        "Refreshed, more elegant interface: redesigned action buttons with clearer icons and hover feedback, labelled categories (Git, Version & Build, Delivery, Tools), a translucent sidebar, and a header that shows at a glance whether you're connected to GitHub or working locally.",
        "Better resizing: a smaller minimum window size, a resizable sidebar, and a scrollable main area so everything stays usable whether the window is large or small.",
    ]),
    ChangelogEntry(version: "1.16", date: "2026-06-28", highlights: [
        "New Standardize this app button: detects how each app stores its version and build numbers (Xcode project settings, Info.plist, or both) and brings it onto the shared scheme in one click. It writes to every place the numbers live, and is smart enough to skip the reset if an app is already standardized — so it never wipes your progress.",
        "Version and build changes now write to both the Xcode project (MARKETING_VERSION / CURRENT_PROJECT_VERSION) and the Info.plist (CFBundleShortVersionString / CFBundleVersion) when both exist, keeping every target and the in-app display in lockstep.",
        "Every version or build change now records a timestamped What's New entry (MM:DD:YY HH:MM) automatically, prepended to the app's existing changelog (CHANGELOG.md, WHATS_NEW.md, or created if none exists).",
        "Instructions updated with the dual-location rules, the timestamped changelog requirement, and a note reconciling the older per-app auto_increment_build / bump_version scripts.",
    ]),
    ChangelogEntry(version: "1.15", date: "2026-06-28", highlights: [
        "Console is now hidden by default with a Show Console button, and a progress bar appears while work runs when the console is closed. Extended-use slowdowns are fixed: console output is tightly capped and trimmed cheaply so it never bogs the UI down.",
        "New inline commit bar: an editable commit message that auto-fills from your changes, with separate Commit and Commit & Push buttons — no more typing a message every time.",
        "Simplified the buttons: switch, new, and merge branch (plus copy SHA) are combined into one Branches sheet; a new Version & Build section bumps version or build with one click.",
        "Standardized version and build numbering across all apps: CFBundleShortVersionString is the VERSION (small changes/fixes), CFBundleVersion is the BUILD (big features/changes). Bump either from BuildBuddy, reset any app to the 1.0 / build 1 baseline, and read the full standard in Instructions — which can now be exported as Markdown, plain text, or copied to the clipboard.",
    ]),
    ChangelogEntry(version: "1.14", date: "2026-06-27", highlights: [
        "Back to a single self-hosted file: BuildBuddy is once again one BuildBuddy.swift compiled by the launcher script, dropping the Xcode project, Sparkle, code-signing and notarization ceremony. Simpler to host and update yourself.",
        "Self-update restored to the git-pull + recompile flow: Check for Updates pulls the BuildBuddy repo, and Update & Relaunch rebuilds through the launcher because the source is now newer than the binary.",
        "Slimmed down: removed the multi-project dashboard, command palette, per-project notes, favorites, the menu-bar extra, scheduled background auto-pull, the multi-zip queue, and stash/unstash — keeping BuildBuddy focused on git and applying deliveries. Everything core stays: clean folder, push recovery, pause-all-auto-push, folder monitoring, clean build files, apply history/undo, diff, commit history, and commit-all-dirty.",
    ]),
    ChangelogEntry(version: "1.13", date: "2026-06-27", highlights: [
        "(Superseded) Briefly explored Sparkle auto-update and Direct Distribution for an Xcode build; reverted in 1.14 back to the single-file, self-hosted approach.",
    ]),
    ChangelogEntry(version: "1.12", date: "2026-06-27", highlights: [
        "Removed the iPhone Remote feature entirely (the on-device agent, its scripts, and the in-app panel). This also removes the background process that was pushing concurrently and reverting the remote — the push-divergence problem is gone at the source.",
        "New Clean folder action: wipe a designated folder completely, or delete only files matching a project's patterns, with a dry-run preview and a typed confirmation before anything is removed.",
    ]),
    ChangelogEntry(version: "1.11", date: "2026-06-27", highlights: [
        "Push recovery: when a push is rejected as non-fast-forward, BuildBuddy now recovers automatically by fetching and force-pushing your local over the remote (force-with-lease, then a plain force if that reports stale info). Your local commits are never altered — only the remote is overwritten. Toggle it in Options under Pushing.",
        "Pause all auto-push: a master switch that makes BuildBuddy commit locally but never touch the remote. Combined with removing the background Remote agent, this fixes the remote rolling back to older commits — there is now only one thing that ever pushes.",
        "Folder monitoring: point BuildBuddy at extra folders to watch for delivery zips (besides Downloads), and at folders to scan for lingering build files.",
        "Clean build files: a new action (and optional on-launch sweep) removes stale .build, build.log, old compiled app copies and similar from the app's parent folder, while never touching BuildBuddy.swift, the launcher, the running app, or git data.",
    ]),
    ChangelogEntry(version: "1.10", date: "2026-06-26", highlights: [
        "Apply history & undo log: every applied delivery is recorded (files, commit SHA, timestamp). Open Apply history to review them and one-click Undo restores the files a delivery overwrote, from the backup taken at apply time.",
        "Scheduled auto-pull: optionally pull the selected project (or every project) on a timer. It only fast-forwards and is skipped while another action runs.",
        "Multi-zip queue: drop several delivery zips on the console at once (or add them in the Delivery queue) and apply them in sequence.",
        "UI/UX pass: status dots in the sidebar, a collapsible and drag-resizable console, toast notifications, accent-color theming, grouped action buttons, colorized diff viewer, and a richer welcome screen.",
    ]),
    ChangelogEntry(version: "1.9.1", date: "2026-06-25", highlights: [
        "Auto-cleanup after a delivery: once a delivery actually applies, BuildBuddy deletes the extracted temp folder AND the original .zip. Skipped or already-applied deliveries keep their zip so you can retry.",
        "Two new options control this (both on by default): delete the original zip after a successful apply, and delete the extracted folder after applying. Dry-run mode never deletes anything.",
    ]),
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
        "Self-update: a Check for Updates button pulls the latest BuildBuddy from GitHub and relaunches via the launcher so it rebuilds — no more applying a drop to update the app itself.",
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
    var deleteZipAfterApply: Bool        // delete the original delivery .zip after a successful apply
    var deleteExtractedAfterApply: Bool  // delete the temp extracted folder after apply (always safe)
    var forcePushOnReject: Bool          // on non-ff rejection, fetch + force-with-lease (then --force)
    var pauseAllAutoPush: Bool           // master kill switch: never auto-push anywhere

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
        dryRunMode: false,
        deleteZipAfterApply: true,
        deleteExtractedAfterApply: true,
        forcePushOnReject: true,
        pauseAllAutoPush: false
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
    @AppStorage("deleteZipAfterApply")      var deleteZipAfterApply = AppSettings.default.deleteZipAfterApply
    @AppStorage("deleteExtractedAfterApply") var deleteExtractedAfterApply = AppSettings.default.deleteExtractedAfterApply
    @AppStorage("forcePushOnReject")        var forcePushOnReject = AppSettings.default.forcePushOnReject
    @AppStorage("pauseAllAutoPush")         var pauseAllAutoPush = AppSettings.default.pauseAllAutoPush
    // v1.10 UI: accent color theming + console height + collapse + grid grouping.
    @AppStorage("accentChoice")             var accentChoice = "blue"
    @AppStorage("consoleHeight")            var consoleHeight = 220.0
    @AppStorage("consoleCollapsed")         var consoleCollapsed = false
    @AppStorage("groupActionGrid")          var groupActionGrid = true
    // v1.11 — folder monitoring + build cleanup.
    // Newline-separated absolute paths BuildBuddy also scans for delivery zips (besides Downloads).
    @AppStorage("extraWatchFolders")        var extraWatchFolders = ""
    // Newline-separated folders to scan for lingering BuildBuddy build artifacts to clean.
    // Defaults to the app's own parent folder at runtime if left blank.
    @AppStorage("buildCleanupFolders")      var buildCleanupFolders = ""
    @AppStorage("cleanBuildOnLaunch")       var cleanBuildOnLaunch = false
    // v2.0 "Aurora" — appearance, motion, and the Sync & Learn engine.
    @AppStorage("themeChoice")              var themeChoice = "system"   // system | light | dark
    @AppStorage("reduceMotion")             var reduceMotion = false     // calm down all animations
    @AppStorage("regressionGuard")          var regressionGuard = true   // warn before commit on missing/shrunk files
    @AppStorage("autoLearnOnCommit")        var autoLearnOnCommit = true // update the project baseline after each commit
    @AppStorage("syncScanOnSelect")         var syncScanOnSelect = true  // surface new files when selecting a project
    @AppStorage("autoClearCachesOnCommit")  var autoClearCachesOnCommit = true // clear caches + prune backups after commit

    // The app-wide color scheme override resolved from themeChoice.
    var colorSchemeOverride: ColorScheme? {
        switch themeChoice {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

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
        deleteZipAfterApply = d.deleteZipAfterApply; deleteExtractedAfterApply = d.deleteExtractedAfterApply
        forcePushOnReject = d.forcePushOnReject; pauseAllAutoPush = d.pauseAllAutoPush
        accentChoice = "blue"; consoleHeight = 220.0; consoleCollapsed = false; groupActionGrid = true
        themeChoice = "system"; reduceMotion = false
        regressionGuard = true; autoLearnOnCommit = true; syncScanOnSelect = true
        autoClearCachesOnCommit = true
    }

    // Map the saved accent choice to a Color (v1.10 theming).
    var accentColor: Color {
        switch accentChoice {
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
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

// MARK: - Apply history (records every delivery applied, for the undo log)

struct ApplyRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var projectPath: String       // which repo it was applied to
    var projectName: String
    var fileCount: Int            // number of files changed
    var files: [String]           // repo-relative paths that were applied
    var commitMessage: String
    var commitSHA: String?        // the resulting commit (if it was committed)
    var backupDir: String?        // path to the file-copy backup, enabling undo
    var zipName: String?          // original delivery zip filename (informational)
}

enum HistoryStore {
    static var file: URL { Persist.dir.appendingPathComponent("apply_history.json") }
    static func load() -> [ApplyRecord] {
        guard let data = try? Data(contentsOf: file),
              let list = try? JSONDecoder().decode([ApplyRecord].self, from: data) else { return [] }
        return list
    }
    static func save(_ list: [ApplyRecord]) {
        // Keep history bounded to the most recent 200 entries.
        let trimmed = Array(list.suffix(200))
        if let data = try? JSONEncoder().encode(trimmed) { try? data.write(to: file) }
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

// ===== Store =====

@MainActor
final class Store: ObservableObject {
    @Published var projects: [Project] = Persist.load()
    @Published var selectionID: Project.ID?
    @Published var console: String = "Welcome to BuildBuddy.\nAdd a project (drag a repo folder into the sidebar, or click +), then use the buttons.\nNew here? Click Instructions for the delivery playbook.\n\n"
    @Published var busy = false
    @Published var branch: String = "—"
    @Published var branches: [String] = []
    @Published var statusLine: String = ""
    // Offline/local support: whether the selected repo has an 'origin' remote, and its URL.
    // When there's no remote, the UI hides push/pull-from-remote and offers a Connect helper.
    @Published var hasRemote: Bool = true
    @Published var remoteURL: String = ""
    @Published var isGitRepo: Bool = true
    @Published var lastResult: String = ""        // improvement #6 — ✅/❌ summary line

    // Freeze-fix support.
    let settings = SettingsStore()
    @Published var canCancel = false              // drives the Cancel button in the UI
    private var currentProcess: Process?          // the live child process, so we can kill it
    @Published var seenDownloadZips: Set<String> = []   // de-dupe Downloads auto-detect

    // ── "Next" workflow state ────────────────────────────────────────────────────
    // Drives the single Next button next to the progress bar. Instead of separate popups, Next does
    // the next sensible thing: apply a detected delivery, else commit (and push) pending changes,
    // else report Finished.
    enum NextStep: Equatable {
        case applyDelivery(String)   // a delivery zip is ready to apply (filename shown)
        case commit                  // uncommitted changes to commit (and push if remote)
        case finished                // nothing to do
        var title: String {
            switch self {
            case .applyDelivery(let name): return "Apply \(name)"
            case .commit: return "Commit changes"
            case .finished: return "Finished"
            }
        }
        var systemImage: String {
            switch self {
            case .applyDelivery: return "tray.and.arrow.down.fill"
            case .commit: return "checkmark.circle.fill"
            case .finished: return "checkmark.seal.fill"
            }
        }
    }
    @Published var pendingDeliveryZip: URL? = nil    // a detected, not-yet-applied delivery

    // v1.10 — apply history / undo log.
    @Published var history: [ApplyRecord] = HistoryStore.load()

    // v1.10 — toast notifications (auto-dismissing banners).
    struct Toast: Identifiable { let id = UUID(); let text: String; let kind: Kind; enum Kind { case success, error, info } }
    @Published var toasts: [Toast] = []
    func toast(_ text: String, _ kind: Toast.Kind = .info) {
        let t = Toast(text: text, kind: kind)
        toasts.append(t)
        // Auto-dismiss after 3.5s.
        let id = t.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.toasts.removeAll { $0.id == id }
        }
    }

    // PERF (v1.9): per-project status cache so re-selecting a project paints instantly while a
    // fresh read happens in the background. Keyed by project id; survives for the app session.
    struct CachedStatus { var branch: String; var branches: [String]; var statusLine: String }
    static var statusCache: [Project.ID: CachedStatus] = [:]

    var selected: Project? { projects.first { $0.id == selectionID } }

    // Console performance: heavy/extended use used to get clunky because every git command
    // appended to one ever-growing String that SwiftUI re-diffs and re-renders in full. We now
    // (1) route ALL writes through one append, (2) keep a hard cap, and (3) trim using utf16
    // count (cheap) instead of String.count (which walks grapheme clusters every time).
    private let consoleHardCap = 40_000      // characters kept in the visible console
    private let consoleTrimTo  = 30_000      // trim target when the cap is exceeded

    func append(_ s: String) {
        console += s
        if console.utf16.count > consoleHardCap {
            console = "…(earlier output trimmed)…\n" + String(console.suffix(consoleTrimTo))
        }
    }
    func line(_ s: String)   { append("\n\(s)\n") }   // route through the bounded append
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
        echo '@@BB_REMOTE@@'; git remote get-url origin 2>/dev/null; \
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

        let st = section("@@BB_STATUS@@", "@@BB_REMOTE@@")
        statusLine = st.isEmpty ? "clean" : "uncommitted changes"

        // Remote detection for offline/local support.
        let rurl = section("@@BB_REMOTE@@", "@@BB_END@@").trimmingCharacters(in: .whitespacesAndNewlines)
        remoteURL = rurl
        hasRemote = !rurl.isEmpty && !rurl.lowercased().contains("fatal")
        isGitRepo = !branch.contains("(no git)")

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
    // v1.9 — IMPROVEMENTS to existing features
    // ════════════════════════════════════════════════════════════════════════════

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
            // v2.0 — the bulk commit uses the same project-scoped staging as a single commit,
            // so nested sibling projects are excluded here too.
            let c = await run(scopedStageAndCommitCommand(for: p, safeMessage: safe), cwd: p.url, label: "Commit \(p.name)")
            if c.code == 0, !c.out.contains("BB_NOTHING_TO_COMMIT") {
                let br = (await runQuiet("git rev-parse --abbrev-ref HEAD 2>/dev/null", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !br.isEmpty, !br.contains(" ") { await pushWithRecovery(branch: br, cwd: p.url) }
                await postCommitMaintenance(for: p, committed: true)
            }
            done += 1
        }
        lastResult = done == 0 ? "Nothing dirty to commit." : "✅ Committed \(done) repo(s)"
        line(lastResult)
    }

    // ════════════════════════════════════════════════════════════════════════════
    // v1.10 — Apply history / undo log
    // ════════════════════════════════════════════════════════════════════════════

    // Record an applied delivery. backupDir (if any) is what makes undo possible.
    func recordApply(project: Project, files: [String], message: String, sha: String?, backupDir: URL?, zipName: String?) {
        let rec = ApplyRecord(date: Date(),
                              projectPath: project.path,
                              projectName: project.name,
                              fileCount: files.count,
                              files: files,
                              commitMessage: message,
                              commitSHA: sha,
                              backupDir: backupDir?.path,
                              zipName: zipName)
        history.append(rec)
        HistoryStore.save(history)
    }

    // Undo a delivery by restoring the backup it made. If the apply was committed, this creates
    // a NEW commit that reverts the files (we don't rewrite history). If the backup is gone, we
    // explain rather than guess.
    func undoApply(_ rec: ApplyRecord) async {
        guard let backupPath = rec.backupDir, FileManager.default.fileExists(atPath: backupPath) else {
            line("⚠️ No backup is available for this delivery — can't auto-undo. (Backups are made only when 'Back up before applying' is on, and may have been cleaned up.)")
            toast("No backup to undo from", .error)
            return
        }
        guard let p = projects.first(where: { $0.path == rec.projectPath }) else {
            line("⚠️ The project for this history entry isn't in BuildBuddy anymore.")
            return
        }
        line("Undoing delivery from \(DateFormatter.bbStamp.string(from: rec.date)) — restoring \(rec.fileCount) file(s) from backup…")
        // Copy the backed-up files back over the repo.
        _ = await run("/usr/bin/rsync -a \(Sh.q(backupPath))/ \(Sh.q(p.path))/", cwd: nil, label: "Restore backup")
        await refresh()
        toast("Restored \(rec.fileCount) file(s) from backup", .success)
        line("✓ Restored. Review the changes and commit if you want to keep the revert.")
    }

    func clearHistory() {
        history.removeAll()
        HistoryStore.save(history)
        toast("History cleared", .info)
    }

    // ════════════════════════════════════════════════════════════════════════════
    // v1.10 — Scheduled auto-pull
    // ════════════════════════════════════════════════════════════════════════════

    // (Scheduled background auto-pull was removed — it was a background writer that could surprise
    // you. Pull is now always user-initiated, plus the optional pull-before-apply / pull-on-select.)

    // ════════════════════════════════════════════════════════════════════════════
    // v1.11 — Folder monitoring + lingering build-file cleanup
    // ════════════════════════════════════════════════════════════════════════════

    // Parse a newline-separated list of folder paths into existing directory URLs.
    static func folderList(_ raw: String) -> [URL] {
        raw.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { ($0 as NSString).expandingTildeInPath }
            .filter { var isDir: ObjCBool = false; return FileManager.default.fileExists(atPath: $0, isDirectory: &isDir) && isDir.boolValue }
            .map { URL(fileURLWithPath: $0) }
    }

    // The folders BuildBuddy scans for delivery zips: always Downloads, plus any extras.
    var watchFolders: [URL] {
        var dirs = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        dirs.append(contentsOf: Self.folderList(settings.extraWatchFolders))
        return dirs
    }

    // The app's own parent folder (where BuildBuddy.swift / the .app / .build live).
    var appParentFolder: URL {
        // Bundle path → .app's parent; in dev the source dir. Fall back to ~/Documents/BuildBuddy.
        if let bundleParent = Bundle.main.bundleURL.deletingLastPathComponent() as URL?,
           FileManager.default.fileExists(atPath: bundleParent.path) {
            return bundleParent
        }
        return URL(fileURLWithPath: ("~/Documents/BuildBuddy" as NSString).expandingTildeInPath)
    }

    // Names/patterns considered "lingering BuildBuddy build artifacts" — safe to remove.
    // These are produced by the launcher's compile step and by stale app copies, NOT source.
    private static let buildArtifactNames: Set<String> = [
        ".build", "build.log", "BuildBuddy.dSYM", ".DS_Store"
    ]
    private static let buildArtifactSuffixes = [".o", ".swiftmodule", ".swiftdoc"]

    // Scan the configured cleanup folders (or the app's parent by default) and remove lingering
    // build artifacts. NEVER deletes BuildBuddy.swift, the launcher, the running .app, or git data.
    @discardableResult
    func cleanLingeringBuildFiles(dryRun: Bool = false) async -> Int {
        let folders = settings.buildCleanupFolders.isEmpty ? [appParentFolder] : Self.folderList(settings.buildCleanupFolders)
        let runningAppPath = Bundle.main.bundleURL.path
        var removed = 0
        let fm = FileManager.default
        line("🧹 Scanning \(folders.count) folder(s) for lingering BuildBuddy build files…")
        for folder in folders {
            guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { continue }
            for item in items {
                let name = item.lastPathComponent
                // Protect critical files no matter what.
                if name == "BuildBuddy.swift" || name.hasSuffix(".command") || name == ".git" { continue }
                if item.path == runningAppPath { continue }   // never delete the running app

                let isArtifactName = Self.buildArtifactNames.contains(name)
                let isArtifactSuffix = Self.buildArtifactSuffixes.contains { name.hasSuffix($0) }
                // Stale compiled app copies: a *.app that isn't the one currently running.
                let isStaleApp = name.hasSuffix(".app") && item.path != runningAppPath && name.contains("BuildBuddy")

                guard isArtifactName || isArtifactSuffix || isStaleApp else { continue }
                if dryRun {
                    line("   would remove: \(item.path)")
                    removed += 1
                } else {
                    do { try fm.removeItem(at: item); line("   removed: \(name)"); removed += 1 }
                    catch { line("   ⚠️ couldn't remove \(name): \(error.localizedDescription)") }
                }
            }
        }
        let verb = dryRun ? "Would remove" : "Removed"
        line("✓ \(verb) \(removed) lingering item(s).")
        toast("\(verb) \(removed) build file\(removed == 1 ? "" : "s")", removed > 0 ? .success : .info)
        return removed
    }

    // ── Clean the Downloads folder ───────────────────────────────────────────────
    // Erase delivery zips and their extracted folders that pile up in ~/Downloads. By default it
    // targets .zip files and any folder named "BuildBuddy" (the extract layout), plus common junk.
    // Everything routes through the guarded cleaner; the UI asks for confirmation first.
    @discardableResult
    func cleanDownloads(zipsOnly: Bool, dryRun: Bool) async -> Int {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: downloads, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            line("Couldn't read \(downloads.path)."); toast("Can't read Downloads", .error); return 0
        }
        line("🧹 Scanning Downloads for delivery leftovers…")
        var removed = 0
        for item in items {
            let name = item.lastPathComponent
            if name.hasPrefix(".") && name != ".DS_Store" { continue }   // leave dotfiles (except junk)
            let isZip = name.lowercased().hasSuffix(".zip")
            let isExtractFolder = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                && (name == "BuildBuddy" || name.hasSuffix(" folder") || name.hasPrefix("untitled"))
            let isJunk = name == ".DS_Store"
            let target = zipsOnly ? (isZip || isJunk) : (isZip || isExtractFolder || isJunk)
            guard target else { continue }
            if dryRun { line("   would remove: \(name)"); removed += 1 }
            else {
                do { try fm.removeItem(at: item); line("   removed: \(name)"); removed += 1 }
                catch { line("   ⚠️ couldn't remove \(name): \(error.localizedDescription)") }
            }
        }
        // Forget cleared zips so the Downloads auto-detect will notice a future same-named zip.
        if !dryRun { seenDownloadZips.removeAll() }
        let verb = dryRun ? "Would remove" : "Cleaned"
        line("✓ \(verb) \(removed) item(s) from Downloads.")
        toast("\(verb) \(removed) item\(removed == 1 ? "" : "s")", removed > 0 ? .success : .info)
        return removed
    }

    // ── Stale-file / integrity scan ──────────────────────────────────────────────
    // Surfaces problems that a normal git status can miss:
    //   • STALE BUILDS: compiled artifacts (.o, .build, DerivedData, *.app) older than the newest
    //     source file — i.e. the build predates your latest edits.
    //   • DUPLICATE NAMES: files with the same name in different folders whose contents differ
    //     (a classic "which one is real?" trap).
    //   • UNTRACKED / MISSED: files git isn't tracking that aren't covered by .gitignore, which are
    //     easy to forget to commit.
    struct StaleReport {
        var staleBuilds: [String] = []
        var duplicateNames: [String] = []
        var missedFiles: [String] = []
        var newestSource: String = ""
        var isEmpty: Bool { staleBuilds.isEmpty && duplicateNames.isEmpty && missedFiles.isEmpty }
    }

    func scanStaleFiles(for p: Project) async -> StaleReport {
        var report = StaleReport()

        // 1) Newest source mtime vs build-artifact mtimes.
        let newestSrc = (await runQuiet("find . -type f \\( -name '*.swift' -o -name '*.h' -o -name '*.m' -o -name '*.c' -o -name '*.cpp' \\) -not -path '*/.build/*' -not -path '*/build/*' -not -path '*/DerivedData/*' -not -path '*/.git/*' -newer /dev/null -printf '%T@ %p\\n' 2>/dev/null | sort -rn | head -1", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
        var newestSrcEpoch: Double = 0
        if let first = newestSrc.split(separator: " ").first, let e = Double(first) {
            newestSrcEpoch = e
            report.newestSource = newestSrc.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
        }
        if newestSrcEpoch > 0 {
            // Build artifacts newer-check: list artifacts OLDER than newest source.
            let arts = (await runQuiet("find . \\( -name '*.o' -o -name '*.app' -o -path '*/.build/*' -o -path '*/DerivedData/*' -o -path '*/build/*' \\) -prune -printf '%T@ %p\\n' 2>/dev/null | sort -n | head -40", cwd: p.url))
            for row in arts.split(separator: "\n") {
                let parts = row.split(separator: " ", maxSplits: 1)
                guard parts.count == 2, let e = Double(parts[0]) else { continue }
                if e < newestSrcEpoch {
                    report.staleBuilds.append(String(parts[1]))
                }
            }
        }

        // 2) Duplicate file names whose contents differ (compare md5 per basename).
        let dupScan = (await runQuiet("find . -type f -not -path '*/.git/*' -not -path '*/.build/*' -not -path '*/build/*' -not -path '*/DerivedData/*' -exec basename {} \\; 2>/dev/null | sort | uniq -d | head -30", cwd: p.url))
        for base in dupScan.split(separator: "\n").map({ String($0).trimmingCharacters(in: .whitespaces) }) where !base.isEmpty {
            // For each repeated basename, hash each occurrence; flag if hashes differ.
            let hashes = (await runQuiet("find . -type f -name \(Sh.q(base)) -not -path '*/.git/*' -not -path '*/.build/*' 2>/dev/null | while read f; do md5 -q \"$f\" 2>/dev/null || md5sum \"$f\" 2>/dev/null | cut -d' ' -f1; done | sort -u", cwd: p.url))
            let uniqueHashes = hashes.split(separator: "\n").filter { !$0.isEmpty }
            if uniqueHashes.count > 1 {
                report.duplicateNames.append("\(base) — \(uniqueHashes.count) differing copies")
            }
        }

        // 3) Untracked files not ignored (git's own view of "missed").
        let untracked = (await runQuiet("git ls-files --others --exclude-standard 2>/dev/null | head -40", cwd: p.url))
        for f in untracked.split(separator: "\n").map({ String($0) }) where !f.isEmpty {
            report.missedFiles.append(f)
        }

        return report
    }

    // ════════════════════════════════════════════════════════════════════════════
    // v1.12 — Clean folder: wipe a folder, or delete only files matching patterns
    // ════════════════════════════════════════════════════════════════════════════

    // List what a clean WOULD remove, without deleting. `patterns` is a comma/space/newline list
    // of glob-ish suffixes or names (e.g. "*.log, .DS_Store, build"). Empty patterns = everything
    // in the folder (a full wipe). Returns the matching item URLs.
    func cleanCandidates(folder: URL, patterns: String) -> [URL] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }
        let pats = patterns.split(whereSeparator: { $0 == "," || $0 == " " || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if pats.isEmpty { return items }   // full wipe
        return items.filter { url in
            let name = url.lastPathComponent
            return pats.contains { pat in
                if pat.hasPrefix("*") { return name.hasSuffix(String(pat.dropFirst())) }
                return name == pat
            }
        }
    }

    // Perform the clean. Guarded: refuses obviously dangerous roots, and the UI requires a typed
    // confirmation. Deletes the matched items (or everything if patterns is empty).
    @discardableResult
    func cleanFolder(_ folder: URL, patterns: String, dryRun: Bool) async -> Int {
        // Safety: never allow cleaning the home dir, a volume root, or a git working tree's root.
        let path = folder.standardizedFileURL.path
        let home = NSHomeDirectory()
        let blocked = [home, "/", "/Users", "/System", "/Library", "/Applications"]
        if blocked.contains(path) {
            line("⛔️ Refusing to clean a protected location: \(path)")
            toast("Protected location — not cleaned", .error)
            return 0
        }
        if FileManager.default.fileExists(atPath: folder.appendingPathComponent(".git").path) && patterns.isEmpty {
            line("⛔️ \(path) looks like a git repository root and patterns are empty (full wipe). Refusing — set patterns, or clean a subfolder.")
            toast("Won't wipe a repo root", .error)
            return 0
        }
        let targets = cleanCandidates(folder: folder, patterns: patterns)
        if targets.isEmpty { line("Nothing to clean in \(path)."); toast("Nothing to clean", .info); return 0 }
        let fm = FileManager.default
        var removed = 0
        line("🧹 \(dryRun ? "Would clean" : "Cleaning") \(targets.count) item(s) in \(path)…")
        for t in targets {
            if dryRun { line("   would remove: \(t.lastPathComponent)"); removed += 1; continue }
            do { try fm.removeItem(at: t); removed += 1 }
            catch { line("   ⚠️ couldn't remove \(t.lastPathComponent): \(error.localizedDescription)") }
        }
        let verb = dryRun ? "Would remove" : "Removed"
        line("✓ \(verb) \(removed) item(s).")
        toast("\(verb) \(removed) item\(removed == 1 ? "" : "s")", removed > 0 ? .success : .info)
        return removed
    }

    // Improvement #3 — guard the commit message before running it. Returns false if blocked.
    @discardableResult
    // Build a default commit message from the working tree, so you don't have to type one.
    // Summarizes how many files changed and lists a few names, e.g.
    //   "Update 3 files: ContentView.swift, Models.swift, README.md"
    func autoCommitMessage() async -> String {
        guard let p = selected else { return "Update" }
        let out = await runQuiet("git status --porcelain 2>/dev/null", cwd: p.url)
        let lines = out.split(separator: "\n").map { String($0) }
        guard !lines.isEmpty else { return "Update" }
        // Parse "XY path" porcelain rows into (status, name).
        var names: [String] = []
        var added = 0, modified = 0, deleted = 0
        for row in lines {
            guard row.count > 3 else { continue }
            let code = row.prefix(2).trimmingCharacters(in: .whitespaces)
            let path = String(row.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            let name = (path as NSString).lastPathComponent
            names.append(name)
            if code.contains("A") || code.contains("?") { added += 1 }
            else if code.contains("D") { deleted += 1 }
            else { modified += 1 }
        }
        let total = names.count
        // Verb based on the dominant change type.
        let verb: String
        if added > modified && added >= deleted { verb = "Add" }
        else if deleted > modified && deleted >= added { verb = "Remove" }
        else { verb = "Update" }
        let shown = names.prefix(3).joined(separator: ", ")
        let suffix = total > 3 ? " and \(total - 3) more" : ""
        let fileWord = total == 1 ? "file" : "files"
        return "\(verb) \(total) \(fileWord): \(shown)\(suffix)"
    }

    // Commit only (stage + commit), no push. Returns true if it ran without a blocking error.
    @discardableResult
    func commitOnly(message: String) async -> Bool {
        await doCommit(message: message, push: false)
    }

    // Push only — push local commits to origin (with the same non-ff recovery as commitPush).
    func pushOnly() async {
        guard let p = selected else { return }
        let branchOK = !branch.isEmpty && !branch.hasPrefix("(") && !branch.contains(" ")
        guard branchOK else { line("❌ Can't push — no valid branch (\(branch)). Click Refresh."); return }
        await pushWithRecovery(branch: branch, cwd: p.url)
        await refresh()
    }

    // ── Offline / local repo support + GitHub connect helper ─────────────────────
    // Local git (init, commit, branch, history, diff) always works with no remote. When a repo has
    // no 'origin', the UI offers this helper to connect it to GitHub — via the gh CLI if installed,
    // or with copy-paste commands + browser steps otherwise.

    // Is the GitHub CLI available?
    func hasGHCLI() async -> Bool {
        let out = (await runQuiet("command -v gh 2>/dev/null", cwd: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
        return !out.isEmpty
    }

    // Is gh authenticated?
    func ghAuthenticated() async -> Bool {
        guard let p = selected else { return false }
        let r = await runQuiet("gh auth status 2>&1", cwd: p.url)
        return r.lowercased().contains("logged in")
    }

    // Initialize a git repo in the selected folder (for non-repos).
    func gitInit() async {
        guard let p = selected else { return }
        _ = await run("git init && git add -A && git commit -m \"Initial commit\" 2>&1 | tail -3", cwd: p.url, label: "git init")
        await refresh()
    }

    // Create the GitHub repo with gh and wire up origin, then push. visibility is private or public.
    func createGitHubRepoWithGH(name: String, visibility: String) async {
        guard let p = selected else { return }
        if !isGitRepo { await gitInit() }
        let vis = visibility == "public" ? "--public" : "--private"
        _ = await run("gh repo create \(Sh.q(name)) \(vis) --source=. --remote=origin --push 2>&1", cwd: p.url, label: "Create GitHub repo")
        await refresh()
        if hasRemote { line("✅ Connected to GitHub and pushed. Remote: \(remoteURL)"); toast("Connected to GitHub", .success) }
    }

    // Manual path: add a remote the user created in the browser, set upstream, push.
    func connectExistingRemote(url: String) async {
        guard let p = selected else { return }
        if !isGitRepo { await gitInit() }
        let br = branch.isEmpty || branch.hasPrefix("(") ? "main" : branch
        _ = await run("git remote add origin \(Sh.q(url)) 2>&1 || git remote set-url origin \(Sh.q(url)); git branch -M \(Sh.q(br)); git push -u origin \(Sh.q(br)) 2>&1", cwd: p.url, label: "Connect remote")
        await refresh()
        if hasRemote { line("✅ Remote connected and pushed."); toast("Remote connected", .success) }
    }

    // ── Version / build numbering ────────────────────────────────────────────────
    // Standard (shared by all apps): VERSION = small changes/fixes (dotted, e.g. 1.0 → 1.1),
    // BUILD = big features/changes (integer, +1). Numbers can live in two places depending on how
    // the app's Xcode project is set up:
    //   • Xcode project (pbxproj): MARKETING_VERSION (version) + CURRENT_PROJECT_VERSION (build)
    //   • Info.plist:              CFBundleShortVersionString (version) + CFBundleVersion (build)
    // BuildBuddy detects which exist and updates BOTH when both are present and don't conflict,
    // so the app, all targets, and the What's New screen stay in lockstep. If they conflict, the
    // pbxproj wins for Xcode apps (it's the build-settings source of truth) and is mirrored to the
    // plist. This reconciles the differing approaches across the Stocked / FrameTV scripts.

    struct VersionInfo {
        var plistPath: String?       // Info.plist with CFBundle* keys, if any
        var pbxPath: String?         // project.pbxproj with *_VERSION settings, if any
        var version: String          // resolved current VERSION (marketing / short)
        var build: String            // resolved current BUILD
        var hasPlistKeys: Bool       // plist actually has the CFBundle* keys
        var hasPbxKeys: Bool         // pbxproj actually has the *_VERSION keys
    }

    // Locate Info.plist (with CFBundle keys) and/or the pbxproj (with version settings).
    func locateVersionFiles(for p: Project) async -> VersionInfo {
        var info = VersionInfo(plistPath: nil, pbxPath: nil, version: "", build: "",
                               hasPlistKeys: false, hasPbxKeys: false)

        // --- Info.plist ---
        let plistCandidates = ["Info.plist", "\(p.name)/Info.plist", "Sources/Info.plist"]
        var plist: String?
        for rel in plistCandidates {
            let full = p.url.appendingPathComponent(rel).path
            if FileManager.default.fileExists(atPath: full) { plist = full; break }
        }
        if plist == nil {
            let found = await runQuiet("find . -name Info.plist -not -path '*/.build/*' -not -path '*/build/*' -not -path '*/DerivedData/*' 2>/dev/null | head -1", cwd: p.url).trimmingCharacters(in: .whitespacesAndNewlines)
            if !found.isEmpty { plist = p.url.appendingPathComponent(found.replacingOccurrences(of: "./", with: "")).path }
        }
        if let plist {
            let q = Sh.q(plist)
            let v = (await runQuiet("/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \(q) 2>/dev/null", cwd: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
            let b = (await runQuiet("/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \(q) 2>/dev/null", cwd: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
            // Only count as "has keys" if they're real literals (not $(VAR) build-setting refs).
            let vReal = !v.isEmpty && !v.contains("$(")
            let bReal = !b.isEmpty && !b.contains("$(")
            info.plistPath = plist
            info.hasPlistKeys = vReal || bReal
            if vReal && info.version.isEmpty { info.version = v }
            if bReal && info.build.isEmpty { info.build = b }
        }

        // --- pbxproj ---
        let pbx = (await runQuiet("find . -name project.pbxproj -not -path '*/.build/*' 2>/dev/null | head -1", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !pbx.isEmpty {
            let pbxFull = p.url.appendingPathComponent(pbx.replacingOccurrences(of: "./", with: "")).path
            let q = Sh.q(pbxFull)
            let mv = (await runQuiet("grep -Eo 'MARKETING_VERSION = [^;]+;' \(q) 2>/dev/null | head -1 | sed -E 's/MARKETING_VERSION = //; s/;//' | tr -d ' '", cwd: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
            let cpv = (await runQuiet("grep -Eo 'CURRENT_PROJECT_VERSION = [0-9]+;' \(q) 2>/dev/null | grep -Eo '[0-9]+' | sort -n | tail -1", cwd: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
            info.pbxPath = pbxFull
            info.hasPbxKeys = !mv.isEmpty || !cpv.isEmpty
            // pbxproj wins for the resolved values when present (build-settings source of truth).
            if !mv.isEmpty { info.version = mv }
            if !cpv.isEmpty { info.build = cpv }
        }

        if info.version.isEmpty { info.version = "1.0" }
        if info.build.isEmpty { info.build = "1" }
        return info
    }

    // Write a VERSION value to every place that exists (plist + pbxproj).
    private func writeVersion(_ v: String, _ info: VersionInfo) async {
        if let plist = info.plistPath {
            let q = Sh.q(plist)
            _ = await run("/usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString \(v)' \(q) 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string \(v)' \(q)", cwd: nil, label: "Set version (plist)")
        }
        if let pbx = info.pbxPath, info.hasPbxKeys {
            let q = Sh.q(pbx)
            _ = await run("/usr/bin/sed -i '' -E 's/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = \(v);/g' \(q)", cwd: nil, label: "Set version (pbxproj)")
        }
    }

    // Write a BUILD value to every place that exists (plist + pbxproj).
    private func writeBuild(_ b: String, _ info: VersionInfo) async {
        if let plist = info.plistPath {
            let q = Sh.q(plist)
            _ = await run("/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion \(b)' \(q) 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string \(b)' \(q)", cwd: nil, label: "Set build (plist)")
        }
        if let pbx = info.pbxPath, info.hasPbxKeys {
            let q = Sh.q(pbx)
            _ = await run("/usr/bin/sed -i '' -E 's/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = \(b);/g' \(q)", cwd: nil, label: "Set build (pbxproj)")
        }
    }

    func readVersionBuild(for p: Project) async -> (version: String, build: String)? {
        let info = await locateVersionFiles(for: p)
        guard info.hasPlistKeys || info.hasPbxKeys else { return nil }
        return (info.version, info.build)
    }

    // Is the app already on the standard? (version is "1.x" form AND a numeric build exists.)
    func isStandardized(_ info: VersionInfo) -> Bool {
        let vOK = info.version.split(separator: ".").first.map { $0 == "1" } ?? false
        let bOK = Int(info.build) != nil
        return (info.hasPlistKeys || info.hasPbxKeys) && vOK && bOK
    }

    // Bump the BUILD number (big change): integer + 1, written everywhere it lives.
    func bumpBuild() async {
        guard let p = selected else { return }
        let info = await locateVersionFiles(for: p)
        guard info.hasPlistKeys || info.hasPbxKeys else { line("No version info found (no Info.plist keys or pbxproj settings) in \(p.name)."); toast("No version info", .error); return }
        let next = (Int(info.build) ?? 1) + 1
        await writeBuild("\(next)", info)
        await appendWhatsNew(for: p, version: info.version, build: "\(next)", kind: "Build", note: "Big change")
        line("⬆️ Build: \(info.build) → \(next) (big change), written to \(targetsDescription(info)).")
        toast("Build → \(next)", .success)
    }

    // Bump the VERSION (small change/fix): increment the last dotted component, written everywhere.
    func bumpVersion() async {
        guard let p = selected else { return }
        let info = await locateVersionFiles(for: p)
        guard info.hasPlistKeys || info.hasPbxKeys else { line("No version info found in \(p.name)."); toast("No version info", .error); return }
        var parts = info.version.split(separator: ".").map { Int($0) ?? 0 }
        if parts.isEmpty { parts = [1, 0] }
        parts[parts.count - 1] += 1
        let next = parts.map(String.init).joined(separator: ".")
        await writeVersion(next, info)
        await appendWhatsNew(for: p, version: next, build: info.build, kind: "Version", note: "Small change or fix")
        line("⬆️ Version: \(info.version) → \(next) (small change), written to \(targetsDescription(info)).")
        toast("Version → \(next)", .success)
    }

    private func targetsDescription(_ info: VersionInfo) -> String {
        var places: [String] = []
        if info.hasPbxKeys { places.append("Xcode project") }
        if info.plistPath != nil { places.append("Info.plist") }
        return places.isEmpty ? "nowhere" : places.joined(separator: " + ")
    }

    // ── Standardize this app (one click, idempotent) ─────────────────────────────
    // Detects the app's setup and brings it onto the shared standard:
    //   • If NOT standardized: reset to VERSION 1.0 / BUILD 1 everywhere the numbers live.
    //   • If ALREADY standardized: leaves the numbers alone (won't reset your progress).
    //   • Either way: ensures a timestamped What's New entry exists/updates.
    func standardizeApp() async {
        guard let p = selected else { return }
        let info = await locateVersionFiles(for: p)
        line("🔎 Standardizing \(p.name) — found: \(info.hasPbxKeys ? "Xcode project version settings" : "no pbxproj settings"), \(info.plistPath != nil ? "Info.plist" : "no Info.plist").")

        if info.hasPlistKeys || info.hasPbxKeys {
            if isStandardized(info) {
                line("✓ \(p.name) is already standardized (version \(info.version), build \(info.build)). Leaving numbers as-is.")
                toast("Already standardized", .info)
            } else {
                await writeVersion("1.0", info)
                await writeBuild("1", info)
                line("↺ Reset \(p.name) to the baseline: version 1.0, build 1 (written to \(targetsDescription(info))).")
                toast("Reset to 1.0 / build 1", .success)
            }
        } else {
            // No version info anywhere — create CFBundle keys in the Info.plist if we have one.
            if info.plistPath != nil {
                var withKeys = info
                withKeys.hasPlistKeys = true
                await writeVersion("1.0", withKeys)
                await writeBuild("1", withKeys)
                line("➕ \(p.name) had no version info — set version 1.0 / build 1 in Info.plist.")
                toast("Initialized 1.0 / build 1", .success)
            } else {
                line("⚠️ \(p.name) has no Info.plist or Xcode project to write version info into. Skipped numbering.")
                toast("No place to write version", .error)
            }
        }

        // Ensure a timestamped What's New entry.
        let final = await locateVersionFiles(for: p)
        await appendWhatsNew(for: p, version: final.version, build: final.build, kind: "Standardize",
                             note: "Standardized to the shared version and build scheme")
    }

    // Reset to the standard baseline: version 1.0, build 1 (used when migrating an app).
    func resetVersionBuild() async {
        guard let p = selected else { return }
        let info = await locateVersionFiles(for: p)
        var i = info
        if i.plistPath != nil { i.hasPlistKeys = true }   // force-create keys on explicit reset
        await writeVersion("1.0", i)
        await writeBuild("1", i)
        await appendWhatsNew(for: p, version: "1.0", build: "1", kind: "Reset", note: "Reset to baseline 1.0 / build 1")
        line("↺ Reset \(p.name) to the standard baseline: version 1.0, build 1.")
        toast("Reset to 1.0 / build 1", .success)
    }

    // ── Timestamped What's New / changelog ───────────────────────────────────────
    // Detects the app's existing changelog and prepends a timestamped entry, format MM:DD:YY HH:MM.
    // Looks for (in order): CHANGELOG.md, WHATS_NEW.md, WHATSNEW.md, CHANGES.md at the repo root,
    // then any Swift file containing a "What's New" / "What's Changed" marker. If none exists,
    // creates CHANGELOG.md.
    func appendWhatsNew(for p: Project, version: String, build: String, kind: String, note: String) async {
        let stamp = Self.timestamp()                       // MM:DD:YY HH:MM
        let header = "\(stamp) — v\(version) (build \(build)) — \(kind)"
        let entry = "\(header)\n\(note)\n"

        // 1) A markdown changelog at the repo root?
        let mdCandidates = ["CHANGELOG.md", "WHATS_NEW.md", "WHATSNEW.md", "CHANGES.md"]
        for name in mdCandidates {
            let path = p.url.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: path.path) {
                await prependToFile(path, entry: entry + "\n")
                line("📝 Updated \(name) with: \(header)")
                return
            }
        }

        // 2) A Swift file with a What's New / What's Changed marker?
        let swiftHit = (await runQuiet("grep -rilE \"what'?s (new|changed)\" --include='*.swift' . 2>/dev/null | head -1", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
        if !swiftHit.isEmpty {
            // Don't rewrite arbitrary Swift structure; instead drop a companion CHANGELOG.md AND
            // leave a note. Editing source changelogs varies too much per app to do safely blind.
            let path = p.url.appendingPathComponent("CHANGELOG.md")
            await prependToFile(path, entry: entry + "\n")
            line("📝 \(p.name) keeps its What's New in source (\(swiftHit)). Recorded the timestamped entry in CHANGELOG.md to keep history; copy it into the in-app list if desired.")
            return
        }

        // 3) Nothing exists — create CHANGELOG.md.
        let path = p.url.appendingPathComponent("CHANGELOG.md")
        let head = "# Changelog\n\nTimestamps are MM:DD:YY HH:MM (local time).\n\n"
        if !FileManager.default.fileExists(atPath: path.path) {
            try? head.write(to: path, atomically: true, encoding: .utf8)
        }
        await prependToFile(path, entry: entry + "\n", afterHeaderLines: 4)
        line("📝 Created CHANGELOG.md and added: \(header)")
    }

    // Prepend an entry to a text file (optionally after a fixed number of header lines).
    private func prependToFile(_ url: URL, entry: String, afterHeaderLines: Int = 0) async {
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        if afterHeaderLines > 0 {
            let lines = existing.components(separatedBy: "\n")
            let head = lines.prefix(afterHeaderLines).joined(separator: "\n")
            let rest = lines.dropFirst(afterHeaderLines).joined(separator: "\n")
            let combined = head + "\n" + entry + rest
            try? combined.write(to: url, atomically: true, encoding: .utf8)
        } else {
            try? (entry + existing).write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // Timestamp in the required MM:DD:YY HH:MM format (local time).
    static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "MM:dd:yy HH:mm"
        return f.string(from: Date())
    }

    // ── Exporting the instructions ───────────────────────────────────────────────
    // The combined playbook (delivery format + build/version standard), as one document.
    static var fullInstructions: String {
        DeliveryInstructions.text + "\n\n\n" + BuildStandard.text + "\n\n\n" + DeployInstructions.text
    }

    // Copy the instructions to the clipboard.
    func copyInstructions() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(Self.fullInstructions, forType: .string)
        toast("Instructions copied", .success)
    }

    // Save the instructions as a .md or .txt file via a save panel.
    func exportInstructions(markdown: Bool) {
        let panel = NSSavePanel()
        panel.title = "Export BuildBuddy instructions"
        panel.nameFieldStringValue = markdown ? "BuildBuddy-Instructions.md" : "BuildBuddy-Instructions.txt"
        panel.allowedContentTypes = markdown ? [.init(filenameExtension: "md") ?? .plainText] : [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let body = markdown ? Self.instructionsMarkdown : Self.fullInstructions
        do {
            try body.write(to: url, atomically: true, encoding: .utf8)
            line("✓ Exported instructions to \(url.path)")
            toast("Exported \(url.lastPathComponent)", .success)
        } catch {
            line("❌ Couldn't export: \(error.localizedDescription)")
            toast("Export failed", .error)
        }
    }

    // A lightly Markdown-formatted version (headings become #/##; the plain text is already close).
    static var instructionsMarkdown: String {
        var out = "# BuildBuddy Instructions\n\n"
        out += "_Delivery format, the shared Build & Version standard, and the website deploy guide._\n\n"
        for block in [DeliveryInstructions.text, BuildStandard.text, DeployInstructions.text] {
            for raw in block.split(separator: "\n", omittingEmptySubsequences: false) {
                let lineStr = String(raw)
                // ALL-CAPS lines (titles) → headings.
                let trimmed = lineStr.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty,
                   trimmed == trimmed.uppercased(),
                   trimmed.rangeOfCharacter(from: CharacterSet.letters) != nil,
                   trimmed.count < 70 {
                    out += "\n## \(trimmed)\n"
                } else {
                    out += lineStr + "\n"
                }
            }
            out += "\n"
        }
        return out
    }

    // What the Next button should do right now.
    var nextStep: NextStep {
        if let zip = pendingDeliveryZip { return .applyDelivery(zip.lastPathComponent) }
        if statusLine != "clean" && statusLine != "" { return .commit }
        return .finished
    }

    // Run whatever Next resolves to. `applyHandler` is provided by the view so applying a delivery
    // reuses the existing preview/commit flow. `commitMessage` is the (possibly edited) inline text.
    func runNextStep(commitMessage: String, applyHandler: (URL) -> Void) async {
        switch nextStep {
        case .applyDelivery(let name):
            if let zip = pendingDeliveryZip {
                line("▶️ Next: applying delivery \(name)…")
                applyHandler(zip)
            }
        case .commit:
            line("▶️ Next: committing changes…")
            let trimmed = commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let msg = trimmed.isEmpty ? await autoCommitMessage() : trimmed
            if hasRemote { _ = await commitPush(message: msg) }
            else { _ = await commitOnly(message: msg) }
        case .finished:
            toast("Nothing to do — you're all caught up", .info)
        }
    }

    func commitPush(message: String) async -> Bool {
        await doCommit(message: message, push: settings.pushAfterCommit && !askedAndDeclinedPush())
    }

    // Shared commit core used by commitOnly / commitPush.
    @discardableResult
    private func doCommit(message: String, push: Bool) async -> Bool {
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
        // ── v2.0 REGRESSION GUARD ────────────────────────────────────────────────
        // Compare the working tree against the last-known-good baseline the Learn
        // engine recorded. If files that existed in every good build are now gone,
        // or a source file collapsed in size, warn BEFORE the commit seals it in.
        if settings.regressionGuard {
            let reg = regressionFindings(for: p)
            if !reg.isEmpty {
                line("⚠️ Possible regression before commit in \(p.name):")
                for m in reg.missing.prefix(10) { line("   • previously present, now missing: \(m)") }
                for s in reg.shrunk.prefix(10) { line("   • drastically smaller than the last good build: \(s)") }
                let alert = NSAlert()
                alert.messageText = "Possible regression detected"
                alert.informativeText = "\(reg.missing.count) file(s) that existed in the last good build are missing, and \(reg.shrunk.count) source file(s) shrank by more than half. This can mean a delivery reverted work. Commit anyway?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Commit anyway")
                alert.addButton(withTitle: "Cancel commit")
                guard alert.runModal() == .alertFirstButtonReturn else {
                    lastResult = "⚠️ Commit cancelled (regression guard)"
                    toast("Commit cancelled — review the findings", .info)
                    return false
                }
            }
        }

        let safe = message.replacingOccurrences(of: "\"", with: "\\\"")

        // ── v2.0 PROJECT-SCOPE GUARD ─────────────────────────────────────────────
        // Commits are strictly project-specific. Two protections:
        //   1. The repo toplevel must BE the project's own path. If the project folder is
        //      nested inside some larger repo, a plain `git add -A` would stage files from
        //      OTHER projects living in that outer repo — so we refuse and explain.
        //   2. Any other registered project nested INSIDE this repo is excluded from
        //      staging with a pathspec, so its files can never ride along.
        let top = (await runQuiet("git rev-parse --show-toplevel 2>/dev/null", cwd: p.url))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !top.isEmpty, URL(fileURLWithPath: top).standardizedFileURL.path != p.url.standardizedFileURL.path {
            line("⛔️ Commit blocked — \(p.name) sits inside a larger git repo (\(top)).")
            line("   Committing from here would sweep in files that belong to other projects.")
            line("   Add \(top) as its own project, or give \(p.name) its own repo (git init).")
            lastResult = "⛔️ Commit blocked (repo scope)"
            toast("Blocked: repo root belongs to another project", .error)
            return false
        }
        let r = await run(scopedStageAndCommitCommand(for: p, safeMessage: safe), cwd: p.url, label: "Commit")

        let nothing = r.out.contains("BB_NOTHING_TO_COMMIT")
        if nothing { line("Nothing new to commit — working tree is clean.") }

        if push {
            await pushWithRecovery(branch: branch, cwd: p.url)
        }
        // ── v2.0 AUTO CACHE CLEAR + LEARN ────────────────────────────────────────
        // Every commit clears this project's cached status (fresh read next paint),
        // prunes stale delivery temp dirs and old apply backups, and — when learning
        // is on — updates the project's baseline manifest so the Sync engine knows
        // this tree as the newest good state.
        await postCommitMaintenance(for: p, committed: !nothing)
        await refresh()
        return true
    }

    // Builds the stage+commit shell command scoped to THIS project only. Other registered
    // projects nested under this repo root are excluded via git pathspecs.
    func scopedStageAndCommitCommand(for p: Project, safeMessage: String) -> String {
        let rootPath = p.url.standardizedFileURL.path
        let nestedOthers = projects.filter {
            $0.id != p.id && $0.url.standardizedFileURL.path.hasPrefix(rootPath + "/")
        }
        var stage = "git add -A -- ."
        if !nestedOthers.isEmpty {
            let excludes = nestedOthers.map { other -> String in
                let rel = String(other.url.standardizedFileURL.path.dropFirst(rootPath.count + 1))
                return Sh.q(":(exclude)\(rel)")
            }
            stage = "git add -A -- . " + excludes.joined(separator: " ")
        }
        return stage + "; if git diff --cached --quiet; then echo 'BB_NOTHING_TO_COMMIT'; else git commit -m \"\(safeMessage)\"; fi"
    }

    // Pushes, and if the push is rejected as non-fast-forward, automatically recovers using the
    // sequence the user verified works: fetch, then push --force-with-lease; if that still reports
    // "stale info", fall back to a plain --force. This is safe for a SOLE-CONTRIBUTOR, DISPOSABLE
    // remote (local history is the source of truth). It is gated behind a setting so it can't
    // surprise anyone who shares the repo. LOCAL COMMITS ARE NEVER TOUCHED — only the remote ref
    // is overwritten to match local.
    func pushWithRecovery(branch: String, cwd: URL) async {
        // Master kill switch: when on, BuildBuddy never auto-pushes. Your local commits are made,
        // but nothing touches the remote — so a concurrent pusher can't race you. Push manually.
        if settings.pauseAllAutoPush {
            line("⏸️ Auto-push is paused (Options → Pushing). Commit done locally; remote untouched.")
            toast("Auto-push paused — pushed nothing", .info)
            return
        }
        let b = Sh.q(branch)
        let first = await run("git push origin \(b)", cwd: cwd, label: "Push")
        let out = first.out.lowercased()
        let rejected = first.code != 0 && (out.contains("non-fast-forward") || out.contains("fetch first")
            || out.contains("rejected") || out.contains("tip of your current branch is behind"))
        guard rejected else { return }

        guard settings.forcePushOnReject else {
            line("⚠️ Push was rejected (the remote has commits your local doesn't, or diverged).")
            line("   Auto force-push recovery is OFF. Turn on 'Force-push over a diverged remote' in Options,")
            line("   or resolve manually: git fetch origin, then git push --force-with-lease origin \(branch).")
            toast("Push rejected — remote diverged", .error)
            return
        }

        line("↩︎ Push rejected as non-fast-forward. Recovering: fetch, then force-with-lease…")
        _ = await run("git fetch origin", cwd: cwd, label: "Fetch (recovery)")
        let lease = await run("git push --force-with-lease origin \(b)", cwd: cwd, label: "Force-push (with lease)")
        if lease.code == 0 {
            line("✓ Recovered: remote overwritten to match local (force-with-lease).")
            toast("Push recovered (force-with-lease)", .success)
            return
        }
        // --force-with-lease can fail with "stale info" if the local remote-tracking ref is itself
        // out of date. The user confirmed a plain --force is the reliable fallback here.
        if lease.out.lowercased().contains("stale info") || lease.code != 0 {
            line("⚠️ force-with-lease reported stale info — falling back to a plain force-push.")
            let force = await run("git push --force origin \(b)", cwd: cwd, label: "Force-push")
            if force.code == 0 {
                line("✓ Recovered: remote overwritten to match local (force).")
                toast("Push recovered (force)", .success)
            } else {
                line("❌ Even a force-push failed. Check your network and 'gh auth status'.")
                toast("Push failed", .error)
            }
        }
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
        let r = await run("git merge --no-edit \(Sh.q(src))", cwd: p.url, label: "Merge")
        if r.code == 0 { await pushWithRecovery(branch: branch, cwd: p.url) }
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

    // MARK: Self-update — pull the BuildBuddy repo and recompile via the launcher.
    // BuildBuddy is a self-hosted single .swift file compiled by "Launch BuildBuddy.command".
    // Updating means: pull the latest source, then relaunch through the launcher, which rebuilds
    // because the source is now newer than the compiled binary.

    @Published var updateStatus: String = ""
    @Published var updateAvailable = false

    // Find the folder that contains this app's own source. Prefers a project named "BuildBuddy";
    // otherwise asks the bundle where it lives and walks up to find the folder with BuildBuddy.swift.
    func locateSelfRepo() -> URL? {
        if let p = projects.first(where: { $0.name.caseInsensitiveCompare("BuildBuddy") == .orderedSame }) {
            return p.url
        }
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
            line(updateStatus); toast("BuildBuddy repo not found", .error)
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
            toast("Update available", .success)
        } else {
            updateAvailable = false
            updateStatus = "BuildBuddy is up to date (v\(BuildBuddyVersion))."
            line("✅ " + updateStatus); toast("Up to date", .info)
        }
    }

    // Relaunch via the launcher, which rebuilds because the source is now newer than the binary.
    func updateAndRelaunch() async {
        guard let repo = locateSelfRepo() else { line("Couldn't find the BuildBuddy repo."); return }
        let launcher = repo.appendingPathComponent("Launch BuildBuddy.command")
        guard FileManager.default.fileExists(atPath: launcher.path) else {
            line("Couldn't find 'Launch BuildBuddy.command' in \(repo.path).")
            toast("Launcher not found", .error)
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
        var zipURL: URL?                  // the original delivery .zip, for post-apply cleanup
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
                               sourceDir: src,
                               zipURL: zip)
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
        guard let p = selected else {
            line("Select a project first.")
            try? FileManager.default.removeItem(at: preview.tmpDir)
            return
        }
        // Applying this delivery satisfies the pending "Next" step.
        pendingDeliveryZip = nil

        if settings.clearConsoleOnAction { clearConsole() }

        // GUARD: don't re-apply files that are already identical in the repo. If the drop
        // contains nothing new or changed, skip the whole apply/commit — it's already applied.
        // NOTE: we still clean up the temp extraction, but we KEEP the zip (nothing was applied,
        // so the user may want it). Cleanup of the zip only happens on a real apply.
        if preview.nothingToApply {
            line("✓ Nothing to apply — all \(preview.files.count) file(s) in this delivery are already identical in \(p.name). Skipping.")
            lastResult = "✓ Already applied (no changes)"
            cleanupDelivery(preview, deleteZip: false)
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

        let backupURL = await backupBeforeApply(preview: preview)

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
            cleanupDelivery(preview, deleteZip: false)
            return
        }

        // The overlay succeeded and there are real changes — this counts as a successful apply,
        // so the original zip is eligible for cleanup regardless of the commit path below.
        cleanupDelivery(preview, deleteZip: true)

        // Decide commit behavior: global master switch AND per-project toggle must allow it.
        let autoOK = settings.autoCommitAndPush && p.autoCommitOnApply
        let msg = preview.commitMessage.isEmpty ? settings.defaultCommitMessage : preview.commitMessage
        let safe = CommitSafety.isSafe(msg) || !settings.blockUnsafeCommitMessages

        var committed = false
        if autoOK && !msg.isEmpty && safe {
            line("Auto-commit \(settings.pushAfterCommit ? "& push " : "")is ON — committing…")
            _ = await commitPush(message: msg)
            committed = true
            await maybePostApply()
        } else if autoOK && !msg.isEmpty && !safe {
            line("Auto-commit is ON, but the message is shell-unsafe — opening it for review instead.")
            pendingCommitMessage = msg
        } else if !preview.commitMessage.isEmpty {
            pendingCommitMessage = preview.commitMessage   // opens the review sheet
        } else {
            line("Applied. Auto-commit is off — review your changes, then Commit & Push.")
        }

        // v1.10 — record this apply in history (for the undo log). Capture the resulting SHA
        // if it was committed; otherwise the entry is still useful (files + backup for undo).
        var sha: String? = nil
        if committed {
            let s = (await runQuiet("git rev-parse HEAD 2>/dev/null", cwd: p.url)).trimmingCharacters(in: .whitespacesAndNewlines)
            sha = s.isEmpty ? nil : s
        }
        recordApply(project: p, files: preview.changedFiles, message: msg, sha: sha,
                    backupDir: backupURL, zipName: preview.zipURL?.lastPathComponent)
        toast("Applied \(preview.changedFiles.count) file\(preview.changedFiles.count == 1 ? "" : "s") to \(p.name)", .success)
    }

    // Cleans up after a delivery: removes the temp extraction folder, and (when the delivery
    // was actually applied AND the setting is on) deletes the original .zip too. Honors the
    // deleteExtractedAfterApply / deleteZipAfterApply options. Never deletes anything in dry-run.
    func cleanupDelivery(_ preview: DeliveryPreview, deleteZip: Bool) {
        if settings.dryRunMode {
            line("〰️ DRY RUN — would clean up the extracted folder" + (deleteZip ? " and the original zip." : "."))
            return
        }
        let fm = FileManager.default
        // 1) Temp extraction folder.
        if settings.deleteExtractedAfterApply {
            try? fm.removeItem(at: preview.tmpDir)
        }
        // 2) Original delivery zip — only on a real apply, only if enabled, and only if it's a
        //    regular file we can resolve. We never touch anything outside a normal .zip path.
        if deleteZip, settings.deleteZipAfterApply, let zip = preview.zipURL,
           zip.pathExtension.lowercased() == "zip", fm.fileExists(atPath: zip.path) {
            do {
                try fm.removeItem(at: zip)
                line("🧹 Cleaned up delivery: removed \(zip.lastPathComponent) and its extracted folder.")
                // Forget it from the Downloads auto-detect set so a future same-named zip is seen.
                seenDownloadZips.remove(zip.path)
            } catch {
                line("⚠️ Couldn't delete \(zip.lastPathComponent): \(error.localizedDescription)")
            }
        } else if settings.deleteExtractedAfterApply {
            line("🧹 Removed the extracted delivery folder.")
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
        let fm = FileManager.default
        let repoName = p.name.lowercased()
        // Gather candidate zips across Downloads + any extra watch folders, newest first.
        var zips: [URL] = []
        for folder in watchFolders {
            guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { continue }
            zips.append(contentsOf: items.filter { $0.pathExtension.lowercased() == "zip" })
        }
        zips.sort { (a, b) in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return da > db
        }
        for zip in zips {
            if seenDownloadZips.contains(zip.path) { continue }
            let fileMatches = zip.lastPathComponent.lowercased().contains(repoName)
            var innerMatches = false
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


// ════════════════════════════════════════════════════════════════════════════
// v2.0 — SYNC & LEARN ENGINE
// ════════════════════════════════════════════════════════════════════════════
// BuildBuddy keeps a lightweight per-project manifest: every file's relative
// path, size and modification time, captured at each known-good moment (a
// successful commit, or an explicit "Learn this build"). The engine powers:
//   • Sync scan   — what's NEW since the last good build (files & folders you
//                   may have forgotten to commit), plus git's untracked view.
//   • Regression  — what VANISHED or collapsed in size versus the last good
//     guard         build, caught BEFORE a commit seals it in.
//   • Learning    — every successful commit re-teaches the baseline, so the
//                   app continuously learns from new builds and changes.

struct FileSnapshot: Codable, Equatable {
    var size: Int
    var mtime: Double
}

struct ProjectManifest: Codable {
    var projectPath: String
    var updated: Date
    var goodBuilds: Int          // how many good builds/commits have taught this baseline
    var files: [String: FileSnapshot]
}

enum ManifestStore {
    static func file(for id: Project.ID) -> URL {
        Persist.dir.appendingPathComponent("manifest_\(id.uuidString).json")
    }
    static func load(for id: Project.ID) -> ProjectManifest? {
        guard let data = try? Data(contentsOf: file(for: id)),
              let m = try? JSONDecoder().decode(ProjectManifest.self, from: data) else { return nil }
        return m
    }
    static func save(_ m: ProjectManifest, for id: Project.ID) {
        if let data = try? JSONEncoder().encode(m) { try? data.write(to: file(for: id)) }
    }
    static func delete(for id: Project.ID) {
        try? FileManager.default.removeItem(at: file(for: id))
    }
}

extension Store {

    // Folders that never belong in a manifest (build output, deps, VCS, backups).
    static let manifestSkipDirs: Set<String> = [
        ".git", ".build", "build", "DerivedData", "node_modules",
        ".buildbuddy-backups", "dist", ".swiftpm", "__pycache__", ".venv",
    ]
    static let sourceExtensions: Set<String> = [
        "swift", "h", "m", "c", "cpp", "js", "ts", "tsx", "jsx", "css",
        "html", "py", "rb", "go", "rs", "json", "md", "sh", "toml", "yml", "yaml",
    ]

    // Walk the project and snapshot every file (bounded; skips build/dep folders).
    nonisolated func snapshotTree(at root: URL) -> [String: FileSnapshot] {
        var out: [String: FileSnapshot] = [:]
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        guard let en = fm.enumerator(at: root, includingPropertiesForKeys: keys,
                                     options: [.skipsPackageDescendants]) else { return out }
        let rootPath = root.standardizedFileURL.path
        for case let u as URL in en {
            guard out.count < 25_000 else { break }   // sanity bound for huge trees
            let name = u.lastPathComponent
            let vals = try? u.resourceValues(forKeys: Set(keys))
            if vals?.isDirectory == true {
                if Self.manifestSkipDirs.contains(name) || name.hasSuffix(".app") {
                    en.skipDescendants()
                }
                continue
            }
            if name == ".DS_Store" || name.hasSuffix(".log") { continue }
            let rel = String(u.standardizedFileURL.path.dropFirst(rootPath.count + 1))
            guard !rel.isEmpty else { continue }
            out[rel] = FileSnapshot(size: vals?.fileSize ?? 0,
                                    mtime: vals?.contentModificationDate?.timeIntervalSince1970 ?? 0)
        }
        return out
    }

    // ── Sync scan — keep the project up to date with new files & folders ─────────
    struct SyncReport {
        var newFiles: [String] = []      // files added since the last good build
        var newFolders: [String] = []    // brand-new top folders those files live in
        var missing: [String] = []       // in the baseline, gone from disk now
        var shrunk: [String] = []        // source files at < 50% of their baseline size
        var untracked: [String] = []     // git's own untracked (not ignored) view
        var baselineDate: Date? = nil
        var goodBuilds: Int = 0
        var hasBaseline: Bool = false
        var isEmpty: Bool { newFiles.isEmpty && missing.isEmpty && shrunk.isEmpty && untracked.isEmpty }
    }

    func syncScan(for p: Project) async -> SyncReport {
        var report = SyncReport()
        let current = snapshotTree(at: p.url)
        if let manifest = ManifestStore.load(for: p.id) {
            report.hasBaseline = true
            report.baselineDate = manifest.updated
            report.goodBuilds = manifest.goodBuilds
            var folders = Set<String>()
            for (rel, snap) in current {
                if let old = manifest.files[rel] {
                    // Shrink check only for source files with a meaningful old size.
                    let ext = (rel as NSString).pathExtension.lowercased()
                    if Self.sourceExtensions.contains(ext), old.size > 2_000,
                       snap.size < old.size / 2 {
                        report.shrunk.append("\(rel)  (\(old.size) → \(snap.size) bytes)")
                    }
                } else {
                    report.newFiles.append(rel)
                    if rel.contains("/") { folders.insert(String(rel.split(separator: "/")[0])) }
                }
            }
            for rel in manifest.files.keys where current[rel] == nil {
                report.missing.append(rel)
            }
            report.newFolders = folders.filter { f in !manifest.files.keys.contains { $0.hasPrefix(f + "/") } }.sorted()
            report.newFiles.sort(); report.missing.sort(); report.shrunk.sort()
        }
        // Git's untracked view rounds out the picture even with no baseline yet.
        let untracked = await runQuiet("git ls-files --others --exclude-standard 2>/dev/null | head -100", cwd: p.url)
        report.untracked = untracked.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        return report
    }

    // ── Learn — record the current tree as the newest known-good baseline ────────
    func learnBaseline(for p: Project, announce: Bool = true) {
        let files = snapshotTree(at: p.url)
        var manifest = ManifestStore.load(for: p.id)
            ?? ProjectManifest(projectPath: p.path, updated: Date(), goodBuilds: 0, files: [:])
        manifest.projectPath = p.path
        manifest.updated = Date()
        manifest.goodBuilds += 1
        manifest.files = files
        ManifestStore.save(manifest, for: p.id)
        if announce {
            line("🧠 Learned this build: \(files.count) files snapshotted (good build #\(manifest.goodBuilds)).")
            toast("Baseline updated — build #\(manifest.goodBuilds)", .success)
        }
    }

    // ── Regression guard (synchronous — used inline by doCommit) ─────────────────
    struct RegressionFindings {
        var missing: [String] = []
        var shrunk: [String] = []
        var isEmpty: Bool { missing.isEmpty && shrunk.isEmpty }
    }

    nonisolated func regressionFindings(for p: Project) -> RegressionFindings {
        guard let manifest = ManifestStore.load(for: p.id) else { return RegressionFindings() }
        var out = RegressionFindings()
        let current = snapshotTree(at: p.url)
        for (rel, old) in manifest.files {
            if let now = current[rel] {
                let ext = (rel as NSString).pathExtension.lowercased()
                if Self.sourceExtensions.contains(ext), old.size > 2_000, now.size < old.size / 2 {
                    out.shrunk.append(rel)
                }
            } else {
                out.missing.append(rel)
            }
        }
        out.missing.sort(); out.shrunk.sort()
        return out
    }

    // ── Post-commit maintenance: auto clear caches + prune, then learn ───────────
    func postCommitMaintenance(for p: Project, committed: Bool) async {
        if settings.autoClearCachesOnCommit {
            // 1) Invalidate this project's cached status so the next paint is a fresh read.
            Self.statusCache[p.id] = nil
            // 2) Drop stale delivery temp extractions left in the system temp dir.
            let fm = FileManager.default
            let tmp = fm.temporaryDirectory
            if let items = try? fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil) {
                for item in items where item.lastPathComponent.hasPrefix("bb_") {
                    try? fm.removeItem(at: item)
                }
            }
            // 3) Prune apply backups to the most recent 10 for this project.
            let backups = p.url.appendingPathComponent(".buildbuddy-backups")
            if let dirs = try? fm.contentsOfDirectory(at: backups, includingPropertiesForKeys: [.creationDateKey]) {
                let sorted = dirs.sorted { a, b in
                    let da = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    let db = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                    return da > db
                }
                for old in sorted.dropFirst(10) { try? fm.removeItem(at: old) }
            }
            if settings.verboseLogging { line("🧽 Caches cleared for \(p.name) (status cache, temp extractions, old backups pruned).") }
        }
        // 4) Learn: a successful commit is by definition a good build.
        if committed, settings.autoLearnOnCommit {
            learnBaseline(for: p, announce: settings.verboseLogging)
        }
    }

    // ── Clean Project — remove build artifacts inside the selected project ───────
    // Never touches source, .git, or anything outside the project folder.
    static let projectJunkDirs: Set<String> = [".build", "build", "DerivedData", "__pycache__"]
    static let projectJunkFiles: Set<String> = [".DS_Store", "build.log"]
    static let projectJunkSuffixes = [".o", ".swiftmodule", ".swiftdoc", ".dSYM"]

    nonisolated func cleanProjectCandidates(for p: Project) -> [URL] {
        var found: [URL] = []
        let fm = FileManager.default
        guard let en = fm.enumerator(at: p.url, includingPropertiesForKeys: [.isDirectoryKey],
                                     options: [.skipsPackageDescendants]) else { return [] }
        for case let u as URL in en {
            let name = u.lastPathComponent
            if name == ".git" { en.skipDescendants(); continue }
            let isDir = (try? u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            if isDir {
                if Self.projectJunkDirs.contains(name) {
                    found.append(u); en.skipDescendants()
                }
                continue
            }
            if Self.projectJunkFiles.contains(name) || Self.projectJunkSuffixes.contains(where: { name.hasSuffix($0) }) {
                found.append(u)
            }
        }
        return found.sorted { $0.path < $1.path }
    }

    @discardableResult
    func cleanProject(for p: Project, dryRun: Bool) async -> Int {
        let targets = cleanProjectCandidates(for: p)
        guard !targets.isEmpty else {
            line("✓ \(p.name) is already clean — no build artifacts found.")
            toast("Project already clean", .info)
            return 0
        }
        let fm = FileManager.default
        var removed = 0
        line("🧹 \(dryRun ? "Would clean" : "Cleaning") \(targets.count) build artifact(s) in \(p.name)…")
        for t in targets {
            let rel = t.path.replacingOccurrences(of: p.path + "/", with: "")
            if dryRun { line("   would remove: \(rel)"); removed += 1; continue }
            do { try fm.removeItem(at: t); line("   removed: \(rel)"); removed += 1 }
            catch { line("   ⚠️ couldn't remove \(rel): \(error.localizedDescription)") }
        }
        let verb = dryRun ? "Would remove" : "Removed"
        line("✓ \(verb) \(removed) item(s) from \(p.name).")
        toast("\(verb) \(removed) artifact\(removed == 1 ? "" : "s")", removed > 0 ? .success : .info)
        if !dryRun { Self.statusCache[p.id] = nil; await refresh() }
        return removed
    }
}

// ════════════════════════════════════════════════════════════════════════════
// v2.0 "AURORA" — DESIGN SYSTEM
// ════════════════════════════════════════════════════════════════════════════
// One small vocabulary used everywhere: glass surfaces, a soft aurora backdrop,
// gradient monograms, capsule pills, tile buttons with gentle hover lift, and
// spring motion that respects the Reduce-motion setting.

enum BB {
    static let radius: CGFloat = 14
    static let radiusSmall: CGFloat = 10
    static let pad: CGFloat = 16

    // Springs (swap to near-instant eases when Reduce motion is on).
    static func spring(_ reduce: Bool) -> Animation {
        reduce ? .easeOut(duration: 0.12) : .spring(response: 0.38, dampingFraction: 0.82)
    }
    static func quick(_ reduce: Bool) -> Animation {
        reduce ? .easeOut(duration: 0.08) : .easeOut(duration: 0.16)
    }
    static func gentle(_ reduce: Bool) -> Animation {
        reduce ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.3)
    }

    // A deterministic gradient per name — powers project monograms and accents.
    static let gradientPalette: [[Color]] = [
        [Color(red: 0.42, green: 0.36, blue: 0.98), Color(red: 0.66, green: 0.33, blue: 0.97)], // violet
        [Color(red: 0.10, green: 0.55, blue: 0.95), Color(red: 0.20, green: 0.80, blue: 0.90)], // ocean
        [Color(red: 0.95, green: 0.42, blue: 0.35), Color(red: 0.98, green: 0.65, blue: 0.25)], // sunset
        [Color(red: 0.15, green: 0.70, blue: 0.50), Color(red: 0.45, green: 0.85, blue: 0.40)], // meadow
        [Color(red: 0.90, green: 0.30, blue: 0.60), Color(red: 0.98, green: 0.50, blue: 0.40)], // rose
        [Color(red: 0.30, green: 0.45, blue: 0.90), Color(red: 0.30, green: 0.75, blue: 0.95)], // sky
        [Color(red: 0.80, green: 0.55, blue: 0.20), Color(red: 0.95, green: 0.75, blue: 0.30)], // amber
        [Color(red: 0.55, green: 0.35, blue: 0.85), Color(red: 0.35, green: 0.60, blue: 0.95)], // twilight
    ]
    static func gradient(for name: String) -> LinearGradient {
        var hash = 0
        for u in name.unicodeScalars { hash = (hash &* 31 &+ Int(u.value)) & 0x7fffffff }
        let colors = gradientPalette[hash % gradientPalette.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static func accentGradient(_ accent: Color) -> LinearGradient {
        LinearGradient(colors: [accent, accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// Frosted glass surface with a hairline gradient border and a soft shadow.
struct GlassCard: ViewModifier {
    var radius: CGFloat = BB.radius
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.04)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            )
            .shadow(color: .black.opacity(elevated ? 0.18 : 0.08), radius: elevated ? 16 : 8, y: elevated ? 8 : 3)
    }
}
extension View {
    func glassCard(radius: CGFloat = BB.radius, elevated: Bool = false) -> some View {
        modifier(GlassCard(radius: radius, elevated: elevated))
    }
}

// The soft, slowly drifting aurora backdrop behind everything.
struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme
    var reduceMotion: Bool
    var accent: Color
    @State private var drift = false

    var body: some View {
        ZStack {
            (scheme == .dark ? Color(red: 0.07, green: 0.07, blue: 0.10)
                             : Color(red: 0.95, green: 0.95, blue: 0.98))
                .ignoresSafeArea()
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    blob(accent, size: w * 0.7)
                        .offset(x: drift ? -w * 0.25 : -w * 0.15, y: drift ? -h * 0.30 : -h * 0.38)
                    blob(Color.purple, size: w * 0.6)
                        .offset(x: drift ? w * 0.35 : w * 0.28, y: drift ? -h * 0.15 : -h * 0.05)
                    blob(Color.teal, size: w * 0.55)
                        .offset(x: drift ? -w * 0.05 : w * 0.05, y: drift ? h * 0.40 : h * 0.32)
                }
                .opacity(scheme == .dark ? 0.30 : 0.20)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func blob(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.55), color.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 40)
    }
}

// Gradient monogram avatar for a project (deterministic color per name).
struct MonogramAvatar: View {
    let name: String
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(BB.gradient(for: name))
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
    }
}

// A quiet, reusable status capsule used across the header, sheets and cards.
enum PillTone {
    case neutral, accent, success, warning, danger
    var fg: Color {
        switch self {
        case .neutral: return .secondary
        case .accent:  return .accentColor
        case .success: return .green
        case .warning: return .orange
        case .danger:  return .red
        }
    }
    var bg: Color {
        switch self {
        case .neutral: return Color.primary.opacity(0.06)
        case .accent:  return Color.accentColor.opacity(0.14)
        case .success: return Color.green.opacity(0.14)
        case .warning: return Color.orange.opacity(0.14)
        case .danger:  return Color.red.opacity(0.14)
        }
    }
}

struct StatusPill: View {
    let title: String
    var systemImage: String?
    var tone: PillTone
    var helpText: String?
    init(_ title: String, systemImage: String? = nil, tone: PillTone = .neutral, help: String? = nil) {
        self.title = title; self.systemImage = systemImage; self.tone = tone; self.helpText = help
    }
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(tone.fg)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(tone.bg, in: Capsule())
        .overlay(Capsule().strokeBorder(tone.fg.opacity(0.18), lineWidth: 1))
        .help(helpText ?? title)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}

// An icon inside a small tinted gradient squircle — the visual anchor of tiles and sheets.
struct GradientIcon: View {
    let systemName: String
    var tint: Color = .accentColor
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.65)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: systemName)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.35), radius: 4, y: 2)
    }
}

// Press feedback: gentle scale-down while the mouse is down.
struct PressableStyle: ButtonStyle {
    var reduceMotion = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.965 : 1)
            .animation(BB.quick(reduceMotion), value: configuration.isPressed)
    }
}

// The action tile — replaces the old flat ActionButton. Icon in a gradient
// squircle, hover lift, press scale, optional ⌘⇧ shortcut.
struct GlassTile: View {
    let title: String; let icon: String; var tint: Color = .accentColor
    var key: Character? = nil
    var reduceMotion: Bool = false
    let action: () -> Void
    init(_ title: String, _ icon: String, tint: Color = .accentColor, key: Character? = nil,
         reduceMotion: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.tint = tint; self.key = key
        self.reduceMotion = reduceMotion; self.action = action
    }
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let btn = Button(action: action) {
            HStack(spacing: 10) {
                GradientIcon(systemName: icon, tint: tint, size: 26)
                Text(title).font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 2)
            }
            .padding(.vertical, 9).padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
                    .strokeBorder(hovering ? tint.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(hovering ? 0.16 : 0.05), radius: hovering ? 9 : 4, y: hovering ? 4 : 2)
            .offset(y: hovering && !reduceMotion ? -1.5 : 0)
            .contentShape(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
        }
        .buttonStyle(PressableStyle(reduceMotion: reduceMotion))
        .opacity(isEnabled ? 1 : 0.45)
        .onHover { h in withAnimation(BB.quick(reduceMotion)) { hovering = h && isEnabled } }
        .help(title)

        if let key {
            btn.keyboardShortcut(KeyEquivalent(key), modifiers: [.command, .shift])
        } else {
            btn
        }
    }
}

// The prominent gradient capsule button (the Next action, sheet primaries).
struct HeroButton: View {
    let title: String; let icon: String
    var tint: Color = .accentColor
    var disabled: Bool = false
    var reduceMotion: Bool = false
    let action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .font(.callout)
            .foregroundStyle(disabled ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(
                Capsule().fill(disabled
                    ? AnyShapeStyle(.quaternary)
                    : AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.75)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(disabled ? 0 : 0.25), lineWidth: 1))
            .shadow(color: disabled ? .clear : tint.opacity(hovering ? 0.5 : 0.3),
                    radius: hovering ? 12 : 7, y: 3)
            .scaleEffect(hovering && !disabled && !reduceMotion ? 1.02 : 1)
        }
        .buttonStyle(PressableStyle(reduceMotion: reduceMotion))
        .disabled(disabled)
        .onHover { h in withAnimation(BB.quick(reduceMotion)) { hovering = h } }
    }
}

// Shared sheet chrome: gradient icon + title on the left, Done on the right.
struct SheetHeader: View {
    let title: String
    let icon: String
    var tint: Color = .accentColor
    var subtitle: String? = nil
    var onDone: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            GradientIcon(systemName: icon, tint: tint, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.title3.bold())
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Button("Done") { onDone() }.keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}

// ===== App =====

@main
struct BuildBuddyApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup("BuildBuddy") {
            ContentView().environmentObject(store)
                .frame(minWidth: 760, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1080, height: 740)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Pull Latest") { Task { await store.pull() } }
                    .keyboardShortcut("l", modifiers: [.command])
                Button("Refresh") { Task { await store.refresh() } }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Cancel Running Command") { store.cancelRunning() }
                    .keyboardShortcut(".", modifiers: [.command])
                Button("Check for Updates…") { Task { await store.checkForUpdates() } }
                    .keyboardShortcut("u", modifiers: [.command])
                Divider()
                Button("Sync Scan") { NotificationCenter.default.post(name: .bbShowSync, object: nil) }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                Button("Clean Project…") { NotificationCenter.default.post(name: .bbShowCleanProject, object: nil) }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
        Settings {
            OptionsView().environmentObject(store)
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

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 210, ideal: 258, max: 340)
        } detail: {
            ZStack {
                AuroraBackground(reduceMotion: store.settings.reduceMotion,
                                 accent: store.settings.accentColor)
                if store.selected == nil {
                    EmptyDetail(showInstructions: $showInstructions)
                        .transition(.opacity)
                } else {
                    DetailView(showDoctor: $showDoctor, showInstructions: $showInstructions,
                               showOptions: $showOptions, showWhatsNew: $showWhatsNew)
                        .transition(.opacity)
                }
            }
            .animation(BB.gentle(store.settings.reduceMotion), value: store.selectionID == nil)
        }
        .overlay { ToastOverlay().environmentObject(store) }
        .tint(store.settings.accentColor)
        .preferredColorScheme(store.settings.colorSchemeOverride)
        .sheet(isPresented: $showDoctor) { DoctorView().environmentObject(store) }
        .sheet(isPresented: $showInstructions) { InstructionsView().environmentObject(store) }
        .sheet(isPresented: $showOptions) { OptionsView().environmentObject(store).frame(width: 620, height: 660) }
        .sheet(isPresented: $showWhatsNew) { WhatsNewView().environmentObject(store) }
        .onReceive(NotificationCenter.default.publisher(for: .bbAddProject)) { note in
            if let url = note.object as? URL { store.addProject(at: url) }
        }
        .task(id: store.selectionID) { await watchDownloadsLoop() }
        .onAppear {
            store.restoreLastSelectionIfEnabled()
            if store.shouldShowWhatsNew() { showWhatsNew = true }
            if store.settings.cleanBuildOnLaunch { Task { await store.cleanLingeringBuildFiles() } }
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
                if store.settings.autoCommitAndPush && store.settings.autoApplyFound {
                    if let preview = await store.previewDelivery(zip: zip) {
                        await store.commitDelivery(from: preview)
                    }
                } else {
                    await MainActor.run { store.pendingDeliveryZip = zip }
                }
            }
        }
    }
}

extension Notification.Name { static let bbShowPreview = Notification.Name("bbShowPreview") }
extension Notification.Name {
    static let bbShowCommitAll = Notification.Name("bbShowCommitAll")
    static let bbAddProject = Notification.Name("bbAddProject")
    static let bbShowSync = Notification.Name("bbShowSync")
    static let bbShowCleanProject = Notification.Name("bbShowCleanProject")
}

// ===== Sidebar =====

struct Sidebar: View {
    @EnvironmentObject var store: Store
    @State private var search = ""

    private var matches: [Project] {
        search.isEmpty ? store.projects
            : store.projects.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.path.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Brand row.
            HStack(spacing: 9) {
                GradientIcon(systemName: "hammer.fill", tint: store.settings.accentColor, size: 26)
                Text("BuildBuddy")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                Text("v\(BuildBuddyVersion)")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.quaternary.opacity(0.6), in: Capsule())
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 10)

            // Glass search field.
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.caption)
                TextField("Search projects", text: $search).textFieldStyle(.plain).font(.callout)
                if !search.isEmpty {
                    Button { withAnimation(BB.quick(store.settings.reduceMotion)) { search = "" } } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
            .padding(.horizontal, 12).padding(.bottom, 8)

            // Project list.
            ScrollView {
                VStack(spacing: 3) {
                    ForEach(matches) { p in row(p) }
                    if matches.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: search.isEmpty ? "square.stack.3d.up.slash" : "magnifyingglass")
                                .font(.title3).foregroundStyle(.tertiary)
                            Text(search.isEmpty ? "No projects yet — drop a repo folder here or click Add."
                                               : "No matches.")
                                .font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 30).padding(.horizontal, 16)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                handleDrop(providers); return true
            }

            Divider().opacity(0.4)
            HStack(spacing: 8) {
                Button { pickProjectFolder() } label: {
                    Label("Add Project", systemImage: "plus.circle.fill")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(role: .destructive) { store.removeSelected() } label: { Image(systemName: "minus.circle") }
                    .buttonStyle(.borderless)
                    .disabled(store.selectionID == nil)
                    .help("Remove the selected project from the list (doesn't delete files)")
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .background(.regularMaterial)
    }

    @ViewBuilder private func row(_ p: Project) -> some View {
        let isSel = p.id == store.selectionID
        Button { store.select(p) } label: {
            HStack(spacing: 10) {
                MonogramAvatar(name: p.name, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(p.name)
                        .font(.callout.weight(isSel ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if isSel {
                        Text((p.path as NSString).abbreviatingWithTildeInPath)
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                    }
                }
                Spacer(minLength: 4)
                if isSel {
                    Circle().fill(store.statusLine == "clean" ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                        .shadow(color: (store.statusLine == "clean" ? Color.green : Color.orange).opacity(0.6), radius: 3)
                        .help(store.statusLine == "clean" ? "Clean" : "Uncommitted changes")
                }
            }
            .padding(.vertical, 6).padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSel ? AnyShapeStyle(Color.accentColor.opacity(0.16)) : AnyShapeStyle(Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSel ? Color.accentColor.opacity(0.35) : .clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(BB.spring(store.settings.reduceMotion), value: store.selectionID)
        .help((p.path as NSString).abbreviatingWithTildeInPath)
        .contextMenu {
            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([p.url]) }
        }
    }

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

// ===== Welcome (no project selected) =====

struct EmptyDetail: View {
    @EnvironmentObject var store: Store
    @Binding var showInstructions: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(BB.accentGradient(store.settings.accentColor))
                    .frame(width: 84, height: 84)
                    .blur(radius: 22).opacity(0.55)
                GradientIcon(systemName: "hammer.fill", tint: store.settings.accentColor, size: 64)
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 6) {
                Text("Welcome to BuildBuddy")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Pick a project from the sidebar, or add one — BuildBuddy handles the pull, apply, commit and push loop for you.")
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)

            HStack(spacing: 12) {
                HeroButton(title: "Add Project", icon: "plus", tint: store.settings.accentColor,
                           reduceMotion: store.settings.reduceMotion) { addProject() }
                Button { showInstructions = true } label: {
                    Label("Instructions", systemImage: "book")
                        .padding(.horizontal, 6).padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .padding(40)
        .onAppear {
            withAnimation(store.settings.reduceMotion ? .easeOut(duration: 0.12)
                          : .spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) { appeared = true }
        }
    }

    private func addProject() {
        let panel = NSOpenPanel()
        panel.title = "Choose a project repo folder"
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            NotificationCenter.default.post(name: .bbAddProject, object: url)
        }
    }
}

// ===== Detail =====

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
    @State private var inlineMessage = ""
    @State private var showConsole = false
    @State private var staleReport: Store.StaleReport?
    @State private var showStaleSheet = false
    @State private var syncReport: Store.SyncReport?     // v2.0 — sync scan results
    @State private var syncBadge = 0                      // new-file count surfaced on the tile

    enum ActiveSheet: Identifiable {
        case commit, branches, diff, history, commitAll, connectGitHub
        case applyHistory, cleanFolder, syncInsights, cleanProject
        var id: Int { hashValue }
    }

    private var reduceMotion: Bool { store.settings.reduceMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    flowCard
                    toolSections
                }
                .padding(BB.pad)
            }
            consoleDrawer
            if showConsole { console }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            handleConsoleDrop(providers); return true
        }
        .overlay {
            if dropTargeted { dropOverlay }
        }
        .navigationTitle(store.selected?.name ?? "BuildBuddy")
        .sheet(item: $sheet) { which in
            switch which {
            case .commit:
                CommitSheet(text: $commitText) { msg in Task { await store.commitPush(message: msg) } }
                    .environmentObject(store)
            case .diff:
                DiffView().environmentObject(store)
            case .history:
                HistoryView().environmentObject(store)
            case .commitAll:
                CommitAllView().environmentObject(store)
            case .branches:
                BranchOpsSheet(
                    current: store.branch,
                    branches: store.branches,
                    onSwitch: { b in Task { await store.switchBranch(b) } },
                    onNew: { name, base in Task { await store.newBranch(name, base: base) } },
                    onMerge: { b in Task { await store.merge(b) } },
                    onCopySHA: { Task { await store.copyCurrentSHA() } }
                ).environmentObject(store)
            case .applyHistory:
                ApplyHistoryView().environmentObject(store)
            case .cleanFolder:
                CleanFolderView().environmentObject(store)
            case .connectGitHub:
                ConnectGitHubSheet().environmentObject(store)
            case .syncInsights:
                SyncInsightsSheet(report: syncReport).environmentObject(store)
            case .cleanProject:
                CleanProjectSheet().environmentObject(store)
            }
        }
        .sheet(item: $pendingPreview) { preview in
            DeliveryPreviewSheet(preview: preview,
                                 autoCommit: store.selected?.autoCommitOnApply ?? true,
                                 onApply: { Task { await store.commitDelivery(from: preview) } },
                                 onCancel: { try? FileManager.default.removeItem(at: preview.tmpDir) })
                .environmentObject(store)
        }
        .onChange(of: store.pendingCommitMessage) { msg in
            if !msg.isEmpty { commitText = msg; sheet = .commit; store.pendingCommitMessage = "" }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowPreview)) { note in
            if let preview = note.object as? Store.DeliveryPreview { pendingPreview = preview }
        }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowCommitAll)) { _ in sheet = .commitAll }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowSync)) { _ in runSyncScan() }
        .onReceive(NotificationCenter.default.publisher(for: .bbShowCleanProject)) { _ in sheet = .cleanProject }
        .sheet(isPresented: $showStaleSheet) {
            StaleReportSheet(report: staleReport ?? Store.StaleReport()).environmentObject(store)
        }
        // v2.0 — quiet sync scan when a project is selected: surfaces a badge, never a popup.
        .task(id: store.selectionID) {
            syncBadge = 0
            guard store.settings.syncScanOnSelect, let p = store.selected else { return }
            let report = await store.syncScan(for: p)
            syncReport = report
            syncBadge = report.newFiles.count + report.untracked.count
            if !report.missing.isEmpty {
                store.toast("\(report.missing.count) file(s) missing vs last good build", .error)
            }
        }
    }

    // ── Header ───────────────────────────────────────────────────────────────────
    private var header: some View {
        HStack(spacing: 12) {
            if let p = store.selected {
                MonogramAvatar(name: p.name, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(p.name).font(.system(.title2, design: .rounded).weight(.bold))
                        Button { showWhatsNew = true } label: {
                            Text("v\(BuildBuddyVersion)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.tint.opacity(0.15), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .help("BuildBuddy \(BuildBuddyVersion) — click for What's New & updates")
                    }
                    Text((p.path as NSString).abbreviatingWithTildeInPath)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            }
            Spacer()

            if let p = store.selected {
                Toggle(isOn: Binding(
                    get: { p.autoCommitOnApply },
                    set: { v in store.updateSelected { $0.autoCommitOnApply = v } }
                )) { Text("Auto-commit").font(.caption) }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help("When ON, applying a delivery commits & pushes automatically using its COMMIT_MSG.txt.")
            }

            HStack(spacing: 6) {
                StatusPill(store.branch, systemImage: "arrow.triangle.branch",
                           tone: .neutral, help: "Current branch")
                StatusPill(store.hasRemote ? "GitHub" : "Local",
                           systemImage: store.hasRemote ? "cloud.fill" : "wifi.slash",
                           tone: store.hasRemote ? .success : .neutral,
                           help: store.hasRemote ? "Remote: \(store.remoteURL)" : "No GitHub remote — local git only.")
                if store.aheadBehind.ahead > 0 {
                    StatusPill("\(store.aheadBehind.ahead)", systemImage: "arrow.up",
                               tone: .success, help: "Commits ahead of origin")
                }
                if store.aheadBehind.behind > 0 {
                    StatusPill("\(store.aheadBehind.behind)", systemImage: "arrow.down",
                               tone: .warning, help: "Commits behind origin")
                }
                StatusPill(store.statusLine,
                           tone: store.statusLine == "clean" ? .success : .warning,
                           help: store.statusLine == "clean" ? "Working tree is clean" : "Uncommitted changes")
            }
            .animation(BB.spring(reduceMotion), value: store.statusLine)
            .animation(BB.spring(reduceMotion), value: store.branch)

            // Theme switcher — cycles System → Light → Dark.
            Button { cycleTheme() } label: {
                Image(systemName: themeIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Theme: \(store.settings.themeChoice) — click to switch")

            if store.busy {
                HStack(spacing: 5) {
                    ProgressView().scaleEffect(0.6)
                    if !store.currentAction.isEmpty {
                        Text(store.currentAction).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity)
            }
            if store.canCancel {
                Button(role: .destructive) { store.cancelRunning() } label: {
                    Label("Cancel", systemImage: "stop.circle.fill")
                }
                .help("Stop the running command (⌘.)")
            }
        }
        .padding(.horizontal, BB.pad).padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) { Divider().opacity(0.4) }
        .task(id: store.selectionID) { await store.updateAheadBehind() }
    }

    private var themeIcon: String {
        switch store.settings.themeChoice {
        case "light": return "sun.max.fill"
        case "dark":  return "moon.fill"
        default:      return "circle.lefthalf.filled"
        }
    }
    private func cycleTheme() {
        let next: String
        switch store.settings.themeChoice {
        case "system": next = "light"
        case "light":  next = "dark"
        default:       next = "system"
        }
        store.settings.themeChoice = next
        store.objectWillChange.send()
    }

    // ── Flow card — the "what should I do next" hero ─────────────────────────────
    private var guideText: String {
        if !store.hasRemote && store.selected != nil {
            return "Local-only repo — commit and branch freely. Use Connect to GitHub when you want to back it up."
        }
        if store.statusLine != "clean" { return "You have uncommitted changes — press Next to commit them, or apply a delivery first." }
        if syncBadge > 0 { return "\(syncBadge) new or untracked file(s) since the last good build — open Sync scan to review them." }
        return "All caught up. Apply a Claude delivery (drop the zip anywhere), or Pull to get the latest."
    }
    private var flowTitle: String {
        if store.busy { return "Working…" }
        switch store.nextStep {
        case .applyDelivery: return "Delivery ready to review"
        case .commit:        return "Changes ready to commit"
        case .finished:      return store.hasRemote ? "Repo is clean" : "Local repo — clean"
        }
    }
    private var flowIcon: String {
        if store.busy { return "hourglass" }
        switch store.nextStep {
        case .applyDelivery: return "tray.and.arrow.down.fill"
        case .commit:        return "square.and.pencil"
        case .finished:      return "checkmark.seal.fill"
        }
    }
    private var flowTint: Color {
        if store.busy { return store.settings.accentColor }
        switch store.nextStep {
        case .applyDelivery: return store.settings.accentColor
        case .commit:        return .orange
        case .finished:      return .green
        }
    }

    private var flowCard: some View {
        let step = store.nextStep
        let dirty = store.statusLine != "clean" && store.statusLine != ""
        let showCommitField = dirty || step == .commit
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                GradientIcon(systemName: flowIcon, tint: flowTint, size: 38)
                    .id(flowIcon)   // re-animate when the state icon changes
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                VStack(alignment: .leading, spacing: 3) {
                    Text(flowTitle).font(.system(.title3, design: .rounded).weight(.bold))
                    Text(guideText).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if store.busy {
                    ProgressView().progressViewStyle(.linear).frame(width: 130)
                }
            }
            if showCommitField { commitBar.transition(.opacity.combined(with: .move(edge: .top))) }
            HStack(spacing: 12) {
                HeroButton(title: step.title, icon: step.systemImage, tint: flowTint,
                           disabled: store.selected == nil || store.busy || step == .finished,
                           reduceMotion: reduceMotion) {
                    Task {
                        await store.runNextStep(commitMessage: inlineMessage, applyHandler: { zip in beginPreview(zip) })
                        inlineMessage = await store.autoCommitMessage()
                    }
                }
                Spacer(minLength: 8)
                HStack(spacing: 14) {
                    Button { pickDeliveryZip() } label: { Label("Apply delivery", systemImage: "tray.and.arrow.down") }
                    Button { sheet = .diff } label: { Label("View diff", systemImage: "doc.text.magnifyingglass") }
                    if store.hasRemote {
                        Button { Task { await store.pull() } } label: { Label("Pull latest", systemImage: "arrow.down.circle") }
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .disabled(store.busy || store.selected == nil)
            }
        }
        .padding(BB.pad)
        .glassCard(elevated: true)
        .animation(BB.spring(reduceMotion), value: store.nextStep)
        .animation(BB.spring(reduceMotion), value: store.busy)
    }

    private var commitBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.pencil").foregroundStyle(.secondary)
            TextField("Commit message (auto-filled — edit if you like)", text: $inlineMessage)
                .textFieldStyle(.plain)
            Button {
                Task { inlineMessage = await store.autoCommitMessage() }
            } label: { Image(systemName: "wand.and.stars").foregroundStyle(.tint) }
                .buttonStyle(.borderless)
                .help("Regenerate an automatic message from the current changes")
                .disabled(store.selected == nil)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        .task(id: store.selectionID) {
            if inlineMessage.isEmpty, store.selected != nil {
                inlineMessage = await store.autoCommitMessage()
            }
        }
    }

    // ── Tool sections ────────────────────────────────────────────────────────────
    private var gridCols: [GridItem] { [GridItem(.adaptive(minimum: 176), spacing: 10)] }

    @ViewBuilder private func sectionLabel(_ title: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(tint)
            Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(.secondary).tracking(0.8)
        }
    }

    private var toolSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Daily", "bolt.fill", store.settings.accentColor)
                LazyVGrid(columns: gridCols, spacing: 10) {
                    if store.hasRemote {
                        tile("Pull latest", "arrow.down.circle.fill", .green, key: "l") { Task { await store.pull() } }
                    }
                    tile("Apply delivery", "tray.and.arrow.down.fill", .blue, key: "d") { pickDeliveryZip() }
                    tile("View diff", "doc.text.magnifyingglass", .purple, key: "i") { sheet = .diff }
                    tile("Branches", "arrow.triangle.branch", .indigo) { sheet = .branches }
                    tile("Open in Xcode", "hammer.fill", .indigo, key: "o") { Task { await store.openXcode() } }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Sync & Learn", "brain.head.profile", .teal)
                LazyVGrid(columns: gridCols, spacing: 10) {
                    ZStack(alignment: .topTrailing) {
                        tile("Sync scan", "arrow.triangle.2.circlepath", .teal) { runSyncScan() }
                        if syncBadge > 0 {
                            Text("\(syncBadge)")
                                .font(.caption2.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.teal, in: Capsule())
                                .offset(x: 6, y: -6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    tile("Learn this build", "graduationcap.fill", .mint) { learnNow() }
                    tile("Check stale files", "exclamationmark.magnifyingglass", .yellow) { runStaleScan() }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Version & Build", "number", .green)
                LazyVGrid(columns: gridCols, spacing: 10) {
                    tile("Bump build", "hammer.circle.fill", .orange) { Task { await store.bumpBuild() } }
                    tile("Bump version", "1.circle.fill", .green) { Task { await store.bumpVersion() } }
                    tile("Standardize app", "checkmark.seal.fill", .blue) { confirmStandardize() }
                    tile("Reset to 1.0 / 1", "arrow.counterclockwise.circle", .gray) { confirmResetVersion() }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Clean", "sparkles", .red)
                LazyVGrid(columns: gridCols, spacing: 10) {
                    tile("Clean project", "wand.and.stars", .red, key: "k") { sheet = .cleanProject }
                    tile("Clean folder…", "folder.badge.minus", .red, key: "e") { sheet = .cleanFolder }
                    tile("Clean Downloads…", "arrow.down.circle.dotted", .red) { confirmCleanDownloads() }
                    tile("Clean build files", "trash.slash.fill", .red) { Task { await store.cleanLingeringBuildFiles() } }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Repo & Tools", "wrench.and.screwdriver.fill", .orange)
                LazyVGrid(columns: gridCols, spacing: 10) {
                    tile("Commit history", "clock.arrow.circlepath", .brown) { sheet = .history }
                    tile("Apply history", "clock.badge.checkmark.fill", .brown) { sheet = .applyHistory }
                    tile("Commit all dirty", "square.stack.3d.up.fill", .orange) { sheet = .commitAll }
                    if store.hasRemote {
                        tile("Push", "arrow.up.circle.fill", .green, key: "p") { Task { await store.pushOnly() } }
                        tile("Fetch", "arrow.down.left.circle.fill", .cyan) { Task { await store.fetch() } }
                        tile("Open on GitHub", "safari.fill", .blue) { Task { await store.openOnGitHub() } }
                    } else {
                        tile("Connect to GitHub…", "link.badge.plus", .green) { sheet = .connectGitHub }
                    }
                    tile("Deploy Worker", "cloud.fill", .teal) { Task { await store.deployWorker() } }
                    tile("Refresh", "arrow.clockwise", .gray, key: "r") { Task { await store.refresh() } }
                    tile("Reveal in Finder", "folder.fill", .gray) { store.revealInFinder() }
                    tile("Discard changes", "arrow.uturn.backward.circle.fill", .red) { confirmDiscard() }
                    tile("Doctor", "stethoscope", .pink) { showDoctor = true }
                    tile("Instructions", "book.fill", .orange) { showInstructions = true }
                    tile("Options", "gearshape.fill", .gray, key: ",") { showOptions = true }
                    tile("Check for updates", "arrow.down.app.fill", .green) { showWhatsNew = true; Task { await store.checkForUpdates() } }
                }
            }
        }
    }

    private func tile(_ title: String, _ icon: String, _ tint: Color, key: Character? = nil,
                      action: @escaping () -> Void) -> GlassTile {
        GlassTile(title, icon, tint: tint, key: key, reduceMotion: reduceMotion, action: action)
    }

    // ── Console drawer ───────────────────────────────────────────────────────────
    private var consoleDrawer: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(BB.gentle(reduceMotion)) { showConsole.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "terminal").font(.system(size: 12, weight: .semibold))
                    Text("Console").font(.caption.bold())
                    Image(systemName: "chevron.up")
                        .font(.caption2.weight(.bold))
                        .rotationEffect(.degrees(showConsole ? 180 : 0))
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(showConsole ? "Hide console" : "Show console")

            if !showConsole {
                if store.busy {
                    ProgressView().progressViewStyle(.linear).frame(maxWidth: 200)
                    Text(store.currentAction.isEmpty ? "Working…" : store.currentAction)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else if !store.lastResult.isEmpty {
                    Text(store.lastResult).font(.caption)
                        .foregroundStyle(store.lastResult.hasPrefix("✅") ? .green : (store.lastResult.hasPrefix("❌") ? .red : .secondary))
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
            Spacer()
            if showConsole {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(store.console, forType: .string)
                }, label: { Image(systemName: "doc.on.doc") })
                    .buttonStyle(.borderless).help("Copy console")
                Button(action: { store.saveConsole() }, label: { Image(systemName: "square.and.arrow.down") })
                    .buttonStyle(.borderless).help("Save console")
                Button(action: { store.clearConsole() }, label: { Image(systemName: "trash") })
                    .buttonStyle(.borderless).help("Clear console")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider().opacity(0.4) }
    }

    private var console: some View {
        VStack(alignment: .leading, spacing: 0) {
            ConsoleResizeHandle(height: Binding(
                get: { store.settings.consoleHeight },
                set: { store.settings.consoleHeight = min(600, max(120, $0)) }
            ))
            HStack {
                Text("CONSOLE").font(.caption2.bold()).foregroundStyle(.secondary).tracking(0.8)
                Spacer()
                TextField("Filter…", text: $consoleQuery)
                    .textFieldStyle(.roundedBorder).frame(width: 160).font(.caption)
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
                .onChange(of: store.console) { _ in proxy.scrollTo("end", anchor: .bottom) }
            }
            .frame(height: store.settings.consoleHeight)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.75))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var dropOverlay: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 12) {
                GradientIcon(systemName: "tray.and.arrow.down.fill", tint: store.settings.accentColor, size: 56)
                Text("Drop the delivery zip").font(.title3.bold())
                Text("It will be previewed before anything is applied.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(30)
            .glassCard(elevated: true)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // ── Actions & confirmations ──────────────────────────────────────────────────
    private func runSyncScan() {
        guard let p = store.selected else { return }
        Task {
            store.line("🔎 Sync scan: comparing \(p.name) against the last good build…")
            let report = await store.syncScan(for: p)
            await MainActor.run {
                syncReport = report
                syncBadge = report.newFiles.count + report.untracked.count
                sheet = .syncInsights
            }
        }
    }

    private func learnNow() {
        guard let p = store.selected else { return }
        store.learnBaseline(for: p)
    }

    private func handleConsoleDrop(_ providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var urls: [URL] = []
        let lock = NSLock()
        for prov in providers {
            group.enter()
            _ = prov.loadObject(ofClass: URL.self) { url, _ in
                if let url, url.pathExtension.lowercased() == "zip" {
                    lock.lock(); urls.append(url); lock.unlock()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            guard !urls.isEmpty else { return }
            if urls.count > 1 {
                store.line("Dropped \(urls.count) zips — applying the first; drop one at a time for the rest.")
            }
            beginPreview(urls[0])
        }
    }

    private func pickDeliveryZip() {
        let panel = NSOpenPanel()
        panel.title = "Choose a delivery zip"
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        if panel.runModal() == .OK, let url = panel.url {
            beginPreview(url)
        }
    }

    private func confirmCleanDownloads() {
        let alert = NSAlert()
        alert.messageText = "Clean the Downloads folder?"
        alert.informativeText = "Removes delivery .zip files (and their extracted folders) that pile up in ~/Downloads. Choose what to remove."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Zips + extracted folders")
        alert.addButton(withTitle: "Zips only")
        alert.addButton(withTitle: "Cancel")
        let r = alert.runModal()
        if r == .alertFirstButtonReturn { Task { await store.cleanDownloads(zipsOnly: false, dryRun: false) } }
        else if r == .alertSecondButtonReturn { Task { await store.cleanDownloads(zipsOnly: true, dryRun: false) } }
    }

    private func runStaleScan() {
        guard let p = store.selected else { return }
        Task {
            store.line("🔎 Scanning for stale builds, duplicate names, and missed files…")
            let report = await store.scanStaleFiles(for: p)
            await MainActor.run {
                staleReport = report
                showStaleSheet = true
                if report.isEmpty { store.toast("No stale files found", .success) }
                else { store.toast("Found items to review", .info) }
            }
        }
    }

    private func confirmDiscard() {
        let alert = NSAlert()
        alert.messageText = "Discard all uncommitted changes?"
        alert.informativeText = "This runs git reset --hard and git clean -fd. Unsaved work in this repo will be permanently lost."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { Task { await store.discardChanges() } }
    }

    private func confirmResetVersion() {
        let alert = NSAlert()
        alert.messageText = "Reset version and build to the standard baseline?"
        alert.informativeText = "Sets CFBundleShortVersionString to 1.0 and CFBundleVersion to 1 in this project's Info.plist, retiring its old numbers. Use this once when migrating an app to the shared standard, then commit."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset to 1.0 / build 1")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { Task { await store.resetVersionBuild() } }
    }

    private func confirmStandardize() {
        Task {
            guard let p = store.selected else { return }
            let info = await store.locateVersionFiles(for: p)
            let already = store.isStandardized(info)
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = already
                    ? "This app is already standardized."
                    : "Standardize this app to the shared scheme?"
                let where_ = [info.hasPbxKeys ? "Xcode project" : nil, info.plistPath != nil ? "Info.plist" : nil]
                    .compactMap { $0 }.joined(separator: " + ")
                alert.informativeText = already
                    ? "It's on version \(info.version), build \(info.build). Standardizing will NOT reset your numbers — it will just add a timestamped What's New entry. Continue?"
                    : "Sets version 1.0 and build 1 in \(where_.isEmpty ? "the app" : where_), and adds a timestamped What's New entry (MM:DD:YY HH:MM). Then commit. Continue?"
                alert.alertStyle = already ? .informational : .warning
                alert.addButton(withTitle: already ? "Add entry" : "Standardize")
                alert.addButton(withTitle: "Cancel")
                if alert.runModal() == .alertFirstButtonReturn { Task { await store.standardizeApp() } }
            }
        }
    }

    private var displayedConsole: String {
        guard !consoleQuery.isEmpty else { return store.console }
        let lines = store.console.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { $0.range(of: consoleQuery, options: .caseInsensitive) != nil }
        return lines.joined(separator: "\n")
    }

    private func beginPreview(_ url: URL) {
        Task {
            if let preview = await store.previewDelivery(zip: url) {
                if store.settings.confirmBeforeApply {
                    await MainActor.run { pendingPreview = preview }
                } else {
                    await store.commitDelivery(from: preview)
                }
            }
        }
    }
}

// ===== Sheets =====

struct DeliveryPreviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let preview: Store.DeliveryPreview
    let autoCommit: Bool
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Review delivery", icon: "tray.and.arrow.down.fill",
                        tint: .blue,
                        subtitle: "Only changed or new files are applied — identical files are skipped.") {
                onCancel(); dismiss()
            }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    StatusPill("\(preview.changedFiles.count) to apply", systemImage: "square.and.pencil",
                               tone: preview.changedFiles.isEmpty ? .neutral : .warning)
                    if !preview.newFiles.isEmpty {
                        StatusPill("\(preview.newFiles.count) new", systemImage: "plus", tone: .accent)
                    }
                    StatusPill("\(preview.unchangedFiles.count) unchanged", systemImage: "equal", tone: .neutral)
                    StatusPill(preview.hasCommitScript ? "commit.sh" : "no commit.sh",
                               systemImage: "terminal",
                               tone: preview.hasCommitScript ? .success : .neutral)
                    Spacer()
                }

                if preview.nothingToApply && !preview.files.isEmpty {
                    Label("Already applied — all \(preview.files.count) file(s) match your repo. Nothing to do.",
                          systemImage: "checkmark.circle.fill")
                        .font(.callout).foregroundStyle(.green)
                }

                reviewCard("Files") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            if preview.files.isEmpty {
                                Text("No files found in the drop.").font(.caption).foregroundStyle(.secondary)
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
                        }.padding(8)
                    }.frame(height: 150)
                }

                reviewCard("Commit message") {
                    ScrollView {
                        Text(preview.commitMessage.isEmpty ? "(none — you'll commit manually)" : preview.commitMessage)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(preview.commitMessage.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }.frame(height: 80)
                }

                if preview.nothingToApply {
                    EmptyView()
                } else if !preview.messageProblems.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Commit message is shell-unsafe — it'll open for manual review instead of auto-committing.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.orange)
                        ForEach(preview.messageProblems, id: \.self) { p in
                            Text("• \(p)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                } else if autoCommit && !preview.commitMessage.isEmpty {
                    Label("Auto-commit is ON — applying will commit & push automatically.",
                          systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    Label("Auto-commit is OFF — you'll see the commit sheet after applying.",
                          systemImage: "hand.raised.fill")
                        .font(.caption).foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Spacer()
                    Button(preview.nothingToApply ? "Close" : "Cancel") { onCancel(); dismiss() }
                    if !preview.nothingToApply {
                        HeroButton(title: "Apply \(preview.changedFiles.count) file\(preview.changedFiles.count == 1 ? "" : "s")",
                                   icon: "checkmark", tint: .blue,
                                   reduceMotion: store.settings.reduceMotion) {
                            onApply(); dismiss()
                        }
                    }
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 580)
    }

    @ViewBuilder private func reviewCard(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(.secondary).tracking(0.8)
            content()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
}

struct CommitSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @Binding var text: String
    let onCommit: (String) -> Void

    private var problems: [String] { CommitSafety.problems(in: text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Commit & Push", icon: "checkmark.circle.fill", tint: .green) { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 12) {
                Text("COMMIT MESSAGE").font(.caption2.bold()).foregroundStyle(.secondary).tracking(0.8)
                TextEditor(text: $text).frame(height: 120)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
                        .strokeBorder(problems.isEmpty ? Color.white.opacity(0.12) : Color.red.opacity(0.8), lineWidth: 1))
                if problems.isEmpty {
                    Label("Safe for BuildBuddy commit", systemImage: "checkmark.circle.fill")
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
                    HeroButton(title: "Commit & Push", icon: "arrow.up.circle.fill", tint: .green,
                               disabled: text.trimmingCharacters(in: .whitespaces).isEmpty || !problems.isEmpty,
                               reduceMotion: store.settings.reduceMotion) {
                        onCommit(text); dismiss()
                    }
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 500)
    }
}

// Combined branch operations: switch, create, merge, and copy SHA in one sheet.
struct BranchOpsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let current: String
    let branches: [String]
    let onSwitch: (String) -> Void
    let onNew: (String, String) -> Void
    let onMerge: (String) -> Void
    let onCopySHA: () -> Void

    @State private var switchTo = ""
    @State private var newName = ""
    @State private var newBase = ""
    @State private var mergeFrom = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Branches", icon: "arrow.triangle.branch", tint: .indigo,
                        subtitle: "Currently on \(current)") { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 14) {
                card("Switch branch", "arrow.left.arrow.right") {
                    HStack {
                        Picker("", selection: $switchTo) {
                            ForEach(branches, id: \.self) { Text($0) }
                        }.labelsHidden()
                        Button("Switch") { onSwitch(switchTo.isEmpty ? (branches.first ?? "") : switchTo); dismiss() }
                            .disabled(branches.isEmpty)
                    }
                }
                card("New branch", "plus.circle") {
                    HStack {
                        TextField("new-branch-name", text: $newName).textFieldStyle(.roundedBorder)
                        Picker("from", selection: $newBase) {
                            Text("current (\(current))").tag("")
                            ForEach(branches, id: \.self) { Text($0).tag($0) }
                        }
                        Button("Create") {
                            let base = newBase.isEmpty ? current : newBase
                            onNew(newName.trimmingCharacters(in: .whitespaces), base); dismiss()
                        }.disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                card("Merge into \(current)", "arrow.triangle.merge") {
                    HStack {
                        Picker("", selection: $mergeFrom) {
                            ForEach(branches.filter { $0 != current }, id: \.self) { Text($0) }
                        }.labelsHidden()
                        Button("Merge") { if !mergeFrom.isEmpty { onMerge(mergeFrom) }; dismiss() }
                            .disabled(branches.filter { $0 != current }.isEmpty)
                    }
                }
                HStack {
                    Button { onCopySHA(); dismiss() } label: { Label("Copy current SHA", systemImage: "doc.on.doc") }
                    Spacer()
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 500)
        .onAppear {
            switchTo = current.isEmpty ? (branches.first ?? "") : current
            mergeFrom = branches.first { $0 != current } ?? ""
        }
    }

    @ViewBuilder private func card(_ title: String, _ icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// ===== v2.0 — Sync & Learn insights =====

struct SyncInsightsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let report: Store.SyncReport?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Sync scan", icon: "arrow.triangle.2.circlepath", tint: .teal,
                        subtitle: subtitleText) { dismiss() }
            Divider().opacity(0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let r = report {
                        if !r.hasBaseline {
                            VStack(spacing: 10) {
                                GradientIcon(systemName: "graduationcap.fill", tint: .mint, size: 46)
                                Text("No baseline yet").font(.headline)
                                Text("Click \"Learn this build\" (or just commit) and BuildBuddy will snapshot every file. From then on it knows exactly what's new, what's missing, and what shrank.")
                                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                Button {
                                    if let p = store.selected { store.learnBaseline(for: p) }
                                    dismiss()
                                } label: { Label("Learn this build now", systemImage: "graduationcap.fill") }
                                    .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                        } else if r.isEmpty {
                            VStack(spacing: 10) {
                                GradientIcon(systemName: "checkmark.seal.fill", tint: .green, size: 46)
                                Text("Fully in sync").font(.headline)
                                Text("No new, missing, or shrunken files versus the last good build, and git reports nothing untracked.")
                                    .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 24)
                        } else {
                            section("New files since the last good build", "sparkles", .teal, r.newFiles,
                                    "These files appeared after the baseline was learned. If they belong to the project, commit them so they're never lost.")
                            section("New folders", "folder.badge.plus", .blue, r.newFolders,
                                    "Entire folders that didn't exist in the last good build.")
                            section("Untracked by git", "questionmark.folder.fill", .orange, r.untracked,
                                    "Files git isn't tracking and isn't ignoring — the classic way work gets left behind.")
                            section("Missing vs last good build", "exclamationmark.triangle.fill", .red, r.missing,
                                    "These existed in the last good build but are gone now. If that's unexpected, this is a regression — restore before committing.")
                            section("Drastically smaller", "arrow.down.right.circle.fill", .red, r.shrunk,
                                    "Source files at less than half their last-good size — a common sign a delivery replaced a full file with a stub.")
                        }
                    } else {
                        Text("Select a project and run Sync scan.").foregroundStyle(.secondary).padding()
                    }
                }
                .padding(BB.pad)
            }
            if let r = report, !(r.untracked.isEmpty && r.newFiles.isEmpty) {
                Divider().opacity(0.4)
                HStack {
                    Text("Committing updates the baseline automatically.")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Task { _ = await store.commitOnly(message: "Add new and untracked project files"); dismiss() }
                    } label: { Label("Commit the new files", systemImage: "checkmark.circle") }
                        .buttonStyle(.borderedProminent)
                }
                .padding(12)
            }
        }
        .frame(width: 640, height: 560)
    }

    private var subtitleText: String {
        guard let r = report, r.hasBaseline else { return "Compare the project to its last good build" }
        let when = r.baselineDate.map { DateFormatter.bbStamp.string(from: $0) } ?? "unknown"
        return "Baseline: good build #\(r.goodBuilds) · learned \(when)"
    }

    @ViewBuilder private func section(_ title: String, _ icon: String, _ tint: Color, _ items: [String], _ desc: String) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: icon).foregroundStyle(tint)
                    Text(title).font(.headline)
                    Text("\(items.count)").font(.caption.bold()).foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
                Text(desc).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(items.prefix(30), id: \.self) { item in
                        Text(item).font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled).lineLimit(1).truncationMode(.middle)
                    }
                    if items.count > 30 {
                        Text("…and \(items.count - 30) more").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
            }
        }
    }
}

// ===== v2.0 — Clean Project =====

struct CleanProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var candidates: [String] = []
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Clean project", icon: "wand.and.stars", tint: .red,
                        subtitle: store.selected.map { "Build artifacts inside \($0.name)" } ?? "") { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 12) {
                Text("Removes build output only — .build, build, DerivedData, object files, logs, and .DS_Store. Source files and .git are never touched.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !loaded {
                    HStack(spacing: 8) { ProgressView().scaleEffect(0.6); Text("Scanning…").font(.caption).foregroundStyle(.secondary) }
                        .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 20)
                } else if candidates.isEmpty {
                    VStack(spacing: 8) {
                        GradientIcon(systemName: "checkmark.seal.fill", tint: .green, size: 40)
                        Text("Already clean — no build artifacts found.").font(.callout)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                } else {
                    Text("\(candidates.count) ITEM(S) TO REMOVE").font(.caption2.bold()).foregroundStyle(.secondary).tracking(0.8)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(candidates, id: \.self) {
                                Text($0).font(.system(.caption2, design: .monospaced))
                                    .lineLimit(1).truncationMode(.middle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(8)
                    }
                    .frame(height: 180)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
                }

                HStack {
                    Button("Rescan") { rescan() }
                    Spacer()
                    Button("Cancel") { dismiss() }
                    HeroButton(title: "Clean \(candidates.count) item\(candidates.count == 1 ? "" : "s")",
                               icon: "wand.and.stars", tint: .red,
                               disabled: candidates.isEmpty,
                               reduceMotion: store.settings.reduceMotion) {
                        guard let p = store.selected else { return }
                        dismiss()
                        Task { await store.cleanProject(for: p, dryRun: false) }
                    }
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 540)
        .onAppear { rescan() }
    }

    private func rescan() {
        loaded = false
        guard let p = store.selected else { candidates = []; loaded = true; return }
        DispatchQueue.global(qos: .userInitiated).async {
            let found = store.cleanProjectCandidates(for: p).map {
                $0.path.replacingOccurrences(of: p.path + "/", with: "")
            }
            DispatchQueue.main.async { candidates = found; loaded = true }
        }
    }
}

// ===== Options =====

struct OptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    private var s: SettingsStore { store.settings }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Options", icon: "gearshape.fill", tint: .gray) { dismiss() }
            Divider().opacity(0.4)
            Form {
                Section("Appearance & motion") {
                    Picker("Theme", selection: binding(\.themeChoice)) {
                        Text("Match system").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    Picker("Accent color", selection: binding(\.accentChoice)) {
                        Text("Blue").tag("blue"); Text("Purple").tag("purple"); Text("Pink").tag("pink")
                        Text("Green").tag("green"); Text("Orange").tag("orange"); Text("Red").tag("red")
                        Text("Teal").tag("teal"); Text("Indigo").tag("indigo")
                    }
                    Toggle("Reduce motion (calmer, faster transitions)", isOn: binding(\.reduceMotion))
                }

                Section("Sync & Learn") {
                    Toggle("Scan for new files when a project is selected", isOn: binding(\.syncScanOnSelect))
                    Toggle("Regression guard — warn before commit if files went missing or shrank", isOn: binding(\.regressionGuard))
                    Toggle("Learn the baseline automatically after every commit", isOn: binding(\.autoLearnOnCommit))
                    Toggle("Auto-clear caches after commit (status cache, temp extractions, prune old backups)", isOn: binding(\.autoClearCachesOnCommit))
                    Text("BuildBuddy snapshots every good build. New files are surfaced so they're never forgotten, and vanished or drastically-shrunken files are flagged before a commit can seal in a regression.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

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

                Section("Cleanup after applying a delivery") {
                    Toggle("Delete the original .zip after a successful apply", isOn: binding(\.deleteZipAfterApply))
                    Toggle("Delete the extracted folder after applying", isOn: binding(\.deleteExtractedAfterApply))
                    Text("The zip is only deleted when a delivery actually applies — skipped or already-applied deliveries keep their zip so you can retry.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Pushing") {
                    Toggle("Pause ALL auto-push (commit locally, never touch the remote)", isOn: binding(\.pauseAllAutoPush))
                    Toggle("Force-push over a diverged remote (fetch, then force-with-lease, then force)", isOn: binding(\.forcePushOnReject))
                    Text("If your push is rejected as non-fast-forward, BuildBuddy can recover automatically by overwriting the remote with your local history. Safe only when you're the sole contributor and the remote is disposable — your LOCAL commits are never altered. If you'd rather be the only thing that pushes, turn on Pause all auto-push and push from Terminal yourself.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Folder monitoring") {
                    Text("Folders to watch for delivery zips (one path per line). Downloads is always watched.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: binding(\.extraWatchFolders)).frame(height: 56)
                        .font(.system(.caption, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.secondary.opacity(0.3)))
                    Divider()
                    Text("Folders to scan when cleaning lingering BuildBuddy build files (one per line). Blank = the app's own parent folder.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: binding(\.buildCleanupFolders)).frame(height: 56)
                        .font(.system(.caption, design: .monospaced))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.secondary.opacity(0.3)))
                    Toggle("Clean lingering build files on launch", isOn: binding(\.cleanBuildOnLaunch))
                    HStack {
                        Button("Preview cleanup (dry run)") { Task { await store.cleanLingeringBuildFiles(dryRun: true) } }
                        Button("Clean now") { Task { await store.cleanLingeringBuildFiles() } }
                    }
                    Text("Removes .build, build.log, stale *.app copies, *.o / *.swiftmodule and similar. Never deletes BuildBuddy.swift, the launcher, the running app, or .git.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Console & feedback") {
                    Toggle("Verbose logging", isOn: binding(\.verboseLogging))
                    Toggle("Monospace console font", isOn: binding(\.monospaceConsole))
                    Toggle("Play a sound when a command finishes", isOn: binding(\.soundOnFinish))
                    Toggle("Dry-run mode (print actions, never write/commit/push)", isOn: binding(\.dryRunMode))
                        .help("Great for testing — shows exactly what BuildBuddy would do without touching anything.")
                }

                Section {
                    Button("Reset all options to defaults") { store.settings.resetToDefaults(); store.objectWillChange.send() }
                }
            }
            .formStyle(.grouped)
        }
    }

    // Bridge SettingsStore @AppStorage to bindings; nudges the Store so accent/theme
    // changes repaint the whole window immediately.
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<SettingsStore, T>) -> Binding<T> {
        Binding(get: { store.settings[keyPath: keyPath] },
                set: { store.settings[keyPath: keyPath] = $0; store.objectWillChange.send() })
    }
}

// ===== What's New =====

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                GradientIcon(systemName: "sparkles", tint: store.settings.accentColor, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("What's New in BuildBuddy").font(.title3.bold())
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
            Divider().opacity(0.4)
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
        .frame(width: 660, height: 580)
    }
}

// ===== Instructions =====

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var doc = 0

    private var currentText: String {
        switch doc {
        case 1:  return BuildStandard.text
        case 2:  return DeployInstructions.text
        default: return DeliveryInstructions.text
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Instructions", icon: "book.fill", tint: .orange,
                        subtitle: "Delivery format · Build & Version standard · Deploy website") { dismiss() }

            Picker("", selection: $doc) {
                Text("Delivery format").tag(0)
                Text("Build & Version standard").tag(1)
                Text("Deploy website").tag(2)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                Text("Export all documents:").font(.caption).foregroundStyle(.secondary)
                Button { store.copyInstructions() } label: { Label("Copy", systemImage: "doc.on.doc") }
                    .controlSize(.small)
                Button { store.exportInstructions(markdown: true) } label: { Label("Save .md", systemImage: "arrow.down.doc") }
                    .controlSize(.small)
                Button { store.exportInstructions(markdown: false) } label: { Label("Save .txt", systemImage: "arrow.down.doc") }
                    .controlSize(.small)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            Divider().opacity(0.4)
            ScrollView {
                Text(currentText)
                    .font(.system(.body, design: .default))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .frame(width: 760, height: 660)
    }
}

// ===== Doctor =====

struct DoctorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var rows: [ToolRow] = []
    @State private var working = false
    @State private var ghAuth: String = "checking…"

    struct ToolRow: Identifiable { let id = UUID(); let name: String; let probe: String; var found: String? }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Doctor", icon: "stethoscope", tint: .pink,
                        subtitle: "Dependency checks · BuildBuddy v\(BuildBuddyVersion)") { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 12) {
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

                Divider().opacity(0.4)
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
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 560)
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

// ===== Feature views =====

struct DiffView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var diff = "Loading…"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Pending changes", icon: "doc.text.magnifyingglass", tint: .purple,
                        subtitle: store.selected?.name ?? "") { dismiss() }
            HStack {
                Spacer()
                Button { Task { diff = await store.pendingDiff() } } label: { Label("Reload", systemImage: "arrow.clockwise") }
                    .controlSize(.small)
            }
            .padding(.horizontal, 16).padding(.bottom, 8)
            Divider().opacity(0.4)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    let lines = diff.split(separator: "\n", omittingEmptySubsequences: false)
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, raw in
                        let s = String(raw)
                        Text(s.isEmpty ? " " : s)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(diffColor(s))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .background(diffBackground(s))
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 780, height: 620)
        .task { diff = await store.pendingDiff() }
    }

    private func diffColor(_ s: String) -> Color {
        if s.hasPrefix("+") && !s.hasPrefix("+++") { return .green }
        if s.hasPrefix("-") && !s.hasPrefix("---") { return .red }
        if s.hasPrefix("@@") { return .cyan }
        if s.hasPrefix("diff ") || s.hasPrefix("+++") || s.hasPrefix("---") || s.hasPrefix("index ") { return .secondary }
        return .primary
    }
    private func diffBackground(_ s: String) -> Color {
        if s.hasPrefix("+") && !s.hasPrefix("+++") { return Color.green.opacity(0.08) }
        if s.hasPrefix("-") && !s.hasPrefix("---") { return Color.red.opacity(0.08) }
        return Color.clear
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var rows: [Store.CommitRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Recent commits", icon: "clock.arrow.circlepath", tint: .brown,
                        subtitle: store.selected?.name ?? "") { dismiss() }
            Divider().opacity(0.4)
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
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 720, height: 560)
        .task { rows = await store.recentCommits() }
    }
}

struct CommitAllView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var msg = ""
    private var problems: [String] { CommitSafety.problems(in: msg) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Commit all dirty repositories", icon: "square.stack.3d.up.fill", tint: .orange,
                        subtitle: "Same message, every dirty project — scoped per repo, then pushed") { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $msg).frame(height: 90)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous)
                        .strokeBorder(problems.isEmpty ? Color.white.opacity(0.12) : Color.red.opacity(0.8), lineWidth: 1))
                if !problems.isEmpty {
                    ForEach(problems, id: \.self) { Text("• \($0)").font(.caption2).foregroundStyle(.red) }
                }
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                    HeroButton(title: "Commit all", icon: "checkmark.circle.fill", tint: .orange,
                               disabled: msg.trimmingCharacters(in: .whitespaces).isEmpty || !problems.isEmpty,
                               reduceMotion: store.settings.reduceMotion) {
                        let m = msg; dismiss(); Task { await store.commitAllDirty(message: m) }
                    }
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 500)
    }
}

struct ApplyHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                GradientIcon(systemName: "clock.badge.checkmark.fill", tint: .brown, size: 34)
                Text("Apply history").font(.title3.bold())
                Spacer()
                Button("Clear") { store.clearHistory() }.disabled(store.history.isEmpty)
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }.padding(16)
            Divider().opacity(0.4)
            if store.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark").font(.system(size: 40)).foregroundStyle(.secondary)
                    Text("No deliveries applied yet.").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.history.reversed()) { rec in
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 8) {
                                        Text(rec.projectName).fontWeight(.semibold)
                                        if let sha = rec.commitSHA {
                                            Text(sha.prefix(8)).font(.caption.monospaced()).foregroundStyle(.tint)
                                        }
                                        Text(rec.date, style: .date).font(.caption2).foregroundStyle(.secondary)
                                        Text(rec.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Text("\(rec.fileCount) file\(rec.fileCount == 1 ? "" : "s")\(rec.zipName.map { " · \($0)" } ?? "")")
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Text(rec.commitMessage.split(separator: "\n").first.map(String.init) ?? "")
                                        .font(.caption).lineLimit(1)
                                }
                                Spacer()
                                if rec.backupDir != nil {
                                    Button("Undo") { Task { await store.undoApply(rec) } }
                                        .buttonStyle(.bordered).controlSize(.small)
                                        .help("Restore the files this delivery overwrote, from the backup taken at apply time")
                                } else {
                                    Text("no backup").font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
        .frame(width: 720, height: 560)
    }
}

struct ConsoleResizeHandle: View {
    @Binding var height: Double
    @State private var startHeight: Double? = nil

    var body: some View {
        ZStack {
            Rectangle().fill(Color.secondary.opacity(0.001)).frame(height: 10)
            Capsule().fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
        }
        .contentShape(Rectangle())
        .onHover { inside in
            if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if startHeight == nil { startHeight = height }
                    height = (startHeight ?? height) - value.translation.height
                }
                .onEnded { _ in startHeight = nil }
        )
    }
}

struct ConnectGitHubSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store

    enum Path: String, CaseIterable { case cli = "GitHub CLI", browser = "Browser + commands" }
    @State private var path: Path = .cli
    @State private var repoName = ""
    @State private var visibility = "private"
    @State private var ghInstalled = false
    @State private var ghAuthed = false
    @State private var checking = true
    @State private var remoteURLField = ""

    private var suggestedName: String { store.selected?.name ?? "my-app" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Connect to GitHub", icon: "link.badge.plus", tint: .green) { dismiss() }
            Divider().opacity(0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    intro
                    Picker("Method", selection: $path) {
                        ForEach(Path.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)

                    if path == .cli { cliPath } else { browserPath }
                }
                .padding(20)
            }
        }
        .frame(width: 660, height: 620)
        .task {
            repoName = suggestedName
            ghInstalled = await store.hasGHCLI()
            if ghInstalled { ghAuthed = await store.ghAuthenticated() }
            checking = false
            path = ghInstalled ? .cli : .browser
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This repo has no GitHub remote yet.").font(.headline)
            Text("Your local work — commits, branches, history, diff — already works without GitHub. Connect a remote when you want to back it up or push. Pick whichever method you prefer; you can copy any command.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if checking {
                HStack(spacing: 6) { ProgressView().scaleEffect(0.6); Text("Checking your setup…").font(.caption).foregroundStyle(.secondary) }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: ghInstalled ? "checkmark.circle.fill" : "info.circle")
                        .foregroundStyle(ghInstalled ? Color.green : Color.orange)
                    Text(ghInstalled
                         ? (ghAuthed ? "GitHub CLI is installed and signed in." : "GitHub CLI is installed but not signed in yet.")
                         : "GitHub CLI (gh) isn't installed — the browser method is ready to use.")
                        .font(.caption)
                }
            }
        }
    }

    private var nameControls: some View {
        HStack(spacing: 10) {
            TextField("repository name", text: $repoName).textFieldStyle(.roundedBorder).frame(maxWidth: 240)
            Picker("", selection: $visibility) { Text("Private").tag("private"); Text("Public").tag("public") }
                .labelsHidden().frame(width: 120)
        }
    }

    private var cliPath: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !ghInstalled {
                stepCard(1, "Install the GitHub CLI", "The gh tool creates the repo and pushes in one step.") {
                    CopyCommand("brew install gh")
                    Text("After installing, reopen this window.").font(.caption2).foregroundStyle(.secondary)
                }
            }
            if ghInstalled && !ghAuthed {
                stepCard(1, "Sign in to GitHub", "Authenticate gh with your account (opens a browser to confirm).") {
                    CopyCommand("gh auth login")
                    Button {
                        Task { _ = await store.run("gh auth login --web 2>&1", cwd: store.selected?.url, label: "gh auth login"); ghAuthed = await store.ghAuthenticated() }
                    } label: { Label("Run for me", systemImage: "play.fill") }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                }
            }
            stepCard(ghInstalled ? (ghAuthed ? 1 : 2) : 2, "Name it and create", "BuildBuddy runs gh to create the repo, add it as origin, and push — all at once.") {
                nameControls
                CopyCommand("gh repo create \(repoNameOrPlaceholder) --\(visibility) --source=. --remote=origin --push")
                Button {
                    Task { await store.createGitHubRepoWithGH(name: repoName.isEmpty ? suggestedName : repoName, visibility: visibility); if store.hasRemote { dismiss() } }
                } label: { Label("Create & push for me", systemImage: "play.fill") }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(!ghInstalled || !ghAuthed)
                if !ghInstalled || !ghAuthed {
                    Text("Finish the step(s) above to enable this.").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var browserPath: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepCard(1, "Create the repo on GitHub.com", "Open the new-repo page, give it a name, and DON'T add a README or .gitignore (your local files will be the first push).") {
                Button {
                    if let url = URL(string: "https://github.com/new") { NSWorkspace.shared.open(url) }
                } label: { Label("Open github.com/new", systemImage: "safari") }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
            stepCard(2, "Copy the repo URL", "On the new repo's page, copy the HTTPS URL — it looks like https://github.com/you/your-app.git — and paste it here.") {
                TextField("https://github.com/you/your-app.git", text: $remoteURLField)
                    .textFieldStyle(.roundedBorder)
            }
            stepCard(3, "Connect and push", "BuildBuddy adds the remote, sets the branch upstream, and pushes. Or copy the commands to run yourself.") {
                CopyCommand("git remote add origin \(remoteURLField.isEmpty ? "REPO_URL" : remoteURLField)\ngit branch -M main\ngit push -u origin main")
                Button {
                    Task { await store.connectExistingRemote(url: remoteURLField); if store.hasRemote { dismiss() } }
                } label: { Label("Connect & push for me", systemImage: "play.fill") }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(remoteURLField.isEmpty)
            }
        }
    }

    private var repoNameOrPlaceholder: String { repoName.isEmpty ? "your-app" : repoName }

    @ViewBuilder private func stepCard<Content: View>(_ n: Int, _ title: String, _ subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(BB.accentGradient(.accentColor)).frame(width: 28, height: 28)
                Text("\(n)").font(.callout.bold()).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                content()
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct CopyCommand: View {
    let command: String
    init(_ command: String) { self.command = command }
    @State private var copied = false
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(copied ? .green : .secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
    }
}

struct StaleReportSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let report: Store.StaleReport

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Stale & Missing File Check", icon: "exclamationmark.magnifyingglass", tint: .yellow) { dismiss() }
            Divider().opacity(0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if report.isEmpty {
                        VStack(spacing: 10) {
                            GradientIcon(systemName: "checkmark.seal.fill", tint: .green, size: 46)
                            Text("Everything looks current.").font(.headline)
                            Text("No stale builds, no conflicting duplicate filenames, and nothing untracked that git isn't already ignoring.")
                                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        section("Stale builds", "hammer.fill", .orange,
                                report.staleBuilds,
                                "Compiled artifacts older than your newest source file — the build predates your latest edits. Rebuild, or use Clean project.")
                        section("Duplicate names, different contents", "doc.on.doc.fill", .red,
                                report.duplicateNames,
                                "The same filename appears in more than one place with different contents — a common source of editing the wrong copy.")
                        section("Untracked / possibly missed", "questionmark.folder.fill", .blue,
                                report.missedFiles,
                                "Files git isn't tracking and isn't ignoring. If they belong in the repo, commit them; if not, add them to .gitignore.")
                    }
                }
                .padding(20)
            }
            if !report.missedFiles.isEmpty {
                Divider().opacity(0.4)
                HStack {
                    Spacer()
                    Button {
                        Task { _ = await store.commitOnly(message: "Add previously untracked files"); dismiss() }
                    } label: { Label("Commit the untracked files", systemImage: "checkmark.circle") }
                        .buttonStyle(.borderedProminent)
                }
                .padding(12)
            }
        }
        .frame(width: 640, height: 560)
    }

    @ViewBuilder private func section(_ title: String, _ icon: String, _ tint: Color, _ items: [String], _ desc: String) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Image(systemName: icon).foregroundStyle(tint)
                    Text(title).font(.headline)
                    Text("\(items.count)").font(.caption.bold()).foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                }
                Text(desc).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(items.prefix(25), id: \.self) { item in
                        Text(item).font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled).lineLimit(1).truncationMode(.middle)
                    }
                    if items.count > 25 {
                        Text("…and \(items.count - 25) more").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BB.radiusSmall, style: .continuous))
            }
        }
    }
}

// Toast overlay — glass capsules that spring in from the bottom.
struct ToastOverlay: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            ForEach(store.toasts) { t in
                HStack(spacing: 8) {
                    Image(systemName: icon(t.kind)).foregroundStyle(color(t.kind))
                    Text(t.text).font(.callout)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(color(t.kind).opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 18)
        .animation(store.settings.reduceMotion ? .easeOut(duration: 0.12)
                   : .spring(response: 0.35, dampingFraction: 0.8), value: store.toasts.count)
        .allowsHitTesting(false)
    }
    private func icon(_ k: Store.Toast.Kind) -> String {
        switch k { case .success: return "checkmark.circle.fill"; case .error: return "exclamationmark.triangle.fill"; case .info: return "info.circle.fill" }
    }
    private func color(_ k: Store.Toast.Kind) -> Color {
        switch k { case .success: return .green; case .error: return .red; case .info: return .blue }
    }
}

// Clean folder — wipe a designated folder, or delete only files matching patterns.
struct CleanFolderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    @State private var folderPath = ""
    @State private var patterns = ""
    @State private var confirmText = ""
    @State private var preview: [String] = []
    @State private var didPreview = false

    private var folderURL: URL? {
        folderPath.isEmpty ? nil : URL(fileURLWithPath: (folderPath as NSString).expandingTildeInPath)
    }
    private var isFullWipe: Bool { patterns.trimmingCharacters(in: .whitespaces).isEmpty }
    private var confirmed: Bool { confirmText == "DELETE" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHeader(title: "Clean a folder", icon: "folder.badge.minus", tint: .red,
                        subtitle: "Preview first — this cannot be undone") { dismiss() }
            Divider().opacity(0.4)
            VStack(alignment: .leading, spacing: 14) {
                Text("Delete files from a folder. Leave patterns empty to remove EVERYTHING in the folder, or list patterns to delete only matching files.")
                    .font(.caption).foregroundStyle(.secondary)

                HStack {
                    TextField("Folder path (e.g. ~/Documents/MyProject/build)", text: $folderPath)
                        .textFieldStyle(.roundedBorder).font(.system(.caption, design: .monospaced))
                    Button("Choose…") { chooseFolder() }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Patterns (comma/space separated). Examples: *.log  .DS_Store  build  node_modules")
                        .font(.caption2).foregroundStyle(.secondary)
                    TextField("leave empty to wipe the whole folder", text: $patterns)
                        .textFieldStyle(.roundedBorder).font(.system(.caption, design: .monospaced))
                    if let p = store.selected {
                        Button("Use \(p.name) build patterns") {
                            patterns = "*.o, *.swiftmodule, *.swiftdoc, .build, build, DerivedData, .DS_Store, dist, node_modules"
                        }.font(.caption2)
                    }
                }

                if isFullWipe {
                    Label("Full wipe: every item in the folder will be deleted.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.red)
                }

                HStack {
                    Button("Preview (dry run)") {
                        guard let f = folderURL else { return }
                        preview = store.cleanCandidates(folder: f, patterns: patterns).map { $0.lastPathComponent }.sorted()
                        didPreview = true
                    }
                    .disabled(folderURL == nil)
                    Spacer()
                    Text(didPreview ? "\(preview.count) item(s) would be removed" : " ")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if didPreview {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 1) {
                            if preview.isEmpty { Text("Nothing matches.").foregroundStyle(.secondary).font(.caption) }
                            ForEach(preview, id: \.self) { Text($0).font(.system(.caption2, design: .monospaced)) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
                    }
                    .frame(height: 120)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Divider().opacity(0.4)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Type DELETE to confirm").font(.caption2).foregroundStyle(.secondary)
                        TextField("DELETE", text: $confirmText).textFieldStyle(.roundedBorder).frame(width: 160)
                    }
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Clean now", role: .destructive) {
                        guard let f = folderURL else { return }
                        let pats = patterns; dismiss()
                        Task { await store.cleanFolder(f, patterns: pats, dryRun: false) }
                    }
                    .disabled(folderURL == nil || !confirmed)
                }
            }
            .padding(BB.pad)
        }
        .frame(width: 580)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to clean"
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { folderPath = url.path }
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

// The build/version standardization playbook — shared across ALL apps so every project numbers
// releases the same way. Embedded so it travels with the app and can be exported.
enum BuildStandard {
    static let text: String = """
BUILD AND VERSION STANDARD
A single, shared scheme for numbering every app the same way. Apply this to all projects.

THE TWO NUMBERS
Every app's Info.plist carries two values. They map directly:

  CFBundleShortVersionString  =  VERSION  (small changes, fixes, minor tweaks)
  CFBundleVersion             =  BUILD    (big features, significant changes)

VERSION is shown to people (e.g. 1.4). BUILD is a single whole number that only goes up (e.g. 7).

WHEN TO BUMP WHICH
- Bump the BUILD number for a big feature addition or a significant change. BUILD goes 7 to 8.
- Bump the VERSION for a small feature, a fix, or a minor change. VERSION 1.4 goes to 1.5.

Rule of thumb: if you would tell someone "this is a notable new capability," bump BUILD. If it is a
small improvement or a bug fix, bump VERSION.

HOW VERSION INCREMENTS
VERSION is dotted. Bumping increases the LAST component:
  1.4   becomes  1.5
  1.4.2 becomes  1.4.3
  1     becomes  1.1
You may carry a major component (the leading number) and raise it by hand for a true milestone, but
day to day you only ever bump the last component for small changes.

HOW BUILD INCREMENTS
BUILD is one whole number, incremented by one for each big change:
  1, 2, 3, 4, ...

THE BASELINE (EVERY APP STARTS HERE)
When standardizing an app for the first time, reset it to:
  VERSION = 1.0
  BUILD   = 1
Then move forward using the rules above. Do this even if the app previously had other numbers, so
all apps share one clean starting point.

WHERE THE NUMBERS LIVE (TWO POSSIBLE PLACES)
Apps differ in how Xcode is configured, so the numbers live in one or both of these:
  - The Xcode project (project.pbxproj): MARKETING_VERSION (= VERSION) and
    CURRENT_PROJECT_VERSION (= BUILD). Used when the app sets versions via Build Settings.
  - The Info.plist: CFBundleShortVersionString (= VERSION) and CFBundleVersion (= BUILD). Used
    when the app keeps a manual Info.plist.
BuildBuddy detects which exist and updates BOTH when both are present, keeping every target and the
in-app display in lockstep. If they ever disagree, the Xcode project is treated as the source of
truth and mirrored to the plist.

DOING IT IN BUILDBUDDY (BUTTONS)
With a project selected, the Version and Build section has:
  - Standardize this app  (one click: detects the setup; if not standardized, sets VERSION 1.0 /
                           BUILD 1 everywhere the numbers live; if ALREADY standardized, it does
                           NOT reset your numbers — it only adds the timestamped What's New entry.)
  - Bump version          (small change: raises the last component of VERSION, everywhere)
  - Bump build            (big change: BUILD + 1, everywhere)
  - Reset to 1.0 / build 1 (force the baseline; use when migrating an app)
Every one of these also writes a timestamped What's New entry automatically (see below), then you
commit the change like any other edit.

TIMESTAMPED WHAT'S NEW / WHAT'S CHANGED (AUTOMATIC)
Every version or build change records an entry stamped MM:DD:YY HH:MM (local time). BuildBuddy finds
the app's existing changelog and prepends to it:
  - If the repo root has CHANGELOG.md, WHATS_NEW.md, WHATSNEW.md, or CHANGES.md, it prepends there.
  - If the app keeps its What's New in a Swift file, BuildBuddy records the timestamped entry in
    CHANGELOG.md (so history is preserved) and notes it, since editing arbitrary Swift changelog
    structures blind is unsafe — copy the line into the in-app list if you want it shown there.
  - If nothing exists, BuildBuddy creates CHANGELOG.md.
Entry format:
    MM:DD:YY HH:MM — v<version> (build <build>) — <kind>
    <short note>

DOING IT BY SCRIPT (NO BUILDBUDDY)
Pick the lines that match where your app keeps its numbers.

  Info.plist apps (replace PLIST with the path to Info.plist):
    Read:   /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" PLIST
    Build:  current=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" PLIST)
            /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $((current + 1))" PLIST
    Version (two-part like 1.4):
            v=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" PLIST)
            major=${v%.*}; minor=${v##*.}; /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $major.$((minor + 1))" PLIST

  Xcode-project apps (replace PBX with the path to project.pbxproj):
    Build:  current=$(grep -Eo 'CURRENT_PROJECT_VERSION = [0-9]+;' PBX | grep -Eo '[0-9]+' | sort -n | tail -1)
            sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $((current + 1));/g" PBX
    Version: sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = 1.1;/g" PBX   (set as needed)

  Timestamped changelog line (append to your changelog of choice):
    stamp=$(date +"%m:%d:%y %H:%M"); printf '%s — v1.0 (build 1) — Note\\n' "$stamp"

MIGRATING AN EXISTING APP TO THIS STANDARD (WIPE OLD NUMBERS)
Easiest: select the app in BuildBuddy and click Standardize this app. It detects the setup, resets
to 1.0 / build 1 only if needed, writes the numbers everywhere they live, and adds the timestamped
entry. Then commit. By hand:

  Step 1 — find the files:
    find . -name Info.plist -not -path "*/.build/*" -not -path "*/build/*" -not -path "*/DerivedData/*"
    find . -name project.pbxproj -not -path "*/.build/*"

  Step 2 — set the baseline in whichever exist:
    Info.plist:
      /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0" PLIST || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" PLIST
      /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" PLIST || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" PLIST
    Xcode project:
      sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = 1.0;/g" PBX
      sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = 1;/g" PBX

  Step 3 — if the project hardcodes a version constant in source, set it to 1.0 to match.
  Step 4 — commit, for example: Standardize version and build to 1.0 and 1.

ABOUT THE OLD PER-APP SCRIPTS (auto_increment_build.sh / bump_version.sh)
Different apps shipped different scripts, and they disagreed:
  - One bumped CURRENT_PROJECT_VERSION in the pbxproj across all targets (build only).
  - Another bumped CFBundleVersion in the Info.plist via PlistBuddy (build only).
  - bump_version.sh bumped MARKETING_VERSION and CURRENT_PROJECT_VERSION together as integers.
The integer-version approach conflicts with this standard (VERSION is dotted, e.g. 1.0, and only
its last component bumps for small changes; BUILD is the integer). Going forward, use BuildBuddy's
buttons (or the commands above) instead of those scripts, so every app behaves identically. You can
keep an auto_increment_build run-script phase in Xcode if you like per-compile build bumps, but the
canonical, cross-app actions are the BuildBuddy buttons.

KEEPING ALL APPS CONSISTENT
- VERSION = CFBundleShortVersionString / MARKETING_VERSION. BUILD = CFBundleVersion /
  CURRENT_PROJECT_VERSION. Update both locations when both exist.
- Every app starts at 1.0 / build 1 after migration.
- Big change bumps BUILD; small change bumps VERSION. Same rule everywhere.
- Every change records a timestamped What's New entry (MM:DD:YY HH:MM).
- When in doubt, read this document (it is the single source of truth) and follow it exactly.
"""
}

// The website deploy playbook — how a static site (e.g. sowensstudios.com) goes from a
// GitHub repo to a live, auto-updating site on Netlify, and how BuildBuddy drives the updates.
// Embedded so it travels with the app and can be exported. No new behavior — this documents
// how to use BuildBuddy's existing apply/commit/push flow as your deploy button.
enum DeployInstructions {
    static let text: String = """
BUILDBUDDY WEBSITE DEPLOY INSTRUCTIONS
How to take a static website (plain HTML, CSS, JS — for example sowensstudios.com) from a
GitHub repo to a live site on Netlify, and then update it forever from BuildBuddy with one
Next click. Project-agnostic: wherever you see ANGLE BRACKETS (e.g. <site-repo> or <site-folder>),
substitute the value for your site. Placeholders used throughout:
   <site-folder>   the local folder holding the site files (must contain index.html at its root)
   <site-repo>     the GitHub repository name for the site (e.g. sowensstudios-site)
   <domain>        the custom domain (e.g. sowensstudios.com)

BIG PICTURE (READ FIRST)
There are TWO systems and they connect once:
   1. GitHub  — stores your site files and their history.
   2. Netlify — watches the GitHub repo and, on every push, publishes the files to the live domain.
Once wired together, the loop is: edit files -> BuildBuddy commits and pushes -> Netlify auto-builds ->
<domain> updates in under a minute. After the one-time setup you never touch Netlify or GitHub by
hand again — BuildBuddy is the deploy button.

WHY THIS WORKS WITH BUILDBUDDY AS-IS
BuildBuddy already commits and pushes a local git repo (the same apply/commit/push flow it uses for
code drops). A Netlify-connected site repo is just another git repo under <site-folder>. So deploying
a website change is identical to any other BuildBuddy push: the only special part is the one-time
GitHub + Netlify connection below. Nothing about commit safety, apply, or push behavior changes.

===================================================================================
PART 1 — ONE-TIME SETUP (do this once per site; all in the browser + BuildBuddy)
===================================================================================

STEP 1. PUT THE SITE FILES IN A LOCAL FOLDER
• Choose or create <site-folder> under a normal location BuildBuddy can reach (e.g. ~/Documents/<site-repo>).
• The folder MUST contain index.html at its top level (not inside a subfolder). Supporting files
  (an assets folder, css, images) sit alongside or under it, exactly as they should serve.
• Example layout:
     <site-folder>/
        index.html
        assets/
           styles.css
           favicon.svg

STEP 2. CREATE THE GITHUB REPOSITORY
Easiest path — let BuildBuddy do it:
• Add <site-folder> as a project in BuildBuddy (drag the folder into the sidebar, or click +).
• If the folder is not yet a git repo, BuildBuddy treats it as local-only. Use the Connect to GitHub
  helper (it appears for repos with no remote) and follow the GitHub CLI path if gh is installed,
  or the browser path: it opens github.com/new, you create an EMPTY repo named <site-repo>
  (no README, no .gitignore, no license — empty), copy the repo URL, paste it back, and BuildBuddy
  wires up the remote and does the first commit and push.
Manual alternative (if you prefer):
• At github.com/new create an empty repo <site-repo>. Then in BuildBuddy's Connect to GitHub sheet
  paste the URL shown on the new repo page (the https://github.com/<you>/<site-repo>.git form).
Result: your site files now live in GitHub with history, pushed from BuildBuddy.

STEP 3. CONNECT NETLIFY TO THE GITHUB REPO (turns pushes into deploys)
This is the step that makes GitHub updates publish automatically. Do it in the browser once.
• Go to app.netlify.com and sign in.
• If a site for <domain> already exists (for example one created earlier by drag-and-drop), you will
  RELINK it to Git rather than make a new one — see STEP 3B. For a brand-new site use STEP 3A.

STEP 3A. NEW SITE FROM GIT
• Netlify dashboard -> Add new project (or Add new site) -> Import an existing project.
• Choose GitHub and authorize Netlify. When asked, install the Netlify GitHub App and grant it access
  to <site-repo> (you can limit it to just that repo).
• Pick <site-repo> from the list.
• Build settings: for a plain static site there is NO build command. Leave Build command EMPTY and set
  Publish directory to the folder that contains index.html — usually "." (the repo root) if index.html
  is at the top, or the subfolder name if you nested it. Then click Deploy.
• Netlify builds and gives a temporary <name>.netlify.app URL. Confirm it looks right.

STEP 3B. EXISTING DRAG-AND-DROP SITE — RELINK TO GIT
If <domain> is already served by a manual (drag-and-drop) Netlify site and you want to keep that same
site and its domain:
• Open that site -> Project configuration (Site settings) -> Build and deploy -> Continuous deployment.
• Under Repository choose Link repository (or Manage repository -> Link to a different repository),
  choose GitHub, install/authorize the Netlify GitHub App for <site-repo>, and select it.
• Set the same build settings as 3A: Build command EMPTY, Publish directory = the folder with index.html.
• From now on this existing site (with its existing <domain> and SSL) deploys from GitHub pushes.

STEP 4. POINT / CONFIRM THE DOMAIN AND HTTPS (only if not already done)
If <domain> already shows the site with a padlock, skip this. Otherwise:
• In Netlify: Domain management -> Add a domain -> <domain> (add the www version too if offered).
• Use Netlify DNS (simplest): Netlify lists 4 nameservers. At the domain registrar (e.g. Namecheap:
  Domain List -> Manage -> Nameservers -> Custom DNS) paste all 4 and save.
• HTTPS: Netlify auto-provisions a free Let's Encrypt certificate once DNS verification succeeds.
  If it stays on "Waiting on DNS propagation," click Verify DNS configuration; when verified it shows
  "DNS verification was successful" and the certificate is issued automatically (minutes, up to a few
  hours). Turn on Force HTTPS when the certificate is active.
• The scary "This Connection Is Not Private" page during this window is normal — it means DNS is
  reaching Netlify but the certificate has not finished. It clears itself once the certificate issues.

ONE-TIME SETUP IS NOW COMPLETE. The rest of your life with this site is Part 2.

===================================================================================
PART 2 — UPDATING THE SITE (the everyday flow — BuildBuddy is the deploy button)
===================================================================================

THE LOOP
1. Edit the files in <site-folder> (change text in index.html, tweak assets/styles.css, add an image).
   Keep everything inside <site-folder> — that folder IS the site.
2. In BuildBuddy, select the <site-repo> project.
3. BuildBuddy shows the repo as dirty (uncommitted changes). Click Next:
      • If you dropped a delivery zip, Next applies it first, then commits and pushes.
      • Otherwise Next commits your edits and pushes to GitHub.
   You can edit the commit message inline first; keep it plain prose (see the Commit-Message Rule in the
   Delivery format document — same rule applies here).
4. The push reaches GitHub. Netlify sees the push, auto-builds, and publishes.
5. Within about a minute, <domain> shows the update. Hard-refresh the browser
   (Command-Shift-R) if you still see the old version — that is browser cache, not a failed deploy.

THAT IS THE ENTIRE UPDATE PROCESS. No dragging folders, no visiting Netlify, no touching the registrar.
Edit -> Next -> done.

DELIVERING SITE CHANGES AS A DROP (optional, same as code drops)
If a change is prepared as a BuildBuddy drop (the v2 zip layout from the Delivery format document),
the top folder's name is <site-repo> and the files inside use repo-root-relative paths
(e.g. index.html at the top, assets/styles.css under it). Applying the drop overlays the files onto
<site-folder>; then Next commits and pushes exactly as above. COMMIT_MSG.txt and commit.sh are handled
the same way they are for code.

===================================================================================
PART 3 — VERIFYING A DEPLOY AND FIXING COMMON PROBLEMS
===================================================================================

HOW TO CONFIRM A DEPLOY LANDED
• GitHub: the repo's commit list shows your new commit at the top.
• Netlify: the site's Deploys page shows a new deploy going Building -> Published. A green Published with
  your commit message means it is live.
• Browser: open <domain> in a fresh/private window; hard-refresh if needed.

TROUBLESHOOTING
• Push succeeded but the site did not change:
   - Check Netlify's Deploys page. If no new deploy appeared, the repo link or webhook may be off:
     Site settings -> Build and deploy -> Continuous deployment -> confirm the branch you pushed matches
     the site's production branch, and that the Netlify GitHub App still has access to <site-repo>.
• Site deployed but looks unstyled (plain text, no colors/images):
   - The Publish directory is wrong, or assets are not where index.html expects. Ensure Publish directory
     points at the folder that actually contains index.html, and that asset paths (like assets/styles.css)
     resolve relative to it. Keep the folder structure intact when editing.
• Deploy failed on Netlify:
   - For a static site there should be NO build command. If Netlify is trying to run one, clear the
     Build command field (leave it empty) and set Publish directory correctly, then Retry deploy.
• "Not secure" / certificate warning:
   - The Let's Encrypt certificate has not finished. In Domain management -> HTTPS click Verify DNS
     configuration; wait for it to provision, then enable Force HTTPS. Test in a private window.
• BuildBuddy could not push:
   - This is an ordinary git push problem, handled by BuildBuddy's normal push recovery. Retry Next;
     if it persists, open the console to read the exact git error.

===================================================================================
QUICK CHECKLISTS
===================================================================================

ONE-TIME SETUP CHECKLIST
[ ] <site-folder> exists locally with index.html at its top level
[ ] <site-folder> added as a BuildBuddy project and pushed to GitHub as <site-repo>
[ ] Netlify linked to <site-repo> (new site, or existing site relinked to Git)
[ ] Build command EMPTY; Publish directory points at the folder containing index.html
[ ] <domain> connected in Netlify and DNS verified
[ ] HTTPS certificate active and Force HTTPS on
[ ] Test: <domain> loads over https with a padlock

EVERYDAY UPDATE CHECKLIST
[ ] Edited files inside <site-folder> (structure kept intact)
[ ] Selected the <site-repo> project in BuildBuddy
[ ] Commit message is plain prose (passes the safety check)
[ ] Clicked Next (apply if needed, then commit and push)
[ ] Netlify Deploys shows Published
[ ] <domain> shows the change after a hard-refresh

NOTES
• Your local <site-folder> is the master copy. Keep it safe; it is what you edit and what BuildBuddy pushes.
• You can point BuildBuddy at multiple site repos the same way — each is just another project.
• This document describes using BuildBuddy's existing flow; it introduces no new commit or push behavior.
"""
}
