import Foundation

public struct StackDetector: Sendable {
    private static let fileManager = FileManager.default
    private static let home = FileManager.default.homeDirectoryForCurrentUser

    public init() {}

    /// Detect which developer stacks are installed on this machine
    public func detectInstalledStacks() async -> Set<DeveloperStack> {
        var installed = Set<DeveloperStack>()

        await withTaskGroup(of: (DeveloperStack, Bool).self) { group in
            for stack in DeveloperStack.allCases {
                group.addTask {
                    let available = await self.isInstalled(stack)
                    return (stack, available)
                }
            }

            for await (stack, available) in group {
                if available {
                    installed.insert(stack)
                }
            }
        }

        return installed
    }

    public func isInstalled(_ stack: DeveloperStack) async -> Bool {
        switch stack {
        case .docker:
            return commandExists("docker") || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent("Library/Containers/com.docker.docker").path)
        case .xcode:
            return commandExists("xcodebuild") || Self.fileManager.fileExists(atPath: "/Applications/Xcode.app")
        case .node:
            return commandExists("node") || commandExists("npm") || commandExists("pnpm") || commandExists("yarn")
        case .homebrew:
            return commandExists("brew")
        case .python:
            return commandExists("python3") || commandExists("pip3") || commandExists("conda")
        case .go:
            return commandExists("go") || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent("go").path)
        case .rust:
            return commandExists("cargo") || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent(".cargo").path)
        case .vscode:
            return Self.fileManager.fileExists(atPath: "/Applications/Visual Studio Code.app")
                || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent("Library/Application Support/Code").path)
        case .git:
            return commandExists("git")
        case .system:
            return true // Always available
        case .browsers:
            return Self.fileManager.fileExists(atPath: "/Applications/Google Chrome.app")
                || Self.fileManager.fileExists(atPath: "/Applications/Firefox.app")
                || true // Safari is always present
        case .gradle:
            return commandExists("gradle") || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent(".gradle").path)
                || commandExists("mvn") || Self.fileManager.fileExists(atPath: Self.home.appendingPathComponent(".m2").path)
        }
    }

    private func commandExists(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
