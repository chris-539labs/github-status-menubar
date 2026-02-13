import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: StatusViewModel
    @ObservedObject var configManager: ConfigurationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("GitHub Status")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                }

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            // Content
            if configManager.configuration.token.isEmpty {
                emptyStateView("Set up your GitHub token in Settings")
            } else if configManager.configuration.repos.isEmpty {
                emptyStateView("Add repositories in Settings")
            } else if viewModel.repoStatuses.isEmpty && !viewModel.isLoading {
                emptyStateView("No data yet. Refreshing...")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.repoStatuses) { status in
                            RepoSectionView(status: status)
                                .padding(.horizontal, 12)
                            if status.id != viewModel.repoStatuses.last?.id {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 400)
            }

            Divider()

            // Footer
            HStack {
                if let lastRefresh = viewModel.lastRefresh {
                    Text("Updated \(lastRefresh.relativeDescription)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button("Settings") {
                    SettingsWindowController.shared.open(configManager: configManager) {
                        Task { @MainActor in
                            viewModel.stopPolling()
                            viewModel.startPolling()
                        }
                    }
                }
                .font(.system(size: 11))

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 420)
        .task {
            viewModel.startPolling()
        }
    }

    private func emptyStateView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
