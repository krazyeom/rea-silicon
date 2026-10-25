# Apple Silicon (macOS arm64) 네이티브 아키텍처 및 재개발 가이드

본 문서는 기존의 레거시 바이너리 또는 크로스 플랫폼 애플리케이션 번들을 역공학하여, 최신 **Swift 6, SwiftUI 및 AppKit 기반의 초고성능 macOS Apple Silicon (`arm64`) 네이티브 애플리케이션**으로 재개발하기 위한 기술 청사진과 실행 지침을 제공합니다.

---

## 1. 재개발 목표 및 아키텍처 원칙

Apple Silicon 네이티브 재개발 시 준수해야 하는 4대 핵심 원칙:

1. **에뮬레이션 오버헤드 제로화 (Zero Overhead)**: Rosetta 2 변환 지연과 메모리 팽창을 원천 배제하고, 순수 `arm64`(또는 유니버설 `arm64` + `x86_64`) 네이티브 바이너리로 빌드합니다.
2. **네이티브 UX 및 전력 효율 극대화**: Electron, Chromium, Python PyInstaller, JVM 등 무거운 런타임을 제거하고 가볍고 전력 소모가 적은 macOS 표준 UI 컴포넌트(`SwiftUI`, `AppKit`, `MenuBarExtra`)로 전환합니다.
3. **모던 Swift 동시성 (Strict Concurrency)**: 레거시 스레드 잠금이나 이벤트 루프 래퍼 대신, Swift 6의 엄격한 동시성 모델(`Sendable`, `actor`, `async/await`, 구조화된 동시성)을 채택합니다.
4. **클린룸 원칙 준수**: 역공학에서 도출된 블랙박스 기능 명세서(`SPEC.md`)만을 기반으로 재작성하여, 원본 코드의 지적 재산권 침해를 원천 방지합니다.

---

## 2. 기존 기술 스택별 Mac Silicon Native 전환 매트릭스

| 원본 앱의 기술 스택 | 주요 문제점 및 한계 | macOS Silicon 권장 타깃 | 전환 시 Apple Silicon 특화 이점 |
| :--- | :--- | :--- | :--- |
| **Electron / Webpack** (.asar, Node.js) | 높은 메모리 점유(유휴 시에도 300MB+), 느린 실행, 배터리 소모 | **SwiftUI + Swift Concurrency** (필요시 WKWebView 부분 연동) | 메모리 10MB 미만, 즉각적인 앱 기동, 네이티브 다크모드 및 키체인 연동 |
| **Qt / wxWidgets (C++)** | 거대한 동적 라이브러리 용량, macOS 비표준 창 디자인 | **SwiftUI + AppKit** | macOS 기본 창 스타일 및 Liquid Retina / ProMotion 고주사율 완벽 대응 |
| **Python (PyInstaller / py2app)** | 파이썬 인터프리터 통째 번들링, 런타임 타입 에러 취약 | **Swift 6 Native CLI / App** | AOT(Ahead-Of-Time) 네이티브 머신 코드 컴파일, 컴파일 타임 타입 검증 |
| **Go / Rust CLI** | Go 런타임 오버헤드, Apple 생태계 API 연동 제약 | **Swift 6 CLI (`swift-argument-parser`)** | macOS 보안(Keychain, Security), 네트워크, 시스템 구성 API 즉시 호출 |
| **.NET / C# (Mono/CoreCLR)** | 무거운 JIT 런타임, GC 프리징 현상 | **Swift 6 + SwiftData / Codable** | ARC(Automatic Reference Counting) 기반 무지연 처리, UMA 메모리 대역폭 활용 |

---

## 3. macOS 환경에서의 역공학 및 바이너리 기술 스택 분석

### 3.1 빠른 진단 스크립트 실행
저장소에 내장된 자동 진단 도구를 실행합니다:
```bash
./scripts/inspect_target.sh /경로/대상파일_또는_앱.app
```

### 3.2 핵심 macOS 분석 명령어 정리

| 명령어 | 분석 용도 |
| :--- | :--- |
| `lipo -info <바이너리>` | Mach-O 지원 아키텍처 슬라이스 확인 (x86_64, arm64, arm64e) |
| `otool -L <바이너리>` | 동적 링크 라이브러리 및 macOS 프레임워크 의존성 확인 |
| `codesign -dv --verbose=4 <바이너리>` | 코드 서명 상태, 번들 식별자(ID), Entitlements 권한 확인 |
| `nm -gU <바이너리>` | 익스포트된 글로벌 심볼 목록 덤프 |
| `strings -a <바이너리> \| grep -E "패턴"` | 엔드포인트 URL, 암호화 알고리즘 식별자, 매직 헤더 탐색 |
| `plutil -p Info.plist` | macOS App 번들의 메타데이터 및 권한 설정 파싱 |

