import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    let settings = SettingsStore()
    let loginItem = LoginItemManager()
    private lazy var overlay = OverlayController(settings: settings)
    private let hotKey = HotKeyManager()
    private var subscriptions = Set<AnyCancellable>()
    private var resumeTask: Task<Void, Never>?

    @Published private(set) var breakDismissedForSession = false
    @Published private(set) var pauseUntil: Date?
    @Published private(set) var hotKeyRegistrationFailed = false

    var isEnabled: Bool { overlay.isRunning }
    var activeProfile: ActiveProfile { overlay.activeProfile }
    var activeAppName: String { overlay.activeAppName }
    var displays: [DisplayInfo] { overlay.displays }
    var sessionMinutes: Int { overlay.sessionMinutes }
    var sessionText: String {
        overlay.sessionMinutes < 1 ? "только что" : "\(overlay.sessionMinutes) мин"
    }
    var brightnessText: String {
        guard let value = overlay.displayBrightness else { return "авто" }
        return "\(Int(value * 100))%"
    }
    var shouldSuggestBreak: Bool {
        settings.breakReminders && isEnabled && sessionMinutes >= settings.breakIntervalMinutes && !breakDismissedForSession
    }
    var isTemporarilyPaused: Bool {
        guard let pauseUntil else { return false }
        return pauseUntil > Date()
    }
    var pauseStatusText: String? {
        guard let pauseUntil, pauseUntil > Date() else { return nil }
        let minutes = max(1, Int(ceil(pauseUntil.timeIntervalSinceNow / 60)))
        return "Пауза ещё \(minutes) мин"
    }

    init() {
        hotKey.action = { [weak self] in
            Task { @MainActor in self?.toggle() }
        }
        hotKeyRegistrationFailed = !hotKey.register(settings.hotKeyShortcut)

        overlay.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)

        settings.$hotKeyShortcut
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] shortcut in
                guard let self else { return }
                self.hotKeyRegistrationFailed = !self.hotKey.register(shortcut)
            }
            .store(in: &subscriptions)
    }

    func setHotKey(_ shortcut: HotKeyShortcut) {
        guard hotKey.register(shortcut) else {
            _ = hotKey.register(settings.hotKeyShortcut)
            hotKeyRegistrationFailed = true
            objectWillChange.send()
            return
        }
        hotKeyRegistrationFailed = false
        settings.hotKeyShortcut = shortcut
    }

    func resetHotKey() {
        setHotKey(.default)
    }

    func start() {
        if settings.autoEnable { overlay.start() }
        objectWillChange.send()
    }

    func toggle() {
        resumeTask?.cancel()
        resumeTask = nil
        pauseUntil = nil
        overlay.toggle()
        if overlay.isRunning { breakDismissedForSession = false }
        objectWillChange.send()
    }

    func pause(for minutes: Int) {
        guard minutes > 0 else { return }
        resumeTask?.cancel()
        if overlay.isRunning { overlay.stop() }

        let deadline = Date().addingTimeInterval(TimeInterval(minutes * 60))
        pauseUntil = deadline
        objectWillChange.send()

        resumeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.pauseUntil = nil
                self.overlay.start()
                self.breakDismissedForSession = false
                self.objectWillChange.send()
            }
        }
    }

    func resumeNow() {
        resumeTask?.cancel()
        resumeTask = nil
        pauseUntil = nil
        if !overlay.isRunning { overlay.start() }
        breakDismissedForSession = false
        objectWillChange.send()
    }

    func apply(_ preset: QuickPreset, enableProtection: Bool = true) {
        settings.userMode = preset.mode
        settings.intensity = preset.intensity
        settings.paperMode = preset.paperMode
        settings.focusEdges = preset.focusEdges
        for display in displays {
            settings.updateDisplayConfiguration(for: display.id) {
                $0.apply(preset)
            }
        }
        if enableProtection && !isEnabled {
            resumeNow()
        }
    }

    func displayConfiguration(for displayID: String) -> DisplayConfiguration {
        settings.displayConfiguration(for: displayID)
    }

    func updateDisplayConfiguration(
        for displayID: String,
        _ update: (inout DisplayConfiguration) -> Void
    ) {
        settings.updateDisplayConfiguration(for: displayID, update)
    }

    func apply(_ preset: QuickPreset, to displayID: String, enableProtection: Bool = true) {
        settings.updateDisplayConfiguration(for: displayID) {
            $0.apply(preset)
        }
        if enableProtection && !isEnabled {
            resumeNow()
        }
    }

    func setModeForAllDisplays(_ mode: UserMode) {
        settings.userMode = mode
        for display in displays {
            settings.updateDisplayConfiguration(for: display.id) { $0.mode = mode }
        }
    }

    func setIntensityForAllDisplays(_ intensity: Double) {
        settings.intensity = intensity
        for display in displays {
            settings.updateDisplayConfiguration(for: display.id) { $0.intensity = intensity }
        }
    }

    func setPaperModeForAllDisplays(_ enabled: Bool) {
        settings.paperMode = enabled
        for display in displays {
            settings.updateDisplayConfiguration(for: display.id) { $0.paperMode = enabled }
        }
    }

    func setFocusEdgesForAllDisplays(_ enabled: Bool) {
        settings.focusEdges = enabled
        for display in displays {
            settings.updateDisplayConfiguration(for: display.id) { $0.focusEdges = enabled }
        }
    }

    func dismissBreakSuggestion() {
        breakDismissedForSession = true
    }
}
