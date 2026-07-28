import AppKit
import ImageIO
import UniformTypeIdentifiers

private let pink = NSColor(calibratedRed: 0.94, green: 0.29, blue: 0.59, alpha: 1)
private let ink = NSColor(calibratedRed: 0.035, green: 0.039, blue: 0.06, alpha: 1)
private let panel = NSColor(calibratedWhite: 0.075, alpha: 0.97)
private let card = NSColor(calibratedWhite: 0.16, alpha: 1)
private let cardSoft = NSColor(calibratedWhite: 0.12, alpha: 1)
private let white = NSColor(calibratedWhite: 0.96, alpha: 1)
private let muted = NSColor(calibratedWhite: 0.66, alpha: 1)

private struct UIState {
    var preset = 0
    var intensity = 0.34
    var paper = true
    var focus = false
    var menuProgress = 0.0
    var cursor = CGPoint(x: 0, y: 0)
}

private final class DrawingView: NSView {
    let handler: (NSRect) -> Void
    override var isFlipped: Bool { true }

    init(size: CGSize, handler: @escaping (NSRect) -> Void) {
        self.handler = handler
        super.init(frame: NSRect(origin: .zero, size: size))
    }

    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) { handler(bounds) }
}

private func image(size: CGSize, draw: @escaping (NSRect) -> Void) -> NSImage {
    let view = DrawingView(size: size, handler: draw)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    view.cacheDisplay(in: view.bounds, to: rep)
    let result = NSImage(size: size)
    result.addRepresentation(rep)
    return result
}

private func savePNG(_ image: NSImage, path: String) {
    guard let data = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: data),
          let png = rep.representation(using: .png, properties: [:]) else { fatalError("PNG") }
    try! png.write(to: URL(fileURLWithPath: path))
}

private func cgImage(_ image: NSImage) -> CGImage {
    var rect = NSRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
}

private func saveGIF(_ frames: [NSImage], path: String, delay: Double) {
    let url = URL(fileURLWithPath: path) as CFURL
    let destination = CGImageDestinationCreateWithURL(url, UTType.gif.identifier as CFString, frames.count, nil)!
    CGImageDestinationSetProperties(destination, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
    ] as CFDictionary)
    for frame in frames {
        CGImageDestinationAddImage(destination, cgImage(frame), [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]
        ] as CFDictionary)
    }
    guard CGImageDestinationFinalize(destination) else { fatalError("GIF") }
}

private func rounded(_ rect: CGRect, radius: CGFloat, color: NSColor, stroke: NSColor? = nil, width: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    color.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = width
        path.stroke()
    }
}

private func text(
    _ value: String,
    x: CGFloat,
    y: CGFloat,
    size: CGFloat,
    color: NSColor = white,
    weight: NSFont.Weight = .regular,
    width: CGFloat = 1000,
    alignment: NSTextAlignment = .left
) {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    (value as NSString).draw(
        in: CGRect(x: x, y: y, width: width, height: size * 1.45),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    )
}

private func symbol(_ name: String, x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor = white) {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    let icon = base.withSymbolConfiguration(config) ?? base
    icon.draw(in: CGRect(x: x, y: y, width: size, height: size))
}

private func background(_ bounds: CGRect) {
    NSGradient(colors: [
        ink,
        NSColor(calibratedRed: 0.075, green: 0.045, blue: 0.085, alpha: 1),
        ink
    ])!.draw(in: bounds, angle: 0)
    NSColor(calibratedRed: 0.9, green: 0.17, blue: 0.48, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: CGRect(x: bounds.width * 0.45, y: -bounds.height * 0.35, width: bounds.width * 0.9, height: bounds.height * 1.7)).fill()
    let stars = [(0.08,0.18),(0.14,0.72),(0.22,0.34),(0.34,0.12),(0.48,0.81),(0.64,0.16),(0.78,0.74),(0.91,0.28)]
    for (sx, sy) in stars {
        NSColor.white.withAlphaComponent(0.22).setFill()
        NSBezierPath(ovalIn: CGRect(x: bounds.width * sx, y: bounds.height * sy, width: 2.2, height: 2.2)).fill()
    }
}

private func toggle(x: CGFloat, y: CGFloat, on: Bool, scale: CGFloat = 1) {
    rounded(CGRect(x: x, y: y, width: 52 * scale, height: 28 * scale), radius: 14 * scale, color: on ? pink : NSColor(calibratedWhite: 0.28, alpha: 1))
    let knobX = on ? x + 28 * scale : x + 4 * scale
    rounded(CGRect(x: knobX, y: y + 4 * scale, width: 20 * scale, height: 20 * scale), radius: 10 * scale, color: white)
}

