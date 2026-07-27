import CoreImage
import CoreMedia
import Metal

final class FrameRenderer {
    private let context: CIContext
    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device, options: [.cacheIntermediates: false, .priorityRequestLow: false])
        } else {
            context = CIContext(options: [.cacheIntermediates: false])
        }
    }

    func render(sampleBuffer: CMSampleBuffer, mode: RenderMode, intensity: Double) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let source = CIImage(cvPixelBuffer: pixelBuffer)
        let amount = min(max(intensity, 0.15), 1)
        let output: CIImage

        switch mode {
        case .adaptive:
            output = source.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -1.1 * amount])
        case .smartDark:
            let inverted = source.applyingFilter("CIColorInvert")
            let monochromeMask = source
                .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.0, kCIInputContrastKey: 1.35])
                .applyingFilter("CIGammaAdjust", parameters: ["inputPower": 1.35])
            output = inverted
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0.78,
                    kCIInputContrastKey: 1.06,
                    kCIInputBrightnessKey: -0.03
                ])
                .applyingFilter("CIBlendWithMask", parameters: [
                    kCIInputBackgroundImageKey: source.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -1.15 * amount]),
                    kCIInputMaskImageKey: monochromeMask
                ])
        case .dimWhites:
            output = source
                .applyingFilter("CIHighlightShadowAdjust", parameters: ["inputHighlightAmount": 1.0 - 0.82 * amount, "inputShadowAmount": 0.0])
                .applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -0.55 * amount])
        case .invertLightness:
            output = source.applyingFilter("CIColorInvert")
                .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.85, kCIInputContrastKey: 1.05])
        case .simpleDim:
            output = source.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: -1.4 * amount])
        }
        return context.createCGImage(output, from: output.extent)
    }
}
