import Foundation

public actor CleanupOrchestrator {
    private let scanner = FileSystemScanner()
    private let stackDetector = StackDetector()
    private let deleter = SafeDeleter()
    private var cleaners: [any Cleaner] = []
    private var scanTask: Task<Void, Never>?

    public init() {
        self.cleaners = Self.allCleaners()
    }

    private static func allCleaners() -> [any Cleaner] {
        [
            DockerCleaner(),
            XcodeCleaner(),
            NodeCleaner(),
            HomebrewCleaner(),
            PythonCleaner(),
            GoCleaner(),
            CargoCleaner(),
            VSCodeCleaner(),
            GitCleaner(),
            SystemCleaner(),
            BrowserDevCleaner(),
            GradleCleaner(),
        ]
    }

    /// Scan all available stacks concurrently, streaming results
    public func scan() -> AsyncStream<ScanEvent> {
        AsyncStream { continuation in
            let task = Task {
                let availableCleaners = await filterAvailableCleaners()
                continuation.yield(.started(totalCleaners: availableCleaners.count))

                await withTaskGroup(of: ScanEvent?.self) { group in
                    for cleaner in availableCleaners {
                        group.addTask {
                            do {
                                // 15-second timeout per cleaner
                                let category = try await withThrowingTaskGroup(of: CleanupCategory.self) { inner in
                                    inner.addTask {
                                        try await cleaner.scan()
                                    }
                                    inner.addTask {
                                        try await Task.sleep(for: .seconds(15))
                                        throw CancellationError()
                                    }
                                    let result = try await inner.next()!
                                    inner.cancelAll()
                                    return result
                                }
                                if !category.items.isEmpty {
                                    return .categoryScanned(category)
                                }
                                return .categoryEmpty(cleanerId: cleaner.id)
                            } catch {
                                return .categoryError(cleanerId: cleaner.id, error: error)
                            }
                        }
                    }

                    for await event in group {
                        if let event {
                            continuation.yield(event)
                        }
                    }
                }

                continuation.yield(.completed)
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }

            self.scanTask = task
        }
    }

    /// Cancel an in-progress scan
    public func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
    }

    /// Clean selected items across categories
    public func clean(categories: [CleanupCategory], method: DeletionMethod) async throws -> CleanResult {
        var totalFreed: Int64 = 0
        var errors: [CleanError] = []
        var itemsCleaned = 0

        for category in categories {
            let selectedItems = category.items.filter(\.isSelected)
            guard !selectedItems.isEmpty else { continue }

            do {
                let freed = try await deleter.delete(items: selectedItems, method: method)
                totalFreed += freed
                itemsCleaned += selectedItems.count
            } catch {
                errors.append(CleanError(categoryId: category.id, error: error))
            }
        }

        return CleanResult(
            bytesFreed: totalFreed,
            itemsCleaned: itemsCleaned,
            errors: errors
        )
    }

    /// Quick clean: only clean safe items across all categories
    public func quickClean(categories: [CleanupCategory]) async throws -> CleanResult {
        let safeCategories = categories.map { category in
            var modified = category
            modified.items = category.items.map { item in
                var modifiedItem = item
                modifiedItem.isSelected = item.safetyLevel == .safe
                return modifiedItem
            }
            return modified
        }
        return try await clean(categories: safeCategories, method: .moveToTrash)
    }

    private func filterAvailableCleaners() async -> [any Cleaner] {
        await withTaskGroup(of: (any Cleaner)?.self) { group in
            for cleaner in cleaners {
                group.addTask {
                    let available = await cleaner.isAvailable()
                    return available ? cleaner : nil
                }
            }

            var available: [any Cleaner] = []
            for await cleaner in group {
                if let cleaner {
                    available.append(cleaner)
                }
            }
            return available
        }
    }
}

// MARK: - Events & Results

public enum ScanEvent: Sendable {
    case started(totalCleaners: Int)
    case categoryScanned(CleanupCategory)
    case categoryEmpty(cleanerId: String)
    case categoryError(cleanerId: String, error: Error)
    case completed
}

public struct CleanResult: Sendable {
    public let bytesFreed: Int64
    public let itemsCleaned: Int
    public let errors: [CleanError]

    public var hasErrors: Bool { !errors.isEmpty }
}

public struct CleanError: Sendable {
    public let categoryId: String
    public let error: Error
}
