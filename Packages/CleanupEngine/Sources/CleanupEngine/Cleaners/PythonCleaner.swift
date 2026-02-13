import Foundation

public struct PythonCleaner: Cleaner {
    public let id = "python"
    public let displayName = "Python"
    public let iconName = "chevron.left.forwardslash.chevron.right"
    public let stack = DeveloperStack.python

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/usr/local/bin/python3")
            || FileManager.default.fileExists(atPath: "/opt/homebrew/bin/python3")
            || URL.home.appendingPathComponent("Library/Caches/pip").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // pip cache
        let pipCache = URL.home.appendingPathComponent("Library/Caches/pip")
        if pipCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: pipCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: pipCache,
                    displayName: "pip Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded Python package wheels. Re-downloaded on next install.",
                    terminalCommand: "pip cache purge"
                ))
            }
        }

        // Conda packages cache
        let condaPkgs = URL.home.appendingPathComponent("miniconda3/pkgs")
        let condaPkgsAlt = URL.home.appendingPathComponent("anaconda3/pkgs")
        for condaPath in [condaPkgs, condaPkgsAlt] {
            if condaPath.existsOnDisk {
                let size = try await scanner.directorySizeIncludingHidden(at: condaPath)
                if size > 10_000_000 {
                    items.append(CleanableItem(
                        path: condaPath,
                        displayName: "Conda Package Cache (\(condaPath.deletingLastPathComponent().lastPathComponent))",
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Cached conda packages. Re-downloaded when creating new environments.",
                        terminalCommand: "conda clean --all -y"
                    ))
                }
            }
        }

        // Conda environments (not active)
        let condaEnvs = URL.home.appendingPathComponent("miniconda3/envs")
        let condaEnvsAlt = URL.home.appendingPathComponent("anaconda3/envs")
        for envsPath in [condaEnvs, condaEnvsAlt] {
            if envsPath.existsOnDisk {
                let subdirs = try await scanner.subdirectories(at: envsPath)
                for dir in subdirs {
                    let size = try await scanner.directorySizeIncludingHidden(at: dir)
                    if size > 10_000_000 {
                        items.append(CleanableItem(
                            path: dir,
                            displayName: "Conda env: \(dir.lastPathComponent)",
                            sizeInBytes: size,
                            safetyLevel: .caution,
                            explanation: "Conda virtual environment. Must be recreated if removed.",
                            terminalCommand: "conda env remove -n \(dir.lastPathComponent)"
                        ))
                    }
                }
            }
        }

        // pipx cache
        let pipxCache = URL.home.appendingPathComponent(".local/pipx/.cache")
        if pipxCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: pipxCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: pipxCache,
                    displayName: "pipx Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Cached pipx downloads. Re-downloaded as needed.",
                    terminalCommand: "rm -rf '\(pipxCache.path)'"
                ))
            }
        }

        // Poetry cache
        let poetryCache = URL.home.appendingPathComponent("Library/Caches/pypoetry")
        if poetryCache.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: poetryCache)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: poetryCache,
                    displayName: "Poetry Cache",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Poetry's package cache. Re-downloaded on next install.",
                    terminalCommand: "poetry cache clear --all ."
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
