import Foundation

public struct CargoCleaner: Cleaner {
    public let id = "cargo"
    public let displayName = "Rust / Cargo"
    public let iconName = "gearshape.2.fill"
    public let stack = DeveloperStack.rust

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        URL.home.appendingPathComponent(".cargo").existsOnDisk
            || URL.home.appendingPathComponent(".rustup").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Cargo registry cache (compressed crates)
        let registryCache = URL.home.appendingPathComponent(".cargo/registry/cache")
        if registryCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: registryCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: registryCache,
                    displayName: "Cargo Registry Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Compressed crate archives. Re-downloaded on next build.",
                    terminalCommand: "rm -rf '\(registryCache.path)'"
                ))
            }
        }

        // Cargo registry src (extracted sources)
        let registrySrc = URL.home.appendingPathComponent(".cargo/registry/src")
        if registrySrc.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: registrySrc)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: registrySrc,
                    displayName: "Cargo Registry Sources",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Extracted crate sources. Re-extracted from cache on next build.",
                    terminalCommand: "rm -rf '\(registrySrc.path)'"
                ))
            }
        }

        // Cargo git checkouts
        let gitCheckouts = URL.home.appendingPathComponent(".cargo/git/checkouts")
        if gitCheckouts.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: gitCheckouts)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: gitCheckouts,
                    displayName: "Cargo Git Checkouts",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Git dependency checkouts. Re-cloned on next build but may be slow.",
                    terminalCommand: "rm -rf '\(gitCheckouts.path)'"
                ))
            }
        }

        // Cargo git db
        let gitDb = URL.home.appendingPathComponent(".cargo/git/db")
        if gitDb.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: gitDb)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: gitDb,
                    displayName: "Cargo Git DB",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Bare git repos for git dependencies. Re-cloned on next build.",
                    terminalCommand: "rm -rf '\(gitDb.path)'"
                ))
            }
        }

        // Rustup toolchains (non-active)
        let toolchains = URL.home.appendingPathComponent(".rustup/toolchains")
        if toolchains.existsOnDisk {
            let subdirs = try await scanner.subdirectories(at: toolchains)
            let activeToolchain = await getActiveToolchain()
            for dir in subdirs {
                if dir.lastPathComponent != activeToolchain {
                    let size = try await scanner.directorySizeIncludingHidden(at: dir)
                    if size > 10_000_000 {
                        items.append(CleanableItem(
                            path: dir,
                            displayName: "Rustup: \(dir.lastPathComponent)",
                            sizeInBytes: size,
                            safetyLevel: .caution,
                            explanation: "Inactive Rust toolchain. Re-install with 'rustup toolchain install \(dir.lastPathComponent)'.",
                            terminalCommand: "rustup toolchain uninstall \(dir.lastPathComponent)"
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

    private func getActiveToolchain() async -> String {
        let process = Process()
        let rustupPath = URL.home.appendingPathComponent(".cargo/bin/rustup").path
        guard FileManager.default.fileExists(atPath: rustupPath) else { return "" }
        process.executableURL = URL(fileURLWithPath: rustupPath)
        process.arguments = ["show", "active-toolchain"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.components(separatedBy: " ").first ?? ""
        } catch {
            return ""
        }
    }
}
