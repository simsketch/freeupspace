import Foundation

public struct BrowserDevCleaner: Cleaner {
    public let id = "browsers"
    public let displayName = "Browsers"
    public let iconName = "globe"
    public let stack = DeveloperStack.browsers

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Google Chrome.app")
            || FileManager.default.fileExists(atPath: "/Applications/Firefox.app")
            || true // Safari is always present
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Chrome
        let chromeSupport = URL.home.appendingPathComponent("Library/Application Support/Google/Chrome")
        if chromeSupport.existsOnDisk {
            // Service Worker cache
            let swStorage = chromeSupport.appendingPathComponent("Default/Service Worker/CacheStorage")
            if swStorage.existsOnDisk {
                let size = try await scanner.directorySizeIncludingHidden(at: swStorage)
                if size > 10_000_000 {
                    items.append(CleanableItem(
                        path: swStorage,
                        displayName: "Chrome Service Worker Cache",
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Cached data from web apps' service workers. Re-cached on next visit.",
                        terminalCommand: "rm -rf '\(swStorage.path)'"
                    ))
                }
            }

            // Chrome Cache
            let chromeCache = URL.home.appendingPathComponent("Library/Caches/Google/Chrome/Default/Cache")
            if chromeCache.existsOnDisk {
                let size = try await scanner.directorySizeIncludingHidden(at: chromeCache)
                if size > 10_000_000 {
                    items.append(CleanableItem(
                        path: chromeCache,
                        displayName: "Chrome Browser Cache",
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Web page cache. Regenerated automatically while browsing.",
                        terminalCommand: "rm -rf '\(chromeCache.path)'"
                    ))
                }
            }

            // Code Cache
            let codeCache = chromeSupport.appendingPathComponent("Default/Code Cache")
            if codeCache.existsOnDisk {
                let size = try await scanner.directorySizeIncludingHidden(at: codeCache)
                if size > 5_000_000 {
                    items.append(CleanableItem(
                        path: codeCache,
                        displayName: "Chrome Code Cache",
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Compiled JavaScript cache for faster page loads. Regenerated automatically.",
                        terminalCommand: "rm -rf '\(codeCache.path)'"
                    ))
                }
            }
        }

        // Firefox
        let firefoxProfiles = URL.home.appendingPathComponent("Library/Application Support/Firefox/Profiles")
        if firefoxProfiles.existsOnDisk {
            let profiles = (try? await scanner.subdirectories(at: firefoxProfiles)) ?? []
            for profile in profiles {
                let cache2 = profile.appendingPathComponent("cache2")
                if cache2.existsOnDisk {
                    let size = try await scanner.directorySizeIncludingHidden(at: cache2)
                    if size > 10_000_000 {
                        items.append(CleanableItem(
                            path: cache2,
                            displayName: "Firefox Cache (\(profile.lastPathComponent))",
                            sizeInBytes: size,
                            safetyLevel: .safe,
                            explanation: "Firefox browser cache. Regenerated while browsing.",
                            terminalCommand: "rm -rf '\(cache2.path)'"
                        ))
                    }
                }
            }
        }

        // Safari
        let safariCache = URL.home.appendingPathComponent("Library/Caches/com.apple.Safari")
        if safariCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: safariCache)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: safariCache,
                    displayName: "Safari Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Safari web cache. Regenerated automatically.",
                    terminalCommand: "rm -rf '\(safariCache.path)'"
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
