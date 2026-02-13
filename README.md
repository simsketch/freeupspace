# FreeUpSpace

Native macOS app that finds and cleans developer tool caches, build artifacts, and other reclaimable disk space. Built with SwiftUI + AppKit, targeting macOS 14 Sonoma and later.

Developers on macOS routinely lose 50–200+ GB to invisible caches: Docker.raw, Xcode DerivedData, node_modules, Homebrew downloads, VS Code service worker caches, and more. FreeUpSpace understands the entire developer toolchain and provides one-click, safety-classified cleanup.

## Features

- **12 developer tool scanners** — Docker, Xcode, Node.js, Homebrew, Python, Go, Rust/Cargo, VS Code, Git, System, Browsers, Gradle/Maven
- **Auto-detects your stack** — only shows categories relevant to tools you have installed
- **Safety-classified cleanup** — every item is tagged green (safe), yellow (caution), or red (danger) with plain-English explanations
- **Shows terminal commands** — power users see the exact `rm -rf` or `brew cleanup` equivalent for each item
- **Menu bar quick-clean** — clean safe items without opening the full app
- **System Data demystifier** — maps what's hiding in macOS's opaque "System Data" category
- **Disk info dashboard** — real-time capacity, used, and available space with visual gauge
- **Cleanup history** — tracks what was cleaned, when, and how much space was recovered
- **Move to Trash by default** — recoverable deletion; permanent delete available as opt-in

## Screenshots

*Coming soon*

## What It Scans

| Category | Key Paths | Typical Size |
|----------|-----------|-------------|
| Docker | `Docker.raw`, logs, caches | 20–100+ GB |
| Xcode | DerivedData, device support, simulators, archives, caches | 10–150+ GB |
| Node.js | npm cache, Yarn cache, pnpm store, stale node_modules | 5–50+ GB |
| Homebrew | Download cache, Cask cache, logs | 1–30+ GB |
| Python | pip cache, conda packages, \_\_pycache\_\_ | 1–20 GB |
| Go | Module cache, build cache | 0.5–10 GB |
| Rust/Cargo | Registry cache, git checkouts | 1–20 GB |
| VS Code | Cache, CachedData, CachedExtensionVSIXs, logs | 1–145+ GB |
| Git | Large `.git` directories | 1–10 GB |
| System | ~/Library/Caches, logs, crash reports | 1–10 GB |
| Browsers | Chrome/Safari/Firefox service worker & dev caches | 1–5 GB |
| Gradle/Maven | Gradle caches, Maven repository | 1–10 GB |

## Safety System

- **Safe (green)** — Pre-selected. Auto-regenerated caches. Zero data loss risk.
- **Caution (yellow)** — Not pre-selected. May require re-download or rebuild. Explanation shown.
- **Danger (red)** — Not pre-selected. Requires confirmation dialog. Could cause data loss.

## Requirements

- macOS 14 Sonoma or later
- Full Disk Access permission (the app will guide you through setup on first launch)

## Building

### With Xcode

Open `FreeUpSpace.xcodeproj` and build the FreeUpSpace scheme.

### With Command Line Tools Only

```bash
# Build packages
mkdir -p build

swiftc -swift-version 5 \
  -emit-library -emit-module \
  -module-name SharedUtilities \
  -o build/libSharedUtilities.dylib \
  -emit-module-path build/SharedUtilities.swiftmodule \
  Packages/SharedUtilities/Sources/SharedUtilities/*.swift \
  -Xlinker -install_name -Xlinker @rpath/libSharedUtilities.dylib

swiftc -swift-version 5 \
  -emit-library -emit-module \
  -module-name Permissions \
  -o build/libPermissions.dylib \
  -emit-module-path build/Permissions.swiftmodule \
  -I build -L build -lSharedUtilities \
  Packages/Permissions/Sources/Permissions/*.swift \
  -Xlinker -install_name -Xlinker @rpath/libPermissions.dylib

swiftc -swift-version 5 \
  -emit-library -emit-module \
  -module-name CleanupEngine \
  -o build/libCleanupEngine.dylib \
  -emit-module-path build/CleanupEngine.swiftmodule \
  -I build -L build -lSharedUtilities \
  Packages/CleanupEngine/Sources/CleanupEngine/**/*.swift \
  -Xlinker -install_name -Xlinker @rpath/libCleanupEngine.dylib

# Build app
swiftc -swift-version 5 -parse-as-library \
  -o build/FreeUpSpace \
  -I build -L build \
  -lSharedUtilities -lPermissions -lCleanupEngine \
  -framework SwiftUI -framework AppKit \
  -Xlinker -rpath -Xlinker @executable_path \
  FreeUpSpace/App/*.swift \
  FreeUpSpace/Views/**/*.swift
```

Then create the `.app` bundle:

```bash
APP="build/FreeUpSpace.app"
mkdir -p "$APP/Contents/MacOS"
cp build/FreeUpSpace "$APP/Contents/MacOS/"
cp build/lib*.dylib "$APP/Contents/MacOS/"
cp FreeUpSpace/Info.plist "$APP/Contents/"
echo "APPL????" > "$APP/Contents/PkgInfo"
codesign --force --deep --sign - "$APP"
open "$APP"
```

## Project Structure

```
FreeUpSpace/
├── FreeUpSpace/                    # Main app target
│   ├── App/                        # App entry point, state, delegate
│   ├── Views/
│   │   ├── MainWindow/             # Dashboard, sidebar, category detail, system data
│   │   ├── MenuBar/                # Quick-clean popover
│   │   ├── Onboarding/             # Welcome + permission setup
│   │   ├── Settings/               # Preferences
│   │   └── Components/             # Reusable UI components
│   └── Resources/                  # Assets
├── Packages/
│   ├── CleanupEngine/              # Core scanning + cleaning (no UI dependencies)
│   │   └── Sources/CleanupEngine/
│   │       ├── Cleaners/           # One file per dev tool (12 cleaners)
│   │       ├── Orchestrator/       # Concurrent scan coordinator
│   │       ├── FileSystem/         # Scanner + safe deleter
│   │       ├── Models/             # CleanableItem, CleanupCategory, SafetyLevel
│   │       ├── Detection/          # Stack detector
│   │       └── Protocols/          # Cleaner protocol
│   ├── Permissions/                # Full Disk Access detection
│   └── SharedUtilities/            # Byte formatting, URL extensions
└── Scripts/                        # Build + notarize helpers
```

## Architecture

- **CleanupEngine** — Swift package with no UI dependencies. Each dev tool gets a `Cleaner` implementation that scans the filesystem for reclaimable items. All scanning is filesystem-only (no subprocess calls) to avoid hanging on unresponsive tools.
- **CleanupOrchestrator** — Swift `actor` that runs all available cleaners concurrently via `TaskGroup` with a 15-second timeout per cleaner. Streams results to the UI via `AsyncStream<ScanEvent>`.
- **AppState** — `@Observable` class that bridges the engine to SwiftUI views.
- **UI** — SwiftUI views hosted in AppKit `NSWindow` via `NSHostingView`, with a `MenuBarExtra`-style status item popover.

## License

MIT
