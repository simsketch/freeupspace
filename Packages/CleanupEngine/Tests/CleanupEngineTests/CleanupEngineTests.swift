import XCTest
@testable import CleanupEngine

final class CleanupEngineTests: XCTestCase {

    // MARK: - Model Tests

    func testCleanableItemDefaultSelection() {
        let safeItem = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/test"),
            displayName: "Test Safe",
            sizeInBytes: 1024,
            safetyLevel: .safe,
            explanation: "Test",
            terminalCommand: "rm -rf /tmp/test"
        )
        XCTAssertTrue(safeItem.isSelected, "Safe items should be selected by default")

        let cautionItem = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/test2"),
            displayName: "Test Caution",
            sizeInBytes: 2048,
            safetyLevel: .caution,
            explanation: "Test",
            terminalCommand: "rm -rf /tmp/test2"
        )
        XCTAssertFalse(cautionItem.isSelected, "Caution items should not be selected by default")

        let dangerItem = CleanableItem(
            path: URL(fileURLWithPath: "/tmp/test3"),
            displayName: "Test Danger",
            sizeInBytes: 4096,
            safetyLevel: .danger,
            explanation: "Test",
            terminalCommand: "rm -rf /tmp/test3"
        )
        XCTAssertFalse(dangerItem.isSelected, "Danger items should not be selected by default")
    }

    func testCleanupCategoryTotalSize() {
        let items = [
            CleanableItem(
                path: URL(fileURLWithPath: "/a"),
                displayName: "A",
                sizeInBytes: 100,
                safetyLevel: .safe,
                explanation: "",
                terminalCommand: ""
            ),
            CleanableItem(
                path: URL(fileURLWithPath: "/b"),
                displayName: "B",
                sizeInBytes: 200,
                safetyLevel: .caution,
                explanation: "",
                terminalCommand: ""
            ),
            CleanableItem(
                path: URL(fileURLWithPath: "/c"),
                displayName: "C",
                sizeInBytes: 300,
                safetyLevel: .danger,
                explanation: "",
                terminalCommand: ""
            ),
        ]

        let category = CleanupCategory(
            id: "test",
            stack: .system,
            displayName: "Test",
            iconName: "folder",
            items: items
        )

        XCTAssertEqual(category.totalSize, 600)
        XCTAssertEqual(category.selectedSize, 100, "Only safe items should be selected")
        XCTAssertEqual(category.safeSize, 100)
        XCTAssertEqual(category.itemCount, 3)
        XCTAssertEqual(category.selectedCount, 1)
    }

    func testSafetyLevelProperties() {
        XCTAssertEqual(SafetyLevel.safe.displayName, "Safe")
        XCTAssertEqual(SafetyLevel.caution.displayName, "Caution")
        XCTAssertEqual(SafetyLevel.danger.displayName, "Danger")

        XCTAssertTrue(SafetyLevel.safe.sortOrder < SafetyLevel.caution.sortOrder)
        XCTAssertTrue(SafetyLevel.caution.sortOrder < SafetyLevel.danger.sortOrder)
    }

    func testDeveloperStackProperties() {
        for stack in DeveloperStack.allCases {
            XCTAssertFalse(stack.displayName.isEmpty, "\(stack) should have a display name")
            XCTAssertFalse(stack.iconName.isEmpty, "\(stack) should have an icon name")
        }
    }

    // MARK: - Safety Classifier Tests

    func testSafetyClassifierSafePaths() {
        let classifier = SafetyClassifier()

        let safePaths = [
            "/Users/test/Library/Caches/something",
            "/Users/test/.npm/_cacache/data",
            "/Users/test/Library/Developer/Xcode/DerivedData/project",
            "/Users/test/Library/Logs/something",
            "/Users/test/__pycache__/module.pyc",
        ]

        for path in safePaths {
            let level = classifier.classify(
                path: URL(fileURLWithPath: path),
                stack: .system
            )
            XCTAssertEqual(level, .safe, "Path \(path) should be classified as safe")
        }
    }

    func testSafetyClassifierCautionPaths() {
        let classifier = SafetyClassifier()

        let cautionPaths = [
            "/Users/test/project/node_modules/package",
            "/Users/test/.conda/envs/myenv",
        ]

        for path in cautionPaths {
            let level = classifier.classify(
                path: URL(fileURLWithPath: path),
                stack: .node
            )
            XCTAssertEqual(level, .caution, "Path \(path) should be classified as caution")
        }
    }

    // MARK: - Stack Detector Tests

    func testStackDetectorDetectsSystem() async {
        let detector = StackDetector()
        let isSystem = await detector.isInstalled(.system)
        XCTAssertTrue(isSystem, "System stack should always be available")
    }

    func testStackDetectorDetectsBrowsers() async {
        let detector = StackDetector()
        let hasBrowsers = await detector.isInstalled(.browsers)
        XCTAssertTrue(hasBrowsers, "Browsers should always be available (Safari is built-in)")
    }

    func testStackDetectorDetectsGit() async {
        let detector = StackDetector()
        let hasGit = await detector.isInstalled(.git)
        // Git is typically available on macOS
        XCTAssertTrue(hasGit, "Git should typically be available on macOS")
    }

    // MARK: - File System Scanner Tests

    func testFileScannerExistsCheck() async {
        let scanner = FileSystemScanner()
        let homeExists = await scanner.exists(at: FileManager.default.homeDirectoryForCurrentUser)
        XCTAssertTrue(homeExists, "Home directory should exist")

        let fakeExists = await scanner.exists(at: URL(fileURLWithPath: "/nonexistent/path"))
        XCTAssertFalse(fakeExists, "Non-existent path should not exist")
    }

    func testFileScannerDirectorySize() async throws {
        let scanner = FileSystemScanner()
        // Create a temp directory with a known file
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let testFile = tempDir.appendingPathComponent("test.txt")
        try "Hello, World!".write(to: testFile, atomically: true, encoding: .utf8)

        let size = try await scanner.directorySize(at: tempDir)
        XCTAssertGreaterThan(size, 0, "Directory with a file should have non-zero size")

        // Cleanup
        try FileManager.default.removeItem(at: tempDir)
    }

    func testFileScannerEmptyDirectorySize() async throws {
        let scanner = FileSystemScanner()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let size = try await scanner.directorySize(at: tempDir)
        XCTAssertEqual(size, 0, "Empty directory should have zero size")

        try FileManager.default.removeItem(at: tempDir)
    }

    func testFileScannerNonExistentDirectory() async throws {
        let scanner = FileSystemScanner()
        let size = try await scanner.directorySize(at: URL(fileURLWithPath: "/nonexistent"))
        XCTAssertEqual(size, 0, "Non-existent directory should return zero size")
    }

    // MARK: - Orchestrator Tests

    func testOrchestratorScanStreamEvents() async {
        let orchestrator = CleanupOrchestrator()
        let stream = await orchestrator.scan()

        var receivedStarted = false
        var receivedCompleted = false

        for await event in stream {
            switch event {
            case .started:
                receivedStarted = true
            case .completed:
                receivedCompleted = true
            default:
                break
            }
        }

        XCTAssertTrue(receivedStarted, "Should receive started event")
        XCTAssertTrue(receivedCompleted, "Should receive completed event")
    }

    // MARK: - Cleaner Availability Tests

    func testSystemCleanerAlwaysAvailable() async {
        let cleaner = SystemCleaner()
        let available = await cleaner.isAvailable()
        XCTAssertTrue(available, "System cleaner should always be available")
    }

    func testCleanerProtocolDefaults() async throws {
        let cleaner = SystemCleaner()
        XCTAssertEqual(cleaner.id, "system")
        XCTAssertEqual(cleaner.displayName, "System")
        XCTAssertEqual(cleaner.stack, .system)
        XCTAssertFalse(cleaner.iconName.isEmpty)
    }
}
