import Foundation

public struct ByteFormatter {
    public static let shared = ByteFormatter()

    private let formatter: ByteCountFormatter

    public init() {
        formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
    }

    public func format(_ bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }

    /// Format with specific precision for display
    public func formatPrecise(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        }
        let kb = Double(bytes) / 1024
        if kb >= 1.0 {
            return String(format: "%.0f KB", kb)
        }
        return "\(bytes) bytes"
    }
}
