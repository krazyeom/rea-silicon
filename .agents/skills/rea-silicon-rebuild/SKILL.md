---
name: rea-silicon-rebuild
description: >-
  Reverse-engineers any target binary, bundle, or macOS application (.app) and rebuilds it into a clean, modern Apple Silicon (macOS arm64) native application using Swift 6, SwiftUI, or AppKit. Activates when given an application path, binary location, or reverse-engineering request.
---

# REA Apple Silicon Native Rebuild Skill

This skill guides the agent through inspecting an application or binary at a given path, profiling its technology stack, creating a clean-room specification (`SPEC.md`), and rebuilding it into native macOS Apple Silicon (`arm64`) code using Swift 6 / SwiftUI.

---

## Trigger & Input
When the user provides:
- A path to an application bundle (e.g., `/Applications/LegacyApp.app`, `./target/Sample.app`)
- A path to an executable binary (e.g., `./bin/core_daemon`, `/usr/local/bin/legacy_cli`)
- A prompt requesting reverse engineering and native rebuild

---

## Execution Protocol

Follow these exact steps:

### Step 1: Read Workspace Rules and Guides
Before executing changes or answering, consult:
- `docs/en/WORKFLOW_AND_RULES.md` / `docs/kr/WORKFLOW_AND_RULES.md`
- `docs/en/MAC_SILICON_REBUILD_GUIDE.md` / `docs/kr/MAC_SILICON_REBUILD_GUIDE.md`
- `docs/en/SPEC_TEMPLATE.md` / `docs/kr/SPEC_TEMPLATE.md`

### Step 2: Run Target Inspection
Execute the bundled inspector script:
```bash
./scripts/inspect_target.sh "<TARGET_PATH>"
```
Analyze the output:
1. Classification (`.app` bundle vs standalone binary).
2. Architecture (`arm64`, `x86_64`, Fat binary).
3. Technology stack signatures (Electron ASAR, Qt, .NET, Go, Python, Swift, Objective-C).
4. Linked dynamic libraries and frameworks (`otool -L`).

### Step 3: Room A – Generate Black-Box Specification (`SPEC.md`) & Identity
1. Devise a witty, humorous homage name for the app (NEVER reuse the exact original trademarked name).
2. Establish a distinctive theme (primary & secondary hex colors, and signature symbol/emoji).
3. Dissect key entrypoints, protocols, data models, and algorithms without copying decompiled code.
4. Fill in `SPEC.md` using [`SPEC_TEMPLATE.md`](../../docs/en/SPEC_TEMPLATE.md).

### Step 4: Room B – Rebuild for Apple Silicon Native & Generate Icon
1. Generate native macOS Big Sur+ squircle AppIcon:
   ```bash
   ./scripts/generate_app_icon.swift "<WittyAppName>" ./Resources "<SymbolEmoji>" "#Hex1" "#Hex2"
   ```
2. Target: `arm64-apple-macosx14.0+` using Swift 6.
3. Select archetype:
   - CLI Tool: `swift-argument-parser`
   - GUI Application: `SwiftUI` + `AppKit` (embed `AppIcon.icns` in bundle)
   - Status Bar Utility: `MenuBarExtra`
4. Structure code in a clean Swift Package Manager project (`Package.swift`, `Sources/`, `Tests/`).

### Step 5: Compile & Ad-Hoc Code Sign
```bash
arch -arm64 swift build -c release --triple arm64-apple-macosx14.0
codesign --force --deep --sign - .build/arm64-apple-macosx/release/<BINARY_NAME>
```

### Step 6: Verify with Test Oracle
Run test oracle to ensure input/output equivalence:
```bash
./scripts/verify_build.sh <PROJECT_DIR>
python3 ./scripts/test_oracle.py --original "<TARGET_PATH>" --rebuilt "<REBUILT_PATH>" --args <SAMPLE_ARGS>
```

### Step 7: Package into Drag-and-Drop `.dmg` Installer
Package the rebuilt app or Swift project into a compressed `.dmg` installer equipped with an `/Applications` symlink for seamless installation:
```bash
./scripts/create_dmg.sh <PROJECT_OR_APP_PATH> [OUTPUT_DMG]
# Example: ./scripts/create_dmg.sh ./build/Calcuroo.app ./dist/Calcuroo-arm64.dmg
```
