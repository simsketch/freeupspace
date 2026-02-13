import Foundation

extension URL {
    public static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    public static func library(_ component: String = "") -> URL {
        home.appendingPathComponent("Library").appendingPathComponent(component)
    }

    public static func libraryCache(_ component: String = "") -> URL {
        library("Caches").appendingPathComponent(component)
    }

    public static func applicationSupport(_ component: String = "") -> URL {
        library("Application Support").appendingPathComponent(component)
    }

    public var existsOnDisk: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    public var isDirectoryOnDisk: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Get the display name (last path component without extension for files)
    public var displayName: String {
        lastPathComponent
    }
}
