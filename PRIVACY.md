# BuildBuddy Privacy Policy

**Effective and last updated: August 8, 2026**

BuildBuddy is a local macOS development utility. It does not include advertising, analytics, cross-app tracking, or a BuildBuddy account service. Sowens Studios does not receive your source code, repository contents, credentials, command output, or usage history through the app.

## Information stored on your Mac

BuildBuddy stores preferences, project locations, build and delivery settings, action history, remote configuration, and a randomly generated remote pairing token in local preferences or Application Support. It reads the repositories and delivery files you select and may create commits, branches, archives, logs, backups, or result files as directed. Git credentials remain managed by Git, GitHub CLI, macOS Keychain, or the credential helper you configured; BuildBuddy does not operate a credential vault.

## Commands and connected services

BuildBuddy runs local developer commands such as Git, Xcode build tools, package managers, and deployment CLIs. Those tools may send repository content, identifiers, build artifacts, diagnostics, or credentials to services you configured, including GitHub, Cloudflare, Apple, package registries, or a hosting provider. Their terms and privacy policies apply.

The update checker contacts the BuildBuddy GitHub repository. Opening a repository or service page sends a normal request from your browser.

## Optional remote control

Remote control is off until enabled. Depending on the mode you choose:

- **LAN or Tailscale:** commands and status travel between your paired device and Mac. Tailscale handles its network under your Tailscale account.
- **Public mode:** your Mac listens through a port you expose. This is higher risk and requires explicit acknowledgement.
- **GitHub relay:** predefined jobs and results are stored in the private GitHub repository you configure.
- **SMB drop folder:** delivery archives and result files are read from and written to the network share you select.

Requests require the local pairing token, but anyone with the token and network access may be able to trigger powerful development actions. Rotate the token after suspected exposure, keep Public mode off unless necessary, and prefer Tailscale or a trusted LAN.

## Retention, deletion, and support

Local information remains until you clear it, remove the relevant Application Support files, or delete the app. Repository history and content sent to GitHub or another provider remain under that provider's controls. Support email contains whatever information you choose to send and is retained only as reasonably necessary to respond, prevent abuse, and meet legal obligations.

To request deletion of support correspondence, email [support@sowensstudios.com](mailto:support@sowensstudios.com). BuildBuddy has no central user account to delete.

## Security, children, and changes

BuildBuddy can execute commands and change repositories. Review actions, restrict folder access, protect credentials, and keep backups. No security measure is perfect. BuildBuddy is a professional developer tool and is not directed to children under 13.

We may update this policy as functionality changes. Material changes will be identified by a new date. Contact: [support@sowensstudios.com](mailto:support@sowensstudios.com).

Public policy URL: <https://sahmoee.github.io/BuildBuddy/privacy.html>
