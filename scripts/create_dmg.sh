#!/usr/bin/env bash
# ==============================================================================
# REA-Silicon: Native macOS Drag-and-Drop DMG Creator
# Creates a polished, compressed .dmg installer with an /Applications symlink
# for seamless drag-and-drop installation on Apple Silicon macOS.
#
# Usage:
#   ./scripts/create_dmg.sh <app_bundle_or_project_dir> [output.dmg] [options]
#
# Examples:
#   ./scripts/create_dmg.sh ./build/Calcuroo.app
#   ./scripts/create_dmg.sh ./projects/Calcuroo
#   ./scripts/create_dmg.sh ./build/Calcuroo.app ./dist/Calcuroo-arm64.dmg --icon ./Resources/AppIcon.icns
# ==============================================================================

set -euo pipefail

TARGET_INPUT="${1:-}"
OUTPUT_DMG="${2:-}"
APP_NAME=""
VOL_NAME=""
CUSTOM_ICON=""
BUNDLE_ID=""
APP_VERSION="1.0.0"

if [[ -z "$TARGET_INPUT" || "$TARGET_INPUT" == "-h" || "$TARGET_INPUT" == "--help" ]]; then
    echo "================================================================================"
    echo "🍏 REA-Silicon Drag-and-Drop DMG Creator"
    echo "================================================================================"
    echo "사용법: $0 <앱_번들_또는_스위프트_프로젝트> [출력_dmg_경로] [옵션]"
    echo ""
    echo "인자:"
    echo "  <대상>                  .app 번들 경로, Swift 프로젝트 디렉토리, 또는 실행 파일"
    echo "  [출력_dmg_경로]         생성될 .dmg 파일 경로 (기본값: dist/<AppName>-arm64.dmg)"
    echo ""
    echo "옵션:"
    echo "  -n, --name <이름>       앱 이름 지정 (기본값: 자동 추론)"
    echo "  -i, --icon <icns경로>   적용할 AppIcon.icns 경로"
    echo "  -v, --version <버전>    앱 버전 (기본값: 1.0.0)"
    echo "  -b, --bundle-id <ID>    앱 Bundle ID (기본값: com.reasilicon.<appname>)"
    echo "  -V, --volname <볼륨명>  DMG 마운트 볼륨 이름"
    echo "================================================================================"
    exit 0
fi

# Shift positional args if 2nd arg was not an option
shift || true
if [[ -n "$OUTPUT_DMG" && "$OUTPUT_DMG" != -* ]]; then
    shift || true
else
    OUTPUT_DMG=""
fi

# Parse additional options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)
            APP_NAME="$2"
            shift 2
            ;;
        -i|--icon)
            CUSTOM_ICON="$2"
            shift 2
            ;;
        -v|--version)
            APP_VERSION="$2"
            shift 2
            ;;
        -b|--bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        -V|--volname)
            VOL_NAME="$2"
            shift 2
            ;;
        *)
            echo "⚠️ 알 수 없는 옵션: $1"
            shift
            ;;
    esac
done

if [[ ! -e "$TARGET_INPUT" ]]; then
    echo "❌ 오류: 대상 경로 '$TARGET_INPUT'을(를) 찾을 수 없습니다."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_ABS="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$TARGET_INPUT")"

TEMP_BUILD_DIR=""
clean_temp() {
    if [[ -n "${TEMP_BUILD_DIR:-}" && -d "$TEMP_BUILD_DIR" ]]; then
        rm -rf "$TEMP_BUILD_DIR"
    fi
}
trap clean_temp EXIT

APP_BUNDLE_PATH=""

# Determine input type: .app bundle, SPM project, or standalone binary
if [[ "$TARGET_ABS" == *.app && -d "$TARGET_ABS" ]]; then
    APP_BUNDLE_PATH="$TARGET_ABS"
    DETECTED_NAME="$(basename "$APP_BUNDLE_PATH" .app)"
    [[ -z "$APP_NAME" ]] && APP_NAME="$DETECTED_NAME"
