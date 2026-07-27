import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Настройки")
                .font(.title2.bold())
            Text("Управление запуском, паузами, комфортом и быстрыми пресетами.")
                .font(.callout)
                .foregroundStyle(.secondary)
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
                presetSettingsButton("Мягкий вечер", symbol: "moon.stars", mode: .auto, intensity: 0.34, paper: true, focus: false)
                presetSettingsButton("Долгое чтение", symbol: "book", mode: .read, intensity: 0.46, paper: true, focus: false)
                presetSettingsButton("Глубокий фокус", symbol: "scope", mode: .work, intensity: 0.52, paper: false, focus: true)
                presetSettingsButton("Точный цвет", symbol: "paintpalette", mode: .play, intensity: 0.18, paper: false, focus: false)
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
                    set: { model.settings.paperMode = $0 }
                )
            )

            Divider()

            settingToggle(
                title: "Фокус по краям",
                description: "Создаёт мягкую виньетку и оставляет центр светлее, не блокируя интерфейс.",
                value: Binding(
                    get: { model.settings.focusEdges },
                    set: { model.settings.focusEdges = $0 }
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

    private func presetSettingsButton(
        _ title: String,
        symbol: String,
        mode: UserMode,
        intensity: Double,
        paper: Bool,
        focus: Bool
    ) -> some View {
        Button {
            model.settings.userMode = mode
            model.settings.intensity = intensity
            model.settings.paperMode = paper
            model.settings.focusEdges = focus
        } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .frame(width: 18)
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
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