private func controlButton(_ title: String, symbolName: String, rect: CGRect, selected: Bool) {
    rounded(rect, radius: 11, color: selected ? pink : card)
    symbol(symbolName, x: rect.midX - 9, y: rect.minY + 12, size: 18)
    text(title, x: rect.minX, y: rect.minY + 36, size: 13, weight: .semibold, width: rect.width, alignment: .center)
}

private func drawAppWindow(rect: CGRect, state: UIState, compact: Bool = false) {
    let s = rect.width / 760
    func X(_ v: CGFloat) -> CGFloat { rect.minX + v * s }
    func Y(_ v: CGFloat) -> CGFloat { rect.minY + v * s }
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: X(x), y: Y(y), width: w * s, height: h * s)
    }

    rounded(rect, radius: 20 * s, color: panel, stroke: NSColor.white.withAlphaComponent(0.22), width: 1)
    for (index, color) in [NSColor.systemRed, .systemYellow, .systemGreen].enumerated() {
        rounded(R(20 + CGFloat(index) * 25, 18, 13, 13), radius: 7 * s, color: color)
    }

    rounded(R(34, 60, 54, 54), radius: 14 * s, color: NSColor.black)
    let appIconPath = FileManager.default.currentDirectoryPath + "/Resources/AppIconLight1024.png"
    if let appIcon = NSImage(contentsOfFile: appIconPath) {
        appIcon.draw(in: R(34, 60, 54, 54))
    } else {
        text("◈", x: X(43), y: Y(65), size: 32 * s, weight: .bold, width: 36 * s, alignment: .center)
    }
    text("NightMode", x: X(106), y: Y(64), size: 27 * s, weight: .semibold)
    text("Night work, without the glare", x: X(106), y: Y(94), size: 13 * s, color: muted)
    symbol("gearshape", x: X(676), y: Y(70), size: 18 * s, color: muted)
    symbol("info.circle", x: X(716), y: Y(70), size: 18 * s, color: muted)

    rounded(R(34, 132, 692, 72), radius: 14 * s, color: cardSoft)
    symbol("display", x: X(54), y: Y(153), size: 28 * s)
    text("Обычный", x: X(98), y: Y(146), size: 18 * s, weight: .semibold)
    text("NightMode · яркость авто · только что", x: X(98), y: Y(174), size: 12 * s, color: muted)
    toggle(x: X(658), y: Y(154), on: true, scale: s)

    rounded(R(34, 218, 692, 50), radius: 12 * s, color: cardSoft)
    symbol("laptopcomputer", x: X(50), y: Y(233), size: 22 * s)
    text("Дисплей", x: X(84), y: Y(228), size: 14 * s, weight: .semibold)
    rounded(R(168, 228, 410, 31), radius: 7 * s, color: NSColor(calibratedWhite: 0.25, alpha: 1))
    text("Built-in Retina Display", x: X(182), y: Y(232), size: 13 * s)
    symbol("chevron.up.chevron.down", x: X(550), y: Y(235), size: 14 * s, color: pink)
    toggle(x: X(646), y: Y(229), on: true, scale: s)

    text("Режим", x: X(34), y: Y(282), size: 13 * s, color: muted, weight: .semibold)
    let modes = [("AI","sparkles"),("Работа","briefcase.fill"),("Чтение","book.fill"),("Ночь","circle.lefthalf.filled"),("Игры","gamecontroller.fill")]
    for (index, item) in modes.enumerated() {
        let modeSelected = index == (state.preset == 1 ? 2 : state.preset == 2 ? 1 : 0)
        let r = R(34 + CGFloat(index) * 139, 304, 128, 56)
        rounded(r, radius: 10 * s, color: modeSelected ? pink : card)
        symbol(item.1, x: r.midX - 8 * s, y: r.minY + 9 * s, size: 16 * s)
        text(item.0, x: r.minX, y: r.minY + 31 * s, size: 12 * s, weight: .semibold, width: r.width, alignment: .center)
    }

    text("Быстрые пресеты", x: X(34), y: Y(376), size: 13 * s, color: muted, weight: .semibold)
    let presets = [("Мягко","moon.stars"),("Чтение","book"),("Фокус","scope"),("Цвет","paintpalette")]
    for (index, item) in presets.enumerated() {
        let r = R(34 + CGFloat(index) * 173, 400, 158, 68)
        controlButton(item.0, symbolName: item.1, rect: r, selected: state.preset == index)
    }

    rounded(R(34, 486, 692, 78), radius: 13 * s, color: cardSoft)
    text("Сила эффекта", x: X(52), y: Y(500), size: 15 * s, weight: .semibold)
    text("\(Int(state.intensity * 100))%", x: X(650), y: Y(500), size: 14 * s, color: muted, width: 55 * s, alignment: .right)
    rounded(R(56, 538, 624, 5), radius: 3 * s, color: NSColor(calibratedWhite: 0.29, alpha: 1))
    rounded(R(56, 538, 624 * state.intensity, 5), radius: 3 * s, color: pink)
    rounded(R(48 + 624 * state.intensity, 529, 22, 22), radius: 11 * s, color: white)

    rounded(R(34, 580, 622, 54), radius: 11 * s, color: NSColor(calibratedWhite: 0.31, alpha: 1))
    symbol("pause.fill", x: X(262), y: Y(598), size: 15 * s)
    text("Приостановить", x: X(286), y: Y(596), size: 16 * s, weight: .semibold)
    rounded(R(668, 586, 58, 42), radius: 10 * s, color: cardSoft)
    symbol("timer", x: X(681), y: Y(596), size: 18 * s)
    symbol("chevron.down", x: X(707), y: Y(602), size: 9 * s)

    rounded(R(34, 650, 335, 66), radius: 12 * s, color: cardSoft)
    symbol("doc.text", x: X(52), y: Y(670), size: 22 * s)
    text("Paper Mode", x: X(86), y: Y(661), size: 14 * s, weight: .semibold)
    text("Мягче белые страницы", x: X(86), y: Y(686), size: 11 * s, color: muted)
    toggle(x: X(300), y: Y(669), on: state.paper, scale: s)

    rounded(R(383, 650, 343, 66), radius: 12 * s, color: cardSoft)
    symbol("scope", x: X(401), y: Y(670), size: 22 * s)
    text("Фокус по краям", x: X(435), y: Y(661), size: 14 * s, weight: .semibold)
    text("Меньше отвлечений", x: X(435), y: Y(686), size: 11 * s, color: muted)
    toggle(x: X(656), y: Y(669), on: state.focus, scale: s)

    symbol("keyboard", x: X(38), y: Y(735), size: 13 * s, color: muted)
    text("⌃⌥⌘N · можно изменить", x: X(58), y: Y(733), size: 10 * s, color: muted)
    text("GitHub  ·  Telegram  ·  @selfztt1337", x: X(248), y: Y(733), size: 10 * s, color: muted, width: 260 * s, alignment: .center)
    text("Настройки", x: X(638), y: Y(733), size: 11 * s, color: white)

    if state.menuProgress > 0 {
        let progress = state.menuProgress
        let menuHeight = 180 * s * progress
        let menuRect = CGRect(x: X(570), y: Y(568), width: 185 * s, height: menuHeight)
        rounded(menuRect, radius: 13 * s, color: NSColor(calibratedWhite: 0.10, alpha: 0.98), stroke: NSColor.white.withAlphaComponent(0.22))
        if progress > 0.6 {
            let labels = ["На 15 минут", "На 30 минут", "На 1 час", "На 2 часа", "До завтра, 09:00"]
            for (index, label) in labels.enumerated() {
                text(label, x: X(588), y: Y(584 + CGFloat(index) * 29), size: 12 * s)
            }
        }
    }

    if state.cursor != .zero {
        symbol("cursorarrow", x: rect.minX + state.cursor.x * s, y: rect.minY + state.cursor.y * s, size: 27 * s, color: pink)
    }
}

