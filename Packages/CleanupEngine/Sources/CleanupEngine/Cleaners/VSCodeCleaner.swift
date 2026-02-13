import Foundation

public struct VSCodeCleaner: Cleaner {
    public let id = "vscode"
    public let displayName = "VS Code"
    public let iconName = "curlybraces"
    public let stack = DeveloperStack.vscode

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Visual Studio Code.app")
            || URL.home.appendingPathComponent("Library/Application Support/Code").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        let codeSupport = URL.home.appendingPathComponent("Library/Application Support/Code")

        // CachedData
        let cachedData = codeSupport.appendingPathComponent("CachedData")
        if cachedData.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: cachedData)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: cachedData,
                    displayName: "VS Code CachedData",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "V8 code cache for faster startup. Regenerated automatically.",
                    terminalCommand: "rm -rf '\(cachedData.path)'"
                ))
            }
        }

        // CachedExtensionVSIXs
        let cachedVSIX = codeSupport.appendingPathComponent("CachedExtensionVSIXs")
        if cachedVSIX.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: cachedVSIX)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: cachedVSIX,
                    displayName: "VS Code Cached Extension VSIXs",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Cached extension packages. Re-downloaded when extensions update.",
                    terminalCommand: "rm -rf '\(cachedVSIX.path)'"
                ))
            }
        }

        // Cache
        let codeCache = URL.home.appendingPathComponent("Library/Caches/com.microsoft.VSCode")
        if codeCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: codeCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: codeCache,
                    displayName: "VS Code Application Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Electron/Chromium cache. Regenerated on next launch.",
                    terminalCommand: "rm -rf '\(codeCache.path)'"
                ))
            }
        }

        // Service Worker cache (can be huge)
        let swCache = codeSupport.appendingPathComponent("Cache/Cache_Data")
        if swCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: swCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: swCache,
                    displayName: "VS Code Cache Data",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Chromium cache data. Can grow very large. Regenerated automatically.",
                    terminalCommand: "rm -rf '\(swCache.path)'"
                ))
            }
        }

        // Logs
        let logs = codeSupport.appendingPathComponent("logs")
        if logs.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: logs)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: logs,
                    displayName: "VS Code Logs",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Extension and application logs. Safe to remove.",
                    terminalCommand: "rm -rf '\(logs.path)'"
                ))
            }
        }

        // Crash reports
        let crashReports = codeSupport.appendingPathComponent("Crashpad/reports")
        if crashReports.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: crashReports)
            if size > 100_000 {
                items.append(CleanableItem(
                    path: crashReports,
                    displayName: "VS Code Crash Reports",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Crash report files. No longer needed after reporting.",
                    terminalCommand: "rm -rf '\(crashReports.path)'"
                ))
            }
        }

        // Also check VS Code Insiders
        let insidersSupport = URL.home.appendingPathComponent("Library/Application Support/Code - Insiders")
        if insidersSupport.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: insidersSupport.appendingPathComponent("CachedData"))
            let size2 = try await scanner.directorySizeIncludingHidden(at: insidersSupport.appendingPathComponent("Cache"))
            let totalInsiders = size + size2
            if totalInsiders > 1_000_000 {
                items.append(CleanableItem(
                    path: insidersSupport.appendingPathComponent("CachedData"),
                    displayName: "VS Code Insiders Cache",
                    sizeInBytes: totalInsiders,
                    safetyLevel: .safe,
                    explanation: "Cache for VS Code Insiders edition.",
                    terminalCommand: "rm -rf '\(insidersSupport.appendingPathComponent("CachedData").path)' '\(insidersSupport.appendingPathComponent("Cache").path)'"
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
