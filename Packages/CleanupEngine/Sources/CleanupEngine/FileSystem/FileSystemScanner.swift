import Foundation

public actor FileSystemScanner {
    private let fileManager = FileManager.default

    public init() {}

    /// Calculate total size of a directory recursively
    public func directorySize(at url: URL) async throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }

        var totalSize: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isRegularFileKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }

        return totalSize
    }

    /// Calculate total size including hidden files
    public func directorySizeIncludingHidden(at url: URL) async throws -> Int64 {
        guard fileManager.fileExists(atPath: url.path) else { return 0 }

        var totalSize: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isRegularFileKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }

        return totalSize
    }

    /// Get size of a single file
    public func fileSize(at url: URL) -> Int64 {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

    /// List immediate subdirectories
    public func subdirectories(at url: URL) throws -> [URL] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    /// Check if path exists
    public func exists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    /// Get modification date of a path
    public func modificationDate(at url: URL) -> Date? {
        try? fileManager.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    /// List contents of a directory with sizes
    public func contentsWithSizes(at url: URL) async throws -> [(url: URL, size: Int64, isDirectory: Bool)] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        )

        var results: [(url: URL, size: Int64, isDirectory: Bool)] = []
        for item in contents {
            let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
            let isDir = resourceValues.isDirectory ?? false
            let size: Int64
            if isDir {
                size = try await directorySizeIncludingHidden(at: item)
            } else {
                size = fileSize(at: item)
            }
            results.append((url: item, size: size, isDirectory: isDir))
        }

        return results
    }
}
