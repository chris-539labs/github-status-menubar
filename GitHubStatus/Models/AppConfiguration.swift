import Foundation

struct RepoIdentifier: Codable, Equatable, Hashable, Identifiable {
    var owner: String
    var repo: String

    var id: String { "\(owner)/\(repo)" }
    var fullName: String { "\(owner)/\(repo)" }
}

struct AppConfiguration: Codable, Equatable {
    var token: String
    var repos: [RepoIdentifier]
    var refreshIntervalSeconds: Int

    static let `default` = AppConfiguration(
        token: "",
        repos: [],
        refreshIntervalSeconds: 300
    )
}
