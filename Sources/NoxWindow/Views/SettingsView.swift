import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedDisplayID: String?

    private let breakIntervals = [25, 50, 75, 90]
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                launchSection
                displaysSection
                timerSection
                presetsSection
                comfortSection
                helpSection
                resetSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 680, idealWidth: 720, minHeight: 620, idealHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { selectAvailableDisplay() }
        .onChange(of: model.displays) { selectAvailableDisplay() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Настройки")
                .font(.title2.bold())
            Text("Управление дисплеями, запуском, паузами, комфортом и быстрыми пресетами.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var displaysSection: some View {
        settingsCard(title: "Мониторы", symbol: "display.2") {
            if model.displays.isEmpty {
                ContentUnavailableView(
                    "Мониторы не найдены",
                    systemImage: "display.trianglebadge.exclamationmark",
                    description: Text("Подключи дисплей — MyNightMode добавит его автоматически.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                Picker("Дисплей", selection: selectedDisplayBinding) {
                    ForEach(model.displays) { display in
                        Label(display.name, systemImage: display.isBuiltIn ? "laptopcomputer" : "display")
                            .tag(Optional(display.id))
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if let display = selectedDisplay {
                    displaySettings(for: display)
                        .id(display.id)
                }
            }

            Text("Выбери монитор, настрой его и переключись на следующий. Каждый оверлей независим, покрывает весь экран и не перехватывает ввод.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var launchSection: some View {
        settingsCard(title: "Запуск", symbol: "power") {
            settingToggle(
                title: "Включать защиту при запуске",
                description: "MyNightMode начнёт работать сразу после открытия приложения.",
                value: Binding(
                    get: { model.settings.autoEnable },
                    set: { model.settings.autoEnable = $0 }
                )
            )

            Divider()

            settingToggle(
                title: "Запускать вместе с macOS",
                description: "Приложение будет доступно в menu bar после входа в систему.",
                value: Binding(
                    get: { model.loginItem.isEnabled },
                    set: { model.loginItem.setEnabled($0) }
                )
            )

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Глобальная горячая клавиша")
                        .font(.callout.weight(.medium))
                    Text(model.hotKeyRegistrationFailed
                         ? "Сочетание занято другим приложением. Выберите другое."
                         : "Нажмите поле и введите сочетание с ⌃, ⌥, ⇧ или ⌘.")
                        .font(.caption)
                        .foregroundStyle(model.hotKeyRegistrationFailed ? Color.red : Color.secondary)
                }

                Spacer()

                HotKeyRecorderView(
                    shortcut: model.settings.hotKeyShortcut,
                    onChange: model.setHotKey
                )
                .frame(width: 150, height: 28)

                Button("Сбросить") {
                    model.resetHotKey()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var timerSection: some View {
        settingsCard(title: "Таймер и паузы", symbol: "timer") {
            settingToggle(
                title: "Напоминать сделать перерыв",
                description: "После выбранного времени приложение ненавязчиво предложит посмотреть вдаль. Системные уведомления не требуются.",
                value: Binding(
                    get: { model.settings.breakReminders },
                    set: { model.settings.breakReminders = $0 }
                )
            )

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Напомнить через")
                        .font(.callout.weight(.medium))
                    Text("Интервал непрерывной работы")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Напомнить через", selection: Binding(
                    get: { model.settings.breakIntervalMinutes },
                    set: { model.settings.breakIntervalMinutes = $0 }
                )) {
                    ForEach(breakIntervals, id: \.self) { minutes in
                        Text("\(minutes) минут").tag(minutes)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
                .disabled(!model.settings.breakReminders)
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Label("Smart Pause", systemImage: "pause.circle")
                    .font(.callout.weight(.semibold))
                Text("В главном окне и menu bar эффект можно остановить на 15, 30, 60 или 120 минут либо до завтра 09:00. После таймера защита включится автоматически.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var presetsSection: some View {
        settingsCard(title: "Быстрые пресеты", symbol: "sparkles") {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(QuickPreset.allCases) { preset in
                    presetSettingsButton(preset)
                }
            }

            Text("Пресет меняет режим, силу эффекта, Paper Mode и фокус по краям. Любую настройку можно скорректировать вручную.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var comfortSection: some View {
        settingsCard(title: "Комфорт", symbol: "eye") {
            settingToggle(
                title: "Paper Mode",
                description: "Смягчает резкий белый фон и контраст при чтении документов, сайтов и таблиц.",
                value: Binding(
                    get: { model.settings.paperMode },
                    set: { model.setPaperModeForAllDisplays($0) }
                )
            )

            Divider()

            settingToggle(
                title: "Фокус по краям",
                description: "Создаёт мягкую виньетку и оставляет центр светлее, не блокируя интерфейс.",
                value: Binding(
                    get: { model.settings.focusEdges },
                    set: { model.setFocusEdgesForAllDisplays($0) }
                )
            )
        }
    }

    private var helpSection: some View {
        settingsCard(title: "Помощь", symbol: "questionmark.circle") {
            Button {
                UserDefaults.standard.set(false, forKey: "didFinishOnboarding.v10")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Показать онбординг при следующем открытии", systemImage: "rectangle.on.rectangle")
            }
            .buttonStyle(.bordered)

            Text("Обучение также можно открыть кнопкой ? в главном окне.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var resetSection: some View {
        HStack {
            Spacer()
            Button("Сбросить настройки", role: .destructive) {
                model.settings.reset()
            }
        }
    }

    private func settingsCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private func presetSettingsButton(_ preset: QuickPreset) -> some View {
        Button {
            model.apply(preset, enableProtection: false)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: preset.symbol)
                    .frame(width: 18)
                Text(preset.settingsTitle)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private func displaySettings(for display: DisplayInfo) -> some View {
        let configuration = model.displayConfiguration(for: display.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 38, height: 38)
                    .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(display.name)
                        .font(.callout.weight(.semibold))
                    Text("\(display.isBuiltIn ? "Встроенный экран" : "Внешний монитор") · \(display.resolution)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Эффект на \(display.name)", isOn: Binding(
                    get: { model.displayConfiguration(for: display.id).isEnabled },
                    set: { value in
                        model.updateDisplayConfiguration(for: display.id) { $0.isEnabled = value }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            HStack(spacing: 12) {
                Text("Пресет")
                    .font(.callout.weight(.medium))

                Spacer()

                Picker("Пресет", selection: Binding(
                    get: { model.displayConfiguration(for: display.id).preset },
                    set: { preset in
                        model.updateDisplayConfiguration(for: display.id) { $0.apply(preset) }
                    }
                )) {
                    ForEach(QuickPreset.allCases) { preset in
                        Label(preset.settingsTitle, systemImage: preset.symbol)
                            .tag(preset)
                    }
                }
                .labelsHidden()
                .frame(width: 190)
                .disabled(!configuration.isEnabled)
            }

            HStack(spacing: 10) {
                Image(systemName: "sun.min")
                    .foregroundStyle(.secondary)
                Slider(value: Binding(
                    get: { model.displayConfiguration(for: display.id).intensity },
                    set: { value in
                        model.updateDisplayConfiguration(for: display.id) { $0.intensity = value }
                    }
                ), in: 0.10...1.0)
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.secondary)
                Text("\(Int(configuration.intensity * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }

            HStack(spacing: 18) {
                Toggle("Paper Mode", isOn: Binding(
                    get: { model.displayConfiguration(for: display.id).paperMode },
                    set: { value in
                        model.updateDisplayConfiguration(for: display.id) { $0.paperMode = value }
                    }
                ))
                Toggle("Фокус по краям", isOn: Binding(
                    get: { model.displayConfiguration(for: display.id).focusEdges },
                    set: { value in
                        model.updateDisplayConfiguration(for: display.id) { $0.focusEdges = value }
                    }
                ))
            }
            .font(.caption)
            .disabled(!configuration.isEnabled)
        }
        .padding(.vertical, 2)
    }

    private var selectedDisplay: DisplayInfo? {
        model.displays.first { $0.id == selectedDisplayID } ?? model.displays.first
    }

    private var selectedDisplayBinding: Binding<String?> {
        Binding(
            get: { selectedDisplay?.id },
            set: { selectedDisplayID = $0 }
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

    private func settingToggle(
        title: String,
        description: String,
        value: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)
            Toggle("", isOn: value)
                .labelsHidden()
        }
    }
}
