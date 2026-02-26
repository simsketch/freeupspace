import SwiftUI
import CleanupEngine
import SharedUtilities

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clean result banner
                if appState.showCleanResultBanner, let result = appState.lastCleanResult {
                    cleanResultBanner(result: result)
                }

                // Header
                headerSection

                // Disk Info
                if let disk = appState.diskInfo {
                    diskInfoSection(disk: disk)
                }

                // Storage bar
                if !appState.categories.isEmpty {
                    StorageBar(categories: appState.sortedCategories)
                        .frame(height: 32)
                        .padding(.horizontal)
                }

                // Selection + Action buttons
                if !appState.categories.isEmpty {
                    selectionButtons
                }
                actionButtons

                // Stats
                if appState.totalBytesFreedAllTime > 0 {
                    statsSection
                }

                // Category cards
                if !appState.sortedCategories.isEmpty {
                    categoryGrid
                }

                // Cleanup history
                if !appState.cleanupHistory.isEmpty {
                    historySection
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Clean Result Banner

    private func cleanResultBanner(result: CleanResult) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cleaned \(ByteFormatter.shared.formatPrecise(result.bytesFreed))")
                        .font(.headline)
                    Text("\(result.itemsCleaned) item\(result.itemsCleaned == 1 ? "" : "s") removed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    appState.showCleanResultBanner = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if !appState.lastCleanedItemNames.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.lastCleanedItemNames.prefix(8), id: \.self) { name in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if appState.lastCleanedItemNames.count > 8 {
                        Text("...and \(appState.lastCleanedItemNames.count - 8) more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.green.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            if appState.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning your development tools...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    ProgressView(value: appState.scanProgress)
                        .frame(maxWidth: 300)
                }
            } else if appState.isCleaning {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Cleaning selected items...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(ByteFormatter.shared.formatPrecise(appState.totalReclaimableSize))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("reclaimable space found")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                if let date = appState.lastScanDate {
                    Text("Last scanned \(date, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Disk Info

    private func diskInfoSection(disk: DiskInfo) -> some View {
        HStack(spacing: 16) {
            diskInfoBox(
                label: "Total Capacity",
                value: ByteFormatter.shared.formatPrecise(disk.totalCapacity),
                icon: "internaldrive"
            )
            diskInfoBox(
                label: "Used",
                value: ByteFormatter.shared.formatPrecise(disk.usedSpace),
                icon: "chart.pie.fill"
            )
            diskInfoBox(
                label: "Available",
                value: ByteFormatter.shared.formatPrecise(disk.availableSpace),
                icon: "externaldrive.badge.checkmark"
            )

            // Available percentage gauge
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: disk.availablePercent)
                        .stroke(
                            disk.availablePercent < 0.1 ? .red : disk.availablePercent < 0.2 ? .orange : .green,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(disk.availablePercent * 100))%")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                }
                .frame(width: 44, height: 44)
                Text("Free")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 80)
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func diskInfoBox(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selection Buttons

    private var selectionButtons: some View {
        HStack(spacing: 12) {
            Button {
                appState.selectAllSafeGlobal()
            } label: {
                Label("Select All Safe", systemImage: "checkmark.shield")
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button {
                appState.selectAllGlobal()
            } label: {
                Label("Select All", systemImage: "checkmark.square")
            }
            .buttonStyle(.bordered)

            Button {
                appState.selectNoneGlobal()
            } label: {
                Label("Select None", systemImage: "square")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("\(ByteFormatter.shared.formatPrecise(appState.totalSelectedSize)) selected")
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                appState.quickClean()
            } label: {
                if appState.isCleaning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Cleaning...")
                    }
                    .frame(maxWidth: 200)
                } else {
                    Label("Clean Safe Items", systemImage: "checkmark.shield")
                        .frame(maxWidth: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(appState.isScanning || appState.isCleaning || appState.totalSafeSize == 0)

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
                    .frame(maxWidth: 200)
                } else {
                    Label("Clean Selected (\(ByteFormatter.shared.formatPrecise(appState.totalSelectedSize)))", systemImage: "trash")
                        .frame(maxWidth: 200)
                }
            }
            .buttonStyle(.bordered)
            .disabled(appState.isScanning || appState.isCleaning || appState.totalSelectedSize == 0)
        }
        .alert("Danger Items Selected", isPresented: Binding(
            get: { appState.showDangerConfirmation },
            set: { appState.showDangerConfirmation = $0 }
        )) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Anyway", role: .destructive) {
                appState.cleanSelected()
            }
        } message: {
            Text("Some selected items are marked as dangerous and may cause data loss. Are you sure you want to proceed?")
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 24) {
            StatBox(
                title: "Total Freed",
                value: ByteFormatter.shared.formatPrecise(appState.totalBytesFreedAllTime),
                icon: "arrow.up.trash"
            )
            StatBox(
                title: "Cleanups",
                value: "\(appState.cleanupCount)",
                icon: "sparkles"
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
        ], spacing: 16) {
            ForEach(appState.sortedCategories) { category in
                CategoryCard(category: category)
                    .onTapGesture {
                        appState.selectedCategoryId = category.id
                        appState.showSystemDataView = false
                    }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Cleanup History")
                    .font(.headline)
                Spacer()
            }

            ForEach(appState.cleanupHistory.prefix(10)) { entry in
                historyRow(entry: entry)
            }

            if appState.cleanupHistory.count > 10 {
                Text("\(appState.cleanupHistory.count - 10) more entries...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func historyRow(entry: CleanupHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.callout.weight(.medium))
                Text("at")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                Text(entry.date, style: .time)
                    .font(.callout)
                Spacer()
                Text(ByteFormatter.shared.formatPrecise(entry.bytesFreed))
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.green)
            }

            HStack(spacing: 8) {
                Text("\(entry.itemsCleaned) item\(entry.itemsCleaned == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.quaternary)

                Text(entry.method)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.itemNames.isEmpty {
                Text(entry.itemNames.prefix(5).joined(separator: ", ") +
                     (entry.itemNames.count > 5 ? " +\(entry.itemNames.count - 5) more" : ""))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
