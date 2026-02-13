import Foundation

public struct SystemCleaner: Cleaner {
    public let id = "system"
    public let displayName = "System"
    public let iconName = "desktopcomputer"
    public let stack = DeveloperStack.system

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        true
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // System logs
        let systemLogs = URL.home.appendingPathComponent("Library/Logs")
        if systemLogs.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: systemLogs)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: systemLogs,
                    displayName: "User Logs",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Application and system logs in ~/Library/Logs.",
                    terminalCommand: "rm -rf '\(systemLogs.path)'/*"
                ))
            }
        }

        // Crash reports
        let crashReports = URL.home.appendingPathComponent("Library/Logs/DiagnosticReports")
        if crashReports.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: crashReports)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: crashReports,
                    displayName: "Crash Reports",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Application crash logs. Useful for debugging but safe to remove.",
                    terminalCommand: "rm -rf '\(crashReports.path)'"
                ))
            }
        }

        // General Library Caches (non-dev specific)
        let libraryCaches = URL.home.appendingPathComponent("Library/Caches")
        if libraryCaches.existsOnDisk {
            let devCachePrefixes = [
                "com.docker.", "com.microsoft.VSCode", "Homebrew",
                "pip", "go-build", "Yarn", "com.apple.dt.Xcode",
            ]

            let contents = try FileManager.default.contentsOfDirectory(
                at: libraryCaches,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            // Only scan the first 30 cache dirs to avoid slow scans
            let directories = contents.filter { url in
                let name = url.lastPathComponent
                let isDev = devCachePrefixes.contains { name.hasPrefix($0) || name.contains($0) }
                guard !isDev else { return false }
                return (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }.prefix(30)

            for cacheDir in directories {
                let name = cacheDir.lastPathComponent
                let size = try await scanner.directorySizeIncludingHidden(at: cacheDir)
                if size > 50_000_000 { // Only show caches > 50MB
                    items.append(CleanableItem(
                        path: cacheDir,
                        displayName: name,
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Application cache for \(name). Regenerated automatically.",
                        terminalCommand: "rm -rf '\(cacheDir.path)'"
                    ))
                }
            }
        }

        // Downloads folder old files (> 30 days)
        let downloads = URL.home.appendingPathComponent("Downloads")
        if downloads.existsOnDisk {
            var oldFilesSize: Int64 = 0
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let contents = try FileManager.default.contentsOfDirectory(
                at: downloads,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            for file in contents {
                let attrs = try file.resourceValues(forKeys: [.contentModificationDateKey])
                if let modDate = attrs.contentModificationDate, modDate < thirtyDaysAgo {
                    let isDir = (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    if isDir {
                        oldFilesSize += (try? await scanner.directorySizeIncludingHidden(at: file)) ?? 0
                    } else {
                        oldFilesSize += await scanner.fileSize(at: file)
                    }
                }
            }
            if oldFilesSize > 100_000_000 {
                items.append(CleanableItem(
                    path: downloads,
                    displayName: "Old Downloads (30+ days)",
                    sizeInBytes: oldFilesSize,
                    safetyLevel: .caution,
                    explanation: "Files in Downloads older than 30 days. Review before removing.",
                    terminalCommand: "find '\(downloads.path)' -maxdepth 1 -mtime +30 -ls"
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
