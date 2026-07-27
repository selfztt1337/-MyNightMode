import Foundation

struct AdaptiveEngine {
    func appearance(
        profile: ActiveProfile,
        intensity: Double,
        displayBrightness: Double?,
        sessionMinutes: Double,
        paperEnabled: Bool,
        focusEdgesEnabled: Bool,
        hour: Int
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

        return AdaptiveAppearance(
            red: rgb.0,
            green: rgb.1,
            blue: rgb.2,
            alpha: alpha,
            paperOpacity: paperEnabled ? paper : 0.0,
            edgeOpacity: focusEdgesEnabled ? edge : 0.0
        )
    }
}
