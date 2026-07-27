import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    var settings = SettingsStore()
    let loginItem = LoginItemManager()
    private lazy var overlay = OverlayController(settings: settings)
    private let hotKey = HotKeyManager()
    private var subscriptions = Set<AnyCancellable>()

    var isEnabled: Bool { overlay.isRunning }
    var activeProfile: ActiveProfile { overlay.activeProfile }
    var activeAppName: String { overlay.activeAppName }
    var brightnessText: String {
        guard let value = overlay.displayBrightness else { return "авто" }
        return "\(Int(value * 100))%"
    }

    init() {
        hotKey.action = { [weak self] in
            Task { @MainActor in self?.toggle() }
        }
        overlay.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
    }

    func start() {
        if settings.autoEnable { overlay.start() }
        objectWillChange.send()
    }

    func toggle() {
        overlay.toggle()
        objectWillChange.send()
    }

    func enable() {
        overlay.start()
        objectWillChange.send()
    }

    func disable() {
        overlay.stop()
        objectWillChange.send()
    }
}
