import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Toggle("Включать при запуске", isOn: $model.settings.autoEnable)
            Toggle("Запускать вместе с macOS", isOn: Binding(
                get: { model.loginItem.isEnabled },
                set: { model.loginItem.setEnabled($0) }
            ))
            Button("Сбросить настройки", role: .destructive) { model.settings.reset() }
        }
        .padding(20)
    }
}
