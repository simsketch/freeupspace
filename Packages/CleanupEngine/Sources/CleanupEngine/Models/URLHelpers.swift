import Foundation

extension URL {
    static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static func library(_ component: String = "") -> URL {
        home.appendingPathComponent("Library").appendingPathComponent(component)
    }

    static func libraryCache(_ component: String = "") -> URL {
        library("Caches").appendingPathComponent(component)
    }

    static func applicationSupport(_ component: String = "") -> URL {
        library("Application Support").appendingPathComponent(component)
    }

    var existsOnDisk: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    var isDirectoryOnDisk: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
