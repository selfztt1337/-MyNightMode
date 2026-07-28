import AppKit

@MainActor
final class AppIconAppearanceController {
    private var themeObserver: NSObjectProtocol?

    func start() {
        updateIcon()
        themeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateIcon() }
        }
    }

    func stop() {
        if let themeObserver {
            DistributedNotificationCenter.default().removeObserver(themeObserver)
        }
        themeObserver = nil
    }

    private func updateIcon() {
        let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let resourceName = match == .darkAqua ? "AppIconDark1024" : "AppIconLight1024"
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
              let icon = NSImage(contentsOf: url) else { return }
        NSApp.applicationIconImage = icon
    }
}
