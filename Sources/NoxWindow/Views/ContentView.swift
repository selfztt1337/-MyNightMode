import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("MyNightMode")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                    Text("created by @selfztt1337")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(model.isEnabled ? .green : .secondary.opacity(0.35))
                    .frame(width: 9, height: 9)
            }

            Picker("Режим", selection: $model.settings.userMode) {
                ForEach(UserMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 10) {
                HStack {
                    Text("Сила фильтра")
                    Spacer()
                    Text("\(Int(model.settings.intensity * 100))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $model.settings.intensity, in: 0.15...1.0)
            }

            if model.settings.userMode == .auto {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(model.activeProfile.rawValue) · \(model.activeAppName)")
                            .font(.callout.weight(.medium))
                        Text("Яркость экрана: \(model.brightnessText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                model.toggle()
            } label: {
                Text(model.isEnabled ? "Выключить" : "Включить")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Фильтр покрывает весь экран, не перехватывает мышь и не требует доступа к записи экрана. ⌥⌘D — быстро включить или выключить.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(width: 520)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color.indigo.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
