import Foundation

struct GitHubRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String?
    let htmlUrl: String
    let publishedAt: Date?
    let prerelease: Bool
    let draft: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, prerelease, draft
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }

    var displayName: String {
        name ?? tagName
    }
}
