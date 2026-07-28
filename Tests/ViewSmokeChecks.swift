import AppKit
import SwiftUI

@main
enum ViewSmokeChecks {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        let suiteName = "app.nightmode.ViewSmokeChecks"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(settings: SettingsStore(defaults: defaults))

        check(
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 520, height: 820),
            minimumSize: NSSize(width: 520, height: 820),
            maximumSize: NSSize(width: 520, height: 820)
        )
        check(
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.light),
            frame: NSRect(x: 0, y: 0, width: 520, height: 820),
            minimumSize: NSSize(width: 520, height: 820),
            maximumSize: NSSize(width: 520, height: 820)
        )
        check(
            MenuBarView()
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 370, height: 760),
            minimumSize: NSSize(width: 360, height: 560)
        )
        check(
            SettingsView(model: model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 780, height: 820),
            minimumSize: NSSize(width: 780, height: 820)
        )
        check(
            SettingsView(model: model)
                .preferredColorScheme(.light),
            frame: NSRect(x: 0, y: 0, width: 780, height: 820),
            minimumSize: NSSize(width: 780, height: 820)
        )
        check(
            OnboardingView(finish: {})
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 520, height: 750)
        )
        check(
            OnboardingView(finish: {})
                .environmentObject(model)
                .preferredColorScheme(.light),
            frame: NSRect(x: 0, y: 0, width: 520, height: 750)
        )
        var previewConfiguration = DisplayConfiguration()
        previewConfiguration.intensity = 0.70
        previewConfiguration.focusEdges = true
        previewConfiguration.focusIntensity = 0.80
        check(
            PresetPreviewView(configuration: previewConfiguration)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 760, height: 540),
            minimumSize: NSSize(width: 740, height: 520)
        )
        check(
            PresetPreviewView(configuration: previewConfiguration)
                .preferredColorScheme(.light),
            frame: NSRect(x: 0, y: 0, width: 760, height: 540),
            minimumSize: NSSize(width: 740, height: 520)
        )

        let diagnosticReport = model.diagnosticReport()
        let localHomePrefix = "/" + "Users/"
        precondition(!diagnosticReport.contains(localHomePrefix))
        precondition(!diagnosticReport.contains(NSFullUserName()))
        for display in model.displays where !display.name.isEmpty {
            precondition(!diagnosticReport.contains(display.name))
        }

        if let displayID = model.displays.first?.id {
            model.previewPreset(previewConfiguration, on: displayID, duration: 0)
            precondition(!model.isEnabled)

            var livePreview = DisplayConfiguration(mode: .work)
            livePreview.intensity = 0.70
            model.previewPreset(livePreview, on: displayID, duration: 0.04)
            model.previewPreset(livePreview, on: displayID, duration: 0.15)
            precondition(model.isEnabled)
            precondition(model.diagnostics.filter(\.overlayIsVisible).map(\.id) == [displayID])
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            precondition(model.isEnabled)
            RunLoop.main.run(until: Date().addingTimeInterval(0.32))
            precondition(!model.isEnabled)

            model.resumeNow()
            model.previewPreset(livePreview, on: displayID, duration: 0.06)
            RunLoop.main.run(until: Date().addingTimeInterval(0.12))
            precondition(model.isEnabled)
            model.toggle()
            precondition(!model.isEnabled)
        }

        print("✅ View smoke checks passed: 10/10")
    }

    @MainActor
    private static func check<Content: View>(
        _ view: Content,
        frame: NSRect,
        minimumSize: NSSize = .zero,
        maximumSize: NSSize? = nil
    ) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = frame
        hostingView.layoutSubtreeIfNeeded()

        precondition(hostingView.fittingSize.width > 0)
        precondition(hostingView.fittingSize.height > 0)
        precondition(hostingView.fittingSize.width >= minimumSize.width)
        precondition(hostingView.fittingSize.height >= minimumSize.height)
        if let maximumSize {
            precondition(hostingView.fittingSize.width <= maximumSize.width)
            precondition(hostingView.fittingSize.height <= maximumSize.height)
        }
    }
}
