import Foundation

public struct NodeCleaner: Cleaner {
    public let id = "node"
    public let displayName = "Node.js"
    public let iconName = "cube.fill"
    public let stack = DeveloperStack.node

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        let paths = ["/usr/local/bin/node", "/opt/homebrew/bin/node"]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
            || URL.home.appendingPathComponent(".npm").existsOnDisk
            || URL.home.appendingPathComponent(".nvm").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // npm cache
        let npmCache = URL.home.appendingPathComponent(".npm/_cacache")
        if npmCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: npmCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: npmCache,
                    displayName: "npm Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded package tarballs. Re-downloaded as needed. Equivalent to 'npm cache clean --force'.",
                    terminalCommand: "npm cache clean --force"
                ))
            }
        }

        // Yarn v1 cache
        let yarnCache = URL.home.appendingPathComponent("Library/Caches/Yarn")
        if yarnCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: yarnCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: yarnCache,
                    displayName: "Yarn Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Yarn's global package cache. Re-downloaded when needed.",
                    terminalCommand: "yarn cache clean"
                ))
            }
        }

        // Yarn v2+ (Berry) cache
        let yarnBerryCache = URL.home.appendingPathComponent(".yarn/berry/cache")
        if yarnBerryCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: yarnBerryCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: yarnBerryCache,
                    displayName: "Yarn Berry Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Yarn v2+ global cache. Re-downloaded when needed.",
                    terminalCommand: "rm -rf '\(yarnBerryCache.path)'"
                ))
            }
        }

        // pnpm store
        let pnpmStore = URL.home.appendingPathComponent("Library/pnpm/store")
        if pnpmStore.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: pnpmStore)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: pnpmStore,
                    displayName: "pnpm Store",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "pnpm's content-addressable store. Re-downloaded as needed.",
                    terminalCommand: "pnpm store prune"
                ))
            }
        }

        // Global node_modules
        let globalNodeModules = URL(fileURLWithPath: "/usr/local/lib/node_modules")
        if globalNodeModules.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: globalNodeModules)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: globalNodeModules,
                    displayName: "Global node_modules",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Globally installed npm packages. Re-install needed after cleanup.",
                    terminalCommand: "ls '\(globalNodeModules.path)'"
                ))
            }
        }

        // NVM installed versions
        let nvmDir = URL.home.appendingPathComponent(".nvm/versions/node")
        if nvmDir.existsOnDisk {
            let subdirs = try await scanner.subdirectories(at: nvmDir)
            if subdirs.count > 1 {
                // Only suggest cleaning old versions, keep the latest
                let sorted = subdirs.sorted { $0.lastPathComponent > $1.lastPathComponent }
                for dir in sorted.dropFirst() {
                    let size = try await scanner.directorySizeIncludingHidden(at: dir)
                    if size > 0 {
                        items.append(CleanableItem(
                            path: dir,
                            displayName: "Node \(dir.lastPathComponent) (NVM)",
                            sizeInBytes: size,
                            safetyLevel: .caution,
                            explanation: "Older Node.js version installed via NVM. Re-install with 'nvm install \(dir.lastPathComponent)'.",
                            terminalCommand: "nvm uninstall \(dir.lastPathComponent)"
                        ))
                    }
                }
            }
        }

        return makeCategory(items: items)
    }

    public func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        let deleter = SafeDeleter()
        return try await deleter.delete(items: items, method: method)
    }
}
