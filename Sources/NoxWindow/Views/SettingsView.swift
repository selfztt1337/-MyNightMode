import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Запуск") {
                Toggle("Включать защиту при запуске", isOn: Binding(
                    get: { model.settings.autoEnable },
                    set: { model.settings.autoEnable = $0 }
                ))
                Toggle("Запускать вместе с macOS", isOn: Binding(
                    get: { model.loginItem.isEnabled },
                    set: { model.loginItem.setEnabled($0) }
                ))
            }

            Section("Комфорт") {
                Toggle("Напоминать о паузе после 50 минут", isOn: Binding(
                    get: { model.settings.breakReminders },
                    set: { model.settings.breakReminders = $0 }
                ))

                settingToggle(
                    title: "Paper Mode",
                    description: "Смягчает резкий белый фон и контраст при чтении документов, сайтов и таблиц.",
                    value: Binding(
                        get: { model.settings.paperMode },
                        set: { model.settings.paperMode = $0 }
                    )
                )

                settingToggle(
                    title: "Фокус по краям",
                    description: "Создаёт мягкую виньетку и оставляет центр светлее, не блокируя интерфейс.",
                    value: Binding(
                        get: { model.settings.focusEdges },
                        set: { model.settings.focusEdges = $0 }
                    )
                )
            }

            Section("Помощь") {
                Button("Показать онбординг при следующем открытии") {
                    UserDefaults.standard.set(false, forKey: "didFinishOnboarding.v10")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                Text("Также обучение можно открыть кнопкой ? в главном окне.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Сбросить настройки", role: .destructive) {
                model.settings.reset()
            }
        }
        .formStyle(.grouped)
        .padding(14)
    }

    private func settingToggle(title: String, description: String, value: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: value)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
