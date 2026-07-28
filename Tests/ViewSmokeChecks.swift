import AppKit
import SwiftUI

@main
enum ViewSmokeChecks {
    @MainActor
    static func main() {
        _ = NSApplication.shared
        let model = AppModel()

        check(
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 520, height: 750)
        )
        check(
            MenuBarView()
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 370, height: 760)
        )
        check(
            SettingsView(model: model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 720, height: 680)
        )
        check(
            OnboardingView(finish: {})
                .environmentObject(model)
                .preferredColorScheme(.dark),
            frame: NSRect(x: 0, y: 0, width: 520, height: 750)
        )

        print("✅ View smoke checks passed: 4/4")
    }

    @MainActor
    private static func check<Content: View>(_ view: Content, frame: NSRect) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = frame
        hostingView.layoutSubtreeIfNeeded()

        precondition(hostingView.fittingSize.width > 0)
        precondition(hostingView.fittingSize.height > 0)
    }
}