elif [[ -d "$TARGET_ABS" && -f "$TARGET_ABS/Package.swift" ]]; then
    echo "[1/4] Swift Package Manager 프로젝트 감지: $TARGET_ABS"
    TEMP_BUILD_DIR="$(mktemp -d -t rea_dmg_build_XXXXXX)"
    
    # Infer package name if not provided
    if [[ -z "$APP_NAME" ]]; then
        APP_NAME="$(basename "$TARGET_ABS")"
    fi
    
    echo "      Apple Silicon (arm64) 릴리즈 빌드 중..."
    (
        cd "$TARGET_ABS"
        arch -arm64 swift build -c release --triple arm64-apple-macosx14.0
    )
    
    # Locate release binary
    RELEASE_BIN_DIR="$TARGET_ABS/.build/arm64-apple-macosx/release"
    EXEC_BIN=""
    if [[ -f "$RELEASE_BIN_DIR/$APP_NAME" ]]; then
        EXEC_BIN="$RELEASE_BIN_DIR/$APP_NAME"
    else
        # Find first executable file in release dir
        EXEC_BIN="$(find "$RELEASE_BIN_DIR" -maxdepth 1 -type f -perm +111 ! -name "*.*" | head -n 1)"
    fi
    
    if [[ -z "$EXEC_BIN" || ! -f "$EXEC_BIN" ]]; then
        echo "❌ 오류: 빌드된 바이너리를 찾을 수 없습니다 ($RELEASE_BIN_DIR)."
        exit 1
    fi
    
    APP_BUNDLE_PATH="$TEMP_BUILD_DIR/${APP_NAME}.app"
    echo "      .app 번들 구조 생성 중: $APP_BUNDLE_PATH"
    mkdir -p "$APP_BUNDLE_PATH/Contents/MacOS"
    mkdir -p "$APP_BUNDLE_PATH/Contents/Resources"
    
    cp "$EXEC_BIN" "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    
    # Look for icon if not provided
    if [[ -z "$CUSTOM_ICON" ]]; then
        if [[ -f "$TARGET_ABS/Resources/AppIcon.icns" ]]; then
            CUSTOM_ICON="$TARGET_ABS/Resources/AppIcon.icns"
        elif [[ -f "$WORKSPACE_ROOT/Resources/AppIcon.icns" ]]; then
            CUSTOM_ICON="$WORKSPACE_ROOT/Resources/AppIcon.icns"
        fi
    fi
    
    # Create Info.plist
    [[ -z "$BUNDLE_ID" ]] && BUNDLE_ID="com.reasilicon.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
    cat << EOF > "$APP_BUNDLE_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
    echo "APPL????" > "$APP_BUNDLE_PATH/Contents/PkgInfo"
    
elif [[ -f "$TARGET_ABS" && -x "$TARGET_ABS" ]]; then
    echo "[1/4] 독립 실행 바이너리 감지: $TARGET_ABS"
    TEMP_BUILD_DIR="$(mktemp -d -t rea_dmg_build_XXXXXX)"
    DETECTED_NAME="$(basename "$TARGET_ABS")"
    [[ -z "$APP_NAME" ]] && APP_NAME="$DETECTED_NAME"
    
    APP_BUNDLE_PATH="$TEMP_BUILD_DIR/${APP_NAME}.app"
    mkdir -p "$APP_BUNDLE_PATH/Contents/MacOS"
    mkdir -p "$APP_BUNDLE_PATH/Contents/Resources"
    cp "$TARGET_ABS" "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
    
    [[ -z "$BUNDLE_ID" ]] && BUNDLE_ID="com.reasilicon.$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
    cat << EOF > "$APP_BUNDLE_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
    echo "APPL????" > "$APP_BUNDLE_PATH/Contents/PkgInfo"
else
    echo "❌ 오류: 유효한 .app 번들, Swift 프로젝트, 또는 실행 바이너리가 아닙니다: $TARGET_INPUT"
    exit 1
