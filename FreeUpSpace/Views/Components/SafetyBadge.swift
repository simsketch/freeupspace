import SwiftUI
import CleanupEngine

struct SafetyBadge: View {
    let level: SafetyLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.iconName)
                .font(.caption2)
            Text(level.displayName)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor, in: Capsule())
        .foregroundStyle(foregroundColor)
    }

    private var backgroundColor: Color {
        switch level {
        case .safe: .green.opacity(0.15)
        case .caution: .orange.opacity(0.15)
        case .danger: .red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch level {
        case .safe: .green
        case .caution: .orange
        case .danger: .red
        }
    }
}
