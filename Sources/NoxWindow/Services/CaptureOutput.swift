import CoreMedia
import Foundation
import ScreenCaptureKit

final class CaptureOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    let queue = DispatchQueue(label: "com.selfztt1337.mynightmode.capture", qos: .userInteractive)
    var onImage: ((CGImage) -> Void)?
    var onError: ((Error) -> Void)?

    private let renderer = FrameRenderer()
    private let lock = NSLock()
    private var mode: RenderMode = .smartDark
    private var intensity: Double = 0.82

    func update(mode: RenderMode, intensity: Double) {
        lock.lock()
        self.mode = mode
        self.intensity = intensity
        lock.unlock()
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onError?(error)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen, sampleBuffer.isValid else { return }
        lock.lock()
        let currentMode = mode
        let currentIntensity = intensity
        lock.unlock()
        guard let image = renderer.render(sampleBuffer: sampleBuffer, mode: currentMode, intensity: currentIntensity) else { return }
        onImage?(image)
    }
}
