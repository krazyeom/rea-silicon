# Apple Silicon (macOS arm64) Native Architecture & Rebuild Guide

This guide establishes the technical blueprint for analyzing any legacy or foreign-platform binary/bundle and reconstructing it into a **high-performance, native macOS Apple Silicon (`arm64`)** application using modern **Swift 6, SwiftUI, and AppKit**.

---

## 1. Objectives & Architectural Principles

When reverse engineering an application to rebuild it for macOS Apple Silicon:

1. **Zero Emulation Overhead**: Eliminate Rosetta 2 translation latency and high memory footprint by producing pure `arm64` (or universal Mach-O `arm64` + `x86_64`) native binaries.
2. **Native UX & Energy Efficiency**: Replace heavy cross-platform runtimes (e.g., Electron, Chromium, Python PyInstaller, JVM) with lightweight, power-efficient native macOS UI components (`SwiftUI`, `AppKit`, `MenuBarExtra`).
3. **Modern Swift Concurrency**: Leverage Swift 6 strict concurrency (`Sendable`, `actor`, `async/await`, structured concurrency) rather than legacy thread locks or event-loop wrappers.
4. **Clean-Room Integrity**: Reconstruct strictly from extracted behavioral specifications (`SPEC.md`), without copying decompiled intellectual property.

---

## 2. Technology Stack Migration Matrix

| Source Stack in Target App | Primary Drawbacks | Modern macOS Silicon Target | Apple Silicon Advantages |
| :--- | :--- | :--- | :--- |
| **Electron / Webpack** (.asar, Node.js) | High RAM consumption (300MB+ idle), slow start, battery drain | **SwiftUI + Swift Concurrency** (Optionally `WKWebView` for web views) | Sub-10MB RAM footprint, instant launch, native dark mode, Keychain integration |
| **Qt / wxWidgets (C++)** | Bulky dynamic libraries, non-standard window frame, high binary size | **SwiftUI + AppKit** | Deep macOS window styling, Liquid Retina / ProMotion support |
| **Python (PyInstaller / py2app)** | Bundled Python runtime, slow startup, dynamic typing risks | **Swift 6 Native CLI / App** | Ahead-Of-Time (AOT) compiled native machine code, compile-time type safety |
| **Go / Rust CLI** | Static Go runtime overhead, non-Apple ecosystem tools | **Swift 6 CLI (`swift-argument-parser`)** | Direct integration with macOS APIs (Security, Network, SystemConfiguration) |
| **.NET / C# (Mono/CoreCLR)** | Bulky JIT runtime, GC pauses | **Swift 6 + SwiftData / Codable** | Automatic Reference Counting (ARC), zero GC stutter, unified memory speed |

---

## 3. Reverse Engineering & Binary Inspection on macOS

### 3.1 Quick Inspection Tool
Use the repository inspection script:
```bash
./scripts/inspect_target.sh /path/to/target_or_app
```

### 3.2 Key macOS CLI Inspection Commands

| Command | Purpose |
| :--- | :--- |
| `lipo -info <binary>` | Check Mach-O architectures (x86_64, arm64, arm64e) |
| `otool -L <binary>` | Inspect linked dynamic libraries and macOS frameworks |
| `codesign -dv --verbose=4 <binary>` | Inspect code signature, team ID, and entitlements |
| `nm -gU <binary>` | Dump exported global symbols |
| `strings -a <binary> \| grep -E "pattern"` | Extract API endpoints, encryption identifiers, magic headers |
| `plutil -p Info.plist` | Inspect macOS App Bundle configuration |

---

## 4. Native Apple Silicon Project Archetypes

### Archetype A: Native High-Performance CLI Tool
For backend tools, deamon utilities, or converters:
```text
my-cli-tool/
├── Package.swift
└── Sources/
    └── main.swift (or CLI entrypoint with ArgumentParser)
```
**`Package.swift` Example:**
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyCliTool",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyCliTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
```

### Archetype B: Modern SwiftUI Native macOS App
For desktop applications with UI:
```swift
import SwiftUI

@main
struct RebuiltApp: App {
    @StateObject private var appState = AppStateModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
```

### Archetype C: Menu Bar Extra / Background Daemon
For lightweight utility apps living in the macOS status bar:
```swift
import SwiftUI

@main
struct MenuBarUtilityApp: App {
    var body: some Scene {
        MenuBarExtra("StatusTool", systemImage: "cpu.fill") {
            Button("Action 1") { executeAction() }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
```

---

## 5. Building & Signing for Apple Silicon

### 5.1 Native Compilation
```bash
# Compile via Swift Package Manager
arch -arm64 swift build -c release --triple arm64-apple-macosx14.0

# Compile single file
arch -arm64 swiftc -O -target arm64-apple-macosx14.0 main.swift -o my_tool_arm64
```

### 5.2 Ad-hoc Code Signing (Required on Apple Silicon)
Apple Silicon kernels enforce valid code signatures on all arm64 binaries before execution:
```bash
codesign --force --deep --sign - ./build/my_tool_arm64
```

### 5.3 Automated Verification
Run the verification script:
```bash
./scripts/verify_build.sh <directory_with_package_or_source>

# Verify and generate installer DMG in one step:
./scripts/verify_build.sh <directory_with_package_or_source> --dmg
```

---

## 6. Drag-and-Drop DMG Installer Creation (Easy /Applications Install)

Package the completed macOS app bundle (`.app`) into a polished, compressed `.dmg` disk image equipped with an `/Applications` drag-and-drop symlink.

### 6.1 Creating the DMG
```bash
# 1. From an existing .app bundle:
./scripts/create_dmg.sh ./build/Calcuroo.app

# 2. Directly from a Swift Package directory:
./scripts/create_dmg.sh ./projects/Calcuroo

# 3. Custom output and icon:
./scripts/create_dmg.sh ./build/Calcuroo.app ./dist/Calcuroo-1.0.0-arm64.dmg --icon ./Resources/AppIcon.icns
```

### 6.2 Packaging Pipeline Details
1. **App Bundle Structuring**: Assembles `Contents/MacOS`, `Contents/Resources`, `Info.plist`, and `PkgInfo`.
2. **Apple Silicon Ad-hoc Signing**: Signs the bundle using `codesign` to pass macOS kernel integrity checks.
3. **`/Applications` Drag Link**: Symlinks `/Applications` inside the DMG root for native drag-and-drop installation.
4. **Volume Custom Icon**: Applies `AppIcon.icns` as the mounted DMG volume icon when present.
5. **UDZO Compression & Verification**: Employs `hdiutil` for compressed read-only packaging and verifies checksum.
