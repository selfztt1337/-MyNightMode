import SwiftUI
import AppKit

@main
struct NightModeApp: App {
    @NSApplicationDelegateAdaptor(NightModeAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .task { model.start() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 820)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("NightMode") {
                Button(model.isEnabled ? "Выключить" : "Включить") { model.toggle() }
            }
        }

        MenuBarExtra("NightMode", systemImage: model.isEnabled ? "circle.lefthalf.filled" : "circle") {
            MenuBarView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
        .defaultSize(width: 780, height: 820)
        .windowResizability(.contentSize)
    }
}

@MainActor
final class NightModeAppDelegate: NSObject, NSApplicationDelegate {
    private let iconAppearanceController = AppIconAppearanceController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        iconAppearanceController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        iconAppearanceController.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            sender.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        }
        sender.activate(ignoringOtherApps: true)
        return true
    }
}
