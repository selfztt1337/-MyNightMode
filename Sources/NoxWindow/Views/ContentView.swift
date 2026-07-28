import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("didFinishOnboarding.v10") private var didFinishOnboarding = false
    @State private var showOnboarding = false
    @State private var visibleHelp: DashboardHelp?
    @State private var showAIReason = false
    @State private var selectedDisplayID: String?

    var body: some View {
        Group {
            if didFinishOnboarding {
                dashboard
            } else {
                OnboardingView {
                    didFinishOnboarding = true
                }
            }
        }
        .frame(width: 520, height: 820)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                didFinishOnboarding = true
                showOnboarding = false
            }
            .environmentObject(model)
            .frame(width: 520, height: 590)
        }
        .onAppear { selectAvailableDisplay() }
        .onChange(of: model.displays) { selectAvailableDisplay() }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statusCard
                displaySelector
                modeSection
                quickPresetsSection
                intensityCard

                if model.shouldSuggestBreak {
                    breakCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                protectionControls
                comfortSection
                footer
            }
            .padding(24)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: model.shouldSuggestBreak)
    }

    private var displaySelector: some View {
        HStack(spacing: 12) {
            Label("Дисплей", systemImage: selectedDisplay?.isBuiltIn == true ? "laptopcomputer" : "display")
                .font(.callout.weight(.semibold))

            Picker("Дисплей", selection: selectedDisplayBinding) {
                ForEach(model.displays) { display in
                    Text(display.name).tag(Optional(display.id))
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Выбранный дисплей")

            Toggle("Эффект", isOn: displayBoolBinding(\.isEnabled))
                .labelsHidden()
                .toggleStyle(.switch)
                .disabled(selectedDisplay == nil)
                .help("Включить эффект на выбранном дисплее")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 13) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("NightMode")
                    .font(.system(size: 25, weight: .semibold))
                Text("Night work, without the glare")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showOnboarding = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 17, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("Открыть краткое обучение")

            Circle()
                .fill(model.isEnabled ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 9, height: 9)
                .help(model.isEnabled ? "Защита экрана активна" : (model.pauseStatusText ?? "Защита выключена"))
        }
    }

    private var statusCard: some View {
        HStack(spacing: 13) {
            Image(systemName: selectedActiveProfile.symbol)
                .font(.system(size: 19, weight: .medium))
                .frame(width: 38, height: 38)
                .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(model.isEnabled ? selectedActiveProfile.rawValue : (model.pauseStatusText ?? "Защита выключена"))
                    .font(.headline)

                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if selectedConfiguration?.mode == .auto {
                Button {
                    showAIReason.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text("Почему AI?")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.primary.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Показать, почему выбран текущий профиль")
                .popover(isPresented: $showAIReason) {
                    AIReasonView(model: model, profile: selectedActiveProfile)
                }
            } else {
                Text((selectedConfiguration?.mode ?? model.settings.userMode).title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.primary.opacity(0.08), in: Capsule())
            }
        }
        .padding(15)
        .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusSubtitle: String {
        if let schedule = model.scheduleStatusText {
            return "\(schedule) · \(selectedDisplay?.name ?? "Дисплей")"
        }
        if model.isEnabled {
            return "\(model.activeAppName) · яркость \(model.brightnessText) · \(model.sessionText)"
        }
        if model.pauseStatusText != nil {
            return "После паузы защита включится автоматически"
        }
        return "Включи защиту, дальше приложение работает само"
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                sectionTitle("Режим")
                Spacer()
                InfoButton(help: .modes, visibleHelp: $visibleHelp)
            }

            HStack(spacing: 7) {
                ForEach(UserMode.allCases) { mode in
                    Button {
                        guard let displayID = selectedDisplay?.id else { return }
                        model.setMode(mode, for: displayID)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: mode.symbol)
                            Text(mode.title)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        selectedConfiguration?.mode == mode ? Color.accentColor : Color.primary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .foregroundStyle(selectedConfiguration?.mode == mode ? Color.white : Color.primary)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                selectedConfiguration?.mode == mode ? Color.white.opacity(0.7) : Color.clear,
                                lineWidth: 1.5
                            )
                    }
                    .accessibilityLabel("Режим \(mode.title)")
                    .accessibilityValue(selectedConfiguration?.mode == mode ? "Выбран" : "Не выбран")
                    .help(modeHelp(mode))
                }
            }
        }
    }

    private var intensityCard: some View {
        VStack(spacing: 9) {
            HStack {
                Text("Сила эффекта")
                    .font(.callout.weight(.medium))
                InfoButton(help: .intensity, visibleHelp: $visibleHelp)
                Spacer()
                Text("\(Int(selectedIntensity * 100))%")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "sun.min")
                    .foregroundStyle(.secondary)
                Slider(value: Binding(
                    get: { selectedIntensity },
                    set: { value in
                        guard let displayID = selectedDisplay?.id else { return }
                        model.updateDisplayConfiguration(for: displayID) { $0.intensity = value }
                    }
                ), in: 0.10...1.0)
                .disabled(selectedDisplay == nil)
                .accessibilityLabel("Сила эффекта")
                .accessibilityValue("\(Int(selectedIntensity * 100)) процентов")
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                sectionTitle("Быстрые пресеты")
                Spacer()
                Text(selectedConfiguration?.mode == .auto
                     ? "Автоподбор"
                     : (selectedConfiguration?.presetLabel(customPresets: model.settings.customPresets) ?? "1 клик"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if selectedConfiguration?.mode == .auto {
                Label("AI сам подбирает профиль — пресеты доступны в ручных режимах", systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(model.presetItems) { item in
                        quickPresetButton(item)
                    }
                }
            }
            .opacity(selectedConfiguration?.mode == .auto ? 0.55 : 1)
        }
    }

    private func quickPresetButton(_ item: PresetItem) -> some View {
        let isSelected = selectedConfiguration.map(item.matches) == true
        return Button {
            guard let displayID = selectedDisplay?.id else { return }
            model.apply(item, to: displayID)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: item.symbol)
                    .font(.system(size: 14, weight: .medium))
                Text(item.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .frame(width: 108)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(selectedConfiguration?.mode == .auto)
        .background(
            isSelected ? Color.accentColor : Color.primary.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.7) : Color.clear, lineWidth: 1.5)
        }
        .accessibilityLabel("Пресет \(item.settingsTitle)")
        .accessibilityValue(isSelected ? "Выбран" : "Не выбран")
        .help("Применить пресет «\(item.settingsTitle)»")
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
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(model.isEnabled ? Color.white : Color.accentColor)
            .foregroundStyle(model.isEnabled ? Color.black : Color.white)

            Menu {
                Button("На 15 минут") { model.pause(for: SmartPauseOption.fifteenMinutes.minutes()) }
                Button("На 30 минут") { model.pause(for: SmartPauseOption.thirtyMinutes.minutes()) }
                Button("На 1 час") { model.pause(for: SmartPauseOption.oneHour.minutes()) }
                Button("На 2 часа") { model.pause(for: SmartPauseOption.twoHours.minutes()) }
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
            .accessibilityLabel("Выбрать длительность Smart Pause")
            .help("Временно выключить эффект и включить его автоматически")
            .disabled(!model.isEnabled && !model.isTemporarilyPaused)
        }
    }

    private var comfortSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Дополнительный комфорт")

            if selectedConfiguration?.mode == .auto {
                Label("Paper Mode и фокус настраивает AI", systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                featureCard(
                    title: "Paper Mode",
                    subtitle: "Мягче белые страницы",
                    symbol: "doc.text",
                    value: Binding(
                        get: { selectedConfiguration?.paperMode ?? false },
                        set: { value in
                            guard let displayID = selectedDisplay?.id else { return }
                            model.updateDisplayConfiguration(for: displayID) { $0.paperMode = value }
                        }
                    ),
                    help: .paper
                )

                featureCard(
                    title: "Фокус по краям",
                    subtitle: "Меньше отвлечений",
                    symbol: "scope",
                    value: Binding(
                        get: { selectedConfiguration?.focusEdges ?? false },
                        set: { value in
                            guard let displayID = selectedDisplay?.id else { return }
                            model.updateDisplayConfiguration(for: displayID) { $0.focusEdges = value }
                        }
                    ),
                    help: .focus
                )
            }

            if selectedConfiguration?.focusEdges == true {
                HStack(spacing: 10) {
                    Label("Интенсивность фокуса", systemImage: "scope")
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { selectedConfiguration?.focusIntensity ?? 0.45 },
                            set: { value in
                                guard let id = selectedDisplay?.id else { return }
                                model.updateDisplayConfiguration(for: id) { $0.focusIntensity = value }
                            }
                        ),
                        in: 0.10...1.0
                    )
                    .accessibilityLabel("Интенсивность фокуса по краям")
                    Text("\(Int((selectedConfiguration?.focusIntensity ?? 0.45) * 100))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 36)
                }
            }
        }
        .disabled(selectedConfiguration?.mode == .auto)
        .opacity(selectedConfiguration?.mode == .auto ? 0.55 : 1)
    }

    private var breakCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(model.settings.breakIntervalMinutes) минут без паузы")
                    .font(.callout.weight(.semibold))
                Text("Посмотри вдаль 20 секунд. Никаких уведомлений и разрешений.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Готово") { model.dismissBreakSuggestion() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(13)
        .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack {
                Label(model.settings.hotKeyShortcut.displayText, systemImage: "keyboard")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .help("Глобальная горячая клавиша включения и выключения")
                Spacer()
                Button("Обучение") { showOnboarding = true }
                    .buttonStyle(.plain)
                SettingsLink {
                    Label("Настройки", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
            }

            BrandFooterView(compact: true)
        }
        .font(.callout)
        .padding(.top, 2)
    }

    private var selectedDisplay: DisplayInfo? {
        model.displays.first { $0.id == selectedDisplayID } ?? model.displays.first
    }

    private var selectedConfiguration: DisplayConfiguration? {
        guard let displayID = selectedDisplay?.id else { return nil }
        return model.displayConfiguration(for: displayID)
    }

    private var selectedActiveProfile: ActiveProfile {
        model.activeProfile(for: selectedDisplay?.id)
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

    private func displayBoolBinding(
        _ keyPath: WritableKeyPath<DisplayConfiguration, Bool>
    ) -> Binding<Bool> {
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

    private func featureCard(
        title: String,
        subtitle: String,
        symbol: String,
        value: Binding<Bool>,
        help: DashboardHelp
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 32, height: 32)
                .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.callout.weight(.medium))
                    InfoButton(help: help, visibleHelp: $visibleHelp)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Toggle(title, isOn: value)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func modeHelp(_ mode: UserMode) -> String {
        switch mode {
        case .auto: return "AI выбирает профиль по приложению, яркости, времени и длительности сессии"
        case .work: return "Сбалансированный эффект для почты, таблиц и рабочих приложений"
        case .read: return "Более тёплый и мягкий режим для статей, PDF и документов"
        case .night: return "Усиленное затемнение и более тёплый оттенок поздно вечером"
        case .play: return "Минимальное изменение цветов для игр и видео"
        }
    }
}

private enum DashboardHelp: Equatable {
    case modes
    case intensity
    case paper
    case focus

    var title: String {
        switch self {
        case .modes: return "Как работают режимы"
        case .intensity: return "Что регулирует сила эффекта"
        case .paper: return "Что делает Paper Mode"
        case .focus: return "Что делает фокус по краям"
        }
    }

    var symbol: String {
        switch self {
        case .modes: return "square.grid.2x2"
        case .intensity: return "slider.horizontal.3"
        case .paper: return "doc.text"
        case .focus: return "scope"
        }
    }

    var description: String {
        switch self {
        case .modes:
            return "AI подходит для ежедневной работы: приложение само учитывает активную программу, яркость, время и длительность сессии. Ручные режимы фиксируют поведение, когда нужен предсказуемый результат."
        case .intensity:
            return "Это общий масштаб эффекта. Он не заменяет яркость macOS, а определяет, насколько заметно NightMode смягчает изображение. Для старта обычно комфортно 35–50%."
        case .paper:
            return "Слегка смягчает белые поверхности, резкий контраст и ощущение глянца. Особенно полезен для PDF, браузера, документов и долгого чтения."
        case .focus:
            return "Создаёт очень мягкую виньетку: центр остаётся светлее, края становятся чуть темнее. Интерфейс остаётся кликабельным, а периферийные отвлечения становятся менее заметными."
        }
    }
}

private struct InfoButton: View {
    let help: DashboardHelp
    @Binding var visibleHelp: DashboardHelp?

    var body: some View {
        Button {
            visibleHelp = help
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(help.title)
        .popover(isPresented: Binding(
            get: { visibleHelp == help },
            set: { if !$0 { visibleHelp = nil } }
        )) {
            HelpPopover(help: help)
        }
    }
}

private struct HelpPopover: View {
    let help: DashboardHelp

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: help.symbol)
                .font(.system(size: 22, weight: .medium))
            Text(help.title)
                .font(.headline)
            Text(help.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 290, alignment: .leading)
    }
}

private struct AIReasonView: View {
    @ObservedObject var model: AppModel
    let profile: ActiveProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Почему выбран профиль «\(profile.rawValue)»", systemImage: "sparkles")
                .font(.headline)

            reasonRow(symbol: "app", title: "Приложение", value: model.activeAppName)
            reasonRow(symbol: "sun.max", title: "Яркость", value: model.brightnessText)
            reasonRow(symbol: "clock", title: "Сессия", value: model.sessionText)

            Text("AI использует только локальный контекст macOS. Содержимое экрана не записывается и не анализируется.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 310, alignment: .leading)
    }

    private func reasonRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .font(.callout)
    }
}
