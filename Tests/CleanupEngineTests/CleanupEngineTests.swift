import XCTest
@testable import CleanupEngine

final class AppCleanupEngineTests: XCTestCase {
    func testAllCleanerStacks() {
        // Verify each cleaner has the correct stack assignment
        let cleaners: [any Cleaner] = [
            DockerCleaner(),
            XcodeCleaner(),
            NodeCleaner(),
            HomebrewCleaner(),
            PythonCleaner(),
            GoCleaner(),
            CargoCleaner(),
            VSCodeCleaner(),
            GitCleaner(),
            SystemCleaner(),
            BrowserDevCleaner(),
            GradleCleaner(),
        ]

        let expectedStacks: [DeveloperStack] = [
            .docker, .xcode, .node, .homebrew, .python,
            .go, .rust, .vscode, .git, .system, .browsers, .gradle,
        ]

        XCTAssertEqual(cleaners.count, 12, "Should have 12 cleaners")

        for (cleaner, expected) in zip(cleaners, expectedStacks) {
            XCTAssertEqual(cleaner.stack, expected, "\(cleaner.id) should map to \(expected)")
        }
    }
}
