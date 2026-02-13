import Foundation

public enum SafetyLevel: String, Sendable, Codable, CaseIterable {
    case safe
    case caution
    case danger

    public var displayName: String {
        switch self {
        case .safe: "Safe"
        case .caution: "Caution"
        case .danger: "Danger"
        }
    }

    public var explanation: String {
        switch self {
        case .safe:
            "Auto-regenerated cache. Zero risk of data loss."
        case .caution:
            "May require re-download or rebuild after deletion."
        case .danger:
            "Could cause data loss. Review carefully before deleting."
        }
    }

    public var iconName: String {
        switch self {
        case .safe: "checkmark.shield.fill"
        case .caution: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .safe: 0
        case .caution: 1
        case .danger: 2
        }
    }
}
