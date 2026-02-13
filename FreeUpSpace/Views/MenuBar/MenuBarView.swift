import SwiftUI
import CleanupEngine
import SharedUtilities

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "externaldrive.badge.minus")
                    .font(.title3)
                Text("FreeUpSpace")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Summary
            if appState.categories.isEmpty {
                VStack(spacing: 8) {
                    Text("No scan data")
                        .foregroundStyle(.secondary)
                    Button("Scan Now") {
                        appState.startScan()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    Text(ByteFormatter.shared.formatPrecise(appState.totalReclaimableSize))
                        .font(.title.weight(.bold))
                        .monospacedDigit()
                    Text("reclaimable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Top 3 categories
                VStack(spacing: 6) {
                    ForEach(appState.sortedCategories.prefix(3)) { category in
                        HStack {
                            Image(systemName: category.iconName)
                                .frame(width: 20)
                            Text(category.displayName)
                                .font(.callout)
                            Spacer()
                            Text(ByteFormatter.shared.formatPrecise(category.totalSize))
                                .font(.callout)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Quick clean button
                Button {
                    appState.quickClean()
                } label: {
                    Label(
                        "Quick Clean Safe Items (\(ByteFormatter.shared.formatPrecise(appState.totalSafeSize)))",
                        systemImage: "checkmark.shield"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.regular)
                .disabled(appState.isCleaning || appState.totalSafeSize == 0)
                .padding(.horizontal)
            }

            // Lifetime stats
            if appState.totalBytesFreedAllTime > 0 {
                Divider()
                HStack {
                    Text("Total freed:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ByteFormatter.shared.formatPrecise(appState.totalBytesFreedAllTime))
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                }
                .padding(.horizontal)
            }

            Divider()

            // Footer actions
            HStack {
                Button("Open FreeUpSpace") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if let window = NSApplication.shared.windows.first(where: { $0.title.contains("FreeUpSpace") || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
    }
}