private func hero() -> NSImage {
    image(size: CGSize(width: 1800, height: 1000)) { bounds in
        background(bounds)
        text("NightMode", x: 100, y: 342, size: 67, weight: .bold)
        text("Спокойный экран для долгой работы", x: 102, y: 440, size: 29, color: muted)
        text("вечером и ночью.", x: 102, y: 482, size: 29, color: muted)
        text("AI Auto  ·  Multi-display  ·  Smart Pause", x: 102, y: 560, size: 18, weight: .semibold)
        text("Custom Hotkey  ·  Paper Mode  ·  Focus Edges", x: 102, y: 592, size: 18, weight: .semibold)
        drawAppWindow(
            rect: CGRect(x: 735, y: 55, width: 790, height: 820),
            state: UIState(preset: 2, intensity: 0.52, paper: false, focus: true)
        )
    }
}

private func demoFrame(_ progress: Double) -> NSImage {
    var state = UIState()
    if progress < 0.28 {
        state.preset = 0
        state.intensity = 0.34
        state.paper = true
        state.cursor = CGPoint(x: 190 + 165 * (progress / 0.28), y: 420)
    } else if progress < 0.56 {
        let local = (progress - 0.28) / 0.28
        state.preset = 1
        state.intensity = 0.34 + (0.46 - 0.34) * local
        state.paper = true
        state.cursor = CGPoint(x: 355 + 165 * local, y: 420)
    } else if progress < 0.80 {
        let local = (progress - 0.56) / 0.24
        state.preset = 2
        state.intensity = 0.46 + (0.52 - 0.46) * local
        state.paper = local < 0.45
        state.focus = local > 0.35
        state.cursor = CGPoint(x: 520 + 180 * local, y: 420 + 165 * local)
    } else {
        let local = (progress - 0.80) / 0.20
        state.preset = 2
        state.intensity = 0.52
        state.focus = true
        state.cursor = CGPoint(x: 690, y: 600)
        state.menuProgress = min(1, local * 1.5)
    }
    return image(size: CGSize(width: 1200, height: 820)) { bounds in
        background(bounds)
        drawAppWindow(rect: CGRect(x: 220, y: 22, width: 760, height: 770), state: state)
    }
}

