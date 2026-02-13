import Foundation

public protocol Cleaner: Sendable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }
    var stack: DeveloperStack { get }

    /// Check if the associated dev tool is installed on this machine
    func isAvailable() async -> Bool

    /// Scan for cleanable items. Returns a category with all found items.
    func scan() async throws -> CleanupCategory

    /// Clean the specified items. Returns total bytes freed.
    func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64
}

extension Cleaner {
    public func makeCategory(items: [CleanableItem]) -> CleanupCategory {
        CleanupCategory(
            id: id,
            stack: stack,
            displayName: displayName,
            iconName: iconName,
            items: items
        )
    }
}
