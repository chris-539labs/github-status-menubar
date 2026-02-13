import SwiftUI

struct ReleaseRow: View {
    let release: GitHubRelease

    var body: some View {
        Button {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 11))

                Text(release.tagName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if release.prerelease {
                    Text("pre")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                Spacer()

                if let date = release.publishedAt {
                    Text(date.relativeDescription)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
