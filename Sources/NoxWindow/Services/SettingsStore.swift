import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var intensity: Double { didSet { defaults.set(intensity, forKey: "intensity") } }
    @Published var userMode: UserMode { didSet { defaults.set(userMode.rawValue, forKey: "userMode") } }
    @Published var autoEnable: Bool { didSet { defaults.set(autoEnable, forKey: "autoEnable") } }

    private let defaults = UserDefaults.standard

    init() {
        intensity = defaults.object(forKey: "intensity") as? Double ?? 0.68
        userMode = UserMode(rawValue: defaults.string(forKey: "userMode") ?? "") ?? .auto
        autoEnable = defaults.object(forKey: "autoEnable") as? Bool ?? true
    }

    func reset() {
        intensity = 0.68
        userMode = .auto
        autoEnable = true
    }
}
