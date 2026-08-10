# BuildBuddy

A focused, local-first macOS workspace for managing Git repositories, Xcode builds,
code deliveries, versions, and deployments. Distributed as a single Swift source file
with lightweight launcher scripts — no account, no developer-controlled data service.

## Features

- Inspect repository status, branches, history, and diffs
- Commit, pull, push, and connect local projects to GitHub
- Run Xcode builds and common project checks
- Preview and apply structured code deliveries with recovery history and undo
- Manage app version and build numbers consistently
- Works fully locally when a repository has no remote

## Requirements

- macOS
- Xcode Command Line Tools

## Getting started

```bash
git clone https://github.com/sahmoee/BuildBuddy.git
cd BuildBuddy
```

Double-click **`Launch BuildBuddy.command`** for a development build, or
**`Build BuildBuddy.app.command`** to produce a standalone local `.app` bundle.

## Project structure

- `BuildBuddy.swift` — the entire application
- `*.command` — launcher and builder scripts

## License

See [LICENSE.md](LICENSE.md). Privacy in [PRIVACY.md](PRIVACY.md); third-party notices
in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
