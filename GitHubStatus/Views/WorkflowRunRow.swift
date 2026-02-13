import SwiftUI

struct WorkflowRunRow: View {
    let run: WorkflowRun

    var body: some View {
        Button {
            if let url = URL(string: run.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                StatusIcon(status: run.effectiveStatus)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(run.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)

                        if let branch = run.headBranch {
                            Text(branch)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if let failedJobs = run.failedJobs, !failedJobs.isEmpty {
                            Text(failedJobs.joined(separator: ", "))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                    }

                    if let commitMessage = run.headCommit?.firstLine {
                        Text(commitMessage)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(run.updatedAt.relativeDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
