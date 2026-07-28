import AppKit

private let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources", isDirectory: true)
private let canvasSize = CGSize(width: 1024, height: 1024)

private func makeIcon(background: NSColor, foreground: NSColor) -> NSImage {
    let image = NSImage(size: canvasSize)
    image.lockFocus()
    defer { image.unlockFocus() }

    let bounds = NSRect(origin: .zero, size: canvasSize)
    background.setFill()
    // macOS icons use a generous optical safe area inside the 1024 px source.
    NSBezierPath(roundedRect: bounds.insetBy(dx: 96, dy: 96), xRadius: 184, yRadius: 184).fill()

    // Crescent: two circles with a clean, intentional negative-space cutout.
    foreground.setFill()
    NSBezierPath(ovalIn: NSRect(x: 437, y: 654, width: 150, height: 150)).fill()
    background.setFill()
    NSBezierPath(ovalIn: NSRect(x: 472, y: 687, width: 150, height: 150)).fill()
    foreground.setFill()

    // Eyelid: a single tapered curve, kept visibly separate from the moon.
    let eyelid = NSBezierPath()
    eyelid.move(to: NSPoint(x: 264, y: 394))
    eyelid.curve(
        to: NSPoint(x: 760, y: 394),
        controlPoint1: NSPoint(x: 395, y: 550),
        controlPoint2: NSPoint(x: 629, y: 550)
    )
    eyelid.curve(
        to: NSPoint(x: 264, y: 394),
        controlPoint1: NSPoint(x: 618, y: 501),
        controlPoint2: NSPoint(x: 406, y: 501)
    )
    eyelid.fill()

    NSBezierPath(ovalIn: NSRect(x: 457, y: 252, width: 110, height: 110)).fill()
    return image
}

private func writePNG(_ image: NSImage, named name: String) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try png.write(to: outputDirectory.appendingPathComponent(name), options: .atomic)
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
try writePNG(
    makeIcon(background: NSColor(calibratedWhite: 0.97, alpha: 1), foreground: .black),
    named: "AppIconLight1024.png"
)
try writePNG(
    makeIcon(background: NSColor(calibratedWhite: 0.035, alpha: 1), foreground: .white),
    named: "AppIconDark1024.png"
)
// The default public icon stays readable in README, Finder and Dock.
try writePNG(
    makeIcon(background: NSColor(calibratedWhite: 0.97, alpha: 1), foreground: .black),
    named: "AppIcon1024.png"
)

print("Generated light and dark 1024×1024 app icons in Resources/")
