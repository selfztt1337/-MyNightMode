import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var visibleHelp: FeatureHelp?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            modeSection
            quickPresetsSection
            intensitySection
            protectionControls
            smartPauseSection
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


    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                sectionTitle("Быстрые пресеты")
                Spacer()
                Text("1 клик")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 7) {
                ForEach(QuickPreset.allCases) { preset in
                    presetButton(preset.title, symbol: preset.symbol) {
                        model.apply(preset)
                    }
                }
            }
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("Сила эффекта")
                Spacer()
                Button {
                    model.settings.intensity = 0.48
                } label: {
                    Text("\(Int(model.settings.intensity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Вернуть рекомендуемую силу 48%")
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

    private var protectionControls: some View {
        HStack(spacing: 9) {
            Button(action: model.isTemporarilyPaused ? model.resumeNow : model.toggle) {
                HStack(spacing: 8) {
                    Image(systemName: model.isTemporarilyPaused ? "play.fill" : (model.isEnabled ? "pause.fill" : "play.fill"))
                    Text(model.isTemporarilyPaused ? "Продолжить сейчас" : (model.isEnabled ? "Приостановить" : "Включить защиту"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(model.isEnabled ? Color.primary.opacity(0.12) : Color.accentColor)
            .foregroundStyle(model.isEnabled ? Color.primary : Color.white)

            Menu {
                Button("15 минут") { model.pause(for: 15) }
                Button("30 минут") { model.pause(for: 30) }
                Button("1 час") { model.pause(for: 60) }
                Button("2 часа") { model.pause(for: 120) }
                Divider()
                Button("До завтра, 09:00") { model.pause(for: minutesUntilTomorrowMorning()) }
            } label: {
                Image(systemName: "timer")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .menuStyle(.borderlessButton)
            .help("Smart Pause: временно выключить эффект")
            .disabled(!model.isEnabled && !model.isTemporarilyPaused)
        }
    }

    private var smartPauseSection: some View {
        HStack(spacing: 11) {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30, height: 30)
                .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("Smart Pause")
                        .font(.callout.weight(.medium))
                    Button {
                        visibleHelp = .pause
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { visibleHelp == .pause },
                        set: { if !$0 { visibleHelp = nil } }
                    )) {
                        FeatureHelpView(feature: .pause)
                    }
                }

                Text(model.pauseStatusText ?? "Пауза на 15, 30 или 60 минут")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("15 минут") { model.pause(for: 15) }
                Button("30 минут") { model.pause(for: 30) }
                Button("1 час") { model.pause(for: 60) }
                Button("2 часа") { model.pause(for: 120) }
                Divider()
                Button("До завтра, 09:00") { model.pause(for: minutesUntilTomorrowMorning()) }
            } label: {
                Text(model.isTemporarilyPaused ? "Изменить" : "Выбрать")
                    .font(.caption.weight(.semibold))
            }
            .disabled(!model.isEnabled && !model.isTemporarilyPaused)
        }
        .padding(11)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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


    private func presetButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .help("Применить готовый набор настроек")
    }

    private func minutesUntilTomorrowMorning() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
        let target = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        return max(1, Int(ceil(target.timeIntervalSince(now) / 60)))
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
    case pause

    var title: String {
        switch self {
        case .paper: return "Что делает Paper Mode"
        case .focus: return "Что делает фокус по краям"
        case .pause: return "Как работает Smart Pause"
        }
    }

    var symbol: String {
        switch self {
        case .paper: return "doc.text"
        case .focus: return "scope"
        case .pause: return "timer"
        }
    }

    var description: String {
        switch self {
        case .paper:
            return "Слегка смягчает белые поверхности, контраст и ощущение глянца. Особенно полезен для PDF, статей, документов и долгого чтения."
        case .focus:
            return "Создаёт очень мягкую виньетку: центр остаётся светлее, а края становятся чуть темнее. Это помогает меньше отвлекаться, не перекрывая интерфейс."
        case .pause:
            return "Останавливает эффект на 15, 30, 60 или 120 минут, либо до завтра 09:00. После таймера MyNightMode автоматически включит защиту обратно."
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
