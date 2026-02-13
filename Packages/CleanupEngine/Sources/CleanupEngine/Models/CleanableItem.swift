import Foundation

public enum DeletionMethod: String, Sendable, Codable {
    case moveToTrash
    case permanentDelete
    case dockerCommand  // Uses docker CLI
    case gitCommand     // Uses git CLI
}

public struct CleanableItem: Identifiable, Sendable {
    public let id: UUID
    public let path: URL
    public let displayName: String
    public let sizeInBytes: Int64
    public let safetyLevel: SafetyLevel
    public let explanation: String
    public let terminalCommand: String
    public let deletionMethod: DeletionMethod
    public var isSelected: Bool
    public let lastModified: Date?

    public init(
        id: UUID = UUID(),
        path: URL,
        displayName: String,
        sizeInBytes: Int64,
        safetyLevel: SafetyLevel,
        explanation: String,
        terminalCommand: String,
        deletionMethod: DeletionMethod = .moveToTrash,
        isSelected: Bool? = nil,
        lastModified: Date? = nil
    ) {
        self.id = id
        self.path = path
        self.displayName = displayName
        self.sizeInBytes = sizeInBytes
        self.safetyLevel = safetyLevel
        self.explanation = explanation
        self.terminalCommand = terminalCommand
        self.deletionMethod = deletionMethod
        self.isSelected = isSelected ?? (safetyLevel == .safe)
        self.lastModified = lastModified
    }
}
