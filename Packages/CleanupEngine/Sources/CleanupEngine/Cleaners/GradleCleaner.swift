import Foundation

public struct GradleCleaner: Cleaner {
    public let id = "gradle"
    public let displayName = "Gradle / Maven"
    public let iconName = "building.columns.fill"
    public let stack = DeveloperStack.gradle

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        URL.home.appendingPathComponent(".gradle").existsOnDisk
            || URL.home.appendingPathComponent(".m2").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Gradle caches
        let gradleCaches = URL.home.appendingPathComponent(".gradle/caches")
        if gradleCaches.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: gradleCaches)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: gradleCaches,
                    displayName: "Gradle Caches",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded dependencies and build cache. Re-downloaded on next build.",
                    terminalCommand: "rm -rf '\(gradleCaches.path)'"
                ))
            }
        }

        // Gradle wrapper distributions
        let gradleWrapper = URL.home.appendingPathComponent(".gradle/wrapper/dists")
        if gradleWrapper.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: gradleWrapper)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: gradleWrapper,
                    displayName: "Gradle Wrapper Distributions",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Downloaded Gradle versions. Re-downloaded when running gradlew.",
                    terminalCommand: "rm -rf '\(gradleWrapper.path)'"
                ))
            }
        }

        // Gradle daemon logs
        let gradleDaemon = URL.home.appendingPathComponent(".gradle/daemon")
        if gradleDaemon.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: gradleDaemon)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: gradleDaemon,
                    displayName: "Gradle Daemon Logs",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Gradle build daemon logs and registry. Safe to remove.",
                    terminalCommand: "rm -rf '\(gradleDaemon.path)'"
                ))
            }
        }

        // Maven repository
        let mavenRepo = URL.home.appendingPathComponent(".m2/repository")
        if mavenRepo.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: mavenRepo)
            if size > 10_000_000 {
                items.append(CleanableItem(
                    path: mavenRepo,
                    displayName: "Maven Local Repository",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Cached Maven dependencies. Re-downloaded on next build.",
                    terminalCommand: "rm -rf '\(mavenRepo.path)'"
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
