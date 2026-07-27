import AppKit
import CoreGraphics

actor WindowCatalog {
    private let excludedOwners: Set<String> = [
        "Dock", "Window Server", "Control Center", "Notification Center",
        "SystemUIServer", "Finder", "MyNightMode"
    ]

    func fetchWindows() async throws -> [WindowDescriptor] {
        guard let rawList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

        let windows: [WindowDescriptor] = rawList.compactMap { info in
            guard
                let number = info[kCGWindowNumber as String] as? NSNumber,
                let pidNumber = info[kCGWindowOwnerPID as String] as? NSNumber,
                let ownerName = info[kCGWindowOwnerName as String] as? String,
                let layerNumber = info[kCGWindowLayer as String] as? NSNumber,
                let alphaNumber = info[kCGWindowAlpha as String] as? NSNumber,
                let boundsRaw = info[kCGWindowBounds as String],
                CFGetTypeID(boundsRaw as CFTypeRef) == CFDictionaryGetTypeID(),
                let bounds = CGRect(dictionaryRepresentation: boundsRaw as! CFDictionary)
            else { return nil }

            let pid = pid_t(pidNumber.int32Value)
            guard pid != ownPID,
                  layerNumber.intValue == 0,
                  alphaNumber.doubleValue > 0.01,
                  bounds.width >= 260,
                  bounds.height >= 180,
                  !excludedOwners.contains(ownerName)
            else { return nil }

            let running = NSRunningApplication(processIdentifier: pid)
            let appName = running?.localizedName ?? ownerName
            let bundleID = running?.bundleIdentifier ?? "pid.\(pid)"
            let title = (info[kCGWindowName as String] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return WindowDescriptor(
                id: CGWindowID(number.uint32Value),
                appName: appName,
                bundleIdentifier: bundleID,
                title: title,
                ownerPID: pid,
                bounds: bounds,
                appIcon: running?.icon
            )
        }

        return windows
            .reduce(into: [CGWindowID: WindowDescriptor]()) { result, window in result[window.id] = window }
            .values
            .sorted { lhs, rhs in
                let lhsActive = lhs.ownerPID == frontPID
                let rhsActive = rhs.ownerPID == frontPID
                if lhsActive != rhsActive { return lhsActive }
                let lhsMiro = lhs.appName.localizedCaseInsensitiveContains("Miro")
                let rhsMiro = rhs.appName.localizedCaseInsensitiveContains("Miro")
                if lhsMiro != rhsMiro { return lhsMiro }
                if lhs.appName != rhs.appName {
                    return lhs.appName.localizedStandardCompare(rhs.appName) == .orderedAscending
                }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    func bestWindow(forPID pid: pid_t) async throws -> WindowDescriptor? {
        let candidates = try await fetchWindows().filter { $0.ownerPID == pid }
        return candidates.max { ($0.bounds.width * $0.bounds.height) < ($1.bounds.width * $1.bounds.height) }
    }

    func snapshot(for windowID: CGWindowID) -> WindowSnapshot? {
        guard let list = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let info = list.first,
              let boundsRaw = info[kCGWindowBounds as String],
              CFGetTypeID(boundsRaw as CFTypeRef) == CFDictionaryGetTypeID(),
              let bounds = CGRect(dictionaryRepresentation: boundsRaw as! CFDictionary),
              let ownerPID = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value
        else { return nil }

        return WindowSnapshot(
            bounds: bounds,
            isOnScreen: (info[kCGWindowIsOnscreen as String] as? Bool) ?? true,
            ownerPID: pid_t(ownerPID)
        )
    }
}
