import Foundation
#if canImport(AppKit)
import AppKit
#endif

public actor SafeDeleter {
    private let fileManager = FileManager.default

    public init() {}

    /// Delete items using the specified method. Returns bytes freed.
    public func delete(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        var totalFreed: Int64 = 0

        for item in items {
            let effectiveMethod = item.deletionMethod == .dockerCommand || item.deletionMethod == .gitCommand
                ? item.deletionMethod
                : method

            switch effectiveMethod {
            case .moveToTrash:
                totalFreed += try await moveToTrash(item: item)
            case .permanentDelete:
                totalFreed += try permanentDelete(item: item)
            case .dockerCommand:
                totalFreed += try await runCommand(item: item)
            case .gitCommand:
                totalFreed += try await runCommand(item: item)
            }
        }

        return totalFreed
    }

    private func moveToTrash(item: CleanableItem) async throws -> Int64 {
        let size = item.sizeInBytes
        var resultURL: NSURL?
        try fileManager.trashItem(at: item.path, resultingItemURL: &resultURL)
        return size
    }

    private func permanentDelete(item: CleanableItem) throws -> Int64 {
        let size = item.sizeInBytes
        try fileManager.removeItem(at: item.path)
        return size
    }

    private func runCommand(item: CleanableItem) async throws -> Int64 {
        let size = item.sizeInBytes
        let command = item.terminalCommand

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CleanupError.commandFailed(command: command, output: output)
        }

        return size
    }
}

public enum CleanupError: LocalizedError {
    case commandFailed(command: String, output: String)
    case permissionDenied(path: String)
    case itemNotFound(path: String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let output):
            "Command failed: \(command)\n\(output)"
        case .permissionDenied(let path):
            "Permission denied: \(path)"
        case .itemNotFound(let path):
            "Item not found: \(path)"
        }
    }
}
