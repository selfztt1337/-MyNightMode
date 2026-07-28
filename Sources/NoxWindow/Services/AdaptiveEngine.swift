import Foundation

struct AutomaticImageTuning: Equatable {
    let warmth: Double
    let paperEnabled: Bool
    let paperIntensity: Double
    let focusEdgesEnabled: Bool
    let focusIntensity: Double
}

struct AdaptiveEngine {
    func automaticTuning(profile: ActiveProfile, hour: Int) -> AutomaticImageTuning {
        let isLate = hour >= 21 || hour < 7
        switch profile {
        case .whiteboard:
            return .init(warmth: isLate ? 0.68 : 0.56, paperEnabled: true, paperIntensity: 0.72, focusEdgesEnabled: true, focusIntensity: 0.42)
        case .coding:
            return .init(warmth: isLate ? 0.64 : 0.48, paperEnabled: true, paperIntensity: 0.34, focusEdgesEnabled: true, focusIntensity: 0.38)
        case .work:
            return .init(warmth: isLate ? 0.66 : 0.52, paperEnabled: true, paperIntensity: 0.44, focusEdgesEnabled: true, focusIntensity: 0.32)
        case .reading:
            return .init(warmth: isLate ? 0.82 : 0.68, paperEnabled: true, paperIntensity: 0.78, focusEdgesEnabled: true, focusIntensity: 0.48)
        case .night:
            return .init(warmth: 0.90, paperEnabled: true, paperIntensity: 0.68, focusEdgesEnabled: true, focusIntensity: 0.52)
        case .creative:
            return .init(warmth: 0.50, paperEnabled: false, paperIntensity: 0.10, focusEdgesEnabled: false, focusIntensity: 0.10)
        case .media, .gaming:
            return .init(warmth: isLate ? 0.54 : 0.50, paperEnabled: false, paperIntensity: 0.10, focusEdgesEnabled: false, focusIntensity: 0.10)
        case .neutral:
            return .init(warmth: isLate ? 0.64 : 0.52, paperEnabled: true, paperIntensity: 0.40, focusEdgesEnabled: false, focusIntensity: 0.10)
        }
    }

    func appearance(
        profile: ActiveProfile,
        intensity: Double,
        displayBrightness: Double?,
        sessionMinutes: Double,
        paperEnabled: Bool,
        focusEdgesEnabled: Bool,
        hour: Int,
        focusIntensity: Double = 0.45,
        warmth: Double = 0.50,
        paperIntensity: Double = 0.50
    ) -> AdaptiveAppearance {
        let strength = min(max(intensity, 0.10), 1.0)
        let brightness = displayBrightness ?? 0.55
        let nightBoost = (hour >= 21 || hour < 7) ? 0.055 : 0.0
        let brightnessBoost = max(0.0, brightness - 0.35) * 0.22
        let fatigueBoost = min(max(sessionMinutes - 40.0, 0.0) / 140.0, 1.0) * 0.045

        let base: Double
        let rgb: (Double, Double, Double)
        let paper: Double
        let edge: Double

        switch profile {
        case .whiteboard:
            base = 0.20; rgb = (0.018, 0.020, 0.026); paper = 0.050; edge = 0.16
        case .coding:
            base = 0.12; rgb = (0.018, 0.024, 0.038); paper = 0.020; edge = 0.10
        case .work:
            base = 0.13; rgb = (0.024, 0.027, 0.038); paper = 0.025; edge = 0.08
        case .reading:
            base = 0.16; rgb = (0.100, 0.048, 0.014); paper = 0.065; edge = 0.11
        case .creative:
            base = 0.025; rgb = (0.010, 0.010, 0.012); paper = 0.0; edge = 0.0
        case .media:
            base = 0.012; rgb = (0.008, 0.010, 0.016); paper = 0.0; edge = 0.0
        case .gaming:
            base = 0.008; rgb = (0.008, 0.010, 0.016); paper = 0.0; edge = 0.0
        case .night:
            base = 0.23; rgb = (0.116, 0.036, 0.008); paper = 0.050; edge = 0.13
        case .neutral:
            base = 0.10; rgb = (0.024, 0.024, 0.032); paper = 0.020; edge = 0.06
        }

        let contextScale: Double = switch profile {
        case .creative, .media, .gaming: 0.30
        default: 1.0
        }

        let alpha = min(0.70, max(0.0,
            base + strength * 0.30 * contextScale + brightnessBoost * contextScale + nightBoost * contextScale + fatigueBoost * contextScale
        ))
        let warmthShift = min(max(warmth, 0.0), 1.0) - 0.50
        let adjustedRed = min(0.24, max(0.0, rgb.0 + warmthShift * 0.16))
        let adjustedGreen = min(0.18, max(0.0, rgb.1 + warmthShift * 0.035))
        let adjustedBlue = min(0.18, max(0.0, rgb.2 - warmthShift * 0.10))
        let paperScale = min(max(paperIntensity, 0.10), 1.0) / 0.50

        return AdaptiveAppearance(
            red: adjustedRed,
            green: adjustedGreen,
            blue: adjustedBlue,
            alpha: alpha,
            paperOpacity: paperEnabled ? min(0.16, paper * paperScale) : 0.0,
            edgeOpacity: focusEdgesEnabled
                ? min(0.35, edge * min(max(focusIntensity, 0.10), 1.0) / 0.45)
                : 0.0
        )
    }
}