---

## 4. Mac Silicon Native 프로젝트 아키텍처 유형

### 아키텍처 A: 고성능 네이티브 CLI 도구
백엔드 도구, 데몬 유틸리티, 데이터 변환 파이프라인:
```text
my-cli-tool/
├── Package.swift
└── Sources/
    └── main.swift (또는 ArgumentParser 기반 엔트리포인트)
```
**`Package.swift` 구성 예시:**
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

### 아키텍처 B: 모던 SwiftUI 네이티브 macOS GUI 앱
데스크톱 인터페이스를 갖춘 풀 애플리케이션:
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

### 아키텍처 C: 메뉴바 상주형 유틸리티 / 백그라운드 서비스
상태 바에 상주하며 상시 동작하는 초경량 유틸리티:
```swift
import SwiftUI

@main
struct MenuBarUtilityApp: App {
    var body: some Scene {
        MenuBarExtra("StatusTool", systemImage: "cpu.fill") {
            Button("작업 실행") { executeAction() }
            Divider()
            Button("종료") { NSApplication.shared.terminate(nil) }
        }
    }
}
```

---

## 5. Apple Silicon 빌드 및 서명 절차

### 5.1 네이티브 컴파일
```bash
# Swift Package Manager를 통한 릴리즈 빌드
arch -arm64 swift build -c release --triple arm64-apple-macosx14.0

# 단일 파일 직접 컴파일
arch -arm64 swiftc -O -target arm64-apple-macosx14.0 main.swift -o my_tool_arm64
```

### 5.2 Ad-hoc 코드 서명 (Apple Silicon 필수 요건)
Apple Silicon 커널은 실행 전 모든 arm64 바이너리에 유효한 코드 서명을 요구합니다:
```bash
codesign --force --deep --sign - ./build/my_tool_arm64
```

### 5.3 자동 빌드 및 검증
내장 검증 스크립트를 실행합니다:
```bash
./scripts/verify_build.sh <프로젝트_디렉토리>

# 빌드 검증과 동시에 배포용 DMG까지 한 번에 생성:
./scripts/verify_build.sh <프로젝트_디렉토리> --dmg
```

---

## 6. 배포용 Drag-and-Drop DMG 생성 (/Applications 간편 설치)

최종 빌드된 macOS 애플리케이션 번들(`.app`)을 일반 사용자가 마우스 드래그 한 번으로 `/Applications` 폴더로 복사하여 설치할 수 있도록 표준 Apple UDZO 압축 `.dmg` 디스크 이미지를 제작합니다.

### 6.1 DMG 자동 생성 스크립트 실행
```bash
# 1. 빌드된 .app 번들로부터 생성
./scripts/create_dmg.sh ./build/Calcuroo.app

# 2. Swift 프로젝트 경로를 직접 전달 (자동 빌드 + 번들링 + DMG 생성)
./scripts/create_dmg.sh ./projects/Calcuroo

# 3. 출력 경로 및 아이콘 지정
./scripts/create_dmg.sh ./build/Calcuroo.app ./dist/Calcuroo-1.0.0-arm64.dmg --icon ./Resources/AppIcon.icns
```

### 6.2 DMG 패키징 내부 동작
1. **.app 번들 구조화**: `Contents/MacOS`, `Contents/Resources`, `Info.plist`, `PkgInfo` 자동 구성.
2. **Apple Silicon Ad-hoc 서명**: Gatekeeper 및 macOS 커널 무결성 통과를 위한 `codesign` 적용.
3. **`/Applications` 심볼릭 링크 탑재**: 사용자가 디스크 이미지를 열었을 때 앱 아이콘을 Applications 폴더 아이콘으로 바로 끌어다 놓을 수 있는 바로가기 탑재.
4. **볼륨 아이콘 적용**: `AppIcon.icns`가 제공되면 마운트된 디스크 이미지 볼륨 자체의 아이콘으로 커스텀 지정.
5. **UDZO 압축 & 무결성 검증**: `hdiutil`을 통해 고압축 읽기 전용 이미지 생성 후 체크섬 무결성 검증.
