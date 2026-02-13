import Foundation

struct RepoStatus: Identifiable {
    let repo: RepoIdentifier
    var runs: [WorkflowRun]
    var latestRelease: GitHubRelease?
    var error: String?

    var id: String { repo.id }

    /// Latest run per workflow name, used for aggregate status.
    var latestRunPerWorkflow: [WorkflowRun] {
        var seen = Set<String>()
        var latest: [WorkflowRun] = []
        for run in runs {
            let key = run.displayName
            if seen.insert(key).inserted {
                latest.append(run)
            }
        }
        return latest
    }

    var aggregateStatus: EffectiveRunStatus {
        if error != nil && runs.isEmpty {
            return .unknown
        }
        let latest = latestRunPerWorkflow
        if latest.isEmpty {
            return .unknown
        }
        if latest.contains(where: { $0.effectiveStatus == .failure }) {
            return .failure
        }
        if latest.contains(where: { $0.effectiveStatus == .inProgress }) {
            return .inProgress
        }
        if latest.allSatisfy({ $0.effectiveStatus == .success }) {
            return .success
        }
        return .neutral
    }
}
