import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedDisplayID: String?
    @State private var newPresetName = ""
    @State private var presetDraft = DisplayConfiguration(mode: .work)
    @State private var presetPlacement: PresetPlacement = .additional
    @State private var presetSymbol = UserPreset.availableSymbols[0]
    @State private var editingPresetID: UUID?
    @State private var isPresetEditorExpanded = true
    @State private var isPresetPreviewPresented = false

    private let breakIntervals = [25, 50, 75, 90]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                launchSection
                scheduleSection
                displaysSection
                presetsSection
                timerSection
                comfortSection
                diagnosticsSection
                helpSection
                resetSection
                BrandFooterView()
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 780)
        .frame(minHeight: 820)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { selectAvailableDisplay() }
        .onChange(of: model.displays) { selectAvailableDisplay() }
        .sheet(isPresented: $isPresetPreviewPresented) {
            PresetPreviewView(configuration: presetDraft)
        }
        .alert(
            "NightMode",
            isPresented: Binding(
                get: { model.presentedError != nil },
                set: { if !$0 { model.presentedError = nil } }
            )
        ) {
            Button("OK") { model.presentedError = nil }
        } message: {
            Text(model.presentedError ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Настройки")
                .font(.system(size: 24, weight: .bold))
            Text("Расписание, профили дисплеев, пресеты и диагностика.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var launchSection: some View {
        settingsCard(title: "Запуск", symbol: "power") {
            settingToggle(
                title: "Включать защиту при запуске",
                description: "Используется, когда расписание выключено.",
                value: Binding(
                    get: { model.settings.autoEnable },
                    set: { model.settings.autoEnable = $0 }
                )
            )

            Divider()

            settingToggle(
                title: "Запускать вместе с macOS",
                description: "NightMode будет доступен в строке меню после входа.",
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
                         ? "Сочетание занято. Выберите другое."
                         : "Нажмите поле и введите сочетание с модификатором.")
                        .font(.caption)
                        .foregroundStyle(model.hotKeyRegistrationFailed ? Color.red : Color.secondary)
                }
                Spacer()
                HotKeyRecorderView(shortcut: model.settings.hotKeyShortcut, onChange: model.setHotKey)
                    .frame(width: 150, height: 28)
                    .accessibilityLabel("Глобальная горячая клавиша")
                Button("Сбросить") { model.resetHotKey() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var scheduleSection: some View {
        settingsCard(title: "Расписание", symbol: "calendar.badge.clock") {
            settingToggle(
                title: "Управлять по расписанию",
                description: "Ручное действие действует до ближайшего события. Геолокация не используется.",
                value: Binding(
                    get: { model.settings.schedule.isEnabled },
                    set: { value in
                        var schedule = model.settings.schedule
                        schedule.isEnabled = value
                        model.settings.schedule = schedule
                    }
                )
            )

            if model.settings.schedule.isEnabled {
                Divider()
                Picker("Тип расписания", selection: scheduleBinding(\.kind)) {
                    ForEach(ScheduleKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                scheduleEventRow(
                    title: model.settings.schedule.kind == .sun ? "Рассвет" : "Утро",
                    symbol: "sunrise",
                    minutes: model.settings.schedule.kind == .sun
                        ? scheduleBinding(\.sunriseMinutes)
                        : scheduleBinding(\.morningMinutes),
                    mode: scheduleBinding(\.morningMode),
                    shouldEnable: scheduleBinding(\.enableInMorning)
                )

                Divider()

                scheduleEventRow(
                    title: model.settings.schedule.kind == .sun ? "Закат" : "Вечер",
                    symbol: "sunset",
                    minutes: model.settings.schedule.kind == .sun
                        ? scheduleBinding(\.sunsetMinutes)
                        : scheduleBinding(\.eveningMinutes),
                    mode: scheduleBinding(\.eveningMode),
                    shouldEnable: scheduleBinding(\.enableInEvening)
                )

                if !model.settings.schedule.hasDistinctTimes {
                    Label("Утреннее и вечернее события должны быть в разное время.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if model.settings.scheduleOverrideUntil != nil {
                    HStack {
                        Label(model.scheduleStatusText ?? "Ручное управление", systemImage: "hand.raised")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Вернуться к расписанию") { model.returnToSchedule() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    private var displaysSection: some View {
        settingsCard(title: "Профили дисплеев", symbol: "display.2") {
            if model.displays.isEmpty {
                ContentUnavailableView(
                    "Мониторы не найдены",
                    systemImage: "display.trianglebadge.exclamationmark",
                    description: Text("Подключи дисплей — профиль восстановится автоматически.")
                )
            } else {
                Picker("Дисплей", selection: selectedDisplayBinding) {
                    ForEach(model.displays) { display in
                        Label(display.name, systemImage: display.isBuiltIn ? "laptopcomputer" : "display")
                            .tag(Optional(display.id))
                    }
                }
                .pickerStyle(.segmented)

                if let display = selectedDisplay {
                    displaySettings(for: display)
                        .id(display.id)

                    HStack {
                        Button("Применить ко всем") {
                            model.applyConfigurationToAll(from: display.id)
                        }
                        .buttonStyle(.bordered)

                        Menu("Скопировать настройки на…") {
                            ForEach(model.displays.filter { $0.id != display.id }) { target in
                                Button(target.name) {
                                    model.copyConfiguration(from: display.id, to: target.id)
                                }
                            }
                        }
                        .disabled(model.displays.count < 2)
                    }
                }
            }

            Text("Профили сохраняются по стабильному идентификатору и возвращаются после отключения монитора.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var presetsSection: some View {
        settingsCard(title: "Пресеты", symbol: "sparkles") {
            HStack {
                Text("Так быстрые пресеты будут выглядеть в приложении и status bar:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(model.settings.customPresets.count)/\(UserPreset.maximumCount)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(model.settings.customPresets.count == UserPreset.maximumCount
                                     ? Color.orange : Color.secondary)
                    .accessibilityLabel("Создано пользовательских пресетов")
                    .accessibilityValue("\(model.settings.customPresets.count) из \(UserPreset.maximumCount)")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.presetItems) { item in
                        Button {
                            guard let id = selectedDisplay?.id else { return }
                            model.apply(item, to: id, enableProtection: false)
                        } label: {
                            Label(item.title, systemImage: item.symbol)
                                .lineLimit(1)
                                .frame(width: 132, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedDisplay == nil || selectedDisplayIsAutomatic)
                    }
                }
            }

            DisclosureGroup("Создать пресет вручную", isExpanded: $isPresetEditorExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Название пресета", text: $newPresetName)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Название нового пресета")
                        Button("Взять с выбранного дисплея") {
                            guard let id = selectedDisplay?.id else { return }
                            presetDraft = model.displayConfiguration(for: id)
                            if presetDraft.mode == .auto { presetDraft.mode = .work }
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedDisplay == nil)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Иконка")
                            .font(.callout.weight(.medium))
                        HStack(spacing: 8) {
                            ForEach(UserPreset.availableSymbols, id: \.self) { symbol in
                                Button {
                                    presetSymbol = symbol
                                } label: {
                                    Image(systemName: symbol)
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(.bordered)
                                .tint(presetSymbol == symbol ? Color.accentColor : nil)
                                .accessibilityLabel("Иконка пресета")
                                .accessibilityValue(presetSymbol == symbol ? "Выбрана" : "Не выбрана")
                            }
                        }
                    }

                    Picker("Режим", selection: $presetDraft.mode) {
                        ForEach(UserMode.allCases.filter { $0 != .auto }) {
                            Label($0.title, systemImage: $0.symbol).tag($0)
                        }
                    }

                    presetEditorSlider(
                        title: "Затемнение",
                        hint: "Меньше — ярче",
                        value: $presetDraft.intensity,
                        range: 0.10...1.0
                    )
                    if presetDraft.mode == .auto {
                        Label(
                            "Теплоту, Paper Mode и Focus Edges подбирает AI",
                            systemImage: "sparkles"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                    } else {
                        presetEditorSlider(
                            title: "Теплота",
                            hint: "Холоднее ↔ теплее",
                            value: $presetDraft.warmth,
                            range: 0.0...1.0
                        )

                        HStack {
                            Toggle("Paper Mode", isOn: $presetDraft.paperMode)
                            Toggle("Focus Edges", isOn: $presetDraft.focusEdges)
                        }

                        if presetDraft.paperMode {
                            presetEditorSlider(
                                title: "Сила Paper Mode",
                                hint: "Текстура и мягкость",
                                value: $presetDraft.paperIntensity,
                                range: 0.10...1.0
                            )
                        }
                        if presetDraft.focusEdges {
                            presetEditorSlider(
                                title: "Сила фокуса",
                                hint: "Затемнение краёв",
                                value: $presetDraft.focusIntensity,
                                range: 0.10...1.0
                            )
                        }
                    }

                    HStack {
                        Picker("Показывать", selection: $presetPlacement) {
                            ForEach(PresetPlacement.allCases) {
                                Text($0.title).tag($0)
                            }
                        }
                        Spacer()
                        Button("Попробовать") {
                            guard let displayID = selectedDisplay?.id else { return }
                            model.previewPreset(presetDraft, on: displayID)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedDisplay == nil)
                        .help("Временно применить настройки к выбранному дисплею на 8 секунд")
                        Button("Тестовая сцена") {
                            isPresetPreviewPresented = true
                        }
                        .buttonStyle(.bordered)
                        Button(editingPresetID == nil ? "Сохранить пресет" : "Сохранить изменения") {
                            savePresetDraft()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            (editingPresetID == nil &&
                             model.settings.customPresets.count >= UserPreset.maximumCount)
                        )
                        if editingPresetID != nil {
                            Button("Отмена") { resetPresetEditor() }
                                .buttonStyle(.borderless)
                        }
                    }
                    if editingPresetID == nil,
                       model.settings.customPresets.count >= UserPreset.maximumCount {
                        Label(
                            "Достигнут лимит: \(UserPreset.maximumCount) пользовательских пресетов",
                            systemImage: "exclamationmark.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.top, 10)
            }

            if !model.settings.customPresets.isEmpty {
                Divider()
                Text("Мои пресеты")
                    .font(.callout.weight(.semibold))
            }

            ForEach(model.settings.customPresets) { preset in
                VStack(spacing: 9) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        TextField(
                            "Название",
                            text: Binding(
                                get: { preset.name },
                                set: { model.settings.renameUserPreset(id: preset.id, to: $0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        Picker(
                            "Размещение",
                            selection: Binding(
                                get: { preset.placement },
                                set: { model.settings.setUserPresetPlacement(id: preset.id, placement: $0) }
                            )
                        ) {
                            ForEach(PresetPlacement.allCases) { Text($0.title).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 175)
                    }

                    HStack {
                        Text(presetSummary(preset))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Button("Редактировать") {
                            beginEditing(preset)
                        }
                        .buttonStyle(.borderless)
                        Button("Применить") {
                            guard let id = selectedDisplay?.id else { return }
                            model.apply(preset, to: id, enableProtection: false)
                        }
                        .buttonStyle(.borderless)
                        .disabled(selectedDisplay == nil || selectedDisplayIsAutomatic)
                        Button {
                            guard let displayID = selectedDisplay?.id else { return }
                            model.settings.updateUserPreset(
                                id: preset.id,
                                configuration: model.displayConfiguration(for: displayID)
                            )
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Обновить пресет \(preset.name) текущими настройками")
                        .help("Сохранить параметры выбранного дисплея в этот пресет")
                        Button(role: .destructive) {
                            model.settings.deleteUserPreset(id: preset.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Удалить пресет \(preset.name)")
                    }
                }
                .padding(10)
                .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Button("Импорт JSON", action: model.importPresets)
                Button("Экспорт JSON", action: model.exportPresets)
                    .disabled(model.settings.customPresets.isEmpty)
            }
            .buttonStyle(.bordered)
        }
    }

    private var timerSection: some View {
        settingsCard(title: "Таймер и паузы", symbol: "timer") {
            settingToggle(
                title: "Напоминать сделать перерыв",
                description: "Ненавязчивая подсказка без системных уведомлений.",
                value: Binding(
                    get: { model.settings.breakReminders },
                    set: { model.settings.breakReminders = $0 }
                )
            )
            HStack {
                Text("Напомнить через")
                Spacer()
                Picker("Интервал", selection: Binding(
                    get: { model.settings.breakIntervalMinutes },
                    set: { model.settings.breakIntervalMinutes = $0 }
                )) {
                    ForEach(breakIntervals, id: \.self) { Text("\($0) минут").tag($0) }
                }
                .frame(width: 150)
                .disabled(!model.settings.breakReminders)
            }
        }
    }

    private var comfortSection: some View {
        settingsCard(title: "Комфорт по умолчанию", symbol: "eye") {
            settingToggle(
                title: "Paper Mode",
                description: "Применить состояние ко всем подключённым дисплеям.",
                value: Binding(
                    get: { model.settings.paperMode },
                    set: { model.setPaperModeForAllDisplays($0) }
                )
            )
            Divider()
            settingToggle(
                title: "Фокус по краям",
                description: "Мягко затемняет периферию, не блокируя интерфейс.",
                value: Binding(
                    get: { model.settings.focusEdges },
                    set: { model.setFocusEdgesForAllDisplays($0) }
                )
            )
            HStack {
                Text("Интенсивность фокуса")
                Slider(
                    value: Binding(
                        get: { model.settings.focusIntensity },
                        set: { model.setFocusIntensityForAllDisplays($0) }
                    ),
                    in: 0.10...1.0
                )
                .accessibilityLabel("Интенсивность фокуса по краям")
                Text("\(Int(model.settings.focusIntensity * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 38, alignment: .trailing)
            }
            .disabled(!model.settings.focusEdges)
        }
    }

    private var diagnosticsSection: some View {
        settingsCard(title: "Диагностика дисплеев", symbol: "stethoscope") {
            ForEach(model.diagnostics) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name).font(.callout.weight(.semibold))
                        Spacer()
                        Label(
                            item.coversFullFrame ? "Полное покрытие" : "Проверь покрытие",
                            systemImage: item.coversFullFrame ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(item.coversFullFrame ? Color.green : Color.orange)
                    }
                    Text("frame: \(item.frame)")
                    Text("visibleFrame: \(item.visibleFrame)")
                    Text("scale: \(item.scaleFactor, specifier: "%.2f")× · id: \(item.id)")
                    Text("overlay: \(item.overlayFrame ?? "эффект не запущен")")
                }
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .padding(10)
                .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                Button("Проверить дисплеи", action: model.highlightDisplays)
                    .buttonStyle(.borderedProminent)
                Button("Экспортировать отчёт", action: model.exportDiagnosticReport)
                    .buttonStyle(.bordered)
            }
            Text("Подсветка длится 1,2 секунды, покрывает полный frame и не перехватывает ввод.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var helpSection: some View {
        settingsCard(title: "Доступность и помощь", symbol: "accessibility") {
            Text("Все основные действия доступны с клавиатуры и имеют VoiceOver-описания. Выбранные состояния обозначаются цветом, рамкой и галочкой.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                UserDefaults.standard.set(false, forKey: "didFinishOnboarding.v10")
                NSApplication.shared.activate(ignoringOtherApps: true)
            } label: {
                Label("Показать онбординг при следующем открытии", systemImage: "rectangle.on.rectangle")
            }
            .buttonStyle(.bordered)
        }
    }

    private var resetSection: some View {
        HStack {
            Spacer()
            Button("Сбросить настройки", role: .destructive) { model.settings.reset() }
        }
    }

    private func displaySettings(for display: DisplayInfo) -> some View {
        let configuration = model.displayConfiguration(for: display.id)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(display.name).font(.headline)
                    Text("\(display.isBuiltIn ? "Встроенный" : "Внешний") · \(display.resolution)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("Эффект", isOn: displayBinding(\.isEnabled, displayID: display.id))
                    .toggleStyle(.switch)
            }

            Picker("Режим", selection: Binding(
                get: { model.displayConfiguration(for: display.id).mode },
                set: { model.setMode($0, for: display.id) }
            )) {
                ForEach(UserMode.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) }
            }

            HStack {
                Text(configuration.presetLabel(customPresets: model.settings.customPresets))
                    .font(.caption.weight(.semibold))
                Spacer()
                Menu("Выбрать пресет") {
                    ForEach(model.presetItems) { item in
                        Button(item.settingsTitle) {
                            model.apply(item, to: display.id, enableProtection: false)
                        }
                    }
                }
                .disabled(configuration.mode == .auto)
                .help(configuration.mode == .auto
                      ? "В AI-режиме профиль выбирается автоматически"
                      : "Выбрать пресет для этого дисплея")
            }

            labeledSlider(
                title: "Сила эффекта",
                value: Binding(
                    get: { model.displayConfiguration(for: display.id).intensity },
                    set: { value in model.updateDisplayConfiguration(for: display.id) { $0.intensity = value } }
                ),
                range: 0.10...1.0
            )

            if configuration.mode == .auto {
                HStack {
                    Text("Настройка изображения")
                        .font(.callout)
                    Spacer()
                    Label("Управляет AI", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Теплотой, Paper Mode и фокусом по краям управляет AI")
            } else {
                labeledSlider(
                    title: "Теплота",
                    value: Binding(
                        get: { model.displayConfiguration(for: display.id).warmth },
                        set: { value in model.updateDisplayConfiguration(for: display.id) { $0.warmth = value } }
                    ),
                    range: 0.0...1.0
                )

                HStack {
                    Toggle("Paper Mode", isOn: displayBinding(\.paperMode, displayID: display.id))
                    Toggle("Фокус по краям", isOn: displayBinding(\.focusEdges, displayID: display.id))
                }

                labeledSlider(
                    title: "Интенсивность Paper Mode",
                    value: Binding(
                        get: { model.displayConfiguration(for: display.id).paperIntensity },
                        set: { value in model.updateDisplayConfiguration(for: display.id) { $0.paperIntensity = value } }
                    ),
                    range: 0.10...1.0
                )
                .disabled(!configuration.paperMode)

                labeledSlider(
                    title: "Интенсивность фокуса",
                    value: Binding(
                        get: { model.displayConfiguration(for: display.id).focusIntensity },
                        set: { value in model.updateDisplayConfiguration(for: display.id) { $0.focusIntensity = value } }
                    ),
                    range: 0.10...1.0
                )
                .disabled(!configuration.focusEdges)
            }
        }
        .padding(.vertical, 4)
    }

    private func scheduleEventRow(
        title: String,
        symbol: String,
        minutes: Binding<Int>,
        mode: Binding<UserMode>,
        shouldEnable: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.callout.weight(.semibold))
                .frame(width: 90, alignment: .leading)
            DatePicker(
                "Время",
                selection: dateBinding(minutes),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            Picker("Режим", selection: mode) {
                ForEach(UserMode.allCases) { Text($0.title).tag($0) }
            }
            .frame(width: 125)
            Toggle("Включить", isOn: shouldEnable)
                .toggleStyle(.switch)
        }
    }

    private func labeledSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        HStack {
            Text(title).font(.callout)
            Slider(value: value, in: range)
                .accessibilityLabel(title)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func presetEditorSlider(
        title: String,
        hint: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(hint).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 145, alignment: .leading)
            Slider(value: value, in: range)
                .accessibilityLabel(title)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func presetSummary(_ preset: UserPreset) -> String {
        var parts = [
            preset.mode.title,
            "затемнение \(Int(preset.intensity * 100))%",
            "теплота \(Int(preset.warmth * 100))%"
        ]
        if preset.paperMode {
            parts.append("Paper \(Int(preset.paperIntensity * 100))%")
        }
        if preset.focusEdges {
            parts.append("Focus \(Int(preset.focusIntensity * 100))%")
        }
        return parts.joined(separator: " · ")
    }

    private func beginEditing(_ preset: UserPreset) {
        editingPresetID = preset.id
        newPresetName = preset.name
        presetSymbol = preset.symbol
        presetPlacement = preset.placement
        var configuration = DisplayConfiguration()
        configuration.apply(preset)
        if configuration.mode == .auto { configuration.mode = .work }
        presetDraft = configuration
        isPresetEditorExpanded = true
    }

    private func savePresetDraft() {
        if let editingPresetID {
            model.updateUserPreset(
                id: editingPresetID,
                named: newPresetName,
                configuration: presetDraft,
                symbol: presetSymbol,
                placement: presetPlacement,
                applyTo: selectedDisplay?.id
            )
        } else {
            model.saveUserPreset(
                named: newPresetName,
                configuration: presetDraft,
                symbol: presetSymbol,
                placement: presetPlacement,
                to: selectedDisplay?.id
            )
        }
        resetPresetEditor()
    }

    private func resetPresetEditor() {
        editingPresetID = nil
        newPresetName = ""
        presetDraft = DisplayConfiguration(mode: .work)
        presetSymbol = UserPreset.availableSymbols[0]
        presetPlacement = .additional
    }

    private func settingsCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol).font(.headline)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.065), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private func settingToggle(
        title: String,
        description: String,
        value: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.weight(.medium))
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(title, isOn: value).labelsHidden()
        }
    }

    private var selectedDisplay: DisplayInfo? {
        model.displays.first { $0.id == selectedDisplayID } ?? model.displays.first
    }

    private var selectedDisplayIsAutomatic: Bool {
        guard let id = selectedDisplay?.id else { return false }
        return model.displayConfiguration(for: id).mode == .auto
    }

    private var selectedDisplayBinding: Binding<String?> {
        Binding(get: { selectedDisplay?.id }, set: { selectedDisplayID = $0 })
    }

    private func selectAvailableDisplay() {
        guard !model.displays.isEmpty else { selectedDisplayID = nil; return }
        if !model.displays.contains(where: { $0.id == selectedDisplayID }) {
            selectedDisplayID = model.displays.first?.id
        }
    }

    private func displayBinding(
        _ keyPath: WritableKeyPath<DisplayConfiguration, Bool>,
        displayID: String
    ) -> Binding<Bool> {
        Binding(
            get: { model.displayConfiguration(for: displayID)[keyPath: keyPath] },
            set: { value in model.updateDisplayConfiguration(for: displayID) { $0[keyPath: keyPath] = value } }
        )
    }

    private func scheduleBinding<Value>(
        _ keyPath: WritableKeyPath<ScheduleSettings, Value>
    ) -> Binding<Value> {
        Binding(
            get: { model.settings.schedule[keyPath: keyPath] },
            set: { value in
                var schedule = model.settings.schedule
                schedule[keyPath: keyPath] = value
                model.settings.schedule = schedule
            }
        )
    }

    private func dateBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: minutes.wrappedValue / 60,
                    minute: minutes.wrappedValue % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                minutes.wrappedValue = Calendar.current.component(.hour, from: date) * 60
                    + Calendar.current.component(.minute, from: date)
            }
        )
    }
}

struct PresetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: DisplayConfiguration

    private var appearance: AdaptiveAppearance {
        AdaptiveEngine().appearance(
            profile: previewProfile,
            intensity: configuration.intensity,
            displayBrightness: 0.70,
            sessionMinutes: 90,
            paperEnabled: configuration.paperMode,
            focusEdgesEnabled: configuration.focusEdges,
            hour: 22,
            focusIntensity: configuration.focusIntensity,
            warmth: configuration.warmth,
            paperIntensity: configuration.paperIntensity
        )
    }

    private var previewProfile: ActiveProfile {
        switch configuration.mode {
        case .auto, .work: return .work
        case .read: return .reading
        case .night: return .night
        case .play: return .gaming
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Предпросмотр эффекта")
                        .font(.title2.bold())
                    Text("Светлая тестовая сцена показывает затемнение, цвет и фокус по краям.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Готово") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            ZStack {
                Color.white
                VStack(alignment: .leading, spacing: 20) {
                    Text("Комфортное чтение вечером")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                    Text("NightMode смягчает яркий фон и сохраняет элементы интерфейса читаемыми. Эта сцена специально сделана светлой, чтобы сила эффекта была заметна сразу.")
                        .font(.title3)
                        .foregroundStyle(.black.opacity(0.82))
                        .frame(maxWidth: 560, alignment: .leading)
                    HStack(spacing: 12) {
                        previewCard("Документ", symbol: "doc.text")
                        previewCard("Таблица", symbol: "tablecells")
                        previewCard("Браузер", symbol: "safari")
                    }
                }
                .padding(42)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Color(
                    red: appearance.red,
                    green: appearance.green,
                    blue: appearance.blue
                )
                .opacity(appearance.alpha)

                if appearance.paperOpacity > 0 {
                    Color(red: 0.50, green: 0.31, blue: 0.12)
                        .blendMode(.softLight)
                        .opacity(appearance.paperOpacity)
                }

                if appearance.edgeOpacity > 0 {
                    RadialGradient(
                        colors: [.clear, .black.opacity(appearance.edgeOpacity)],
                        center: .center,
                        startRadius: 100,
                        endRadius: 430
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.primary.opacity(0.18))
            }

            HStack {
                Label("\(Int(configuration.intensity * 100))% затемнения", systemImage: "sun.min")
                Label("\(Int(configuration.warmth * 100))% теплоты", systemImage: "sun.haze")
                if configuration.focusEdges {
                    Label("\(Int(configuration.focusIntensity * 100))% фокуса", systemImage: "scope")
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(width: 760, height: 540)
    }

    private func previewCard(_ title: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.title)
            Text(title).font(.headline)
        }
        .foregroundStyle(.black.opacity(0.78))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}
