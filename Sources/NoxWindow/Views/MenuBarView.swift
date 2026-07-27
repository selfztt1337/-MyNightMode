import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var visibleHelp: FeatureHelp?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            modeSection
            intensitySection
            protectionButton
            comfortSection
            footer
        }
        .padding(18)
        .frame(width: 370)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: model.activeProfile.symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 38, height: 38)
                .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("MyNightMode")
                    .font(.headline)

                Text(model.isEnabled ? "\(model.activeProfile.rawValue) · \(model.activeAppName)" : "Защита выключена")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Circle()
                .fill(model.isEnabled ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 8, height: 8)
                .help(model.isEnabled ? "Защита активна" : "Защита выключена")
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Режим")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                ForEach(UserMode.allCases) { mode in
                    Button {
                        model.settings.userMode = mode
                    } label: {
                        Text(mode.title)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        model.settings.userMode == mode ? Color.accentColor : Color.primary.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
                    .foregroundStyle(model.settings.userMode == mode ? Color.white : Color.primary)
                    .help(modeHelp(mode))
                }
            }
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("Сила эффекта")
                Spacer()
                Text("\(Int(model.settings.intensity * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "sun.min")
                    .foregroundStyle(.secondary)
                Slider(value: Binding(
                    get: { model.settings.intensity },
                    set: { model.settings.intensity = $0 }
                ), in: 0.10...1.0)
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var protectionButton: some View {
        Button(action: model.toggle) {
            HStack(spacing: 8) {
                Image(systemName: model.isEnabled ? "pause.fill" : "play.fill")
                Text(model.isEnabled ? "Приостановить защиту" : "Включить защиту")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(model.isEnabled ? Color.primary.opacity(0.12) : Color.accentColor)
        .foregroundStyle(model.isEnabled ? Color.primary : Color.white)
    }

    private var comfortSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Дополнительный комфорт")

            comfortRow(
                title: "Paper Mode",
                subtitle: "Смягчает белый фон и контраст при чтении",
                symbol: "doc.text",
                value: Binding(
                    get: { model.settings.paperMode },
                    set: { model.settings.paperMode = $0 }
                ),
                help: .paper
            )

            comfortRow(
                title: "Фокус по краям",
                subtitle: "Незаметно затемняет края и удерживает внимание в центре",
                symbol: "scope",
                value: Binding(
                    get: { model.settings.focusEdges },
                    set: { model.settings.focusEdges = $0 }
                ),
                help: .focus
            )
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                SettingsLink {
                    Label("Настройки", systemImage: "gearshape")
                }
                Spacer()
                Button("Выйти") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.plain)
            .font(.callout)
        }
    }

    private func comfortRow(
        title: String,
        subtitle: String,
        symbol: String,
        value: Binding<Bool>,
        help: FeatureHelp
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30, height: 30)
                .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.callout.weight(.medium))

                    Button {
                        visibleHelp = help
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { visibleHelp == help },
                        set: { if !$0 { visibleHelp = nil } }
                    )) {
                        FeatureHelpView(feature: help)
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle(title, isOn: value)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(11)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func modeHelp(_ mode: UserMode) -> String {
        switch mode {
        case .auto: return "Сам выбирает профиль по активному приложению, времени и яркости"
        case .work: return "Сбалансированный режим для длительной работы"
        case .read: return "Мягкий контраст и более комфортный белый фон"
        case .night: return "Более сильное затемнение для позднего времени"
        case .play: return "Минимальное вмешательство в изображение"
        }
    }
}

private enum FeatureHelp: Equatable {
    case paper
    case focus

    var title: String {
        switch self {
        case .paper: return "Что делает Paper Mode"
        case .focus: return "Что делает фокус по краям"
        }
    }

    var symbol: String {
        switch self {
        case .paper: return "doc.text"
        case .focus: return "scope"
        }
    }

    var description: String {
        switch self {
        case .paper:
            return "Слегка смягчает белые поверхности, контраст и ощущение глянца. Особенно полезен для PDF, статей, документов и долгого чтения."
        case .focus:
            return "Создаёт очень мягкую виньетку: центр остаётся светлее, а края становятся чуть темнее. Это помогает меньше отвлекаться, не перекрывая интерфейс."
        }
    }
}

private struct FeatureHelpView: View {
    let feature: FeatureHelp

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: feature.symbol)
                .font(.system(size: 22, weight: .medium))
            Text(feature.title)
                .font(.headline)
            Text(feature.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 270, alignment: .leading)
    }
}
