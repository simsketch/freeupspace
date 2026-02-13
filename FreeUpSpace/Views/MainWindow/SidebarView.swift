import SwiftUI
import CleanupEngine
import SharedUtilities

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        List(selection: Binding(
            get: { appState.selectedCategoryId },
            set: { newValue in
                appState.selectedCategoryId = newValue
                appState.showSystemDataView = false
            }
        )) {
            Section {
                Button {
                    appState.selectedCategoryId = nil
                    appState.showSystemDataView = false
                } label: {
                    Label {
                        HStack {
                            Text("Dashboard")
                            Spacer()
                            Text(ByteFormatter.shared.formatPrecise(appState.totalReclaimableSize))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: "gauge.with.dots.needle.33percent")
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
            }

            if !appState.sortedCategories.isEmpty {
                Section("Dev Tools") {
                    ForEach(appState.sortedCategories) { category in
                        NavigationLink(value: category.id) {
                            Label {
                                HStack {
                                    Text(category.displayName)
                                    Spacer()
                                    Text(ByteFormatter.shared.formatPrecise(category.totalSize))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            } icon: {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(colorForStack(category.stack))
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    appState.showSystemDataView = true
                    appState.selectedCategoryId = nil
                } label: {
                    Label {
                        Text("System Data")
                    } icon: {
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.purple)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if appState.isScanning {
                    VStack(spacing: 2) {
                        ProgressView(value: appState.scanProgress)
                            .progressViewStyle(.linear)
                        Text("Scanning...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100)
                }
            }
        }
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
