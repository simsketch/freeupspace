import Foundation
import AppKit

@Observable
public final class PermissionManager: @unchecked Sendable {
    public private(set) var hasFullDiskAccess: Bool = false

    public init() {
        checkFullDiskAccess()
    }

    /// Check if the app has Full Disk Access
    @discardableResult
    public func checkFullDiskAccess() -> Bool {
        // Try to read a known FDA-protected path
        let testPaths = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Mail"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Safari/Bookmarks.plist"),
        ]

        for testPath in testPaths {
            if FileManager.default.fileExists(atPath: testPath.path) {
                let readable = FileManager.default.isReadableFile(atPath: testPath.path)
                hasFullDiskAccess = readable
                return readable
            }
        }

        // If test paths don't exist, assume we have access
        // (e.g., Mail/Safari not used)
        hasFullDiskAccess = true
        return true
    }

    /// Open System Settings to the Full Disk Access pane
    public func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open System Settings to the Login Items pane
    public func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
