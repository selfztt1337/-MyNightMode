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

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let intensity = "intensity.v9"
        static let userMode = "userMode.v9"
        static let autoEnable = "autoEnable.v9"
        static let paperMode = "paperMode.v9"
        static let focusEdges = "focusEdges.v9"
        static let breakReminders = "breakReminders.v9"
        static let breakIntervalMinutes = "breakIntervalMinutes.v10.1"
    }

    init() {
        intensity = defaults.object(forKey: Keys.intensity) as? Double ?? 0.48
        userMode = UserMode(rawValue: defaults.string(forKey: Keys.userMode) ?? "") ?? .auto
        autoEnable = defaults.object(forKey: Keys.autoEnable) as? Bool ?? true
        paperMode = defaults.object(forKey: Keys.paperMode) as? Bool ?? true
        focusEdges = defaults.object(forKey: Keys.focusEdges) as? Bool ?? true
        breakReminders = defaults.object(forKey: Keys.breakReminders) as? Bool ?? true
        breakIntervalMinutes = defaults.object(forKey: Keys.breakIntervalMinutes) as? Int ?? 50
    }

    func reset() {
        intensity = 0.48
        userMode = .auto
        autoEnable = true
        paperMode = true
        focusEdges = true
        breakReminders = true
        breakIntervalMinutes = 50
    }
}
