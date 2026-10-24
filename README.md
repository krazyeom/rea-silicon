# REA-Silicon (Reverse Engineer Anything for Apple Silicon)

[![macOS](https://img.shields.io/badge/Platform-macOS%20Apple%20Silicon%20(arm64)-000000?logo=apple&style=flat-square)](https://apple.com)
[![Swift](https://img.shields.io/badge/Language-Swift%206.0-FA7343?logo=swift&style=flat-square)](https://swift.org)
[![License-Safe](https://img.shields.io/badge/Pattern-Clean--Room%20Rebuild-success?style=flat-square)](#)
[![Git](https://img.shields.io/badge/Repository-rea--silicon-blue?logo=git&style=flat-square)](#)

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

## ⚡ Quick Start: 가장 간단한 1초 실행 가이드 (LLM CLI Quickstart)

`aaa.app`의 위치만 주고 터미널에서 즉시 분석 및 Apple Silicon 네이티브 재개발을 시작하는 가장 간단한 방법입니다:

### 🚀 방법 1. 원터치 전용 스크립트 (가장 추천)
앱 위치만 인자로 넘기면 기술 스택 진단(`inspect_target.sh`) 후 설치된 LLM CLI(`agy`, `claude` 등)를 자동 실행합니다:
```bash
./scripts/rebuild_app.sh /Applications/aaa.app
```

### 💬 방법 2. Antigravity CLI (`agy`)로 직접 실행
터미널에서 `agy`에 앱 경로만 전달하면 워크스페이스 규칙(`AGENTS.md`)에 따라 자율 재개발을 시작합니다:
```bash
# 대화형 모드로 실행
agy "이 앱 분석해서 Apple Silicon 네이티브로 재개발해줘: /Applications/aaa.app"

# 논스톱 원샷 자동 실행 (자동 승인 모드)
agy --dangerously-skip-permissions -p "이 앱 분석해서 Apple Silicon 네이티브로 재개발해줘: /Applications/aaa.app"
```

### 🤖 방법 3. Claude Code CLI (`claude`)로 직접 실행
```bash
claude "이 앱 분석해서 Apple Silicon 네이티브 Swift로 재개발해줘: /Applications/aaa.app"
```

---

## 🧭 에이전트 자동 수행 흐름 (Behind the Scenes)

명령어가 실행되면 에이전트는 사용자의 추가 개입 없이 다음 단계를 자율적으로 수행합니다:
1. [`AGENTS.md`](file:///Users/krazyeom/dev/rea/AGENTS.md) 및 [`.agents/skills/rea-silicon-rebuild/SKILL.md`](file:///Users/krazyeom/dev/rea/.agents/skills/rea-silicon-rebuild/SKILL.md) 규칙 자동 로드.
2. [`scripts/inspect_target.sh`](file:///Users/krazyeom/dev/rea/scripts/inspect_target.sh)를 실행하여 아키텍처 슬라이스, 링크된 프레임워크, 런타임 기술 스택(Electron, Qt, .NET, Go 등)을 자동 진단.
3. 클린룸 원칙에 따라 [`SPEC_TEMPLATE.md`](file:///Users/krazyeom/dev/rea/docs/kr/SPEC_TEMPLATE.md) 기반의 블랙박스 명세서(`SPEC.md`) 추출.
4. `SPEC.md`만을 참조하여 Swift 6 / SwiftUI 기반의 macOS Apple Silicon (`arm64`) 네이티브 프로젝트 생성.
5. [`scripts/verify_build.sh`](file:///Users/krazyeom/dev/rea/scripts/verify_build.sh)로 컴파일 및 코드 서명 후, [`scripts/test_oracle.py`](file:///Users/krazyeom/dev/rea/scripts/test_oracle.py)로 입출력 검증 완료.

---

## 🚀 Publishing to GitHub (Git 저장소 연동 가이드)

If you are publishing this project to your GitHub account as `rea-silicon`:

```bash
# 1. GitHub 원격 저장소 연결 (등록 완료됨)
git remote add origin https://github.com/krazyeom/rea-silicon.git

# 2. main 브랜치 푸시
git branch -M main
git push -u origin main
```

---

## 📁 Repository Structure

```text
rea-silicon/
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

**REA-Silicon**은 레거시 바이너리나 Electron 등의 크로스 플랫폼 앱을 역공학하여 최신 **Apple Silicon (macOS arm64)** 환경에 최적화된 고성능 **Swift 6 / SwiftUI / AppKit 네이티브 애플리케이션**으로 재개발할 수 있도록 지원하는 오픈소스 프레임워크입니다.

- **규칙(Rules) 자동화**: 사용자가 앱 경로만 제공하면 `AGENTS.md`와 스킬 정의에 따라 에이전트가 자동 진단부터 명세 작성(`SPEC.md`), 신규 네이티브 개발, 오라클 검증까지 원스톱으로 처리합니다.
- **클린룸 원칙(Clean-Room)**: 원본 코드의 지적 재산권 침해를 막기 위해 분석(Room A)과 재개발(Room B)을 엄격히 분리합니다.
- **Git 버전 관리**: 모든 문서, 템플릿, 규칙, 스크립트가 Git으로 완벽하게 추적됩니다.
