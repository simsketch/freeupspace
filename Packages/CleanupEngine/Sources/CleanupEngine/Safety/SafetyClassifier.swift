import Foundation

public struct SafetyClassifier: Sendable {
    public init() {}

    /// Classify a path's safety level based on known patterns
    public func classify(path: URL, stack: DeveloperStack) -> SafetyLevel {
        let pathString = path.path.lowercased()

        // Known safe patterns (auto-regenerated caches)
        let safePatterns = [
            "/caches/", "/cache/", "/_cacache/", "/cacheddata/",
            "/cachedextensionvsixs/", "/logs/", "/log/",
            "/deriveddata/", "/downloads/", "/tmp/",
            "/crash reports/", "/crashreporter/",
            "/__pycache__/", ".pyc",
            "/pkg/mod/cache/", "/go-build/",
            "/registry/cache/", "/registry/src/",
        ]

        let cautionPatterns = [
            "/node_modules/", "/archives/",
            "/virtualenvs/", "/envs/", "/venv/",
            "/git/db/", "/git/checkouts/",
            "/simulators/", "/device support/",
        ]

        let dangerPatterns = [
            "/archives/", "/xcuserdata/",
        ]

        for pattern in dangerPatterns {
            if pathString.contains(pattern) && stack == .xcode {
                return .danger
            }
        }

        for pattern in cautionPatterns {
            if pathString.contains(pattern) {
                return .caution
            }
        }

        for pattern in safePatterns {
            if pathString.contains(pattern) {
                return .safe
            }
        }

        return .caution // Default to caution for unknown paths
    }
}
