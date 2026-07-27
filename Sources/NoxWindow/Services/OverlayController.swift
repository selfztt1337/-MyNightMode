import AppKit
import Combine

@MainActor
final class OverlayController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var activeProfile: ActiveProfile = .neutral
    @Published private(set) var displayBrightness: Double?
    @Published private(set) var activeAppName = "macOS"

    private let settings: SettingsStore
    private let brightnessReader = DisplayBrightnessReader()
    private let classifier = AppClassifier()
    private var panels: [PassiveOverlayPanel] = []
    private var timer: Timer?
    private var subscriptions = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []

    init(settings: SettingsStore) {
        self.settings = settings

        Publishers.CombineLatest(settings.$userMode, settings.$intensity)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in self?.refreshNow() }
            .store(in: &subscriptions)

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.append(workspaceCenter.addObserver(
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
        rebuildPanels()
        isRunning = true
        refreshNow()

        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
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
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func rebuildPanels() {
        guard isRunning || panels.isEmpty else { return }
        panels.forEach { $0.orderOut(nil); $0.close() }
        panels = NSScreen.screens.map(makePanel)
        if isRunning { panels.forEach { $0.orderFrontRegardless() } }
        applyAppearance()
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

        let view = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        panel.contentView = view
        return panel
    }

    private func refreshNow() {
        let app = NSWorkspace.shared.frontmostApplication
        activeAppName = app?.localizedName ?? "macOS"
        displayBrightness = brightnessReader.currentBrightness()

        switch settings.userMode {
        case .auto: activeProfile = classifier.profile(for: app)
        case .work: activeProfile = .work
        case .read: activeProfile = .read
        case .play: activeProfile = .play
        }
        applyAppearance()
    }

    private func applyAppearance() {
        guard isRunning else { return }
        let appearance = appearanceForCurrentContext()
        for panel in panels {
            guard let layer = panel.contentView?.layer else { continue }
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.22)
            layer.backgroundColor = appearance.color.withAlphaComponent(appearance.alpha).cgColor
            CATransaction.commit()
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    private func appearanceForCurrentContext() -> (color: NSColor, alpha: CGFloat) {
        let strength = min(max(settings.intensity, 0.15), 1.0)
        let brightness = displayBrightness ?? 0.55
        let hour = Calendar.current.component(.hour, from: Date())
        let nightBoost: Double = (hour >= 21 || hour < 7) ? 0.08 : 0

        // At higher physical display brightness the filter becomes stronger.
        let brightnessBoost = max(0, brightness - 0.35) * 0.28
        let base: Double
        let color: NSColor

        switch activeProfile {
        case .work:
            base = 0.16
            color = NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.055, alpha: 1)
        case .read:
            base = 0.19
            color = NSColor(calibratedRed: 0.14, green: 0.065, blue: 0.018, alpha: 1)
        case .play:
            base = 0.045
            color = NSColor(calibratedRed: 0.015, green: 0.018, blue: 0.028, alpha: 1)
        case .neutral:
            base = 0.12
            color = NSColor(calibratedRed: 0.035, green: 0.030, blue: 0.048, alpha: 1)
        }

        let alpha = min(0.78, base + strength * 0.37 + brightnessBoost + nightBoost)
        return (color, CGFloat(alpha))
    }
}

private final class PassiveOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
