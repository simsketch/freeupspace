import Foundation

public struct HomebrewCleaner: Cleaner {
    public let id = "homebrew"
    public let displayName = "Homebrew"
    public let iconName = "mug.fill"
    public let stack = DeveloperStack.homebrew

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
            || FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Homebrew downloads cache
        let brewCache = URL.home.appendingPathComponent("Library/Caches/Homebrew/downloads")
        if brewCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: brewCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: brewCache,
                    displayName: "Homebrew Download Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded formula/cask archives. Re-downloaded if needed.",
                    terminalCommand: "brew cleanup --prune=all"
                ))
            }
        }

        // Homebrew Cask cache
        let caskCache = URL.home.appendingPathComponent("Library/Caches/Homebrew/Cask")
        if caskCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: caskCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: caskCache,
                    displayName: "Homebrew Cask Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded application installers from Homebrew Cask.",
                    terminalCommand: "brew cleanup --prune=all"
                ))
            }
        }

        // Homebrew logs
        let brewLogs = URL.home.appendingPathComponent("Library/Logs/Homebrew")
        if brewLogs.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: brewLogs)
            if size > 100_000 {
                items.append(CleanableItem(
                    path: brewLogs,
                    displayName: "Homebrew Logs",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Build and installation logs. Safe to remove.",
                    terminalCommand: "rm -rf '\(brewLogs.path)'"
                ))
            }
        }

        return makeCategory(items: items)
    }

    public func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        let deleter = SafeDeleter()
        return try await deleter.delete(items: items, method: method)
    }
}
