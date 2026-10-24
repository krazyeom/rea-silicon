# REA-Silicon Agent Operating Rules: Reverse Engineering & Apple Silicon Rebuild

This workspace (`REA-Silicon`) is configured to autonomously reverse-engineer target applications and rebuild them into high-performance **Apple Silicon Native (macOS arm64)** applications using modern **Swift 6, SwiftUI, and AppKit**.

---

## 🚀 Autonomous Execution Protocol When User Provides an App Path

Whenever the user provides an application path (e.g., `/Applications/App.app`, `./bin/target`, or any binary) and requests analysis or rebuild:

### 1. Mandatory Rule & Guide Consultation
Before executing, the agent MUST consult the workspace documentation:
- **English Guides**:
  - `docs/en/WORKFLOW_AND_RULES.md`
  - `docs/en/MAC_SILICON_REBUILD_GUIDE.md`
  - `docs/en/SPEC_TEMPLATE.md`
  - `docs/en/PROMPTS.md`
- **Korean Guides (한국어 가이드)**:
  - `docs/kr/WORKFLOW_AND_RULES.md`
  - `docs/kr/MAC_SILICON_REBUILD_GUIDE.md`
  - `docs/kr/SPEC_TEMPLATE.md`
  - `docs/kr/PROMPTS.md`

### 2. Primary Rebuild Target: Apple Silicon Native (`arm64`)
- Unless explicitly directed otherwise, rebuilds MUST target **macOS Apple Silicon (`arm64`)** with **Swift 6 / SwiftUI / AppKit**.
- Eliminate emulation layers, Rosetta 2 dependencies, and heavy web wrappers (Electron/Node) in favor of native compiled machine code.

### 3. Step-by-Step Execution Sequence
1. **Target Inspection (자동 진단)**:
   Run the analysis script to extract architecture, dylibs, entitlements, and technology stack fingerprint:
   ```bash
   ./scripts/inspect_target.sh "<TARGET_PATH>"
   ```
2. **Phase 1: Room A – Clean-Room Specification (`SPEC.md`)**:
   - Extract the core business algorithms, data structures, and CLI/API contracts.
   - Do NOT paste decompiled C/C++ or assembly code into source files or specifications.
   - Follow `docs/en/SPEC_TEMPLATE.md` or `docs/kr/SPEC_TEMPLATE.md`.
3. **Phase 2: Room B – Swift 6 Native Re-implementation**:
   - Create a clean Swift package (`Package.swift`) targeting `arm64-apple-macosx14.0+`.
   - Implement idiomatic Swift 6 strict concurrency (`Sendable`, `actor`, `async/await`).
4. **Phase 3: Verification & Build**:
   - Compile and ad-hoc sign:
     ```bash
     arch -arm64 swift build -c release --triple arm64-apple-macosx14.0
     ```
   - Run verification test oracle:
     ```bash
     ./scripts/verify_build.sh <PROJECT_DIR>
     python3 ./scripts/test_oracle.py --original "<ORIGINAL_BIN>" --rebuilt "<REBUILT_BIN>"
     ```

---

## 📜 한국어 요약 안내 (Korean Summary)

사용자가 애플리케이션의 경로(예: `/Applications/Target.app` 또는 바이너리 파일 경로)를 제공하면, 에이전트는 다음 절차를 즉시 수행해야 합니다:
1. `docs/kr/WORKFLOW_AND_RULES.md` 및 `docs/kr/MAC_SILICON_REBUILD_GUIDE.md`를 필독합니다.
2. `./scripts/inspect_target.sh "<대상경로>"`를 실행하여 기술 스택, 아키텍처, 프레임워크를 진단합니다.
3. **클린룸 원칙(Clean-Room)**에 따라 원작 코드를 일체 복제하지 않고 `docs/kr/SPEC_TEMPLATE.md` 양식의 블랙박스 명세서(`SPEC.md`)를 작성합니다.
4. 명세서에 기반하여 최신 Apple Silicon(`arm64`) 네이티브 환경(Swift 6, SwiftUI, AppKit)으로 새 프로젝트를 구현합니다.
5. `verify_build.sh` 및 `test_oracle.py`로 빌드 및 입출력 동치성을 검증합니다.
