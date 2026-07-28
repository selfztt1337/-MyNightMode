import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var intensity: Double { didSet { defaults.set(intensity, forKey: Keys.intensity) } }
    @Published var userMode: UserMode { didSet { defaults.set(userMode.rawValue, forKey: Keys.userMode) } }
    @Published var autoEnable: Bool { didSet { defaults.set(autoEnable, forKey: Keys.autoEnable) } }
    @Published var paperMode: Bool { didSet { defaults.set(paperMode, forKey: Keys.paperMode) } }
    @Published var focusEdges: Bool { didSet { defaults.set(focusEdges, forKey: Keys.focusEdges) } }
    @Published var focusIntensity: Double { didSet { defaults.set(focusIntensity, forKey: Keys.focusIntensity) } }
    @Published var breakReminders: Bool { didSet { defaults.set(breakReminders, forKey: Keys.breakReminders) } }
    @Published var breakIntervalMinutes: Int { didSet { defaults.set(breakIntervalMinutes, forKey: Keys.breakIntervalMinutes) } }
    @Published var hotKeyShortcut: HotKeyShortcut { didSet { saveHotKeyShortcut() } }
    @Published var schedule: ScheduleSettings { didSet { save(schedule, forKey: Keys.schedule) } }
    @Published var scheduleOverrideUntil: Date? {
        didSet { defaults.set(scheduleOverrideUntil, forKey: Keys.scheduleOverrideUntil) }
    }
    @Published private(set) var customPresets: [UserPreset] {
        didSet { save(customPresets, forKey: Keys.customPresets) }
    }
    @Published private(set) var displayConfigurations: [String: DisplayConfiguration] {
        didSet { saveDisplayConfigurations() }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let intensity = "intensity.v9"
        static let userMode = "userMode.v9"
        static let autoEnable = "autoEnable.v9"
        static let paperMode = "paperMode.v9"
        static let focusEdges = "focusEdges.v9"
        static let focusIntensity = "focusIntensity.v12"
        static let breakReminders = "breakReminders.v9"
        static let breakIntervalMinutes = "breakIntervalMinutes.v10.1"
        static let displayConfigurations = "displayConfigurations.v11.3"
        static let hotKeyShortcut = "hotKeyShortcut.v11.3"
        static let schedule = "schedule.v12"
        static let scheduleOverrideUntil = "scheduleOverrideUntil.v12"
        static let customPresets = "customPresets.v12"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        intensity = defaults.object(forKey: Keys.intensity) as? Double ?? 0.48
        userMode = UserMode(rawValue: defaults.string(forKey: Keys.userMode) ?? "") ?? .auto
        autoEnable = defaults.object(forKey: Keys.autoEnable) as? Bool ?? true
        paperMode = defaults.object(forKey: Keys.paperMode) as? Bool ?? true
        focusEdges = defaults.object(forKey: Keys.focusEdges) as? Bool ?? true
        focusIntensity = defaults.object(forKey: Keys.focusIntensity) as? Double ?? 0.45
        breakReminders = defaults.object(forKey: Keys.breakReminders) as? Bool ?? true
        breakIntervalMinutes = defaults.object(forKey: Keys.breakIntervalMinutes) as? Int ?? 50
        if let data = defaults.data(forKey: Keys.hotKeyShortcut),
           let saved = try? JSONDecoder().decode(HotKeyShortcut.self, from: data) {
            hotKeyShortcut = saved
        } else {
            hotKeyShortcut = .default
        }
        schedule = Self.decode(ScheduleSettings.self, from: defaults, key: Keys.schedule)
            ?? ScheduleSettings()
        scheduleOverrideUntil = defaults.object(forKey: Keys.scheduleOverrideUntil) as? Date
        customPresets = Self.decode([UserPreset].self, from: defaults, key: Keys.customPresets)
            ?? []
        if let data = defaults.data(forKey: Keys.displayConfigurations),
           let saved = try? JSONDecoder().decode([String: DisplayConfiguration].self, from: data) {
            displayConfigurations = saved
        } else {
            displayConfigurations = [:]
        }
    }

    func displayConfiguration(for displayID: String) -> DisplayConfiguration {
        displayConfigurations[displayID] ?? DisplayConfiguration(
            isEnabled: true,
            preset: matchingPreset,
            mode: userMode,
            intensity: intensity,
            paperMode: paperMode,
            focusEdges: focusEdges,
            focusIntensity: focusIntensity
        )
    }

    func updateDisplayConfiguration(
        for displayID: String,
        _ update: (inout DisplayConfiguration) -> Void
    ) {
        var configuration = displayConfiguration(for: displayID)
        update(&configuration)
        displayConfigurations[displayID] = configuration
    }

    func updateDisplayConfigurations(
        for displayIDs: [String],
        _ update: (inout DisplayConfiguration) -> Void
    ) {
        guard !displayIDs.isEmpty else { return }
        var configurations = displayConfigurations

        for displayID in displayIDs {
            var configuration = configurations[displayID]
                ?? displayConfiguration(for: displayID)
            update(&configuration)
            configurations[displayID] = configuration
        }

        displayConfigurations = configurations
    }

    func saveUserPreset(
        named name: String,
        configuration: DisplayConfiguration,
        symbol: String = "slider.horizontal.3",
        placement: PresetPlacement = .additional
    ) -> UserPreset? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, customPresets.count < UserPreset.maximumCount else { return nil }
        let preset = UserPreset(
            name: cleanName,
            configuration: configuration,
            symbol: symbol,
            placement: placement
        )
        customPresets = normalizedPlacements(customPresets + [preset])
        return preset
    }

    func renameUserPreset(id: UUID, to name: String) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty,
              let index = customPresets.firstIndex(where: { $0.id == id }) else { return }
        customPresets[index].name = cleanName
    }

    func updateUserPreset(
        id: UUID,
        name: String? = nil,
        symbol: String? = nil,
        configuration: DisplayConfiguration,
        placement: PresetPlacement? = nil
    ) {
        guard let index = customPresets.firstIndex(where: { $0.id == id }) else { return }
        let current = customPresets[index]
        let cleanName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedName = cleanName.flatMap { $0.isEmpty ? nil : $0 } ?? current.name
        var presets = customPresets
        let updatedPlacement = placement ?? current.placement
        makeSlotAvailable(for: id, placement: updatedPlacement, presets: &presets)
        presets[index] = UserPreset(
            id: id,
            name: updatedName,
            configuration: configuration,
            symbol: symbol ?? current.symbol,
            placement: updatedPlacement
        )
        customPresets = normalizedPlacements(presets)
    }

    func setUserPresetPlacement(id: UUID, placement: PresetPlacement) {
        guard let index = customPresets.firstIndex(where: { $0.id == id }) else { return }
        var presets = customPresets
        makeSlotAvailable(for: id, placement: placement, presets: &presets)
        presets[index].placement = placement
        customPresets = normalizedPlacements(presets)
    }

    func deleteUserPreset(id: UUID) {
        customPresets.removeAll { $0.id == id }
        updateDisplayConfigurations(for: Array(displayConfigurations.keys)) {
            if $0.customPresetID == id { $0.customPresetID = nil }
        }
    }

    func replaceUserPresets(_ presets: [UserPreset]) {
        var unique: [UUID: UserPreset] = [:]
        for preset in presets where !preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            unique[preset.id] = preset
        }
        customPresets = Array(normalizedPlacements(unique.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }).prefix(UserPreset.maximumCount))
    }

    func reset() {
        intensity = 0.48
        userMode = .auto
        autoEnable = true
        paperMode = true
        focusEdges = true
        focusIntensity = 0.45
        breakReminders = true
        breakIntervalMinutes = 50
        hotKeyShortcut = .default
        schedule = ScheduleSettings()
        scheduleOverrideUntil = nil
        customPresets = []
        displayConfigurations = [:]
    }

    private var matchingPreset: QuickPreset {
        QuickPreset.allCases.first {
            $0.mode == userMode &&
            abs($0.intensity - intensity) < 0.001 &&
            $0.paperMode == paperMode &&
            $0.focusEdges == focusEdges &&
            abs($0.focusIntensity - focusIntensity) < 0.001
        } ?? .soft
    }

    private func saveDisplayConfigurations() {
        guard let data = try? JSONEncoder().encode(displayConfigurations) else { return }
        defaults.set(data, forKey: Keys.displayConfigurations)
    }

    private func saveHotKeyShortcut() {
        guard let data = try? JSONEncoder().encode(hotKeyShortcut) else { return }
        defaults.set(data, forKey: Keys.hotKeyShortcut)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(
        _ type: T.Type,
        from defaults: UserDefaults,
        key: String
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func normalizedPlacements(_ presets: [UserPreset]) -> [UserPreset] {
        var result = presets
        var occupied: [QuickPreset: Int] = [:]
        for index in result.indices {
            guard let slot = result[index].placement.replacedPreset else { continue }
            if let previous = occupied[slot] {
                result[previous].placement = .additional
            }
            occupied[slot] = index
        }
        return result
    }

    private func makeSlotAvailable(
        for presetID: UUID,
        placement: PresetPlacement,
        presets: inout [UserPreset]
    ) {
        guard let slot = placement.replacedPreset else { return }
        for index in presets.indices
        where presets[index].id != presetID && presets[index].placement.replacedPreset == slot {
            presets[index].placement = .additional
        }
    }
}
