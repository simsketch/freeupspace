import Foundation

public struct GitCleaner: Cleaner {
    public let id = "git"
    public let displayName = "Git"
    public let iconName = "arrow.triangle.branch"
    public let stack = DeveloperStack.git

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        true
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // Only search dedicated dev directories (skip Documents/Desktop - too slow)
        let searchPaths = [
            URL.home.appendingPathComponent("Developer"),
            URL.home.appendingPathComponent("Projects"),
            URL.home.appendingPathComponent("repos"),
            URL.home.appendingPathComponent("code"),
            URL.home.appendingPathComponent("src"),
            URL.home.appendingPathComponent("workspace"),
        ]

        for searchPath in searchPaths {
            guard searchPath.existsOnDisk else { continue }
            // Only look 2 levels deep, max 20 repos per directory
            let gitDirs = await findLargeGitDirs(in: searchPath, minSize: 100_000_000, depth: 2, maxResults: 20)
            for (gitDir, size) in gitDirs {
                let repoName = gitDir.deletingLastPathComponent().lastPathComponent
                items.append(CleanableItem(
                    path: gitDir,
                    displayName: "\(repoName)/.git",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Large git repository. Running 'git gc' can reclaim space without losing data.",
                    terminalCommand: "cd '\(gitDir.deletingLastPathComponent().path)' && git gc --aggressive --prune=now",
                    deletionMethod: .gitCommand,
                    isSelected: false,
                    lastModified: await scanner.modificationDate(at: gitDir)
                ))
            }
        }

        return makeCategory(items: items)
    }

    public func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        let deleter = SafeDeleter()
        return try await deleter.delete(items: items, method: method)
    }

    private func findLargeGitDirs(in directory: URL, minSize: Int64, depth: Int, maxResults: Int) async -> [(URL, Int64)] {
        guard depth > 0 else { return [] }
        var results: [(URL, Int64)] = []

        let gitDir = directory.appendingPathComponent(".git")
        if gitDir.existsOnDisk {
            let size = (try? await scanner.directorySizeIncludingHidden(at: gitDir)) ?? 0
            if size >= minSize {
                results.append((gitDir, size))
            }
            return results
        }

        guard let subdirs = try? await scanner.subdirectories(at: directory) else { return [] }
        for subdir in subdirs.prefix(15) {
            guard results.count < maxResults else { break }
            let subResults = await findLargeGitDirs(in: subdir, minSize: minSize, depth: depth - 1, maxResults: maxResults - results.count)
            results.append(contentsOf: subResults)
        }

        return results
    }
}
