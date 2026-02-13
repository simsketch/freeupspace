import Foundation

public struct GoCleaner: Cleaner {
    public let id = "go"
    public let displayName = "Go"
    public let iconName = "hare.fill"
    public let stack = DeveloperStack.go

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/usr/local/go/bin/go")
            || FileManager.default.fileExists(atPath: "/opt/homebrew/bin/go")
            || URL.home.appendingPathComponent("go").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Go module cache
        let goModCache = URL.home.appendingPathComponent("go/pkg/mod/cache")
        if goModCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: goModCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: goModCache,
                    displayName: "Go Module Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Cached Go module downloads. Re-downloaded with 'go mod download'.",
                    terminalCommand: "go clean -modcache"
                ))
            }
        }

        // Go build cache
        let goBuildCache = URL.home.appendingPathComponent("Library/Caches/go-build")
        if goBuildCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: goBuildCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: goBuildCache,
                    displayName: "Go Build Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Compiled package cache. Rebuilt automatically on next build.",
                    terminalCommand: "go clean -cache"
                ))
            }
        }

        // Go test cache
        let goTestCache = URL.home.appendingPathComponent("Library/Caches/go-build")
        // Test cache is part of build cache, but we can also clean it
        if goTestCache.existsOnDisk {
            // Already captured in build cache above
        }

        // GOPATH bin (old binaries)
        let goBin = URL.home.appendingPathComponent("go/bin")
        if goBin.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: goBin)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: goBin,
                    displayName: "Go Installed Binaries",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Go tools installed via 'go install'. Re-install with 'go install <package>@latest'.",
                    terminalCommand: "ls -la '\(goBin.path)'"
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
