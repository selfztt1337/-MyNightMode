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

    var isEnabled: Bool { overlay.isRunning }
    var activeProfile: ActiveProfile { overlay.activeProfile }
    var activeAppName: String { overlay.activeAppName }
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

        overlay.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
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
        if enableProtection && !isEnabled {
            resumeNow()
        }
    }

    func dismissBreakSuggestion() {
        breakDismissedForSession = true
    }
}
