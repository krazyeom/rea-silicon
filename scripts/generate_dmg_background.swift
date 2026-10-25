#!/usr/bin/env swift
// ==============================================================================
// REA-Silicon: Project-Themed DMG Background Generator
// Renders high-resolution Retina (2x) background art for macOS DMG installers
// tailored to the project's unique brand colors, title, and identity.
//
// Usage:
//   ./scripts/generate_dmg_background.swift <AppName> <OutputDir> [Subtitle] [HexColor1] [HexColor2]
//
// Example:
//   ./scripts/generate_dmg_background.swift "Calcuroo" ./dist "Apple Silicon Native Calculator" "#10B981" "#047857"
// ==============================================================================

import Cocoa

// MARK: - Color Parser Helper
func parseColor(hex: String) -> NSColor {
    var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    if cleanHex.count == 3 {
        cleanHex = cleanHex.map { "\($0)\($0)" }.joined()
    }
    guard cleanHex.count == 6, let rgbValue = UInt64(cleanHex, radix: 16) else {
        return NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
    }
    let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
    let b = CGFloat(rgbValue & 0x0000FF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: 1.0)
}

// MARK: - CLI Argument Processing
let args = CommandLine.arguments
if args.count < 3 {
    print("""
    사용법: \(args[0]) <앱이름> <출력폴더> [부제/설명] [색상Hex1] [색상Hex2]
    예  시: \(args[0]) "Calcuroo" ./dist "Apple Silicon Native Calculator" "#10B981" "#047857"
    """)
    exit(1)
}

let appName = args[1]
let outputDir = args[2]
let subtitle = args.count > 3 && !args[3].isEmpty ? args[3] : "Apple Silicon Native Edition"
let hex1 = args.count > 4 && !args[4].isEmpty ? args[4] : "#3B82F6"
let hex2 = args.count > 5 && !args[5].isEmpty ? args[5] : "#1D4ED8"

let primaryColor = parseColor(hex: hex1)
let secondaryColor = parseColor(hex: hex2)

let width: CGFloat = 640
let height: CGFloat = 400
let scale: CGFloat = 2.0

let imgSize = NSSize(width: width * scale, height: height * scale)
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(imgSize.width),
    pixelsHigh: Int(imgSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    print("❌ 오류: NSBitmapImageRep 생성 실패")
    exit(1)
}
rep.size = NSSize(width: width, height: height)

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    print("❌ 오류: NSGraphicsContext 생성 실패")
    exit(1)
}
NSGraphicsContext.current = context

// 1. Sleek Modern Dark Backdrop
let canvasRect = NSRect(x: 0, y: 0, width: width, height: height)
let bgTop = NSColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1.0)
let bgBottom = NSColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1.0)
if let bgGradient = NSGradient(starting: bgBottom, ending: bgTop) {
    bgGradient.draw(in: canvasRect, angle: 90)
}

// 2. Ambient Themed Radial Glow
let glowCenter = NSPoint(x: width / 2, y: height * 0.55)
let glowRadius: CGFloat = 220
let glowPath = NSBezierPath(ovalIn: NSRect(
    x: glowCenter.x - glowRadius,
    y: glowCenter.y - glowRadius,
    width: glowRadius * 2,
    height: glowRadius * 2
))
let glowStart = primaryColor.withAlphaComponent(0.20)
let glowEnd = primaryColor.withAlphaComponent(0.0)
if let glowGradient = NSGradient(starting: glowStart, ending: glowEnd) {
    glowGradient.draw(in: glowPath, relativeCenterPosition: .zero)
}

// 3. Subtle Inner Border
let borderPath = NSBezierPath(roundedRect: canvasRect.insetBy(dx: 1, dy: 1), xRadius: 16, yRadius: 16)
NSColor(white: 1.0, alpha: 0.08).setStroke()
borderPath.lineWidth = 1.5
borderPath.stroke()

// 4. Header Titles (Top)
// App Title
let titleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
let titleParagraph = NSMutableParagraphStyle()
titleParagraph.alignment = .center
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor.white,
    .paragraphStyle: titleParagraph
]
let titleRect = NSRect(x: 30, y: height - 52, width: width - 60, height: 28)
(appName as NSString).draw(in: titleRect, withAttributes: titleAttrs)

