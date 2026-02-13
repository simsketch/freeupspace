import SwiftUI
import CleanupEngine

// MARK: - Cleanup History Entry

struct CleanupHistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bytesFreed: Int64
    let itemsCleaned: Int
    let itemNames: [String]
    let method: String

    init(id: UUID = UUID(), date: Date = Date(), bytesFreed: Int64, itemsCleaned: Int, itemNames: [String], method: String) {
        self.id = id
        self.date = date
        self.bytesFreed = bytesFreed
        self.itemsCleaned = itemsCleaned
        self.itemNames = itemNames
        self.method = method
    }
}

// MARK: - Disk Info

struct DiskInfo {
    let totalCapacity: Int64
    let availableSpace: Int64
    let usedSpace: Int64

    var availablePercent: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(availableSpace) / Double(totalCapacity)
    }
}

@Observable
final class AppState {
    // MARK: - Scan State
    var categories: [CleanupCategory] = []
    var isScanning = false
    var scanProgress: Double = 0
    var totalCleanersCount = 0
    var scannedCleanersCount = 0
    var lastScanDate: Date?

    // MARK: - UI State
    var selectedCategoryId: String?
    var showOnboarding: Bool
    var showSystemDataView = false

    // MARK: - Cleaning State
    var isCleaning = false
    var lastCleanResult: CleanResult?
    var showCleanConfirmation = false
    var showDangerConfirmation = false
    var showCleanResultBanner = false
    var lastCleanedItemNames: [String] = []

    // MARK: - Settings
    var defaultDeletionMethod: DeletionMethod = .moveToTrash
    var excludedPaths: [String] = []
    var nodeModulesStaleDays: Int = 30
    var launchAtLogin = false

    // MARK: - Stats
    var totalBytesFreedAllTime: Int64 = 0
    var cleanupCount: Int = 0
    var cleanupHistory: [CleanupHistoryEntry] = []
    var diskInfo: DiskInfo?

