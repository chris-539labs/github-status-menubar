import SwiftUI

struct StatusIcon: View {
    let status: EffectiveRunStatus
    var size: CGFloat = 12

    var body: some View {
        Image(systemName: iconName)
            .foregroundStyle(iconColor)
            .font(.system(size: size))
    }

    private var iconName: String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .neutral: return "minus.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    private var iconColor: Color {
        switch status {
        case .success: return .green
        case .failure: return .red
        case .inProgress: return .orange
        case .neutral: return .gray
        case .unknown: return .gray
        }
    }
}
