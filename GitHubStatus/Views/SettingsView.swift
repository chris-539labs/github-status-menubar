import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager: ConfigurationManager
    var onConfigChange: () -> Void

    var body: some View {
        TabView {
            GeneralSettingsTab(configManager: configManager, onConfigChange: onConfigChange)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            RepositoriesSettingsTab(configManager: configManager, onConfigChange: onConfigChange)
                .tabItem {
                    Label("Repositories", systemImage: "list.bullet")
                }
        }
        .frame(width: 450, height: 420)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var configManager: ConfigurationManager
    var onConfigChange: () -> Void

    @State private var token: String = ""
    @State private var refreshInterval: String = ""

    var body: some View {
        Form {
            SecureField("GitHub Token:", text: $token)
                .textFieldStyle(.roundedBorder)

            TextField("Refresh Interval (seconds):", text: $refreshInterval)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Save") {
                    var config = configManager.configuration
                    config.token = token
                    config.refreshIntervalSeconds = Int(refreshInterval) ?? 300
                    configManager.save(config)
                    onConfigChange()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .onAppear {
            token = configManager.configuration.token
            refreshInterval = String(configManager.configuration.refreshIntervalSeconds)
        }
    }
}

struct RepositoriesSettingsTab: View {
    @ObservedObject var configManager: ConfigurationManager
    var onConfigChange: () -> Void

    @State private var availableRepos: [RepoIdentifier] = []
    @State private var searchText: String = ""
    @State private var isLoadingRepos = false
    @State private var loadError: String?

    private let apiService = GitHubAPIService()

    private var filteredRepos: [RepoIdentifier] {
        let alreadyAdded = Set(configManager.configuration.repos.map(\.id))
        let candidates = availableRepos.filter { !alreadyAdded.contains($0.id) }
        if searchText.isEmpty { return candidates }
        return candidates.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Search + dropdown
            HStack(spacing: 8) {
                TextField("Search repos...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if isLoadingRepos {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                }

                Button {
                    Task { await loadRepos() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoadingRepos || configManager.configuration.token.isEmpty)
            }

            if let loadError {
                Text(loadError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }

            // Available repos to add
            if !availableRepos.isEmpty {
                List(filteredRepos) { repo in
                    HStack {
                        Text(repo.fullName)
                            .font(.system(size: 12))
                        Spacer()
                        Button("Add") { addRepo(repo) }
                            .controlSize(.small)
                    }
                }
                .listStyle(.bordered)
                .frame(maxHeight: 120)
            }

            if !configManager.configuration.repos.isEmpty {
                Text("Added Repositories")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Added repos
            List {
                ForEach(configManager.configuration.repos) { repo in
                    HStack {
                        Text(repo.fullName)
                            .font(.system(size: 13))
                        Spacer()
                        Button {
                            removeRepo(repo)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.bordered)
        }
        .padding(20)
        .task {
            if availableRepos.isEmpty && !configManager.configuration.token.isEmpty {
                await loadRepos()
            }
        }
    }

    private func loadRepos() async {
        isLoadingRepos = true
        loadError = nil
        do {
            let repos = try await apiService.fetchAccessibleRepos(token: configManager.configuration.token)
            availableRepos = repos
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingRepos = false
    }

    private func addRepo(_ repo: RepoIdentifier) {
        guard !configManager.configuration.repos.contains(repo) else { return }
        var config = configManager.configuration
        config.repos.append(repo)
        configManager.save(config)
        onConfigChange()
    }

    private func removeRepo(_ repo: RepoIdentifier) {
        var config = configManager.configuration
        config.repos.removeAll { $0 == repo }
        configManager.save(config)
        onConfigChange()
    }
}