    // MARK: - Computed
    var totalReclaimableSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }

    var totalSelectedSize: Int64 {
        categories.reduce(0) { $0 + $1.selectedSize }
    }

    var totalSafeSize: Int64 {
        categories.reduce(0) { $0 + $1.safeSize }
    }

    var sortedCategories: [CleanupCategory] {
        categories.sorted { $0.totalSize > $1.totalSize }
    }

    var selectedCategory: CleanupCategory? {
        guard let id = selectedCategoryId else { return nil }
        return categories.first { $0.id == id }
    }

    var hasDangerItemsSelected: Bool {
        categories.flatMap(\.items).contains { $0.isSelected && $0.safetyLevel == .danger }
    }

    // MARK: - Engine
    private let orchestrator = CleanupOrchestrator()
    private var scanTask: Task<Void, Never>?

    init() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.showOnboarding = !hasLaunched

        self.defaultDeletionMethod = DeletionMethod(
            rawValue: UserDefaults.standard.string(forKey: "defaultDeletionMethod") ?? "moveToTrash"
        ) ?? .moveToTrash

        self.totalBytesFreedAllTime = Int64(UserDefaults.standard.integer(forKey: "totalBytesFreed"))
        self.cleanupCount = UserDefaults.standard.integer(forKey: "cleanupCount")
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        loadHistory()
        refreshDiskInfo()
    }

    // MARK: - Actions

    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        categories = []
        scanProgress = 0
        scannedCleanersCount = 0

        scanTask = Task { @MainActor in
            let stream = await orchestrator.scan()

            for await event in stream {
                switch event {
                case .started(let total):
                    totalCleanersCount = total

                case .categoryScanned(let category):
                    categories.append(category)
                    scannedCleanersCount += 1
                    scanProgress = Double(scannedCleanersCount) / Double(max(totalCleanersCount, 1))

                case .categoryEmpty:
                    scannedCleanersCount += 1
                    scanProgress = Double(scannedCleanersCount) / Double(max(totalCleanersCount, 1))

                case .categoryError(_, _):
                    scannedCleanersCount += 1
                    scanProgress = Double(scannedCleanersCount) / Double(max(totalCleanersCount, 1))

                case .completed:
                    isScanning = false
                    scanProgress = 1.0
                    lastScanDate = Date()
                    refreshDiskInfo()
                }
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        Task {
            await orchestrator.cancelScan()
        }
        isScanning = false
    }

    func cleanSelected() {
        guard !isCleaning else { return }
        isCleaning = true

        // Capture what we're about to clean
        let selectedItems = categories.flatMap { $0.items.filter(\.isSelected) }
        let itemNames = selectedItems.map(\.displayName)

        Task { @MainActor in
            do {
                let result = try await orchestrator.clean(
                    categories: categories,
                    method: defaultDeletionMethod
                )
                lastCleanResult = result
                lastCleanedItemNames = itemNames
                totalBytesFreedAllTime += result.bytesFreed
                cleanupCount += 1

                // Record history
                let entry = CleanupHistoryEntry(
                    bytesFreed: result.bytesFreed,
                    itemsCleaned: result.itemsCleaned,
                    itemNames: itemNames,
                    method: defaultDeletionMethod == .moveToTrash ? "Moved to Trash" : "Permanently Deleted"
                )
                cleanupHistory.insert(entry, at: 0)
                if cleanupHistory.count > 50 { cleanupHistory = Array(cleanupHistory.prefix(50)) }

                saveStats()
                saveHistory()
                showCleanResultBanner = true
                refreshDiskInfo()

                // Auto-dismiss banner after 8 seconds
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(8))
                    showCleanResultBanner = false
                }

                // Re-scan after cleaning
                startScan()
            } catch {
                // Error handled via lastCleanResult
            }
            isCleaning = false
        }
    }

    func quickClean() {
        guard !isCleaning else { return }
        isCleaning = true

        let safeItems = categories.flatMap { $0.items.filter { $0.safetyLevel == .safe } }
        let itemNames = safeItems.map(\.displayName)

        Task { @MainActor in
            do {
                let result = try await orchestrator.quickClean(categories: categories)
                lastCleanResult = result
                lastCleanedItemNames = itemNames
                totalBytesFreedAllTime += result.bytesFreed
                cleanupCount += 1

                let entry = CleanupHistoryEntry(
                    bytesFreed: result.bytesFreed,
                    itemsCleaned: result.itemsCleaned,
                    itemNames: itemNames,
                    method: "Moved to Trash (Quick Clean)"
                )
                cleanupHistory.insert(entry, at: 0)
                if cleanupHistory.count > 50 { cleanupHistory = Array(cleanupHistory.prefix(50)) }

                saveStats()
                saveHistory()
                showCleanResultBanner = true
                refreshDiskInfo()

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(8))
                    showCleanResultBanner = false
                }

                startScan()
            } catch {
                // Error handled via lastCleanResult
            }
            isCleaning = false
        }
    }

    func toggleItem(categoryId: String, itemId: UUID) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }),
              let itemIndex = categories[catIndex].items.firstIndex(where: { $0.id == itemId }) else {
            return
        }
        categories[catIndex].items[itemIndex].isSelected.toggle()
    }

    func selectAllSafe(categoryId: String) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        for i in categories[catIndex].items.indices {
            categories[catIndex].items[i].isSelected = categories[catIndex].items[i].safetyLevel == .safe
        }
    }

    func selectNone(categoryId: String) {
        guard let catIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        for i in categories[catIndex].items.indices {
            categories[catIndex].items[i].isSelected = false
        }
    }

    func selectAllSafeGlobal() {
        for catIndex in categories.indices {
            for i in categories[catIndex].items.indices {
                categories[catIndex].items[i].isSelected = categories[catIndex].items[i].safetyLevel == .safe
            }
        }
    }

    func selectNoneGlobal() {
        for catIndex in categories.indices {
            for i in categories[catIndex].items.indices {
                categories[catIndex].items[i].isSelected = false
            }
        }
    }

    func selectAllGlobal() {
        for catIndex in categories.indices {
            for i in categories[catIndex].items.indices {
                categories[catIndex].items[i].isSelected = true
            }
        }
    }

    func completeOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        startScan()
    }

    // MARK: - Disk Info

    func refreshDiskInfo() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path) {
            let total = (attrs[.systemSize] as? Int64) ?? 0
            let free = (attrs[.systemFreeSize] as? Int64) ?? 0
            diskInfo = DiskInfo(totalCapacity: total, availableSpace: free, usedSpace: total - free)
        }
    }

    // MARK: - Persistence

    private func saveStats() {
        UserDefaults.standard.set(Int(totalBytesFreedAllTime), forKey: "totalBytesFreed")
        UserDefaults.standard.set(cleanupCount, forKey: "cleanupCount")
    }

    func updateDeletionMethod(_ method: DeletionMethod) {
        defaultDeletionMethod = method
        UserDefaults.standard.set(method.rawValue, forKey: "defaultDeletionMethod")
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(cleanupHistory) {
            UserDefaults.standard.set(data, forKey: "cleanupHistory")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "cleanupHistory"),
           let history = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) {
            cleanupHistory = history
        }
    }
}
