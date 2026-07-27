import SwiftUI

@main
struct MyNightModeApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .task { model.start() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("MyNightMode") {
                Button(model.isEnabled ? "Выключить" : "Включить") { model.toggle() }
            }
        }

        MenuBarExtra("MyNightMode", systemImage: model.isEnabled ? "circle.lefthalf.filled" : "circle") {
            MenuBarView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 720, height: 680)
    }
}