fi

# Ensure AppIcon is included if available
if [[ -n "$CUSTOM_ICON" && -f "$CUSTOM_ICON" ]]; then
    mkdir -p "$APP_BUNDLE_PATH/Contents/Resources"
    cp "$CUSTOM_ICON" "$APP_BUNDLE_PATH/Contents/Resources/AppIcon.icns"
elif [[ -f "$APP_BUNDLE_PATH/Contents/Resources/AppIcon.icns" ]]; then
    CUSTOM_ICON="$APP_BUNDLE_PATH/Contents/Resources/AppIcon.icns"
fi

# Apple Silicon Ad-hoc Code Signing
echo "[2/4] Apple Silicon 코드 서명 확인 및 ad-hoc 서명 적용..."
codesign --force --deep --sign - "$APP_BUNDLE_PATH" >/dev/null 2>&1 || true

# Prepare default naming and paths
[[ -z "$APP_NAME" ]] && APP_NAME="$(basename "$APP_BUNDLE_PATH" .app)"
[[ -z "$VOL_NAME" ]] && VOL_NAME="${APP_NAME} Installer"
if [[ -z "$OUTPUT_DMG" ]]; then
    mkdir -p "$WORKSPACE_ROOT/dist"
    OUTPUT_DMG="$WORKSPACE_ROOT/dist/${APP_NAME}-arm64.dmg"
else
    mkdir -p "$(dirname "$OUTPUT_DMG")"
fi

# Staging DMG content
echo "[3/4] DMG 스테이징 디렉토리 준비 중..."
DMG_STAGE_DIR="$(mktemp -d -t rea_dmg_stage_XXXXXX)"
trap 'clean_temp; rm -rf "$DMG_STAGE_DIR"' EXIT

# Copy App bundle using ditto to preserve attributes & signatures
ditto "$APP_BUNDLE_PATH" "$DMG_STAGE_DIR/$(basename "$APP_BUNDLE_PATH")"

# Create standard macOS Drag-to-Applications symlink
echo "      /Applications 드래그 앤 드롭 심볼릭 링크 생성..."
ln -s /Applications "$DMG_STAGE_DIR/Applications"

# Set Volume Icon if custom icon is present
if [[ -n "$CUSTOM_ICON" && -f "$CUSTOM_ICON" ]]; then
    cp "$CUSTOM_ICON" "$DMG_STAGE_DIR/.VolumeIcon.icns"
    if command -v SetFile >/dev/null 2>&1; then
        SetFile -c icnC "$DMG_STAGE_DIR/.VolumeIcon.icns" 2>/dev/null || true
        SetFile -a C "$DMG_STAGE_DIR" 2>/dev/null || true
    fi
fi

# Remove existing DMG if present
rm -f "$OUTPUT_DMG"

# Build compressed UDZO DMG
echo "[4/4] Apple Silicon 표준 UDZO 압축 DMG 생성 중..."
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$DMG_STAGE_DIR" \
    -ov \
    -format UDZO \
    "$OUTPUT_DMG" >/dev/null

# Verify DMG integrity
hdiutil verify "$OUTPUT_DMG" >/dev/null

# Get file size
DMG_SIZE="$(du -h "$OUTPUT_DMG" | awk '{print $1}')"

echo ""
echo "================================================================================"
echo "🎉 DMG 배포 패키지 생성 완료!"
echo "================================================================================"
echo "📦 DMG 파일   : $OUTPUT_DMG"
echo "📏 용량        : $DMG_SIZE"
echo "🏷️ 볼륨 레이블 : $VOL_NAME"
echo "📱 포함된 앱   : $(basename "$APP_BUNDLE_PATH")"
echo "📂 바로가기    : /Applications (드래그 앤 드롭 설치 지원)"
echo ""
echo "💡 테스트 실행 방법:"
echo "   open \"$OUTPUT_DMG\""
echo "================================================================================"
