import SwiftUI
import CleanupEngine
import SharedUtilities

struct CategoryCard: View {
    let category: CleanupCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundStyle(colorForStack(category.stack))
                Spacer()
                Text(ByteFormatter.shared.formatPrecise(category.totalSize))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }

            Text(category.displayName)
                .font(.headline)

            HStack {
                Text("\(category.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                let safeCount = category.items.filter { $0.safetyLevel == .safe }.count
                if safeCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("\(safeCount) safe")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForStack(_ stack: DeveloperStack) -> Color {
        switch stack {
        case .docker: .blue
        case .xcode: .cyan
        case .node: .green
        case .homebrew: .orange
        case .python: .yellow
        case .go: .teal
        case .rust: .red
        case .vscode: .indigo
        case .git: .pink
        case .system: .gray
        case .browsers: .mint
        case .gradle: .brown
        }
    }
}
