import SwiftUI
import CleanupEngine
import SharedUtilities

struct CategoryDetailView: View {
    let category: CleanupCategory
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
                .padding()

            Divider()

            // Item list
            List {
                ForEach(SafetyLevel.allCases, id: \.self) { level in
                    let itemsForLevel = category.items.filter { $0.safetyLevel == level }
                    if !itemsForLevel.isEmpty {
                        Section {
                            ForEach(itemsForLevel) { item in
                                FileItemRow(item: item, categoryId: category.id)
                            }
                        } header: {
                            HStack {
                                SafetyBadge(level: level)
                                Text("\(itemsForLevel.count) items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            // Footer actions
            footerSection
                .padding()
        }
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: category.iconName)
                .font(.title)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.title2.weight(.semibold))
                Text("\(category.itemCount) items \u{2022} \(ByteFormatter.shared.formatPrecise(category.totalSize)) total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(ByteFormatter.shared.formatPrecise(category.selectedSize))
                    .font(.title3.weight(.medium))
                    .monospacedDigit()
                Text("selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Button("Select Safe") {
                appState.selectAllSafe(categoryId: category.id)
            }
            Button("Select None") {
                appState.selectNone(categoryId: category.id)
            }

            Spacer()

            Button {
                if appState.hasDangerItemsSelected {
                    appState.showDangerConfirmation = true
                } else {
                    appState.cleanSelected()
                }
            } label: {
                if appState.isCleaning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Cleaning...")
                    }
                } else {
                    Label("Clean Selected", systemImage: "trash")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isCleaning || category.selectedSize == 0)
        }
    }
}
