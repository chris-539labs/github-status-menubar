import Foundation

enum RunStatus: String, Codable {
    case completed
    case actionRequired = "action_required"
    case inProgress = "in_progress"
    case queued
    case requested
    case waiting
    case pending

    var isSuccess: Bool {
        self == .completed
    }

    var isInProgress: Bool {
        switch self {
        case .inProgress, .queued, .requested, .waiting, .pending:
            return true
        default:
            return false
        }
    }
}

enum RunConclusion: String, Codable {
    case success
    case failure
    case cancelled
    case skipped
    case timedOut = "timed_out"
    case actionRequired = "action_required"
    case neutral
    case stale
    case startupFailure = "startup_failure"

    var isSuccess: Bool {
        self == .success
    }

    var isFailure: Bool {
        switch self {
        case .failure, .timedOut, .startupFailure:
            return true
        default:
            return false
        }
    }
}

struct HeadCommit: Codable {
    let message: String

    var firstLine: String {
        let line = message.prefix(while: { $0 != "\n" && $0 != "\r" })
        if line.count > 60 {
            return String(line.prefix(57)) + "..."
        }
        return String(line)
    }
}

struct WorkflowRun: Codable, Identifiable {
    let id: Int
    let name: String?
    let headBranch: String?
    let headCommit: HeadCommit?
    let status: RunStatus
    let conclusion: RunConclusion?
    let htmlUrl: String
    let createdAt: Date
    let updatedAt: Date
    var failedJobs: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case headBranch = "head_branch"
        case headCommit = "head_commit"
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        name ?? "Workflow #\(id)"
    }

    var effectiveStatus: EffectiveRunStatus {
        if status.isInProgress {
            return .inProgress
        }
        guard let conclusion else {
            return .unknown
        }
        if conclusion.isSuccess {
            return .success
        }
        if conclusion.isFailure {
            return .failure
        }
        return .neutral
    }
}

enum EffectiveRunStatus {
    case success
    case failure
    case inProgress
    case neutral
    case unknown
}

struct WorkflowRunsResponse: Codable {
    let totalCount: Int
    let workflowRuns: [WorkflowRun]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case workflowRuns = "workflow_runs"
    }
}

struct WorkflowJob: Codable, Identifiable {
    let id: Int
    let name: String
    let status: String
    let conclusion: String?
}

struct WorkflowJobsResponse: Codable {
    let totalCount: Int
    let jobs: [WorkflowJob]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case jobs
    }
}
