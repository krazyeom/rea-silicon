#!/usr/bin/env bash
# ==============================================================================
# REA-Silicon: One-Touch App Analyzer & Rebuilder CLI
# Usage: ./scripts/rebuild_app.sh /path/to/aaa.app
# ==============================================================================

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    echo "❌ 오류: 대상 애플리케이션의 경로를 입력해 주세요."
    echo "사용법: $0 <앱_또는_바이너리_경로>"
    echo "예  시: $0 /Applications/aaa.app"
    exit 1
fi

if [[ ! -e "$TARGET" ]]; then
    echo "❌ 오류: 대상 경로 '$TARGET'을(를) 찾을 수 없습니다."
    exit 1
fi

# Resolve absolute path
ABS_PATH=$(python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$TARGET")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "================================================================================"
echo "🍏 REA-Silicon: One-Touch Apple Silicon Native Rebuilder"
echo "Target Application: $ABS_PATH"
echo "Workspace Root    : $PROJECT_ROOT"
echo "================================================================================"

# Step 1: Pre-flight target inspection
echo ""
echo "[Step 1] 타깃 애플리케이션 기술 스택 및 구조 자동 분석 중..."
"$SCRIPT_DIR/inspect_target.sh" "$ABS_PATH"

# Step 2: Detect available LLM CLI
LLM_CLI=""
if command -v agy >/dev/null 2>&1; then
    LLM_CLI="agy"
elif [[ -x "/Users/krazyeom/.local/bin/agy" ]]; then
    LLM_CLI="/Users/krazyeom/.local/bin/agy"
elif command -v claude >/dev/null 2>&1; then
    LLM_CLI="claude"
fi

PROMPT_MSG="[REA-Silicon Rebuild Request]
타깃 애플리케이션 위치: $ABS_PATH
AGENTS.md 및 docs/kr/MAC_SILICON_REBUILD_GUIDE.md 규칙을 읽고 다음 과업을 수행하세요:
1. [위트 있는 명칭 변경]: 원작 앱 이름을 그대로 쓰지 말고, 원작의 특징을 연상시키는 재치 있고 유머러스한 오마주 이름(예: Calcuroo, PacketBoy 등)을 선정하세요.
2. [사양 및 분석]: 타깃 기술 스택을 분석하고 docs/kr/SPEC_TEMPLATE.md 양식에 맞추어 SPEC.md 명세서를 작성하세요.
3. [아이콘 및 비주얼 생성]: ./scripts/generate_app_icon.swift 도구를 사용하여 macOS 네이티브 AppIcon.icns 및 고해상도 에셋을 생성하세요.
4. [클린룸 Swift 6 재개발]: Swift 6 / SwiftUI 기반의 macOS Apple Silicon (arm64) 네이티브 프로젝트로 완성도 높게 구현하세요.
5. [검증]: ./scripts/verify_build.sh로 컴파일과 테스트를 검증하세요."

echo ""
echo "[Step 2] LLM CLI 연동 및 자율 재개발 시작"
if [[ -n "$LLM_CLI" ]]; then
    echo "✅ 감지된 LLM CLI 도구: $LLM_CLI"
    echo "🚀 에이전트를 실행하여 Apple Silicon 네이티브 재개발을 시작합니다..."
    echo "--------------------------------------------------------------------------------"
    cd "$PROJECT_ROOT"
    
    if [[ "$LLM_CLI" == *"agy"* ]]; then
        # Run agy in interactive prompt mode
        exec "$LLM_CLI" "$PROMPT_MSG"
    else
        exec "$LLM_CLI" "$PROMPT_MSG"
    fi
else
    echo "⚠️ LLM CLI 도구(agy 또는 claude)를 PATH에서 찾지 못했습니다."
    echo "아래 프롬프트를 복사하여 사용하시는 LLM CLI 또는 웹 UI에 붙여넣으세요:"
    echo "--------------------------------------------------------------------------------"
    echo "$PROMPT_MSG"
    echo "--------------------------------------------------------------------------------"
fi
