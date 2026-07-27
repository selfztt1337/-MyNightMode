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
        .defaultSize(width: 520, height: 470)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("MyNightMode") {
                Button(model.isEnabled ? "Выключить" : "Включить") { model.toggle() }
                    .keyboardShortcut("d", modifiers: [.command, .option])
            }
        }

        MenuBarExtra("MyNightMode", systemImage: model.isEnabled ? "circle.lefthalf.filled" : "circle") {
            MenuBarView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .frame(width: 420, height: 230)
                .preferredColorScheme(.dark)
        }
    }
}
