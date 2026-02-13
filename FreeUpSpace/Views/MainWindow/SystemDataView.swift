import SwiftUI
import CleanupEngine
import SharedUtilities

struct SystemDataView: View {
    @State private var libraryContents: [LibraryItem] = []
    @State private var isLoading = true
    @State private var totalLibrarySize: Int64 = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "internaldrive.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.purple)

                Text("System Data Demystifier")
                    .font(.title2.weight(.semibold))

                Text("macOS shows a large \"System Data\" category in storage settings.\nHere's what's actually taking up that space in ~/Library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !isLoading {
                    Text("Total: \(ByteFormatter.shared.formatPrecise(totalLibrarySize))")
                        .font(.title3.weight(.medium))
                        .monospacedDigit()
                }
            }
            .padding()

            Divider()

            if isLoading {
                VStack {
                    ProgressView("Analyzing ~/Library...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(libraryContents) { item in
                    HStack {
                        Image(systemName: item.icon)
                            .frame(width: 24)
                            .foregroundStyle(item.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.body.weight(.medium))
                            Text(item.explanation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        SizeLabel(bytes: item.size)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .task {
            await analyzeLibrary()
        }
    }

    private func analyzeLibrary() async {
        isLoading = true
        let scanner = FileSystemScanner()
        let libraryURL = URL.home.appendingPathComponent("Library")

        do {
            let contents = try await scanner.contentsWithSizes(at: libraryURL)
            var items: [LibraryItem] = []
            var total: Int64 = 0

            for (url, size, _) in contents where size > 10_000_000 { // > 10MB
                total += size
                let name = url.lastPathComponent
                let (displayName, explanation, icon, color) = categorizeLibraryDir(name)

                items.append(LibraryItem(
                    path: url,
                    displayName: displayName,
                    explanation: explanation,
                    size: size,
                    icon: icon,
                    color: color
                ))
            }

            libraryContents = items.sorted { $0.size > $1.size }
            totalLibrarySize = total
        } catch {
            libraryContents = []
        }

        isLoading = false
    }

    private func categorizeLibraryDir(_ name: String) -> (String, String, String, Color) {
        switch name {
        case "Developer":
            return ("Developer Tools", "Xcode, simulators, device support, derived data", "hammer.fill", .cyan)
        case "Caches":
            return ("Caches", "Application and system caches (usually safe to clear)", "archivebox.fill", .orange)
        case "Application Support":
            return ("Application Data", "App data, configs, and databases", "app.badge.fill", .blue)
        case "Containers":
            return ("Sandboxed App Data", "Data for Mac App Store and sandboxed apps (includes Docker)", "shippingbox.fill", .indigo)
        case "Group Containers":
            return ("Shared App Data", "Data shared between apps from the same developer", "person.2.fill", .teal)
        case "Mail":
            return ("Mail", "Email messages, attachments, and databases", "envelope.fill", .blue)
        case "Messages":
            return ("Messages", "iMessage history and attachments", "message.fill", .green)
        case "Photos":
            return ("Photos Library", "Photos database and thumbnails", "photo.fill", .pink)
        case "Mobile Documents":
            return ("iCloud Drive", "Locally cached iCloud files", "icloud.fill", .blue)
        case "Logs":
            return ("Logs", "Application and system logs", "doc.text.fill", .gray)
        case "Preferences":
            return ("Preferences", "App preferences and settings", "gearshape.fill", .gray)
        case "Saved Application State":
            return ("Saved App State", "Window positions and restoration data", "window.ceiling", .purple)
        case "WebKit":
            return ("WebKit Data", "Safari and web view caches", "globe", .mint)
        default:
            return (name, "Library/\(name)", "folder.fill", .secondary)
        }
    }
}

struct LibraryItem: Identifiable {
    let id = UUID()
    let path: URL
    let displayName: String
    let explanation: String
    let size: Int64
    let icon: String
    let color: Color
}
