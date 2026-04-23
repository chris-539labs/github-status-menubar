import Foundation
import SwiftUI

@MainActor
final class StatusViewModel: ObservableObject {
    @Published var repoStatuses: [RepoStatus] = []
    @Published var isLoading = false
    @Published var lastRefresh: Date?

    private let apiService = GitHubAPIService()
    private let configManager: ConfigurationManager
    private var pollingTask: Task<Void, Never>?

    init(configManager: ConfigurationManager) {
        self.configManager = configManager
        startPolling()
    }

    var aggregateStatus: EffectiveRunStatus {
        if repoStatuses.isEmpty {
            return .unknown
        }
        if repoStatuses.contains(where: { $0.aggregateStatus == .failure }) {
            return .failure
        }
        if repoStatuses.contains(where: { $0.aggregateStatus == .inProgress }) {
            return .inProgress
        }
        if repoStatuses.allSatisfy({ $0.aggregateStatus == .success }) {
            return .success
        }
        if repoStatuses.allSatisfy({ $0.aggregateStatus == .unknown }) {
            return .unknown
        }
        return .neutral
    }

    var menuBarIconName: String {
        switch aggregateStatus {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .neutral: return "minus.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await refresh()
                let interval = configManager.configuration.refreshIntervalSeconds
                try? await Task.sleep(for: .seconds(max(interval, 30)))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        let config = configManager.configuration
        guard !config.token.isEmpty, !config.repos.isEmpty else {
            repoStatuses = []
            return
        }

        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        let statuses = await withTaskGroup(of: RepoStatus.self, returning: [RepoStatus].self) { group in
            for repo in config.repos {
                group.addTask {
                    await self.apiService.fetchRepoStatus(repo: repo, token: config.token)
                }
            }
            var results: [RepoStatus] = []
            for await status in group {
                results.append(status)
            }
            return results
        }

        // Don't update UI if task was cancelled during fetch
        guard !Task.isCancelled else { return }

        // Preserve the order from config
        let orderedStatuses = config.repos.compactMap { repo in
            statuses.first(where: { $0.repo == repo })
        }
        repoStatuses = orderedStatuses
        lastRefresh = Date()
    }
}
