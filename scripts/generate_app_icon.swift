#!/usr/bin/env swift
// ==============================================================================
// REA-Silicon: Native macOS App Icon & Asset Generator
// Generates Big Sur style squircle icons with gradients, shadows, and symbols.
// Outputs .icns and complete AppIcon.appiconset for Xcode / Swift Packages.
// ==============================================================================

import Cocoa
import Foundation

struct IconGenerator {
    let appName: String
    let outputDir: URL
    let symbolText: String
    let primaryColorHex: String
    let secondaryColorHex: String

    init(appName: String, outputDir: URL, symbolText: String = "⚡", primaryColorHex: String = "#3B82F6", secondaryColorHex: String = "#1D4ED8") {
        self.appName = appName
        self.outputDir = outputDir
        self.symbolText = symbolText
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
    }

    private func color(from hex: String) -> NSColor {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") { cleanHex.removeFirst() }
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    func renderMasterImage(size: CGFloat = 1024) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            img.unlockFocus()
            return img
        }

        // Margin for macOS Big Sur icon shape (squircle)
        let margin = size * 0.1
        let rect = NSRect(x: margin, y: margin, width: size - (margin * 2), height: size - (margin * 2))
        let cornerRadius = rect.width * 0.225

        // 1. Drop shadow behind the squircle
        ctx.saveGState()
        let shadowColor = NSColor.black.withAlphaComponent(0.28).cgColor
        ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.025), blur: size * 0.05, color: shadowColor)

        let squirclePath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.black.withAlphaComponent(0.01).setFill()
        squirclePath.fill()
        ctx.restoreGState()

        // 2. Gradient background inside squircle
        ctx.saveGState()
        squirclePath.addClip()

        let startColor = color(from: primaryColorHex)
        let endColor = color(from: secondaryColorHex)
        if let gradient = NSGradient(starting: startColor, ending: endColor) {
            gradient.draw(in: rect, angle: 295)
        }

        // 3. Subtle inner highlight rim
        let rimPath = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: cornerRadius - 2, yRadius: cornerRadius - 2)
        rimPath.lineWidth = size * 0.004
        NSColor.white.withAlphaComponent(0.35).setStroke()
        rimPath.stroke()

        ctx.restoreGState()

        // 4. Render Center Symbol / Emoji / Text
        let fontScale: CGFloat = symbolText.count <= 2 ? 0.42 : 0.28
        let font = NSFont.systemFont(ofSize: size * fontScale, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
        ]

        let attrString = NSAttributedString(string: symbolText, attributes: attrs)
        let textSize = attrString.size()
        let textRect = NSRect(
            x: (size - textSize.width) / 2.0,
            y: (size - textSize.height) / 2.0 - (size * 0.01),
            width: textSize.width,
            height: textSize.height
        )

        // Text shadow for depth
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.015), blur: size * 0.02, color: NSColor.black.withAlphaComponent(0.4).cgColor)
        attrString.draw(in: textRect)
        ctx.restoreGState()

        img.unlockFocus()
        return img
    }

    func savePNG(image: NSImage, at url: URL, targetWidth: Int) {
        let resized = NSImage(size: NSSize(width: targetWidth, height: targetWidth))
        resized.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetWidth),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        resized.unlockFocus()

        if let tiff = resized.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let pngData = rep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: url)
        }
    }

    func generateAll() {
        let fileManager = FileManager.default
        let iconsetDir = outputDir.appendingPathComponent("AppIcon.iconset")
        try? fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

        print("[+] Rendering master 1024x1024 icon for '\(appName)' with symbol '\(symbolText)'...")
        let master = renderMasterImage(size: 1024)

        // Save master 1024 PNG
        let masterURL = outputDir.appendingPathComponent("icon_1024.png")
        savePNG(image: master, at: masterURL, targetWidth: 1024)

        // Dimensions needed for macOS iconset
        let sizes: [(String, Int)] = [
            ("icon_16x16.png", 16),
            ("icon_16x16@2x.png", 32),
            ("icon_32x32.png", 32),
            ("icon_32x32@2x.png", 64),
            ("icon_128x128.png", 128),
            ("icon_128x128@2x.png", 256),
            ("icon_256x256.png", 256),
            ("icon_256x256@2x.png", 512),
            ("icon_512x512.png", 512),
            ("icon_512x512@2x.png", 1024)
        ]

        for (filename, px) in sizes {
            let targetURL = iconsetDir.appendingPathComponent(filename)
            savePNG(image: master, at: targetURL, targetWidth: px)
        }

        // Convert to .icns using macOS iconutil
        let icnsURL = outputDir.appendingPathComponent("AppIcon.icns")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        proc.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
        try? proc.run()
        proc.waitUntilExit()

        if fileManager.fileExists(atPath: icnsURL.path) {
            print("✅ Successfully generated native macOS icon: \(icnsURL.path)")
            // Clean up temporary iconset directory
            try? fileManager.removeItem(at: iconsetDir)
        } else {
            print("⚠️ iconutil completed. Iconset available at: \(iconsetDir.path)")
        }
    }
}

// CLI Argument Parsing
let args = CommandLine.arguments
if args.count < 3 {
    print("Usage: \(args[0]) <AppName> <OutputDir> [SymbolOrEmoji] [PrimaryHex] [SecondaryHex]")
    print("Example: \(args[0]) Calcuroo ./Resources '🧮' '#10B981' '#047857'")
    exit(1)
}

let name = args[1]
let outPath = URL(fileURLWithPath: args[2])
let symbol = args.count > 3 ? args[3] : "⚡"
let c1 = args.count > 4 ? args[4] : "#6366F1"
let c2 = args.count > 5 ? args[5] : "#4338CA"

let gen = IconGenerator(appName: name, outputDir: outPath, symbolText: symbol, primaryColorHex: c1, secondaryColorHex: c2)
gen.generateAll()