// Subtitle
let subFont = NSFont.systemFont(ofSize: 12, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(white: 0.70, alpha: 1.0),
    .paragraphStyle: titleParagraph
]
let subRect = NSRect(x: 30, y: height - 74, width: width - 60, height: 20)
(subtitle as NSString).draw(in: subRect, withAttributes: subAttrs)

// 5. Left & Right Placement Guide Pods
// App Icon Zone: Center (160, 195) in macOS window coordinates
// In AppKit coords (origin bottom-left): y = 400 - 195 = 205
let leftCenter = NSPoint(x: 160, y: 195)
let rightCenter = NSPoint(x: 480, y: 195)
let podSize: CGFloat = 130

func drawPod(at center: NSPoint, label: String) {
    let rect = NSRect(x: center.x - podSize / 2, y: center.y - podSize / 2, width: podSize, height: podSize)
    let path = NSBezierPath(roundedRect: rect, xRadius: 28, yRadius: 28)
    
    // Fill
    NSColor(white: 1.0, alpha: 0.03).setFill()
    path.fill()
    
    // Dashed border
    let borderStroke = NSColor(white: 1.0, alpha: 0.12)
    borderStroke.setStroke()
    path.lineWidth = 1.5
    let pattern: [CGFloat] = [6, 4]
    path.setLineDash(pattern, count: 2, phase: 0)
    path.stroke()
}

drawPod(at: leftCenter, label: appName)
drawPod(at: rightCenter, label: "Applications")

// 6. Center Stylized Drag-and-Drop Arrow
let arrowY: CGFloat = 195
let arrowStartX: CGFloat = 240
let arrowEndX: CGFloat = 400

let arrowPath = NSBezierPath()
arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX, y: arrowY))
arrowPath.lineWidth = 3.5

// Arrow Head
let headSize: CGFloat = 12
arrowPath.move(to: NSPoint(x: arrowEndX - headSize, y: arrowY + headSize * 0.8))
arrowPath.line(to: NSPoint(x: arrowEndX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX - headSize, y: arrowY - headSize * 0.8))

NSGraphicsContext.saveGraphicsState()
primaryColor.withAlphaComponent(0.85).setStroke()
arrowPath.stroke()
NSGraphicsContext.restoreGraphicsState()

// 7. Center Instruction Badge
let badgeWidth: CGFloat = 170
let badgeHeight: CGFloat = 26
let badgeRect = NSRect(x: (width - badgeWidth) / 2, y: arrowY - 38, width: badgeWidth, height: badgeHeight)
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 13, yRadius: 13)

primaryColor.withAlphaComponent(0.18).setFill()
badgePath.fill()

primaryColor.withAlphaComponent(0.40).setStroke()
badgePath.lineWidth = 1.0
badgePath.stroke()

let badgeFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
let badgeAttrs: [NSAttributedString.Key: Any] = [
    .font: badgeFont,
    .foregroundColor: NSColor(white: 0.95, alpha: 1.0),
    .paragraphStyle: titleParagraph
]
let badgeText = "드래그하여 설치 ➔"
(badgeText as NSString).draw(in: NSRect(x: badgeRect.origin.x, y: badgeRect.origin.y + 5, width: badgeWidth, height: 18), withAttributes: badgeAttrs)

// 8. Footer Architecture Tag
let footFont = NSFont.systemFont(ofSize: 10, weight: .regular)
let footAttrs: [NSAttributedString.Key: Any] = [
    .font: footFont,
    .foregroundColor: NSColor(white: 0.45, alpha: 1.0),
    .paragraphStyle: titleParagraph
]
let footText = "Apple Silicon Native (arm64) • Swift 6"
(footText as NSString).draw(in: NSRect(x: 30, y: 16, width: width - 60, height: 16), withAttributes: footAttrs)

NSGraphicsContext.restoreGraphicsState()

// Ensure output directory exists
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let finalPath = (outputDir as NSString).appendingPathComponent("dmg_background.png")
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    print("❌ 오류: PNG 인코딩 실패")
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: finalPath))
    print("✅ 맞춤형 DMG 배경 생성 완료: \(finalPath)")
    print("   🎨 테마 색상: \(hex1) -> \(hex2)")
    print("   📐 해상도   : \(Int(width * scale))x\(Int(height * scale)) (@2x Retina)")
} catch {
    print("❌ 오류: 파일 쓰기 실패 (\(error))")
    exit(1)
}
