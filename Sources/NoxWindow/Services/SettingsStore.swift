import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var intensity: Double { didSet { defaults.set(intensity, forKey: Keys.intensity) } }
    @Published var userMode: UserMode { didSet { defaults.set(userMode.rawValue, forKey: Keys.userMode) } }
    @Published var autoEnable: Bool { didSet { defaults.set(autoEnable, forKey: Keys.autoEnable) } }
    @Published var paperMode: Bool { didSet { defaults.set(paperMode, forKey: Keys.paperMode) } }
    @Published var focusEdges: Bool { didSet { defaults.set(focusEdges, forKey: Keys.focusEdges) } }
    @Published var breakReminders: Bool { didSet { defaults.set(breakReminders, forKey: Keys.breakReminders) } }
    @Published var breakIntervalMinutes: Int { didSet { defaults.set(breakIntervalMinutes, forKey: Keys.breakIntervalMinutes) } }
    @Published var hotKeyShortcut: HotKeyShortcut { didSet { saveHotKeyShortcut() } }
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
        static let breakReminders = "breakReminders.v9"
        static let breakIntervalMinutes = "breakIntervalMinutes.v10.1"
        static let displayConfigurations = "displayConfigurations.v11.3"
        static let hotKeyShortcut = "hotKeyShortcut.v11.3"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        intensity = defaults.object(forKey: Keys.intensity) as? Double ?? 0.48
        userMode = UserMode(rawValue: defaults.string(forKey: Keys.userMode) ?? "") ?? .auto
        autoEnable = defaults.object(forKey: Keys.autoEnable) as? Bool ?? true
        paperMode = defaults.object(forKey: Keys.paperMode) as? Bool ?? true
        focusEdges = defaults.object(forKey: Keys.focusEdges) as? Bool ?? true
        breakReminders = defaults.object(forKey: Keys.breakReminders) as? Bool ?? true
        breakIntervalMinutes = defaults.object(forKey: Keys.breakIntervalMinutes) as? Int ?? 50
        if let data = defaults.data(forKey: Keys.hotKeyShortcut),
           let saved = try? JSONDecoder().decode(HotKeyShortcut.self, from: data) {
            hotKeyShortcut = saved
        } else {
            hotKeyShortcut = .default
        }
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
            focusEdges: focusEdges
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

    func reset() {
        intensity = 0.48
        userMode = .auto
        autoEnable = true
        paperMode = true
        focusEdges = true
        breakReminders = true
        breakIntervalMinutes = 50
        hotKeyShortcut = .default
        displayConfigurations = [:]
    }

    private var matchingPreset: QuickPreset {
        QuickPreset.allCases.first {
            $0.mode == userMode &&
            abs($0.intensity - intensity) < 0.001 &&
            $0.paperMode == paperMode &&
            $0.focusEdges == focusEdges
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
}
