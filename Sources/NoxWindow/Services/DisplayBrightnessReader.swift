import Foundation
import IOKit
import IOKit.graphics

final class DisplayBrightnessReader {
    func currentBrightness() -> Double? {
        let classes = ["AppleBacklightDisplay", "IODisplayConnect"]
        for className in classes {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(className))
            guard service != 0 else { continue }
            defer { IOObjectRelease(service) }

            var value: Float = 0
            let result = IODisplayGetFloatParameter(
                service,
                IOOptionBits(0),
                kIODisplayBrightnessKey as CFString,
                &value
            )
            if result == kIOReturnSuccess, value.isFinite {
                return min(max(Double(value), 0), 1)
            }
        }
        return nil
    }
}
