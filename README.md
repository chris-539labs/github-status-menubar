# GitHub Status Menubar

> [!WARNING]
> This menubar app was born out of frustration and with the help of Claude Code. There might be tons of others like it, but it was quicker to make Claude build it for me than for me to Google one. Use it if its helpful. No warranties included.

A native macOS menubar app that monitors GitHub Actions statuses and latest releases for your repositories.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- Menubar icon reflects aggregate status across all repos (green/red/orange/gray)
- Compact repo list with status icon, repo name, and latest release tag
- Click a repo row to expand and see the last 10 workflow runs
- Click a workflow run or release tag to open it in your browser
- Settings UI to configure your token, refresh interval, and repos
- Repo picker that fetches all repos your token has access to
- Configurable polling interval (default: 5 minutes)
- Per-repo error isolation — one failing repo won't break the others

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+
- A [GitHub Personal Access Token](https://github.com/settings/tokens) with `repo` and `actions` read access

## Install

```bash
git clone <repo-url>
cd github-status
./scripts/bundle.sh
```

This builds a release binary, packages it as `GitHub Status.app`, copies it to `/Applications`, and launches it.

### Run at Login

**System Settings → General → Login Items → click `+` → select `GitHub Status`**

## Development

```bash
swift build
swift run
```

Or run the debug binary directly:

```bash
.build/debug/GitHubStatus
```

## Configuration

Configure via the Settings UI (click the menubar icon → Settings), or edit `~/.github-status.json` directly:

```json
{
  "token": "ghp_your_token_here",
  "repos": [
    { "owner": "539ventures", "repo": "some-project" },
    { "owner": "octocat", "repo": "Hello-World" }
  ],
  "refreshIntervalSeconds": 300
}
```

| Field | Description | Default |
|-------|-------------|---------|
| `token` | GitHub Personal Access Token | `""` |
| `repos` | List of `owner/repo` pairs to monitor | `[]` |
| `refreshIntervalSeconds` | Polling interval in seconds (minimum 30) | `300` |

## Menubar Icons

| Icon | Meaning |
|------|---------|
| ✅ Checkmark | All workflow runs passing |
| ❌ X | At least one run failing |
| 🔄 Arrows | Runs in progress |
| ❓ Question mark | No data or not configured |

## Project Structure

```
GitHubStatus/
  App/
    GitHubStatusApp.swift       App entry point, MenuBarExtra scene
    Info.plist                   LSUIElement = true (no Dock icon)
  Models/
    AppConfiguration.swift      Config model + RepoIdentifier
    WorkflowRun.swift           GitHub Actions run models
    Release.swift               GitHub release model
    RepoStatus.swift            Aggregated status per repo
  Services/
    GitHubAPIService.swift      GitHub REST API client
    ConfigurationManager.swift  Config file I/O (~/.github-status.json)
  ViewModels/
    StatusViewModel.swift       State management + polling
  Views/
    MenuBarView.swift           Main popover UI
    RepoSectionView.swift       Expandable repo row
    WorkflowRunRow.swift        Workflow run row (clickable)
    ReleaseRow.swift            Release tag row (clickable)
    SettingsView.swift          Settings window (General + Repositories)
    StatusIcon.swift            Status → SF Symbol + color helper
scripts/
  bundle.sh                     Build + package as .app
```

## License

MIT
