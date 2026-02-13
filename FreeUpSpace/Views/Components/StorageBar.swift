import SwiftUI
import CleanupEngine

struct StorageBar: View {
    let categories: [CleanupCategory]

    private var totalSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(categories) { category in
                    let fraction = totalSize > 0
                        ? CGFloat(category.totalSize) / CGFloat(totalSize)
                        : 0

                    if fraction > 0.01 { // Only show segments > 1%
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForStack(category.stack))
                            .frame(width: max(4, geometry.size.width * fraction))
                            .help("\(category.displayName): \(ByteFormatter.shared.formatPrecise(category.totalSize))")
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
        )
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

// Need ByteFormatter import
import SharedUtilities
