import Combine
import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    private static let maximumPresetImportBytes = 1_000_000

    let settings: SettingsStore
    let loginItem = LoginItemManager()
    private lazy var overlay = OverlayController(settings: settings)
    private let hotKey = HotKeyManager()
    private var subscriptions = Set<AnyCancellable>()
    private var resumeTask: Task<Void, Never>?
    private var scheduleTimer: Timer?
    private let scheduleEngine = ScheduleEngine()
    private var lastAppliedScheduleEvent: ScheduleEvent?

    @Published private(set) var breakDismissedForSession = false
    @Published private(set) var pauseUntil: Date?
    @Published private(set) var hotKeyRegistrationFailed = false
    @Published var presentedError: String?

    var isEnabled: Bool { overlay.isRunning }
    var activeProfile: ActiveProfile { overlay.activeProfile }
    var activeAppName: String { overlay.activeAppName }
    var displays: [DisplayInfo] { overlay.displays }
    var diagnostics: [DisplayDiagnostic] { overlay.diagnostics() }
    var presetItems: [PresetItem] {
        PresetCatalog().items(customPresets: settings.customPresets)
    }
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

    var scheduleStatusText: String? {
        guard settings.schedule.isEnabled,
              let decision = scheduleEngine.decision(settings: settings.schedule) else { return nil }
        if let override = settings.scheduleOverrideUntil,
           scheduleEngine.overrideIsActive(until: override) {
            return "Вручную до \(override.formatted(date: .omitted, time: .shortened))"
        }
        return "\(decision.event.phase.title): \(decision.event.mode.title)"
    }

    convenience init() {
        self.init(settings: SettingsStore())
    }

    init(settings: SettingsStore) {
        self.settings = settings
        hotKey.action = { [weak self] in
            Task { @MainActor in self?.toggle() }
        }
        hotKeyRegistrationFailed = !hotKey.register(settings.hotKeyShortcut)

        overlay.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)

        overlay.$displays
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applySchedule(force: true) }
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

        settings.$schedule
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] schedule in self?.scheduleDidChange(schedule) }
            .store(in: &subscriptions)

        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.applySchedule() }
        }
        scheduleTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    deinit {
        scheduleTimer?.invalidate()
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
        if settings.schedule.isEnabled,
           scheduleEngine.decision(settings: settings.schedule) != nil {
            applySchedule(force: true)
        } else if settings.autoEnable {
            overlay.start()
        }
        objectWillChange.send()
    }

    func toggle() {
        beginManualScheduleOverride()
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
        beginManualScheduleOverride(until: deadline)
        pauseUntil = deadline
        objectWillChange.send()

        resumeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.pauseUntil = nil
                if self.settings.schedule.isEnabled {
                    self.settings.scheduleOverrideUntil = nil
                    self.lastAppliedScheduleEvent = nil
                    self.applySchedule(force: true)
                } else {
                    self.overlay.start()
                    self.breakDismissedForSession = false
                    self.objectWillChange.send()
                }
            }
        }
    }

    func resumeNow() {
        beginManualScheduleOverride()
        resumeTask?.cancel()
        resumeTask = nil
        pauseUntil = nil
        if !overlay.isRunning { overlay.start() }
        breakDismissedForSession = false
        objectWillChange.send()
    }

    func displayConfiguration(for displayID: String) -> DisplayConfiguration {
        settings.displayConfiguration(for: displayID)
    }

    func activeProfile(for displayID: String?) -> ActiveProfile {
        guard let displayID else { return activeProfile }
        switch settings.displayConfiguration(for: displayID).mode {
        case .auto: return overlay.automaticProfile
        case .work: return .work
        case .read: return .reading
        case .night: return .night
        case .play: return .gaming
        }
    }

    func updateDisplayConfiguration(
        for displayID: String,
        _ update: (inout DisplayConfiguration) -> Void
    ) {
        settings.updateDisplayConfiguration(for: displayID, update)
    }

    func setMode(_ mode: UserMode, for displayID: String) {
        beginManualScheduleOverride()
        settings.updateDisplayConfiguration(for: displayID) { $0.mode = mode }
    }

    func apply(_ preset: QuickPreset, to displayID: String, enableProtection: Bool = true) {
        guard settings.displayConfiguration(for: displayID).mode != .auto else { return }
        beginManualScheduleOverride()
        settings.updateDisplayConfiguration(for: displayID) {
            $0.apply(preset)
        }
        if enableProtection && !isEnabled {
            resumeNow()
        }
    }

    func apply(_ preset: UserPreset, to displayID: String, enableProtection: Bool = true) {
        guard settings.displayConfiguration(for: displayID).mode != .auto else { return }
        beginManualScheduleOverride()
        settings.updateDisplayConfiguration(for: displayID) { $0.apply(preset) }
        if enableProtection && !isEnabled { resumeNow() }
    }

    func apply(_ item: PresetItem, to displayID: String, enableProtection: Bool = true) {
        switch item {
        case .builtIn(let preset):
            apply(preset, to: displayID, enableProtection: enableProtection)
        case .custom(let preset):
            apply(preset, to: displayID, enableProtection: enableProtection)
        }
    }

    func applyToAll(_ item: PresetItem) {
        beginManualScheduleOverride()
        switch item {
        case .builtIn(let preset):
            settings.updateDisplayConfigurations(for: displays.map(\.id)) {
                guard $0.mode != .auto else { return }
                $0.apply(preset)
            }
        case .custom(let preset):
            settings.updateDisplayConfigurations(for: displays.map(\.id)) {
                guard $0.mode != .auto else { return }
                $0.apply(preset)
            }
        }
        if !isEnabled { resumeNow() }
    }

    func applyConfigurationToAll(from displayID: String) {
        beginManualScheduleOverride()
        let source = settings.displayConfiguration(for: displayID)
        settings.updateDisplayConfigurations(for: displays.map(\.id)) { configuration in
            let enabled = configuration.isEnabled
            configuration = source
            configuration.isEnabled = enabled
        }
    }

    func copyConfiguration(from sourceID: String, to targetID: String) {
        beginManualScheduleOverride()
        let source = settings.displayConfiguration(for: sourceID)
        settings.updateDisplayConfiguration(for: targetID) { target in
            let enabled = target.isEnabled
            target = source
            target.isEnabled = enabled
        }
    }

    func setPaperModeForAllDisplays(_ enabled: Bool) {
        settings.paperMode = enabled
        settings.updateDisplayConfigurations(for: displays.map(\.id)) {
            $0.paperMode = enabled
        }
    }

    func setFocusEdgesForAllDisplays(_ enabled: Bool) {
        settings.focusEdges = enabled
        settings.updateDisplayConfigurations(for: displays.map(\.id)) {
            $0.focusEdges = enabled
        }
    }

    func setFocusIntensityForAllDisplays(_ intensity: Double) {
        settings.focusIntensity = intensity
        settings.updateDisplayConfigurations(for: displays.map(\.id)) {
            $0.focusIntensity = intensity
        }
    }

    func saveUserPreset(
        named name: String,
        configuration: DisplayConfiguration,
        symbol: String,
        placement: PresetPlacement,
        to displayID: String?
    ) {
        guard let preset = settings.saveUserPreset(
            named: name,
            configuration: configuration,
            symbol: symbol,
            placement: placement
        ) else { return }
        if let displayID, settings.displayConfiguration(for: displayID).mode != .auto {
            settings.updateDisplayConfiguration(for: displayID) { $0.apply(preset) }
        }
    }

    func updateUserPreset(
        id: UUID,
        named name: String,
        configuration: DisplayConfiguration,
        symbol: String,
        placement: PresetPlacement,
        applyTo displayID: String?
    ) {
        settings.updateUserPreset(
            id: id,
            name: name,
            symbol: symbol,
            configuration: configuration,
            placement: placement
        )
        guard let displayID,
              settings.displayConfiguration(for: displayID).mode != .auto,
              let preset = settings.customPresets.first(where: { $0.id == id }) else { return }
        settings.updateDisplayConfiguration(for: displayID) { $0.apply(preset) }
    }

    func exportPresets() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "NightMode-Presets.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(PresetArchive(presets: settings.customPresets)).write(to: url, options: .atomic)
        } catch {
            presentedError = "Не удалось экспортировать пресеты: \(error.localizedDescription)"
        }
    }

    func importPresets() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard fileSize <= Self.maximumPresetImportBytes else {
                presentedError = "Файл пресетов слишком большой. Максимальный размер — 1 МБ."
                return
            }
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let archive = try JSONDecoder().decode(PresetArchive.self, from: data)
            guard archive.formatVersion == 1 else {
                presentedError = "Эта версия файла пресетов не поддерживается."
                return
            }
            let merged = settings.customPresets + archive.presets
            let uniqueCount = Set(merged.map(\.id)).count
            guard uniqueCount <= UserPreset.maximumCount else {
                presentedError = "Можно хранить не больше \(UserPreset.maximumCount) пользовательских пресетов. Удалите лишние и повторите импорт."
                return
            }
            settings.replaceUserPresets(merged)
        } catch {
            presentedError = "Файл пресетов повреждён или имеет неверный формат."
        }
    }

    func highlightDisplays() {
        overlay.highlightDisplays()
    }

    func previewPreset(
        _ configuration: DisplayConfiguration,
        on displayID: String,
        duration: TimeInterval = 8
    ) {
        overlay.preview(configuration, on: displayID, duration: duration)
    }

    func exportDiagnosticReport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "NightMode-Diagnostics.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try diagnosticReport().write(to: url, atomically: true, encoding: .utf8)
        } catch {
            presentedError = "Не удалось сохранить отчёт: \(error.localizedDescription)"
        }
    }

    func diagnosticReport(now: Date = Date()) -> String {
        let lines = diagnostics.enumerated().map { index, item in
            """
            Display \(index + 1)
              id: \(item.id.prefix(8))…
              frame: \(item.frame)
              visibleFrame: \(item.visibleFrame)
              scale: \(String(format: "%.2f", item.scaleFactor))
              overlayFrame: \(item.overlayFrame ?? "not running")
              overlayVisible: \(item.overlayIsVisible ? "yes" : "no")
              fullCoverage: \(item.coversFullFrame ? "yes" : "no")
            """
        }
        return """
        NightMode diagnostics
        Generated: \(ISO8601DateFormatter().string(from: now))
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        App running: \(isEnabled ? "yes" : "no")
        Displays: \(diagnostics.count)

        \(lines.joined(separator: "\n\n"))

        No usernames, file paths, window contents or application activity are included.
        """
    }

    func returnToSchedule() {
        settings.scheduleOverrideUntil = nil
        lastAppliedScheduleEvent = nil
        applySchedule(force: true)
    }

    func dismissBreakSuggestion() {
        breakDismissedForSession = true
    }

    private func beginManualScheduleOverride(until requestedDeadline: Date? = nil) {
        guard settings.schedule.isEnabled,
              let decision = scheduleEngine.decision(settings: settings.schedule) else { return }
        settings.scheduleOverrideUntil = scheduleEngine.overrideDeadline(
            requested: requestedDeadline,
            decision: decision
        )
    }

    private func applySchedule(force: Bool = false) {
        guard settings.schedule.isEnabled,
              let decision = scheduleEngine.decision(settings: settings.schedule) else {
            lastAppliedScheduleEvent = nil
            return
        }
        if scheduleEngine.overrideIsActive(until: settings.scheduleOverrideUntil) { return }
        if settings.scheduleOverrideUntil != nil { settings.scheduleOverrideUntil = nil }
        guard force || lastAppliedScheduleEvent != decision.event else { return }

        resumeTask?.cancel()
        resumeTask = nil
        pauseUntil = nil
        settings.userMode = decision.event.mode
        settings.updateDisplayConfigurations(for: displays.map(\.id)) {
            $0.mode = decision.event.mode
        }
        if decision.event.shouldEnable {
            if !overlay.isRunning { overlay.start() }
        } else if overlay.isRunning {
            overlay.stop()
        }
        lastAppliedScheduleEvent = decision.event
        objectWillChange.send()
    }

    private func scheduleDidChange(_ schedule: ScheduleSettings) {
        guard schedule.isEnabled else {
            settings.scheduleOverrideUntil = nil
            lastAppliedScheduleEvent = nil
            return
        }
        if scheduleEngine.overrideIsActive(until: settings.scheduleOverrideUntil),
           let decision = scheduleEngine.decision(settings: schedule) {
            settings.scheduleOverrideUntil = decision.nextTransition
            return
        }
        applySchedule(force: true)
    }
}
