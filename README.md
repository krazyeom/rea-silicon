# REA (Reverse Engineer Anything) Engine & Apple Silicon Native Rebuilder

[![macOS](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon%20(arm64)-000000?logo=apple&style=flat-square)](https://apple.com)
[![Swift](https://img.shields.io/badge/Language-Swift%206.0-FA7343?logo=swift&style=flat-square)](https://swift.org)
[![License-Safe](https://img.shields.io/badge/Pattern-Clean--Room%20Rebuild-success?style=flat-square)](#)

> **Autonomous Reverse Engineering & Native Rebuild System**  
> Analyzes legacy binaries, Electron packages, and cross-platform applications, then reconstructs them into high-performance, native macOS Apple Silicon (`arm64`) applications using **Swift 6, SwiftUI, and AppKit**.

---

## 🌐 Language Navigation (문서 언어 선택)

| Documentation | English (EN) | 한국어 (KR) |
| :--- | :--- | :--- |
| **Complete Reverse Engineering Guide** | [`docs/en/REA_REVERSE_ENGINEERING_GUIDE.md`](file:///Users/krazyeom/dev/rea/docs/en/REA_REVERSE_ENGINEERING_GUIDE.md) | [`docs/kr/REA_REVERSE_ENGINEERING_GUIDE.md`](file:///Users/krazyeom/dev/rea/docs/kr/REA_REVERSE_ENGINEERING_GUIDE.md) |
| **Apple Silicon Rebuild Blueprint** | [`docs/en/MAC_SILICON_REBUILD_GUIDE.md`](file:///Users/krazyeom/dev/rea/docs/en/MAC_SILICON_REBUILD_GUIDE.md) | [`docs/kr/MAC_SILICON_REBUILD_GUIDE.md`](file:///Users/krazyeom/dev/rea/docs/kr/MAC_SILICON_REBUILD_GUIDE.md) |
| **Agent Rules & SOP Workflow** | [`docs/en/WORKFLOW_AND_RULES.md`](file:///Users/krazyeom/dev/rea/docs/en/WORKFLOW_AND_RULES.md) | [`docs/kr/WORKFLOW_AND_RULES.md`](file:///Users/krazyeom/dev/rea/docs/kr/WORKFLOW_AND_RULES.md) |
| **Clean-Room SPEC Template** | [`docs/en/SPEC_TEMPLATE.md`](file:///Users/krazyeom/dev/rea/docs/en/SPEC_TEMPLATE.md) | [`docs/kr/SPEC_TEMPLATE.md`](file:///Users/krazyeom/dev/rea/docs/kr/SPEC_TEMPLATE.md) |
| **Engineered Prompts Catalog** | [`docs/en/PROMPTS.md`](file:///Users/krazyeom/dev/rea/docs/en/PROMPTS.md) | [`docs/kr/PROMPTS.md`](file:///Users/krazyeom/dev/rea/docs/kr/PROMPTS.md) |

---

## ⚡ Quick Start: How to Use with Antigravity / AI Agent

Simply point the agent to the application bundle or binary path:

```text
"Analyze and rebuild this application for Apple Silicon Native: /Applications/SampleLegacyApp.app"
```

The agent will automatically:
1. Load operating rules from [`AGENTS.md`](file:///Users/krazyeom/dev/rea/AGENTS.md) and activation skill [`.agents/skills/rea-silicon-rebuild/SKILL.md`](file:///Users/krazyeom/dev/rea/.agents/skills/rea-silicon-rebuild/SKILL.md).
2. Execute [`scripts/inspect_target.sh`](file:///Users/krazyeom/dev/rea/scripts/inspect_target.sh) to diagnose architecture, frameworks, and runtime stack.
3. Formulate a clean-room `SPEC.md` (Room A) adhering to zero-copyright contamination principles.
4. Rebuild the application natively using Swift 6 / SwiftUI targeting Apple Silicon `arm64` (Room B).
5. Verify builds with [`scripts/verify_build.sh`](file:///Users/krazyeom/dev/rea/scripts/verify_build.sh) and validate output equivalence with [`scripts/test_oracle.py`](file:///Users/krazyeom/dev/rea/scripts/test_oracle.py).

---

## 📁 Repository Structure

```text
rea/
├── .agents/
│   └── skills/
│       └── rea-silicon-rebuild/
│           ├── SKILL.md                 # Antigravity skill definition
│           └── scripts/
├── docs/
│   ├── en/                              # English Documentation
│   │   ├── REA_REVERSE_ENGINEERING_GUIDE.md
│   │   ├── MAC_SILICON_REBUILD_GUIDE.md
│   │   ├── WORKFLOW_AND_RULES.md
│   │   ├── SPEC_TEMPLATE.md
│   │   └── PROMPTS.md
│   └── kr/                              # Korean Documentation (한국어 문서)
│       ├── REA_REVERSE_ENGINEERING_GUIDE.md
│       ├── MAC_SILICON_REBUILD_GUIDE.md
│       ├── WORKFLOW_AND_RULES.md
│       ├── SPEC_TEMPLATE.md
│       └── PROMPTS.md
├── scripts/
│   ├── inspect_target.sh                # Target binary & bundle inspector
│   ├── verify_build.sh                  # Apple Silicon build verifier
│   └── test_oracle.py                   # Automated differential test oracle
├── AGENTS.md                            # Global Workspace Rules for Agents
├── GEMINI.md                            # Compatibility Rules
└── README.md                            # Repository Overview & Quick Start
```

---

## 🛠️ CLI Utilities Reference

### 1. Inspect Target App or Binary
```bash
./scripts/inspect_target.sh /path/to/any_app.app
```
*Outputs: Mach-O slices, dynamic libraries, code signatures, and runtime stack fingerprinting.*

### 2. Verify Native Apple Silicon Build
```bash
./scripts/verify_build.sh ./path_to_rebuilt_swift_package
```

### 3. Run Differential Test Oracle
```bash
python3 ./scripts/test_oracle.py --original /path/to/legacy_bin --rebuilt /path/to/rebuilt_arm64_bin --args "-v"
```

---

## 📜 한국어 개요 (Korean Overview)

본 저장소는 레거시 바이너리나 Electron 등의 크로스 플랫폼 앱을 역공학하여 최신 **Apple Silicon (macOS arm64)** 환경에 최적화된 고성능 **Swift 6 / SwiftUI / AppKit 네이티브 애플리케이션**으로 재개발할 수 있도록 지원하는 프레임워크입니다.

- **규칙(Rules) 자동화**: 사용자가 앱 경로만 제공하면 `AGENTS.md`와 스킬 정의에 따라 에이전트가 자동 진단부터 명세 작성(`SPEC.md`), 신규 네이티브 개발, 오라클 검증까지 원스톱으로 처리합니다.
- **클린룸 원칙(Clean-Room)**: 원본 코드의 지적 재산권 침해를 막기 위해 분석(Room A)과 재개발(Room B)을 엄격히 분리합니다.
- **Git 버전 관리**: 모든 문서, 템플릿, 규칙, 스크립트가 Git으로 완벽하게 추적됩니다.
