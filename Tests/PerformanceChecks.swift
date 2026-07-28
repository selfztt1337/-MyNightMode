import Foundation

@main
enum PerformanceChecks {
    static func main() {
        let iterations = 1_000_000
        let deduplicate = CommandLine.arguments.contains("--deduplicate")
        let engine = AdaptiveEngine()
        var previous: AdaptiveAppearance?
        var renderSubmissions = 0
        var checksum = 0.0

        let startedAt = DispatchTime.now().uptimeNanoseconds
        for _ in 0..<iterations {
            let appearance = engine.appearance(
                profile: .reading,
                intensity: 0.46,
                displayBrightness: 0.55,
                sessionMinutes: 20,
                paperEnabled: true,
                focusEdgesEnabled: false,
                hour: 22
            )

            if !deduplicate || appearance != previous {
                renderSubmissions += 1
                previous = appearance
            }
            checksum += appearance.alpha
        }
        let elapsed = DispatchTime.now().uptimeNanoseconds - startedAt
        let milliseconds = Double(elapsed) / 1_000_000
        let nanosecondsPerOperation = Double(elapsed) / Double(iterations)

        print("mode=\(deduplicate ? "deduplicated" : "baseline")")
        print("iterations=\(iterations)")
        print(String(format: "elapsed_ms=%.3f", milliseconds))
        print(String(format: "ns_per_operation=%.3f", nanosecondsPerOperation))
        print("render_submissions=\(renderSubmissions)")
        print(String(format: "checksum=%.3f", checksum))
    }
}
