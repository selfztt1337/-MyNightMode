import AppKit
import Combine
import CoreImage
import QuartzCore

@MainActor
final class OverlayController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var activeProfile: ActiveProfile = .neutral
    @Published private(set) var displayBrightness: Double?
    @Published private(set) var activeAppName = "macOS"
    @Published private(set) var sessionMinutes: Int = 0

    private let settings: SettingsStore
    private let brightnessReader = DisplayBrightnessReader()
    private let classifier = AppClassifier()
    private let adaptiveEngine = AdaptiveEngine()
    private var panels: [PassiveOverlayPanel] = []
    private var timer: Timer?
    private var subscriptions = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []
    private var sessionStartedAt = Date()

    init(settings: SettingsStore) {
        self.settings = settings

        Publishers.CombineLatest4(settings.$userMode, settings.$intensity, settings.$paperMode, settings.$focusEdges)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _, _ in self?.refreshNow() }
            .store(in: &subscriptions)

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshNow() }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.rebuildPanels() }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.hidePanels() }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshNow() }
        })
    }

    deinit {
        timer?.invalidate()
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func start() {
        guard !isRunning else { refreshNow(); return }
        isRunning = true
        sessionStartedAt = Date()
        rebuildPanels()
        refreshNow()

        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshNow() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        panels.forEach { $0.orderOut(nil); $0.close() }
        panels.removeAll()
        isRunning = false
        sessionMinutes = 0
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func rebuildPanels() {
        panels.forEach { $0.orderOut(nil); $0.close() }
        panels = NSScreen.screens.map(makePanel)
        if isRunning {
            panels.forEach { $0.orderFrontRegardless() }
            applyAppearance()
        }
    }

    private func hidePanels() {
        panels.forEach { $0.orderOut(nil) }
    }

    private func makePanel(for screen: NSScreen) -> PassiveOverlayPanel {
        let panel = PassiveOverlayPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.sharingType = .none
        panel.becomesKeyOnlyIfNeeded = false
        panel.contentView = OverlayView(frame: CGRect(origin: .zero, size: screen.frame.size))
        return panel
    }

    private func refreshNow() {
        guard isRunning else { return }
        let app = NSWorkspace.shared.frontmostApplication
        activeAppName = app?.localizedName ?? "macOS"
        displayBrightness = brightnessReader.currentBrightness()
        sessionMinutes = max(0, Int(Date().timeIntervalSince(sessionStartedAt) / 60.0))

        switch settings.userMode {
        case .auto: activeProfile = classifier.profile(for: app)
        case .work: activeProfile = .work
        case .read: activeProfile = .reading
        case .night: activeProfile = .night
        case .play: activeProfile = .gaming
        }
        applyAppearance()
    }

    private func applyAppearance() {
        guard isRunning else { return }
        let appearance = adaptiveEngine.appearance(
            profile: activeProfile,
            intensity: settings.intensity,
            displayBrightness: displayBrightness,
            sessionMinutes: Double(sessionMinutes),
            paperEnabled: settings.paperMode,
            focusEdgesEnabled: settings.focusEdges,
            hour: Calendar.current.component(.hour, from: Date())
        )

        let color = NSColor(
            calibratedRed: appearance.red,
            green: appearance.green,
            blue: appearance.blue,
            alpha: 1.0
        )

        for panel in panels {
            guard let view = panel.contentView as? OverlayView else { continue }
            view.apply(color: color, alpha: appearance.alpha, paperOpacity: appearance.paperOpacity, edgeOpacity: appearance.edgeOpacity)
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }
}

private final class PassiveOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class OverlayView: NSView {
    private let tintLayer = CALayer()
    private let paperLayer = CALayer()
    private let edgeLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        guard let root = layer else { return }

        tintLayer.frame = bounds
        tintLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        root.addSublayer(tintLayer)

        paperLayer.frame = bounds
        paperLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        paperLayer.contentsGravity = .resizeAspectFill
        paperLayer.compositingFilter = "softLightBlendMode"
        paperLayer.contents = Self.makePaperTexture()
        root.addSublayer(paperLayer)

        edgeLayer.type = .radial
        edgeLayer.frame = bounds
        edgeLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        edgeLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        edgeLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        edgeLayer.locations = [0.0, 0.58, 1.0]
        edgeLayer.colors = [
            NSColor.clear.cgColor,
            NSColor.clear.cgColor,
            NSColor.black.cgColor
        ]
        edgeLayer.opacity = 0
        root.addSublayer(edgeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(color: NSColor, alpha: Double, paperOpacity: Double, edgeOpacity: Double) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.28)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        tintLayer.backgroundColor = color.withAlphaComponent(alpha).cgColor
        paperLayer.opacity = Float(paperOpacity)
        edgeLayer.opacity = Float(edgeOpacity)
        CATransaction.commit()
    }

    private static func makePaperTexture() -> CGImage? {
        guard let random = CIFilter(name: "CIRandomGenerator")?.outputImage else { return nil }
        let crop = random.cropped(to: CGRect(x: 0, y: 0, width: 512, height: 512))
        let controls = CIFilter(name: "CIColorControls")
        controls?.setValue(crop, forKey: kCIInputImageKey)
        controls?.setValue(0.0, forKey: kCIInputSaturationKey)
        controls?.setValue(0.12, forKey: kCIInputContrastKey)
        controls?.setValue(-0.44, forKey: kCIInputBrightnessKey)
        guard let output = controls?.outputImage else { return nil }
        return CIContext(options: [.useSoftwareRenderer: false]).createCGImage(output, from: output.extent)
    }
}