private func comfortFrame(focus: Bool) -> NSImage {
    image(size: CGSize(width: 1200, height: 760)) { bounds in
        background(bounds)
        text(focus ? "Глубокий фокус" : "Долгое чтение", x: 70, y: 70, size: 42, weight: .bold)
        text(
            focus ? "Спокойный центр, меньше отвлечений." : "Мягкий фон без лишнего контраста.",
            x: 72, y: 130, size: 18, color: muted, width: 340
        )
        let state = UIState(preset: focus ? 2 : 1, intensity: focus ? 0.52 : 0.46, paper: !focus, focus: focus)
        drawAppWindow(rect: CGRect(x: 445, y: 30, width: 650, height: 660), state: state, compact: true)
    }
}

private func featureOverview() -> NSImage {
    image(size: CGSize(width: 1600, height: 900)) { bounds in
        background(bounds)
        text("Всё важное —", x: 80, y: 66, size: 44, weight: .bold, width: 540)
        text("под рукой", x: 80, y: 116, size: 44, weight: .bold, width: 540)
        text("Новые функции в одном спокойном потоке.", x: 82, y: 172, size: 21, color: muted, width: 530)

        let items = [
            ("display.2", "Профили дисплеев", "Режим и эффект сохраняются отдельно"),
            ("clock.badge.checkmark", "Умное расписание", "По времени или от заката до рассвета"),
            ("slider.horizontal.3", "Свои пресеты", "До пяти сценариев с предпросмотром"),
            ("keyboard", "Хоткей и Smart Pause", "Своя клавиша и безопасная пауза")
        ]
        for (index, item) in items.enumerated() {
            let y = 220 + CGFloat(index) * 145
            rounded(CGRect(x: 82, y: y, width: 520, height: 112), radius: 18, color: cardSoft, stroke: NSColor.white.withAlphaComponent(0.12))
            rounded(CGRect(x: 106, y: y + 20, width: 72, height: 72), radius: 18, color: card)
            symbol(item.0, x: 126, y: y + 40, size: 32)
            text(item.1, x: 202, y: y + 22, size: 22, weight: .semibold)
            text(item.2, x: 202, y: y + 60, size: 15, color: muted)
        }

        var state = UIState(preset: 1, intensity: 0.46, paper: true, focus: false)
        state.menuProgress = 1
        state.cursor = CGPoint(x: 690, y: 600)
        drawAppWindow(rect: CGRect(x: 700, y: 48, width: 790, height: 800), state: state)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
savePNG(hero(), path: root.appendingPathComponent("Docs/showcase/hero.png").path)
let demoFrames = (0..<48).map { demoFrame(Double($0) / 47.0) }
saveGIF(demoFrames, path: root.appendingPathComponent("Docs/assets/interface-current.gif").path, delay: 0.085)
saveGIF(
    [comfortFrame(focus: false), comfortFrame(focus: true)],
    path: root.appendingPathComponent("Docs/showcase/comfort-modes.gif").path,
    delay: 1.8
)
savePNG(featureOverview(), path: root.appendingPathComponent("Docs/showcase/smart-pause.png").path)
