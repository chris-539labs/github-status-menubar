import SwiftUI

struct RepoSectionView: View {
    let status: RepoStatus

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Repo row: icon, name, release tag, chevron
            Button {
                if !status.runs.isEmpty {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    StatusIcon(status: status.aggregateStatus)
                    Text(status.repo.fullName)
                        .font(.system(size: 13, weight: .semibold))

                    Spacer()

                    if let release = status.latestRelease {
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.blue)
                            Text(release.tagName)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture {
                            if let url = URL(string: release.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    if !status.runs.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let error = status.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .padding(.leading, 20)
            }

            // Expanded runs
            if isExpanded {
                VStack(spacing: 3) {
                    ForEach(status.runs) { run in
                        WorkflowRunRow(run: run)
                    }
                }
                .padding(.leading, 20)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}
