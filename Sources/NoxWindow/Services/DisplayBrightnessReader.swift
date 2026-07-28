import Foundation
import CoreGraphics
import IOKit
import IOKit.graphics

final class DisplayBrightnessReader {
    func currentBrightness(for displayID: CGDirectDisplayID? = nil) -> Double? {
        let classes = ["AppleBacklightDisplay", "IODisplayConnect"]
        for className in classes {
            var iterator: io_iterator_t = 0
            guard IOServiceGetMatchingServices(
                kIOMainPortDefault,
                IOServiceMatching(className),
                &iterator
            ) == kIOReturnSuccess else { continue }
            defer { IOObjectRelease(iterator) }

            while case let displayService = IOIteratorNext(iterator), displayService != 0 {
                defer { IOObjectRelease(displayService) }
                if let displayID, !matches(displayService, displayID: displayID) {
                    continue
                }

                var value: Float = 0
                let result = IODisplayGetFloatParameter(
                    displayService,
                    IOOptionBits(0),
                    kIODisplayBrightnessKey as CFString,
                    &value
                )
                if result == kIOReturnSuccess, value.isFinite {
                    return min(max(Double(value), 0), 1)
                }
            }
        }
        return nil
    }

    private func matches(_ service: io_service_t, displayID: CGDirectDisplayID) -> Bool {
        guard let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName))
            .takeRetainedValue() as? [String: Any] else { return false }
        let vendor = (info[kDisplayVendorID] as? NSNumber)?.uint32Value
        let product = (info[kDisplayProductID] as? NSNumber)?.uint32Value
        let serial = (info[kDisplaySerialNumber] as? NSNumber)?.uint32Value
        guard vendor == CGDisplayVendorNumber(displayID),
              product == CGDisplayModelNumber(displayID) else { return false }
        let targetSerial = CGDisplaySerialNumber(displayID)
        return targetSerial == 0 || serial == nil || serial == targetSerial
    }
}
