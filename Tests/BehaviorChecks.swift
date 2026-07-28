import Carbon
import Combine
import Foundation

@main
enum BehaviorChecks {
    @MainActor
    static func main() {
        checkPresets()
        checkAppClassification()
        checkHotKey()
        checkSmartPause()
        checkSchedule()
        checkUserPresets()
        checkPresetCatalog()
        checkAdaptiveAppearance()
        checkStableAppearanceIdentity()
        checkDisplayGeometry()
        checkLegacyDisplayConfigurationDecoding()
        checkSettingsPersistence()
        print("✅ Core behavior checks passed")
    }

    private static func checkDisplayGeometry() {
        let display = CGRect(x: 1920, y: -120, width: 3440, height: 1440)
        precondition(DisplayGeometry.fullyCovers(overlay: display, display: display))
        precondition(DisplayGeometry.fullyCovers(
            overlay: CGRect(x: 1920.2, y: -119.8, width: 3439.8, height: 1440.2),
            display: display
        ))
        precondition(!DisplayGeometry.fullyCovers(
            overlay: CGRect(x: 1920, y: -120, width: 1720, height: 1440),
            display: display
        ))
    }

    private static func checkPresets() {
        for preset in QuickPreset.allCases {
            var configuration = DisplayConfiguration()
            configuration.apply(preset)

            precondition(configuration.matches(preset))
            precondition(configuration.preset == preset)
            precondition(configuration.mode == preset.mode)
            precondition(abs(configuration.intensity - preset.intensity) < 0.000_001)
            precondition(configuration.paperMode == preset.paperMode)
            precondition(configuration.focusEdges == preset.focusEdges)
            precondition(abs(configuration.focusIntensity - preset.focusIntensity) < 0.000_001)
            precondition(abs(configuration.warmth - preset.warmth) < 0.000_001)
            precondition(abs(configuration.paperIntensity - preset.paperIntensity) < 0.000_001)
        }

        var configuration = DisplayConfiguration()
        configuration.apply(.focus)
        configuration.intensity += 0.01
        precondition(!configuration.matches(.focus))
    }

    private static func checkAppClassification() {
        let classifier = AppClassifier()
        precondition(classifier.profile(
            bundleIdentifier: "com.apple.dt.Xcode",
            name: "Xcode",
            category: "public.app-category.developer-tools"
        ) == .coding)
        precondition(classifier.profile(
            bundleIdentifier: "com.example.unknown-game",
            name: "Never Seen Before",
            category: "public.app-category.games"
        ) == .gaming)
        precondition(classifier.profile(
            bundleIdentifier: "com.example.brand-new",
            name: "Brand New App",
            category: nil
        ) == .work)
    }

