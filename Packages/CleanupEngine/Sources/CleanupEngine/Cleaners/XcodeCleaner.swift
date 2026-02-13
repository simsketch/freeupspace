import Foundation

public struct XcodeCleaner: Cleaner {
    public let id = "xcode"
    public let displayName = "Xcode"
    public let iconName = "hammer.fill"
    public let stack = DeveloperStack.xcode

    private let scanner = FileSystemScanner()

    public init() {}

    public func isAvailable() async -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Xcode.app")
            || URL.home.appendingPathComponent("Library/Developer/Xcode").existsOnDisk
    }

    public func scan() async throws -> CleanupCategory {
        var items: [CleanableItem] = []

        // DerivedData
        let derivedData = URL.home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        if derivedData.existsOnDisk {
            let subdirs = try await scanner.subdirectories(at: derivedData)
            for dir in subdirs {
                let size = try await scanner.directorySizeIncludingHidden(at: dir)
                if size > 1_000_000 { // > 1MB
                    items.append(CleanableItem(
                        path: dir,
                        displayName: "DerivedData/\(dir.lastPathComponent)",
                        sizeInBytes: size,
                        safetyLevel: .safe,
                        explanation: "Build artifacts for a project. Xcode will rebuild on next open.",
                        terminalCommand: "rm -rf '\(dir.path)'",
                        lastModified: await scanner.modificationDate(at: dir)
                    ))
                }
            }
        }

        // iOS Device Support
        let deviceSupport = URL.home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
        if deviceSupport.existsOnDisk {
            let subdirs = try await scanner.subdirectories(at: deviceSupport)
            for dir in subdirs {
                let size = try await scanner.directorySizeIncludingHidden(at: dir)
                if size > 0 {
                    items.append(CleanableItem(
                        path: dir,
                        displayName: "iOS Device Support/\(dir.lastPathComponent)",
                        sizeInBytes: size,
                        safetyLevel: .caution,
                        explanation: "Debug symbols for iOS \(dir.lastPathComponent). Re-downloaded when connecting a device with this version.",
                        terminalCommand: "rm -rf '\(dir.path)'"
                    ))
                }
            }
        }

        // watchOS Device Support
        let watchDeviceSupport = URL.home.appendingPathComponent("Library/Developer/Xcode/watchOS DeviceSupport")
        if watchDeviceSupport.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: watchDeviceSupport)
            if size > 0 {
                items.append(CleanableItem(
                    path: watchDeviceSupport,
                    displayName: "watchOS Device Support",
                    sizeInBytes: size,
                    safetyLevel: .caution,
                    explanation: "Debug symbols for watchOS devices. Re-downloaded when connecting a watch.",
                    terminalCommand: "rm -rf '\(watchDeviceSupport.path)'"
                ))
            }
        }

        // Simulators (CoreSimulator caches)
        let coreSimulatorCaches = URL.home.appendingPathComponent("Library/Developer/CoreSimulator/Caches")
        if coreSimulatorCaches.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: coreSimulatorCaches)
            if size > 0 {
                items.append(CleanableItem(
                    path: coreSimulatorCaches,
                    displayName: "Simulator Caches",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Cached simulator runtime data. Regenerated automatically.",
                    terminalCommand: "rm -rf '\(coreSimulatorCaches.path)'"
                ))
            }
        }

        // Archives
        let archives = URL.home.appendingPathComponent("Library/Developer/Xcode/Archives")
        if archives.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: archives)
            if size > 0 {
                items.append(CleanableItem(
                    path: archives,
                    displayName: "Xcode Archives",
                    sizeInBytes: size,
                    safetyLevel: .danger,
                    explanation: "App Store submission archives. Cannot be regenerated without rebuilding.",
                    terminalCommand: "rm -rf '\(archives.path)'"
                ))
            }
        }

        // Xcode caches
        let xcodeCaches = URL.libraryCache("com.apple.dt.Xcode")
        if xcodeCaches.existsOnDisk {
            let size = try await scanner.directorySizeIncludingHidden(at: xcodeCaches)
            if size > 1_000_000 {
                items.append(CleanableItem(
                    path: xcodeCaches,
                    displayName: "Xcode Caches",
                    sizeInBytes: size,
                    safetyLevel: .safe,
                    explanation: "Xcode's internal caches. Regenerated automatically.",
                    terminalCommand: "rm -rf '\(xcodeCaches.path)'"
                ))
            }
        }

        return makeCategory(items: items)
    }

    public func clean(items: [CleanableItem], method: DeletionMethod) async throws -> Int64 {
        let deleter = SafeDeleter()
        return try await deleter.delete(items: items, method: method)
    }

}
