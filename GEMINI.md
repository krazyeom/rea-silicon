# Gemini Workspace Rules: REA-Silicon Apple Silicon Rebuild

Please refer to and follow the operating rules defined in `AGENTS.md` and the detailed technical guides in `docs/en/` and `docs/kr/`.

- Target inspection tool: `./scripts/inspect_target.sh`
- Icon generator: `./scripts/generate_app_icon.swift`
- DMG Background generator: `./scripts/generate_dmg_background.swift`
- Verification tool: `./scripts/verify_build.sh`
- Test oracle: `./scripts/test_oracle.py`
- Project-Themed Drag-and-Drop DMG packager: `./scripts/create_dmg.sh`
- Primary target: macOS Apple Silicon (`arm64-apple-macosx`) using Swift 6 & SwiftUI
- Creative Rules: Never use exact original app name (use witty homage name), always generate distinctive app icon & visual branding, and package project-tailored DMGs adhering to `docs/kr/PROJECT_DMG_BRANDING_GUIDE.md`.
