# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build              # Debug build
swift run                # Build and run
.build/debug/GitHubStatus  # Run built binary directly
swift build -c release   # Release build
./scripts/bundle.sh      # Package as .app, install to /Applications, and launch
```

No external dependencies. Pure Swift Package Manager, macOS 13+ only.

## Architecture

Native macOS menubar-only app using **MenuBarExtra** (`.window` style) with MVVM pattern.

**Data flow**: `ConfigurationManager` (reads `~/.github-status.json`) → `StatusViewModel` (polling loop, parallel fetches) → `MenuBarView` (popover UI) → `RepoSectionView` (expandable rows).

**Concurrency model**: `GitHubAPIService` is an `actor`. All repos are fetched in parallel via `withTaskGroup`. Within each repo, runs and releases are fetched concurrently via `async let`. Failed job details are fetched only for failed runs (additional parallel task group).

**Settings window**: Can't use SwiftUI `Settings` scene from SPM executables — uses a manual `SettingsWindowController` that creates an `NSWindow` with `NSHostingController`. Temporarily switches activation policy from `.accessory` to `.regular` while settings window is open so text fields can receive focus, reverts on close.

**Menubar icon**: Aggregate status computed across all repos — failure trumps in-progress trumps success. Maps to SF Symbols via `StatusViewModel.menuBarIconName`.

**Polling**: `Task.sleep`-based infinite loop in `StatusViewModel.startPolling()`. Minimum 30s interval enforced. Restarts when config changes via Settings.

## Key Patterns

- `LSUIElement = true` in Info.plist hides from Dock (menubar-only)
- Config file at `~/.github-status.json` with atomic writes and pretty-printed JSON
- Per-repo error isolation: one repo failing doesn't affect others, error shown inline
- `RepoSectionView` is collapsed by default, click to expand and see last 10 workflow runs
- Release tag shown inline on the repo header row, clickable to open in browser
- `WorkflowRun.failedJobs` is a non-Codable field populated after initial fetch
