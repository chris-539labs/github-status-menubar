import Foundation

actor GitHubAPIService {
    private let baseURL = "https://api.github.com"
    private let session: URLSession
    private let decoder: JSONDecoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func fetchWorkflowRuns(owner: String, repo: String, token: String) async throws -> [WorkflowRun] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/actions/runs?per_page=10")!
        let request = makeRequest(url: url, token: token)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        let runsResponse = try decoder.decode(WorkflowRunsResponse.self, from: data)
        return runsResponse.workflowRuns
    }

    func fetchLatestRelease(owner: String, repo: String, token: String) async throws -> GitHubRelease? {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/releases/latest")!
        let request = makeRequest(url: url, token: token)
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            return nil
        }

        try validateResponse(response)
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    func fetchFailedJobs(owner: String, repo: String, runId: Int, token: String) async throws -> [String] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/actions/runs/\(runId)/jobs?filter=latest")!
        let request = makeRequest(url: url, token: token)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        let jobsResponse = try decoder.decode(WorkflowJobsResponse.self, from: data)
        return jobsResponse.jobs
            .filter { $0.conclusion == "failure" || $0.conclusion == "timed_out" || $0.conclusion == "startup_failure" }
            .map(\.name)
    }

    func fetchAccessibleRepos(token: String) async throws -> [RepoIdentifier] {
        var allRepos: [RepoIdentifier] = []
        var page = 1

        while true {
            let url = URL(string: "\(baseURL)/user/repos?per_page=100&sort=full_name&page=\(page)")!
            let request = makeRequest(url: url, token: token)
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let repos = try decoder.decode([GitHubRepoResponse].self, from: data)
            if repos.isEmpty { break }

            allRepos.append(contentsOf: repos.map {
                RepoIdentifier(owner: $0.owner.login, repo: $0.name)
            })

            if repos.count < 100 { break }
            page += 1
        }

        return allRepos
    }

    func fetchRepoStatus(repo: RepoIdentifier, token: String) async -> RepoStatus {
        do {
            async let runs = fetchWorkflowRuns(owner: repo.owner, repo: repo.repo, token: token)
            async let release = fetchLatestRelease(owner: repo.owner, repo: repo.repo, token: token)

            var fetchedRuns = try await runs
            let fetchedRelease = try await release

            // Fetch failed job names for failed runs (in parallel)
            let failedIndices = fetchedRuns.enumerated()
                .filter { $0.element.effectiveStatus == .failure }
                .map(\.offset)

            if !failedIndices.isEmpty {
                let jobResults = await withTaskGroup(of: (Int, [String]).self, returning: [(Int, [String])].self) { group in
                    for index in failedIndices {
                        let run = fetchedRuns[index]
                        group.addTask {
                            let jobs = (try? await self.fetchFailedJobs(
                                owner: repo.owner, repo: repo.repo,
                                runId: run.id, token: token
                            )) ?? []
                            return (index, jobs)
                        }
                    }
                    var results: [(Int, [String])] = []
                    for await result in group {
                        results.append(result)
                    }
                    return results
                }
                for (index, jobs) in jobResults {
                    fetchedRuns[index].failedJobs = jobs
                }
            }

            return RepoStatus(
                repo: repo,
                runs: fetchedRuns,
                latestRelease: fetchedRelease,
                error: nil
            )
        } catch {
            return RepoStatus(
                repo: repo,
                runs: [],
                latestRelease: nil,
                error: error.localizedDescription
            )
        }
    }

    private func makeRequest(url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

struct GitHubRepoResponse: Codable {
    let name: String
    let fullName: String
    let owner: GitHubRepoOwner

    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case owner
    }
}

struct GitHubRepoOwner: Codable {
    let login: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .httpError(statusCode: let code):
            switch code {
            case 401: return "Unauthorized - check your token"
            case 403: return "Forbidden - rate limit or insufficient permissions"
            case 404: return "Repository not found"
            default: return "HTTP error \(code)"
            }
        }
    }
}
