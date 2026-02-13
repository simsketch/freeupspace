import SwiftUI
import CleanupEngine
import SharedUtilities

struct FileItemRow: View {
    let item: CleanableItem
    let categoryId: String
    @Environment(AppState.self) private var appState
    @State private var showTerminalCommand = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in appState.toggleItem(categoryId: categoryId, itemId: item.id) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            // Safety badge
            SafetyBadge(level: item.safetyLevel)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if showTerminalCommand {
                    Text(item.terminalCommand)
                        .font(.caption.monospaced())
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            // Size
            SizeLabel(bytes: item.sizeInBytes)

            // Actions
            Button {
                showTerminalCommand.toggle()
            } label: {
                Image(systemName: "terminal")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Show terminal command")

            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: item.path.deletingLastPathComponent().path)
            } label: {
                Image(systemName: "folder")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 4)
    }
}
