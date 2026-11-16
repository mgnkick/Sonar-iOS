import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: GenerateAppIcon.swift <output-png>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let viewport: CGFloat = 108
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
) else {
    fputs("Could not create icon bitmap context.\n", stderr)
    exit(1)
}

context.translateBy(x: 0, y: CGFloat(size))
context.scaleBy(x: CGFloat(size) / viewport, y: -CGFloat(size) / viewport)

func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
}

func stroke(_ path: (CGContext) -> Void, color: CGColor, width: CGFloat) {
    context.beginPath()
    path(context)
    context.setStrokeColor(color)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
}

func fillCircle(x: CGFloat, y: CGFloat, radius: CGFloat, color: CGColor) {
    context.beginPath()
    context.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
    context.setFillColor(color)
    context.fillPath()
}

// Android adaptive-icon background: res/values/colors.xml (#0F172A).
context.setFillColor(rgb(15, 23, 42))
context.fill(CGRect(x: 0, y: 0, width: viewport, height: viewport))

// Android foreground vector paths: res/drawable/ic_launcher_foreground.xml.
stroke({ path in
    path.move(to: CGPoint(x: 16, y: 31))
    path.addCurve(to: CGPoint(x: 92, y: 31),
                  control1: CGPoint(x: 37, y: 12),
                  control2: CGPoint(x: 71, y: 12))
}, color: rgb(0, 221, 244), width: 8)

stroke({ path in
    path.move(to: CGPoint(x: 25, y: 45))
    path.addCurve(to: CGPoint(x: 83, y: 45),
                  control1: CGPoint(x: 42, y: 30),
                  control2: CGPoint(x: 66, y: 30))
}, color: rgb(0, 184, 255), width: 8)

stroke({ path in
    path.move(to: CGPoint(x: 36, y: 58))
    path.addCurve(to: CGPoint(x: 62, y: 53),
                  control1: CGPoint(x: 44, y: 51),
                  control2: CGPoint(x: 54, y: 49))
}, color: rgb(0, 221, 244), width: 8)

stroke({ path in
    path.move(to: CGPoint(x: 76, y: 77))
    path.addLine(to: CGPoint(x: 91, y: 92))
}, color: rgb(255, 255, 255), width: 7)

context.beginPath()
context.addEllipse(in: CGRect(x: 47, y: 38, width: 34, height: 34))
context.setStrokeColor(rgb(255, 255, 255))
context.setLineWidth(7)
context.strokePath()

fillCircle(x: 64, y: 55, radius: 8, color: rgb(0, 201, 242))

guard let image = context.makeImage() else {
    fputs("Could not create final icon image.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("Could not create PNG destination.\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write PNG icon.\n", stderr)
    exit(1)
}
print("Generated Android-matched WiFi Sonar AppIcon at \(outputURL.path)")
