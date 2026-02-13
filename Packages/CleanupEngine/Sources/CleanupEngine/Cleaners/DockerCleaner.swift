import Foundation

public struct DockerCleaner: Cleaner {
    public let id = "docker"
    public let displayName = "Docker"
    public let iconName = "shippingbox.fill"
    public let stack = DeveloperStack.docker

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        // Just check filesystem, don't call docker CLI
        URL.home.appendingPathComponent("Library/Containers/com.docker.docker").existsOnDisk
            || FileManager.default.fileExists(atPath: "/usr/local/bin/docker")
            || FileManager.default.fileExists(atPath: "/opt/homebrew/bin/docker")
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Docker.raw disk image - this is always the biggest item
        let dockerRawPaths = [
            URL.home.appendingPathComponent("Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"),
            URL.home.appendingPathComponent("Library/Containers/com.docker.docker/Data/docker.raw"),
        ]

        for rawPath in dockerRawPaths {
            if rawPath.existsOnDisk {
                let size = await scanner.fileSize(at: rawPath)
                if size > 0 {
                    items.append(CleanableItem(
                        path: rawPath,
                        displayName: "Docker Disk Image (Docker.raw)",
                        sizeInBytes: size,
                        safetyLevel: .danger,
                        explanation: "Docker's virtual disk. Run 'docker system prune -a' then restart Docker to shrink it.",
                        terminalCommand: "docker system prune -a --volumes",
                        deletionMethod: .dockerCommand
                    ))
                }
            }
        }

        // Docker data directory (covers build cache, images, volumes on disk)
        let dockerDataDir = URL.home.appendingPathComponent("Library/Containers/com.docker.docker/Data")
        if dockerDataDir.existsOnDisk {
            // Check for large subdirectories besides the raw image
            let logDir = dockerDataDir.appendingPathComponent("log")
            if logDir.existsOnDisk {
                let logSize = (try? await scanner.directorySizeIncludingHidden(at: logDir)) ?? 0
                if logSize > 10_000_000 {
                    items.append(CleanableItem(
                        path: logDir,
                        displayName: "Docker Logs",
                        sizeInBytes: logSize,
                        safetyLevel: .safe,
                        explanation: "Docker Desktop log files. Safe to remove.",
                        terminalCommand: "rm -rf '\(logDir.path)'"
                    ))
                }
            }
        }

        // Docker Desktop caches
        let dockerCache = URL.home.appendingPathComponent("Library/Caches/com.docker.docker")
        if dockerCache.existsOnDisk {
            let cacheSize = (try? await scanner.directorySizeIncludingHidden(at: dockerCache)) ?? 0
            if cacheSize > 1_000_000 {
                items.append(CleanableItem(
                    path: dockerCache,
                    displayName: "Docker Desktop Cache",
                    sizeInBytes: cacheSize,
                    safetyLevel: .safe,
                    explanation: "Docker Desktop application cache.",
                    terminalCommand: "rm -rf '\(dockerCache.path)'"
                ))
            }
        }

        // Add a helper item for docker system prune (no size, just actionable)
        if !items.isEmpty {
            items.append(CleanableItem(
                path: URL(fileURLWithPath: "/usr/local/bin/docker"),
                displayName: "Run Docker System Prune",
                sizeInBytes: 0,
                safetyLevel: .caution,
                explanation: "Removes all unused containers, networks, images, and optionally volumes. Run this to shrink Docker.raw.",
                terminalCommand: "docker system prune -a --volumes -f",
                deletionMethod: .dockerCommand,
                isSelected: false
            ))
        }

        return makeCategory(items: items)
    }

    public func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        let deleter = SafeDeleter()
        return try await deleter.delete(items: items, method: method)
    }
}
