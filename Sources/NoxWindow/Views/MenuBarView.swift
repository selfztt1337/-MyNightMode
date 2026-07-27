import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MyNightMode").font(.headline)
                    Text(model.isEnabled ? "Включён" : "Выключен")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle().fill(model.isEnabled ? .green : .secondary.opacity(0.35)).frame(width: 8, height: 8)
            }

            Picker("Режим", selection: $model.settings.userMode) {
                ForEach(UserMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            Slider(value: $model.settings.intensity, in: 0.15...1.0)

            if model.settings.userMode == .auto {
                Text("\(model.activeProfile.rawValue) · \(model.activeAppName) · яркость \(model.brightnessText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(model.isEnabled ? "Выключить" : "Включить") { model.toggle() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

            Divider()
            Toggle("Запускать автоматически", isOn: $model.settings.autoEnable)
            HStack {
                SettingsLink { Label("Настройки", systemImage: "gear") }
                Spacer()
                Button("Выйти") { NSApplication.shared.terminate(nil) }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 330)
    }
}
