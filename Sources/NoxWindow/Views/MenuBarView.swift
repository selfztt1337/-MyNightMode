import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var visibleHelp: FeatureHelp?
    @State private var selectedDisplayID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            displaySection
            modeSection
            quickPresetsSection
            intensitySection
            protectionControls
            comfortSection
            footer
        }
        .padding(18)
        .frame(width: 370)
        .onAppear { selectAvailableDisplay() }
        .onChange(of: model.displays) { selectAvailableDisplay() }
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

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                sectionTitle("Дисплей")
                Spacer()
                if let display = selectedDisplay {
                    Text(display.isBuiltIn ? "Встроенный" : "Внешний")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Picker("Дисплей", selection: selectedDisplayBinding) {
                ForEach(model.displays) { display in
                    Label(display.name, systemImage: display.isBuiltIn ? "laptopcomputer" : "display")
                        .tag(Optional(display.id))
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            if selectedDisplay != nil {
                Toggle("Эффект на этом дисплее", isOn: displayBinding(\.isEnabled))
                    .font(.callout)
            } else {
                Text("Подключённые дисплеи не найдены")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Режим")

            HStack(spacing: 6) {
                ForEach(UserMode.allCases) { mode in
                    Button {
                        guard let displayID = selectedDisplay?.id else { return }
                        model.updateDisplayConfiguration(for: displayID) { $0.mode = mode }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode.symbol)
                            Text(mode.title)
                                .lineLimit(1)
                        }
                        .font(.caption2.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        selectedConfiguration?.mode == mode ? Color.accentColor : Color.primary.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
                    .foregroundStyle(selectedConfiguration?.mode == mode ? Color.white : Color.primary)
                    .help(modeHelp(mode))
                }
            }
            .disabled(selectedDisplay == nil || selectedConfiguration?.isEnabled == false)
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
                    presetButton(
                        preset.title,
                        symbol: preset.symbol,
                        isSelected: selectedConfiguration?.matches(preset) == true
                    ) {
                        if let displayID = selectedDisplay?.id {
                            model.apply(preset, to: displayID)
                        } else {
                            model.apply(preset)
                        }
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
                    if let displayID = selectedDisplay?.id {
                        model.updateDisplayConfiguration(for: displayID) { $0.intensity = 0.48 }
                    } else {
                        model.settings.intensity = 0.48
                    }
                } label: {
                    Text("\(Int(selectedIntensity * 100))%")
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
                    get: { selectedIntensity },
                    set: { value in
                        guard let displayID = selectedDisplay?.id else {
                            model.settings.intensity = value
                            return
                        }
                        model.updateDisplayConfiguration(for: displayID) { $0.intensity = value }
                    }
                ), in: 0.10...1.0)
                .disabled(selectedDisplay == nil)
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
                Button("15 минут") { model.pause(for: SmartPauseOption.fifteenMinutes.minutes()) }
                Button("30 минут") { model.pause(for: SmartPauseOption.thirtyMinutes.minutes()) }
                Button("1 час") { model.pause(for: SmartPauseOption.oneHour.minutes()) }
                Button("2 часа") { model.pause(for: SmartPauseOption.twoHours.minutes()) }
                Divider()
                Button("До завтра, 09:00") { model.pause(for: SmartPauseOption.tomorrowMorning.minutes()) }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 52, height: 38)
                .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Smart Pause: временно выключить эффект")
            .disabled(!model.isEnabled && !model.isTemporarilyPaused)
        }
    }

    private var comfortSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Дополнительный комфорт")

            comfortRow(
                title: "Paper Mode",
                subtitle: "Смягчает белый фон и контраст при чтении",
                symbol: "doc.text",
                value: Binding(
                    get: { selectedConfiguration?.paperMode ?? model.settings.paperMode },
                    set: { value in
                        guard let displayID = selectedDisplay?.id else { return }
                        model.updateDisplayConfiguration(for: displayID) { $0.paperMode = value }
                    }
                ),
                help: .paper
            )

            comfortRow(
                title: "Фокус по краям",
                subtitle: "Незаметно затемняет края и удерживает внимание в центре",
                symbol: "scope",
                value: Binding(
                    get: { selectedConfiguration?.focusEdges ?? model.settings.focusEdges },
                    set: { value in
                        guard let displayID = selectedDisplay?.id else { return }
                        model.updateDisplayConfiguration(for: displayID) { $0.focusEdges = value }
                    }
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

            Text("MyNightMode")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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


    private func presetButton(
        _ title: String,
        symbol: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
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
        .background(
            isSelected ? Color.accentColor : Color.primary.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .help("Применить готовый набор настроек")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var selectedDisplay: DisplayInfo? {
        model.displays.first { $0.id == selectedDisplayID } ?? model.displays.first
    }

    private var selectedConfiguration: DisplayConfiguration? {
        guard let displayID = selectedDisplay?.id else { return nil }
        return model.displayConfiguration(for: displayID)
    }

    private var selectedIntensity: Double {
        selectedConfiguration?.intensity ?? model.settings.intensity
    }

    private var selectedDisplayBinding: Binding<String?> {
        Binding(
            get: { selectedDisplay?.id },
            set: { selectedDisplayID = $0 }
        )
    }

    private func displayBinding(_ keyPath: WritableKeyPath<DisplayConfiguration, Bool>) -> Binding<Bool> {
        Binding(
            get: { selectedConfiguration?[keyPath: keyPath] ?? false },
            set: { value in
                guard let displayID = selectedDisplay?.id else { return }
                model.updateDisplayConfiguration(for: displayID) { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func selectAvailableDisplay() {
        guard !model.displays.isEmpty else {
            selectedDisplayID = nil
            return
        }
        if !model.displays.contains(where: { $0.id == selectedDisplayID }) {
            selectedDisplayID = model.displays.first?.id
        }
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
