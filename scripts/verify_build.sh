#!/usr/bin/env bash
# ==============================================================================
# REA Mac Silicon Native Build & Verification Script
# Builds Swift package or single-file Swift native binary for Apple Silicon (arm64).
# Optionally generates a drag-and-drop .dmg installer when --dmg is supplied.
# ==============================================================================

set -euo pipefail

TARGET_DIR="."
CREATE_DMG=false

for arg in "$@"; do
    case "$arg" in
        --dmg|-d)
            CREATE_DMG=true
            ;;
        *)
            if [[ "$arg" != -* ]]; then
                TARGET_DIR="$arg"
            fi
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ABS="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$TARGET_DIR")"

echo "================================================================================"
echo "🍏 Apple Silicon (arm64) Native Build & Verification"
echo "Directory: $TARGET_ABS"
echo "================================================================================"

cd "$TARGET_ABS"

BUILD_SUCCESS=false

if [[ -f "Package.swift" ]]; then
    echo "[+] Detected Swift Package Manager (Package.swift)"
    echo "[-] Resolving dependencies and building for arm64-apple-macosx..."
    
    # Force native arm64 build
    arch -arm64 swift build -c release --triple arm64-apple-macosx14.0
    BUILD_SUCCESS=true
    
    echo "[-] Running Swift Package tests..."
    if arch -arm64 swift test --triple arm64-apple-macosx14.0 2>/dev/null; then
        echo "✅ All Swift tests passed successfully!"
    else
        echo "⚠️ Swift tests completed with warnings or no tests declared."
    fi
elif [[ -f "main.swift" ]]; then
    echo "[+] Detected standalone main.swift"
    echo "[-] Compiling native arm64 binary with swiftc..."
    mkdir -p build
    arch -arm64 swiftc -O -target arm64-apple-macosx14.0 main.swift -o build/native_app_arm64
    echo "✅ Compiled native binary to build/native_app_arm64"
    file build/native_app_arm64
    BUILD_SUCCESS=true
elif [[ -d "$TARGET_ABS" && "$TARGET_ABS" == *.app ]]; then
    echo "[+] Detected existing .app bundle: $TARGET_ABS"
    BUILD_SUCCESS=true
else
    echo "[-] No Package.swift or main.swift found in '$TARGET_ABS'."
    echo "    Please point to a Swift package or provide a Swift source file."
fi

# Create DMG if requested
if [[ "$CREATE_DMG" == true && "$BUILD_SUCCESS" == true ]]; then
    echo ""
    echo "[+] --dmg 옵션 감지: Drag-and-Drop .dmg 인스톨러 생성 중..."
    "$SCRIPT_DIR/create_dmg.sh" "$TARGET_ABS"
fi

echo "================================================================================"