    private static func checkSchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let morning = calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 28, hour: 8
        ))!
        let night = calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 28, hour: 22
        ))!
        let beforeMorning = calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 28, hour: 5
        ))!
        var settings = ScheduleSettings()
        settings.isEnabled = true
        settings.morningMinutes = 7 * 60
        settings.eveningMinutes = 20 * 60

        let morningDecision = ScheduleEngine().decision(
            settings: settings,
            at: morning,
            calendar: calendar
        )
        precondition(morningDecision?.event.phase == .morning)
        precondition(morningDecision?.event.mode == .work)
        precondition(morningDecision?.event.shouldEnable == false)
        precondition(calendar.component(.hour, from: morningDecision!.nextTransition) == 20)

        let eveningDecision = ScheduleEngine().decision(
            settings: settings,
            at: night,
            calendar: calendar
        )
        precondition(eveningDecision?.event.phase == .evening)
        precondition(eveningDecision?.event.mode == .night)
        precondition(eveningDecision?.event.shouldEnable == true)
        precondition(calendar.component(.day, from: eveningDecision!.nextTransition) == 29)

        let earlyDecision = ScheduleEngine().decision(
            settings: settings,
            at: beforeMorning,
            calendar: calendar
        )
        precondition(earlyDecision?.event.phase == .evening)
        precondition(calendar.component(.day, from: earlyDecision!.nextTransition) == 28)
        precondition(calendar.component(.hour, from: earlyDecision!.nextTransition) == 7)
        let requestedPause = calendar.date(byAdding: .hour, value: 24, to: beforeMorning)!
        precondition(
            ScheduleEngine().overrideDeadline(requested: requestedPause, decision: earlyDecision!)
                == earlyDecision!.nextTransition
        )
        precondition(ScheduleEngine().overrideIsActive(
            until: earlyDecision!.nextTransition,
            at: beforeMorning
        ))
        precondition(!ScheduleEngine().overrideIsActive(
            until: earlyDecision!.nextTransition,
            at: earlyDecision!.nextTransition
        ))

        settings.kind = .sun
        settings.sunriseMinutes = 6 * 60
        settings.sunsetMinutes = 21 * 60
        precondition(
            ScheduleEngine().decision(settings: settings, at: night, calendar: calendar)?.event.phase
                == .evening
        )
        settings.sunsetMinutes = settings.sunriseMinutes
        precondition(ScheduleEngine().decision(settings: settings, at: night, calendar: calendar) == nil)
    }

    private static func checkUserPresets() {
        var configuration = DisplayConfiguration()
        configuration.apply(.reading)
        configuration.focusIntensity = 0.81
        configuration.warmth = 0.77
        configuration.paperIntensity = 0.68
        let preset = UserPreset(
            name: "  Мой вечер  ",
            configuration: configuration,
            placement: .replaceReading
        )
        precondition(preset.name == "Мой вечер")
        precondition(preset.symbol == "slider.horizontal.3")
        precondition(preset.placement == .replaceReading)
        var restored = DisplayConfiguration()
        restored.apply(preset)
        precondition(preset.matches(restored))
        precondition(abs(restored.warmth - 0.77) < 0.000_001)
        precondition(abs(restored.paperIntensity - 0.68) < 0.000_001)
        precondition(restored.presetLabel(customPresets: [preset]) == "Мой вечер")
        restored.intensity += 0.02
        precondition(restored.presetLabel(customPresets: [preset]) == "Мой вечер · изменён")

        let data = try! JSONEncoder().encode(PresetArchive(presets: [preset]))
        let archive = try! JSONDecoder().decode(PresetArchive.self, from: data)
        precondition(archive.formatVersion == 1)
        precondition(archive.presets == [preset])

        let legacyJSON = """
        {
          "id": "\(UUID().uuidString)",
          "name": "Старый пресет",
          "mode": "read",
          "intensity": 0.46,
          "paperMode": true,
          "focusEdges": false,
          "focusIntensity": 0.45
        }
        """.data(using: .utf8)!
        let legacy = try! JSONDecoder().decode(UserPreset.self, from: legacyJSON)
        precondition(legacy.placement == .additional)
        precondition(legacy.symbol == "slider.horizontal.3")
        precondition(abs(legacy.warmth - 0.50) < 0.000_001)
        precondition(abs(legacy.paperIntensity - 0.50) < 0.000_001)

        let invalidRangeJSON = """
        {
          "id": "\(UUID().uuidString)",
          "name": "Некорректные диапазоны",
          "mode": "work",
          "intensity": 8,
          "paperMode": true,
          "focusEdges": true,
          "focusIntensity": -4,
          "warmth": 3,
          "paperIntensity": 0
        }
        """.data(using: .utf8)!
        let normalized = try! JSONDecoder().decode(UserPreset.self, from: invalidRangeJSON)
        precondition(normalized.intensity == 1)
        precondition(normalized.focusIntensity == 0.10)
        precondition(normalized.warmth == 1)
        precondition(normalized.paperIntensity == 0.10)
    }

    private static func checkPresetCatalog() {
        var readingConfiguration = DisplayConfiguration()
        readingConfiguration.apply(.reading)
        let replacement = UserPreset(
            name: "Моё чтение",
            configuration: readingConfiguration,
            placement: .replaceReading
        )
        var nightConfiguration = DisplayConfiguration()
        nightConfiguration.mode = .night
        let additional = UserPreset(
            name: "После полуночи",
            configuration: nightConfiguration
        )
        let items = PresetCatalog().items(customPresets: [replacement, additional])
        precondition(items.count == QuickPreset.allCases.count + 1)
        precondition(items[1] == .custom(replacement))
        precondition(items.last == .custom(additional))
        precondition(items.contains(.builtIn(.soft)))
        precondition(!items.contains(.builtIn(.reading)))
    }

    private static func checkHotKey() {
        precondition(HotKeyShortcut.default.keyCode == UInt32(kVK_ANSI_N))
        precondition(HotKeyShortcut.default.displayText == "⌃⌥⌘N")
    }

    private static func checkSmartPause() {
        precondition(SmartPauseOption.fifteenMinutes.minutes() == 15)
        precondition(SmartPauseOption.thirtyMinutes.minutes() == 30)
        precondition(SmartPauseOption.oneHour.minutes() == 60)
        precondition(SmartPauseOption.twoHours.minutes() == 120)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(
            year: 2026,
            month: 7,
            day: 28,
            hour: 22,
            minute: 30
        ))!
        precondition(SmartPauseOption.tomorrowMorning.minutes(from: now, calendar: calendar) == 630)
    }

    private static func checkAdaptiveAppearance() {
        let engine = AdaptiveEngine()
        let daytimeCreative = engine.automaticTuning(profile: .creative, hour: 12)
        let nighttimeReading = engine.automaticTuning(profile: .reading, hour: 23)
        precondition(!daytimeCreative.paperEnabled)
        precondition(!daytimeCreative.focusEdgesEnabled)
        precondition(nighttimeReading.paperEnabled)
        precondition(nighttimeReading.focusEdgesEnabled)
        precondition(nighttimeReading.warmth > daytimeCreative.warmth)

        let profiles: [ActiveProfile] = [
            .whiteboard,
            .coding,
            .work,
            .reading,
            .creative,
            .media,
            .gaming,
            .night,
            .neutral
        ]

        for profile in profiles {
            let appearance = engine.appearance(
                profile: profile,
                intensity: 1,
                displayBrightness: 1,
                sessionMinutes: 300,
                paperEnabled: true,
                focusEdgesEnabled: true,
                hour: 23
            )

            precondition((0...0.70).contains(appearance.alpha))
            precondition(appearance.paperOpacity >= 0)
            precondition(appearance.edgeOpacity >= 0)
        }

        let subtleFocus = engine.appearance(
            profile: .work,
            intensity: 0.5,
            displayBrightness: 0.5,
            sessionMinutes: 0,
            paperEnabled: false,
            focusEdgesEnabled: true,
            hour: 12,
            focusIntensity: 0.10
        )
        let strongFocus = engine.appearance(
            profile: .work,
            intensity: 0.5,
            displayBrightness: 0.5,
            sessionMinutes: 0,
            paperEnabled: false,
            focusEdgesEnabled: true,
            hour: 12,
            focusIntensity: 1.0
        )
        precondition(strongFocus.edgeOpacity > subtleFocus.edgeOpacity)

        let cool = engine.appearance(
            profile: .reading,
            intensity: 0.5,
            displayBrightness: 0.5,
            sessionMinutes: 0,
            paperEnabled: true,
            focusEdgesEnabled: false,
            hour: 12,
            warmth: 0,
            paperIntensity: 0.2
        )
        let warm = engine.appearance(
            profile: .reading,
            intensity: 0.5,
            displayBrightness: 0.5,
            sessionMinutes: 0,
            paperEnabled: true,
            focusEdgesEnabled: false,
            hour: 12,
            warmth: 1,
            paperIntensity: 1
        )
        precondition(warm.red > cool.red)
        precondition(warm.blue < cool.blue)
        precondition(warm.paperOpacity > cool.paperOpacity)
    }

    private static func checkStableAppearanceIdentity() {
        let engine = AdaptiveEngine()
        let first = engine.appearance(
            profile: .reading,
            intensity: 0.46,
            displayBrightness: 0.55,
            sessionMinutes: 20,
            paperEnabled: true,
            focusEdgesEnabled: false,
            hour: 22
        )
        let second = engine.appearance(
            profile: .reading,
            intensity: 0.46,
            displayBrightness: 0.55,
            sessionMinutes: 20,
            paperEnabled: true,
            focusEdgesEnabled: false,
            hour: 22
        )

        precondition(first == second)
    }

    private static func checkLegacyDisplayConfigurationDecoding() {
        let legacyJSON = """
        {
          "isEnabled": true,
          "preset": "reading",
          "intensity": 0.46,
          "paperMode": true,
          "focusEdges": false
        }
        """.data(using: .utf8)!

        let configuration = try! JSONDecoder().decode(
            DisplayConfiguration.self,
            from: legacyJSON
        )
        precondition(configuration.mode == .read)
        precondition(configuration.matches(.reading))
        precondition(abs(configuration.warmth - 0.50) < 0.000_001)
        precondition(abs(configuration.paperIntensity - 0.50) < 0.000_001)

        let invalidJSON = """
        {
          "isEnabled": true,
          "preset": "soft",
          "mode": "work",
          "intensity": -10,
          "paperMode": true,
          "focusEdges": true,
          "focusIntensity": 99,
          "warmth": -3,
          "paperIntensity": 4
        }
        """.data(using: .utf8)!
        let normalized = try! JSONDecoder().decode(DisplayConfiguration.self, from: invalidJSON)
        precondition(normalized.intensity == 0.10)
        precondition(normalized.focusIntensity == 1)
        precondition(normalized.warmth == 0)
        precondition(normalized.paperIntensity == 1)
    }

    @MainActor
    private static func checkSettingsPersistence() {
        let suiteName = "app.nightmode.BehaviorChecks"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let shortcut = HotKeyShortcut(
            keyCode: 49,
            modifiers: UInt32(controlKey | optionKey),
            displayKey: "Space"
        )
        let original = SettingsStore(defaults: defaults)
        original.hotKeyShortcut = shortcut
        var schedule = ScheduleSettings()
        schedule.isEnabled = true
        schedule.kind = .sun
        original.schedule = schedule
        original.updateDisplayConfiguration(for: "external-display") {
            $0.apply(.focus)
            $0.isEnabled = false
        }
        original.updateDisplayConfiguration(for: "external-display") {
            $0.intensity = 0.73
            $0.focusIntensity = 0.82
        }
        let userPreset = original.saveUserPreset(
            named: "Рабочий монитор",
            configuration: original.displayConfiguration(for: "external-display")
        )
        precondition(userPreset != nil)
        let competingPreset = original.saveUserPreset(
            named: "Другой фокус",
            configuration: DisplayConfiguration(),
            placement: .replaceFocus
        )
        precondition(competingPreset != nil)
        original.setUserPresetPlacement(id: userPreset!.id, placement: .replaceFocus)
        precondition(
            original.customPresets.first(where: { $0.id == userPreset!.id })?.placement
                == .replaceFocus
        )
        precondition(
            original.customPresets.first(where: { $0.id == competingPreset!.id })?.placement
                == .additional
        )
        for index in original.customPresets.count..<UserPreset.maximumCount {
            precondition(original.saveUserPreset(
                named: "Пресет \(index)",
                configuration: DisplayConfiguration()
            ) != nil)
        }
        precondition(original.customPresets.count == UserPreset.maximumCount)
        precondition(original.saveUserPreset(
            named: "Лишний",
            configuration: DisplayConfiguration()
        ) == nil)
        original.updateUserPreset(
            id: userPreset!.id,
            name: "Обновлённый",
            symbol: "eye",
            configuration: original.displayConfiguration(for: "external-display"),
            placement: .replaceFocus
        )
        precondition(original.customPresets.first(where: { $0.id == userPreset!.id })?.name == "Обновлённый")
        precondition(original.customPresets.first(where: { $0.id == userPreset!.id })?.symbol == "eye")
        var batchChangeCount = 0
        let batchObserver = original.objectWillChange.sink {
            batchChangeCount += 1
        }
        original.updateDisplayConfigurations(for: ["display-a", "display-b"]) {
            $0.apply(.reading)
        }
        withExtendedLifetime(batchObserver) {}
        precondition(batchChangeCount == 1)

        let restored = SettingsStore(defaults: defaults)
        let configuration = restored.displayConfiguration(for: "external-display")
        precondition(restored.hotKeyShortcut == shortcut)
        precondition(restored.schedule == schedule)
        precondition(restored.customPresets.count == UserPreset.maximumCount)
        precondition(!configuration.isEnabled)
        precondition(abs(configuration.intensity - 0.73) < 0.000_001)
        precondition(configuration.mode == .work)
        precondition(configuration.paperMode == false)
        precondition(configuration.focusEdges == true)
        precondition(abs(configuration.focusIntensity - 0.82) < 0.000_001)
        precondition(restored.displayConfiguration(for: "display-a").matches(.reading))
        precondition(restored.displayConfiguration(for: "display-b").matches(.reading))
    }
}
