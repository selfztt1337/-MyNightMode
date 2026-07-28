import Carbon
import Combine
import Foundation

@main
enum BehaviorChecks {
    @MainActor
    static func main() {
        checkPresets()
        checkHotKey()
        checkSmartPause()
        checkAdaptiveAppearance()
        checkStableAppearanceIdentity()
        checkLegacyDisplayConfigurationDecoding()
        checkSettingsPersistence()
        print("✅ Core behavior checks passed")
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
        }

        var configuration = DisplayConfiguration()
        configuration.apply(.focus)
        configuration.intensity += 0.01
        precondition(!configuration.matches(.focus))
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
    }

    @MainActor
    private static func checkSettingsPersistence() {
        let suiteName = "app.mynightmode.BehaviorChecks"
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
        original.updateDisplayConfiguration(for: "external-display") {
            $0.apply(.focus)
            $0.isEnabled = false
        }
        original.updateDisplayConfiguration(for: "external-display") {
            $0.intensity = 0.73
        }
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
        precondition(!configuration.isEnabled)
        precondition(abs(configuration.intensity - 0.73) < 0.000_001)
        precondition(configuration.mode == .work)
        precondition(configuration.paperMode == false)
        precondition(configuration.focusEdges == true)
        precondition(restored.displayConfiguration(for: "display-a").matches(.reading))
        precondition(restored.displayConfiguration(for: "display-b").matches(.reading))
    }
}
