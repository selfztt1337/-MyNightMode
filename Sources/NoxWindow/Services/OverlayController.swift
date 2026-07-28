import AppKit
import Combine
import CoreGraphics
import CoreImage
import QuartzCore

@MainActor
final class OverlayController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var activeProfile: ActiveProfile = .neutral
    @Published private(set) var automaticProfile: ActiveProfile = .neutral
    @Published private(set) var displayBrightness: Double?
    @Published private(set) var activeAppName = "macOS"
    @Published private(set) var sessionMinutes: Int = 0
    @Published private(set) var displays: [DisplayInfo] = []

    private let settings: SettingsStore
    private let brightnessReader = DisplayBrightnessReader()
    private let classifier = AppClassifier()
    private let adaptiveEngine = AdaptiveEngine()
    private var panels: [String: PassiveOverlayPanel] = [:]
    private var timer: Timer?
    private var subscriptions = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []
    private var sessionStartedAt = Date()
    private var previewConfiguration: (displayID: String, value: DisplayConfiguration)?
    private var previewTask: Task<Void, Never>?
    private var previewStartedProtection = false

    init(settings: SettingsStore) {
        self.settings = settings

        Publishers.CombineLatest4(settings.$userMode, settings.$intensity, settings.$paperMode, settings.$focusEdges)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _, _ in self?.refreshNow() }
            .store(in: &subscriptions)

        settings.$displayConfigurations
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshNow() }
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
            Task { @MainActor in
                guard let self else { return }
                self.isRunning ? self.rebuildPanels() : self.refreshDisplayList()
            }
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
            Task { @MainActor in
                guard let self else { return }
                self.isRunning ? self.rebuildPanels() : self.refreshDisplayList()
            }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isRunning ? self.rebuildPanels() : self.refreshDisplayList()
            }
        })

        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshNow() }
        })

        refreshDisplayList()
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

        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshNow() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        previewTask?.cancel()
        previewTask = nil
        previewConfiguration = nil
        previewStartedProtection = false
        timer?.invalidate()
        timer = nil
        panels.values.forEach { $0.orderOut(nil); $0.close() }
        panels.removeAll()
        isRunning = false
        sessionMinutes = 0
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func preview(
        _ configuration: DisplayConfiguration,
        on displayID: String,
        duration: TimeInterval = 8
    ) {
        guard duration > 0 else { return }
        previewTask?.cancel()
        if !isRunning {
            previewStartedProtection = true
            start()
        }

        var preview = configuration
        preview.isEnabled = true
        previewConfiguration = (displayID, preview)
        refreshNow()

        previewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                let shouldStop = self.previewStartedProtection
                self.previewConfiguration = nil
                self.previewTask = nil
                self.previewStartedProtection = false
                if shouldStop {
                    self.stop()
                } else {
                    self.refreshNow()
                }
            }
        }
    }

    func diagnostics() -> [DisplayDiagnostic] {
        NSScreen.screens.map { screen in
            let id = Self.identifier(for: screen)
            let panelFrame = panels[id]?.frame
            return DisplayDiagnostic(
                id: id,
                name: screen.localizedName,
                frame: Self.rectDescription(screen.frame),
                visibleFrame: Self.rectDescription(screen.visibleFrame),
                scaleFactor: screen.backingScaleFactor,
                overlayFrame: panelFrame.map(Self.rectDescription),
                overlayIsVisible: panels[id]?.isVisible == true,
                coversFullFrame: panelFrame.map {
                    DisplayGeometry.fullyCovers(overlay: $0, display: screen.frame)
                } ?? false
            )
        }
    }

    func highlightDisplays() {
        for screen in NSScreen.screens {
            let panel = DiagnosticOverlayPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            panel.setFrame(screen.frame, display: false)
            panel.level = .floating
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.contentView = DiagnosticHighlightView(
                frame: CGRect(origin: .zero, size: screen.frame.size),
                displayName: screen.localizedName
            )
            panel.orderFrontRegardless()

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                panel.orderOut(nil)
                panel.close()
            }
        }
    }

    private func rebuildPanels() {
        panels.values.forEach { $0.orderOut(nil); $0.close() }
        panels.removeAll()
        refreshDisplayList()
        for screen in NSScreen.screens {
            panels[Self.identifier(for: screen)] = makePanel(for: screen)
        }
        if isRunning {
            applyAppearance()
        }
    }

    private func hidePanels() {
        panels.values.forEach { $0.orderOut(nil) }
    }

    private func makePanel(for screen: NSScreen) -> PassiveOverlayPanel {
        let panel = PassiveOverlayPanel(
            contentRect: CGRect(origin: .zero, size: screen.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        panel.setFrame(screen.frame, display: false)
        // Stay above application windows without covering or changing the Dock,
        // menu bar, notifications, or other system-owned UI.
        panel.level = .floating
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
        let overlayView = OverlayView(frame: panel.contentLayoutRect)
        overlayView.autoresizingMask = [.width, .height]
        panel.contentView = overlayView
        panel.setFrame(screen.frame, display: false)
        return panel
    }

    private func refreshNow() {
        guard isRunning else { return }
        let app = NSWorkspace.shared.frontmostApplication
        let automaticProfile = classifier.profile(for: app)
        self.automaticProfile = automaticProfile
        activeAppName = app?.localizedName ?? "macOS"
        let mainDisplayID = NSScreen.main.flatMap(Self.displayID(for:))
        displayBrightness = brightnessReader.currentBrightness(for: mainDisplayID)
        sessionMinutes = max(0, Int(Date().timeIntervalSince(sessionStartedAt) / 60.0))

        let mainMode = NSScreen.main
            .map(Self.identifier(for:))
            .map(settings.displayConfiguration(for:))?
            .mode ?? settings.userMode
        activeProfile = profile(for: mainMode, automaticProfile: automaticProfile)
        applyAppearance(for: app, automaticProfile: automaticProfile)
    }

    private func applyAppearance(
        for app: NSRunningApplication? = NSWorkspace.shared.frontmostApplication,
        automaticProfile: ActiveProfile? = nil
    ) {
        guard isRunning else { return }
        let automaticProfile = automaticProfile ?? classifier.profile(for: app)
        let hour = Calendar.current.component(.hour, from: Date())

        for (displayID, panel) in panels {
            if previewStartedProtection, previewConfiguration?.displayID != displayID {
                panel.orderOut(nil)
                continue
            }
            let configuration: DisplayConfiguration
            if let previewConfiguration, previewConfiguration.displayID == displayID {
                configuration = previewConfiguration.value
            } else {
                configuration = settings.displayConfiguration(for: displayID)
            }
            guard configuration.isEnabled else {
                panel.orderOut(nil)
                continue
            }

            let profile = profile(
                for: configuration.mode,
                automaticProfile: automaticProfile
            )
            let automaticTuning = adaptiveEngine.automaticTuning(profile: profile, hour: hour)
            let isAutomatic = configuration.mode == .auto
            let directDisplayID = NSScreen.screens
                .first(where: { Self.identifier(for: $0) == displayID })
                .flatMap(Self.displayID(for:))
            let screenBrightness = directDisplayID.flatMap {
                brightnessReader.currentBrightness(for: $0)
            }
            let appearance = adaptiveEngine.appearance(
                profile: profile,
                intensity: configuration.intensity,
                displayBrightness: screenBrightness,
                sessionMinutes: Double(sessionMinutes),
                paperEnabled: isAutomatic ? automaticTuning.paperEnabled : configuration.paperMode,
                focusEdgesEnabled: isAutomatic ? automaticTuning.focusEdgesEnabled : configuration.focusEdges,
                hour: hour,
                focusIntensity: isAutomatic ? automaticTuning.focusIntensity : configuration.focusIntensity,
                warmth: isAutomatic ? automaticTuning.warmth : configuration.warmth,
                paperIntensity: isAutomatic ? automaticTuning.paperIntensity : configuration.paperIntensity
            )

            guard let view = panel.contentView as? OverlayView else { continue }
            view.apply(appearance)
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    private func refreshDisplayList() {
        displays = NSScreen.screens.map { screen in
            let scale = screen.backingScaleFactor
            let width = Int(screen.frame.width * scale)
            let height = Int(screen.frame.height * scale)
            let displayID = Self.displayID(for: screen)
            return DisplayInfo(
                id: Self.identifier(for: screen),
                name: screen.localizedName,
                resolution: "\(width) × \(height)",
                isBuiltIn: displayID.map(CGDisplayIsBuiltin) == 1,
                frameDescription: Self.rectDescription(screen.frame),
                visibleFrameDescription: Self.rectDescription(screen.visibleFrame),
                scaleFactor: scale
            )
        }
    }

    private static func rectDescription(_ rect: CGRect) -> String {
        "x \(Int(rect.origin.x)), y \(Int(rect.origin.y)), "
            + "\(Int(rect.width)) × \(Int(rect.height)) pt"
    }

    private func profile(
        for mode: UserMode,
        automaticProfile: ActiveProfile
    ) -> ActiveProfile {
        switch mode {
        case .auto: return automaticProfile
        case .work: return .work
        case .read: return .reading
        case .night: return .night
        case .play: return .gaming
        }
    }

    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    private static func identifier(for screen: NSScreen) -> String {
        guard let displayID = displayID(for: screen),
              let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return "screen-\(screen.localizedName)-\(Int(screen.frame.origin.x))-\(Int(screen.frame.origin.y))"
        }
        return CFUUIDCreateString(nil, uuid) as String
    }
}

private final class PassiveOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

private final class DiagnosticOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class DiagnosticHighlightView: NSView {
    private let displayName: String

    init(frame frameRect: NSRect, displayName: String) {
        self.displayName = displayName
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.borderWidth = 8
        layer?.borderColor = NSColor.systemPink.cgColor
        layer?.backgroundColor = NSColor.systemPink.withAlphaComponent(0.06).cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let text = displayName as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.72)
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2),
            withAttributes: attributes
        )
    }
}

private final class OverlayView: NSView {
    private static let paperTexture = makePaperTexture()

    private let tintLayer = CALayer()
    private let paperLayer = CALayer()
    private let edgeLayer = CAGradientLayer()
    private var lastAppearance: AdaptiveAppearance?

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
        paperLayer.contents = Self.paperTexture
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

    override func layout() {
        super.layout()
        tintLayer.frame = bounds
        paperLayer.frame = bounds
        edgeLayer.frame = bounds
    }

    func apply(_ appearance: AdaptiveAppearance) {
        guard appearance != lastAppearance else { return }
        lastAppearance = appearance

        let color = NSColor(
            calibratedRed: appearance.red,
            green: appearance.green,
            blue: appearance.blue,
            alpha: 1.0
        )

        CATransaction.begin()
        CATransaction.setAnimationDuration(
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.28
        )
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        tintLayer.backgroundColor = color.withAlphaComponent(appearance.alpha).cgColor
        paperLayer.opacity = Float(appearance.paperOpacity)
        edgeLayer.opacity = Float(appearance.edgeOpacity)
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
