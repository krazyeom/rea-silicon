#!/usr/bin/env bash
# ==============================================================================
# REA Target Inspector (macOS Apple Silicon & Universal Binary Analyzer)
# Analyzes any binary, macOS .app bundle, Electron app, or executable archive.
# ==============================================================================

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <path_to_binary_or_app>" >&2
    exit 1
fi

if [[ ! -e "$TARGET" ]]; then
    echo "Error: Target '$TARGET' does not exist." >&2
    exit 1
fi

echo "================================================================================"
echo "🎯 REA TARGET ANALYSIS REPORT"
echo "Target: $TARGET"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Host Architecture: $(uname -m) (Kernel: $(uname -s) $(uname -r))"
echo "================================================================================"

# Resolve real path
REAL_TARGET=$(python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$TARGET")
echo "[1] Target Identity & Type"
echo "    Path: $REAL_TARGET"

# Check if target is a .app bundle
EXECUTABLE_BIN=""
BUNDLE_TYPE="Unknown"

if [[ -d "$REAL_TARGET" && "$REAL_TARGET" == *".app"* ]]; then
    BUNDLE_TYPE="macOS App Bundle"
    echo "    Classification: $BUNDLE_TYPE"
    INFO_PLIST="$REAL_TARGET/Contents/Info.plist"
    if [[ -f "$INFO_PLIST" ]]; then
        BUNDLE_ID=$(plutil -p "$INFO_PLIST" 2>/dev/null | grep -E '"CFBundleIdentifier"' | awk -F '=> ' '{print $2}' || true)
        BUNDLE_NAME=$(plutil -p "$INFO_PLIST" 2>/dev/null | grep -E '"CFBundleName"' | awk -F '=> ' '{print $2}' || true)
        BUNDLE_EXE=$(plutil -p "$INFO_PLIST" 2>/dev/null | grep -E '"CFBundleExecutable"' | awk -F '=> ' '{print $2}' | tr -d '"' || true)
        echo "    Bundle ID: $BUNDLE_ID"
        echo "    Bundle Name: $BUNDLE_NAME"
        echo "    Main Executable: $BUNDLE_EXE"
        if [[ -n "$BUNDLE_EXE" && -f "$REAL_TARGET/Contents/MacOS/$BUNDLE_EXE" ]]; then
            EXECUTABLE_BIN="$REAL_TARGET/Contents/MacOS/$BUNDLE_EXE"
        fi
    fi
    # Check for Electron / ASAR
    ASAR_FILES=$(find "$REAL_TARGET" -name "*.asar" 2>/dev/null || true)
    if [[ -n "$ASAR_FILES" ]]; then
        echo "    [!] Detected Electron Framework (ASAR package found):"
        echo "$ASAR_FILES" | sed 's/^/        - /'
    fi
elif [[ -f "$REAL_TARGET" ]]; then
    BUNDLE_TYPE="Single File / Executable Binary"
    EXECUTABLE_BIN="$REAL_TARGET"
    echo "    Classification: $BUNDLE_TYPE"
else
    echo "    Classification: Directory / Archive"
fi

echo ""
echo "[2] Binary Architecture & File Details"
if [[ -n "$EXECUTABLE_BIN" && -f "$EXECUTABLE_BIN" ]]; then
    file "$EXECUTABLE_BIN" | sed 's/^/    /'
    
    echo ""
    echo "    Lipo Architecture Info:"
    lipo -info "$EXECUTABLE_BIN" 2>&1 | sed 's/^/    /' || echo "    (Not a Mach-O fat binary or lipo failed)"
    
    echo ""
    echo "    Apple Silicon (arm64) Native Compatibility:"
    if lipo -info "$EXECUTABLE_BIN" 2>/dev/null | grep -q "arm64"; then
        echo "    ✅ Binary contains arm64 / arm64e architecture (Native Apple Silicon compatible)"
    else
        echo "    ⚠️ Binary does NOT contain native arm64 slice (x86_64 / Intel only or alien architecture)"
        echo "       Requires Rosetta 2 emulation or Clean-room re-implementation to arm64 native."
    fi
else
    file "$REAL_TARGET" | sed 's/^/    /'
fi

echo ""
echo "[3] Code Signature & Entitlements"
if [[ -n "$EXECUTABLE_BIN" && -f "$EXECUTABLE_BIN" ]]; then
    codesign -dv --verbose=2 "$EXECUTABLE_BIN" 2>&1 | sed 's/^/    /' || echo "    (Unsigned or codesign not applicable)"
fi

echo ""
echo "[4] Dynamic Linkage & Framework Dependencies"
if [[ -n "$EXECUTABLE_BIN" && -f "$EXECUTABLE_BIN" ]]; then
    if otool -L "$EXECUTABLE_BIN" >/dev/null 2>&1; then
        echo "    Linked Frameworks/Dylibs (Top 25):"
        otool -L "$EXECUTABLE_BIN" | head -n 25 | sed 's/^/    /'
    else
        echo "    otool could not inspect dynamic linkage."
    fi
fi

echo ""
echo "[5] Technology Stack Fingerprinting (Strings & Symbols Heuristics)"
SEARCH_FILE="${EXECUTABLE_BIN:-$REAL_TARGET}"

if [[ -f "$SEARCH_FILE" ]]; then
    DETECTED_STACKS=()
    
    # Swift
    if strings "$SEARCH_FILE" | grep -q -m 1 "swift_allocObject\|libswiftCore"; then
        DETECTED_STACKS+=("Swift (Native Apple)")
    fi
    # Objective-C
    if strings "$SEARCH_FILE" | grep -q -m 1 "OBJC_CLASS_\$_NSObject\|objc_msgSend"; then
        DETECTED_STACKS+=("Objective-C (Cocoa / AppKit)")
    fi
    # Go
    if strings "$SEARCH_FILE" | grep -q -m 1 "runtime.goexit\|go.buildid"; then
        DETECTED_STACKS+=("Go (Golang)")
    fi
    # Rust
    if strings "$SEARCH_FILE" | grep -q -m 1 "rust_begin_unwind\|std::rt::lang_start"; then
        DETECTED_STACKS+=("Rust")
    fi
    # Python
    if strings "$SEARCH_FILE" | grep -q -m 1 "Py_Initialize\|PyRun_SimpleString"; then
        DETECTED_STACKS+=("Python (PyInstaller / Embedded)")
    fi
    # Node.js / Electron
    if strings "$SEARCH_FILE" | grep -q -m 1 "node::Start\|process.versions.electron"; then
        DETECTED_STACKS+=("Node.js / Electron")
    fi
    # .NET / Mono
    if strings "$SEARCH_FILE" | grep -q -m 1 "mono_jit_init\|CoreCLR"; then
        DETECTED_STACKS+=(".NET / Mono")
    fi
    # Qt
    if strings "$SEARCH_FILE" | grep -q -m 1 "QApplication\|QtCore"; then
        DETECTED_STACKS+=("Qt (C++ Framework)")
    fi
    # Flutter
    if strings "$SEARCH_FILE" | grep -q -m 1 "FlutterEngine\|libflutter.dylib"; then
        DETECTED_STACKS+=("Flutter / Dart")
    fi

    if [[ ${#DETECTED_STACKS[@]} -gt 0 ]]; then
        echo "    Detected Stack Signature(s):"
        for stack in "${DETECTED_STACKS[@]}"; do
            echo "    ⭐ $stack"
        done
    else
        echo "    No distinct high-level runtime detected (Likely pure C/C++, stripped binary, or customized loader)."
    fi
fi

echo ""
echo "[6] Next Steps for Apple Silicon Native Rebuild"
echo "    1. Read SPEC_TEMPLATE: docs/en/SPEC_TEMPLATE.md or docs/kr/SPEC_TEMPLATE.md"
echo "    2. Use Room A prompt to dissect key entrypoints & protocol logic into SPEC.md"
echo "    3. Use Room B prompt with target: Swift 6 / SwiftUI (macOS 14+ arm64)"
echo "    4. Verify functionality using Phase 3 test harness"
echo "================================================================================"
