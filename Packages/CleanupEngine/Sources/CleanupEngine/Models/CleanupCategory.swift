import Foundation

public enum DeveloperStack: String, Sendable, Codable, CaseIterable {
    case docker
    case xcode
    case node
    case homebrew
    case python
    case go
    case rust
    case vscode
    case git
    case system
    case browsers
    case gradle

    public var displayName: String {
        switch self {
        case .docker: "Docker"
        case .xcode: "Xcode"
        case .node: "Node.js"
        case .homebrew: "Homebrew"
        case .python: "Python"
        case .go: "Go"
        case .rust: "Rust / Cargo"
        case .vscode: "VS Code"
        case .git: "Git"
        case .system: "System"
        case .browsers: "Browsers"
        case .gradle: "Gradle / Maven"
        }
    }

    public var iconName: String {
        switch self {
        case .docker: "shippingbox.fill"
        case .xcode: "hammer.fill"
        case .node: "cube.fill"
        case .homebrew: "mug.fill"
        case .python: "chevron.left.forwardslash.chevron.right"
        case .go: "hare.fill"
        case .rust: "gearshape.2.fill"
        case .vscode: "curlybraces"
        case .git: "arrow.triangle.branch"
        case .system: "desktopcomputer"
        case .browsers: "globe"
        case .gradle: "building.columns.fill"
        }
    }
}

public struct CleanupCategory: Identifiable, Sendable {
    public let id: String
    public let stack: DeveloperStack
    public let displayName: String
    public let iconName: String
    public var items: [CleanableItem]

    public var totalSize: Int64 {
        items.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var selectedSize: Int64 {
        items.filter(\.isSelected).reduce(0) { $0 + $1.sizeInBytes }
    }

    public var safeSize: Int64 {
        items.filter { $0.safetyLevel == .safe }.reduce(0) { $0 + $1.sizeInBytes }
    }

    public var itemCount: Int { items.count }
    public var selectedCount: Int { items.filter(\.isSelected).count }

    public init(
        id: String,
        stack: DeveloperStack,
        displayName: String,
        iconName: String,
        items: [CleanableItem]
    ) {
        self.id = id
        self.stack = stack
        self.displayName = displayName
        self.iconName = iconName
        self.items = items
    }
}
