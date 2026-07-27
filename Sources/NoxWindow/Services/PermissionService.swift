import AppKit
import CoreGraphics

@MainActor
final class PermissionService: ObservableObject {
    @Published private(set) var hasScreenRecordingPermission = false

    init() { refresh() }

    func refresh() {
        hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
    }

    func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        refresh()
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
}
