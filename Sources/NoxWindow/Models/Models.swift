import Foundation
import Carbon

struct HotKeyShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var displayKey: String

    static let `default` = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_N),
        modifiers: UInt32(controlKey | optionKey | cmdKey),
        displayKey: "N"
    )

    var displayText: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + displayKey
    }
}

enum UserMode: String, CaseIterable, Identifiable, Codable {
    case auto, work, read, night, play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "AI"
        case .work: return "Работа"
        case .read: return "Чтение"
        case .night: return "Ночь"
        case .play: return "Игры"
        }
    }

    var symbol: String {
        switch self {
        case .auto: return "sparkles"
        case .work: return "briefcase.fill"
        case .read: return "book.fill"
        case .night: return "circle.lefthalf.filled"
        case .play: return "gamecontroller.fill"
        }
    }
}

enum QuickPreset: String, CaseIterable, Identifiable, Codable {
    case soft
    case reading
    case focus
    case color

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft: return "Мягко"
        case .reading: return "Чтение"
        case .focus: return "Фокус"
        case .color: return "Цвет"
        }
    }

    var settingsTitle: String {
        switch self {
        case .soft: return "Мягкий вечер"
        case .reading: return "Долгое чтение"
        case .focus: return "Глубокий фокус"
        case .color: return "Точный цвет"
        }
    }

    var symbol: String {
        switch self {
        case .soft: return "moon.stars"
        case .reading: return "book"
        case .focus: return "scope"
        case .color: return "paintpalette"
        }
    }

    var mode: UserMode {
        switch self {
        case .soft: return .auto
        case .reading: return .read
        case .focus: return .work
        case .color: return .play
        }
    }

    var intensity: Double {
        switch self {
        case .soft: return 0.34
        case .reading: return 0.46
        case .focus: return 0.52
        case .color: return 0.18
        }
    }

    var paperMode: Bool {
        switch self {
        case .soft, .reading: return true
        case .focus, .color: return false
        }
    }

    var focusEdges: Bool {
        self == .focus
    }

    var focusIntensity: Double {
        self == .focus ? 0.72 : 0.45
    }

    var warmth: Double { 0.50 }
    var paperIntensity: Double { 0.50 }
}

enum PresetPlacement: String, CaseIterable, Identifiable, Codable {
    case additional
    case replaceSoft
    case replaceReading
    case replaceFocus
    case replaceColor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .additional: return "Добавить рядом"
        case .replaceSoft: return "Вместо «Мягко»"
        case .replaceReading: return "Вместо «Чтение»"
        case .replaceFocus: return "Вместо «Фокус»"
        case .replaceColor: return "Вместо «Цвет»"
        }
    }

    var replacedPreset: QuickPreset? {
        switch self {
        case .additional: return nil
        case .replaceSoft: return .soft
        case .replaceReading: return .reading
        case .replaceFocus: return .focus
        case .replaceColor: return .color
        }
    }
}

struct UserPreset: Identifiable, Codable, Equatable {
    static let maximumCount = 5
    static let availableSymbols = [
        "slider.horizontal.3", "moon.stars", "book", "scope",
        "paintpalette", "sun.haze", "eye", "sparkles"
    ]

    var id: UUID
    var name: String
    var symbol: String
    var mode: UserMode
    var intensity: Double
    var paperMode: Bool
    var focusEdges: Bool
    var focusIntensity: Double
    var warmth: Double
    var paperIntensity: Double
    var placement: PresetPlacement

    init(
        id: UUID = UUID(),
        name: String,
        configuration: DisplayConfiguration,
        symbol: String = "slider.horizontal.3",
        placement: PresetPlacement = .additional
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.symbol = Self.availableSymbols.contains(symbol) ? symbol : Self.availableSymbols[0]
        mode = configuration.mode
        intensity = configuration.intensity
        paperMode = configuration.paperMode
        focusEdges = configuration.focusEdges
        focusIntensity = configuration.focusIntensity
        warmth = configuration.warmth
        paperIntensity = configuration.paperIntensity
        self.placement = placement
    }

    func matches(_ configuration: DisplayConfiguration) -> Bool {
        mode == configuration.mode &&
        abs(intensity - configuration.intensity) < 0.001 &&
        paperMode == configuration.paperMode &&
        focusEdges == configuration.focusEdges &&
        abs(focusIntensity - configuration.focusIntensity) < 0.001 &&
        abs(warmth - configuration.warmth) < 0.001 &&
        abs(paperIntensity - configuration.paperIntensity) < 0.001
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, symbol, mode, intensity, paperMode, focusEdges, focusIntensity
        case warmth, paperIntensity, placement
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        let decodedSymbol = try values.decodeIfPresent(String.self, forKey: .symbol)
            ?? Self.availableSymbols[0]
        symbol = Self.availableSymbols.contains(decodedSymbol) ? decodedSymbol : Self.availableSymbols[0]
        mode = try values.decode(UserMode.self, forKey: .mode)
        intensity = min(max(try values.decode(Double.self, forKey: .intensity), 0.10), 1.0)
        paperMode = try values.decode(Bool.self, forKey: .paperMode)
        focusEdges = try values.decode(Bool.self, forKey: .focusEdges)
        focusIntensity = min(max(
            try values.decodeIfPresent(Double.self, forKey: .focusIntensity) ?? 0.45,
            0.10
        ), 1.0)
        warmth = min(max(
            try values.decodeIfPresent(Double.self, forKey: .warmth) ?? 0.50,
            0.0
        ), 1.0)
        paperIntensity = min(max(
            try values.decodeIfPresent(Double.self, forKey: .paperIntensity) ?? 0.50,
            0.10
        ), 1.0)
        placement = try values.decodeIfPresent(PresetPlacement.self, forKey: .placement) ?? .additional
    }
}

enum PresetItem: Identifiable, Equatable {
    case builtIn(QuickPreset)
    case custom(UserPreset)

    var id: String {
        switch self {
        case .builtIn(let preset): return "built-in-\(preset.rawValue)"
        case .custom(let preset): return "custom-\(preset.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .builtIn(let preset): return preset.title
        case .custom(let preset): return preset.name
        }
    }

    var settingsTitle: String {
        switch self {
        case .builtIn(let preset): return preset.settingsTitle
        case .custom(let preset): return preset.name
        }
    }

    var symbol: String {
        switch self {
        case .builtIn(let preset): return preset.symbol
        case .custom(let preset): return preset.symbol
        }
    }

    func matches(_ configuration: DisplayConfiguration) -> Bool {
        switch self {
        case .builtIn(let preset): return configuration.matches(preset)
        case .custom(let preset): return preset.matches(configuration)
        }
    }
}

struct PresetCatalog {
    func items(customPresets: [UserPreset]) -> [PresetItem] {
        let replacements = Dictionary(
            customPresets.compactMap { preset in
                preset.placement.replacedPreset.map { ($0, preset) }
            },
            uniquingKeysWith: { _, latest in latest }
        )
        let slots = QuickPreset.allCases.map { preset in
            replacements[preset].map(PresetItem.custom) ?? .builtIn(preset)
        }
        let additional = customPresets
            .filter { $0.placement == .additional }
            .map(PresetItem.custom)
        return slots + additional
    }
}

struct PresetArchive: Codable, Equatable {
    let formatVersion: Int
    let presets: [UserPreset]

    init(presets: [UserPreset]) {
        formatVersion = 1
        self.presets = presets
    }
}

enum ScheduleKind: String, CaseIterable, Identifiable, Codable {
    case fixed
    case sun

    var id: String { rawValue }
    var title: String {
        switch self {
        case .fixed: return "По времени"
        case .sun: return "Закат–рассвет"
        }
    }
}

struct ScheduleSettings: Codable, Equatable {
    var isEnabled = false
    var kind: ScheduleKind = .fixed
    var morningMinutes = 7 * 60
    var eveningMinutes = 20 * 60
    var sunriseMinutes = 7 * 60
    var sunsetMinutes = 20 * 60
    var morningMode: UserMode = .work
    var eveningMode: UserMode = .night
    var enableInMorning = false
    var enableInEvening = true

    var hasDistinctTimes: Bool {
        let activeMorning = kind == .sun ? sunriseMinutes : morningMinutes
        let activeEvening = kind == .sun ? sunsetMinutes : eveningMinutes
        return activeMorning != activeEvening
    }

    func events() -> [ScheduleEvent] {
        [
            ScheduleEvent(
                minutes: kind == .sun ? sunriseMinutes : morningMinutes,
                mode: morningMode,
                shouldEnable: enableInMorning,
                phase: .morning
            ),
            ScheduleEvent(
                minutes: kind == .sun ? sunsetMinutes : eveningMinutes,
                mode: eveningMode,
                shouldEnable: enableInEvening,
                phase: .evening
            )
        ].sorted { $0.minutes < $1.minutes }
    }
}

enum SchedulePhase: String, Codable {
    case morning
    case evening

    var title: String { self == .morning ? "Утро" : "Вечер" }
}

struct ScheduleEvent: Equatable {
    let minutes: Int
    let mode: UserMode
    let shouldEnable: Bool
    let phase: SchedulePhase
}

struct ScheduleDecision: Equatable {
    let event: ScheduleEvent
    let nextTransition: Date
}

struct ScheduleEngine {
    func decision(
        settings: ScheduleSettings,
        at date: Date = Date(),
        calendar: Calendar = .current
    ) -> ScheduleDecision? {
        guard settings.isEnabled else { return nil }
        let events = settings.events()
        guard events.count == 2, settings.hasDistinctTimes else { return nil }

        let currentMinutes = calendar.component(.hour, from: date) * 60
            + calendar.component(.minute, from: date)
        let currentEventIndex = events.lastIndex { $0.minutes <= currentMinutes }
        let activeIndex = currentEventIndex ?? events.index(before: events.endIndex)
        let nextIndex = events.index(after: activeIndex) == events.endIndex
            ? events.startIndex
            : events.index(after: activeIndex)
        let active = events[activeIndex]
        let next = events[nextIndex]
        let dayOffset = currentEventIndex == events.index(before: events.endIndex) ? 1 : 0
        let startOfDay = calendar.startOfDay(for: date)
        let transitionDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay)
            ?? startOfDay
        let nextTransition = calendar.date(
            byAdding: .minute,
            value: next.minutes,
            to: transitionDay
        ) ?? date.addingTimeInterval(60)
        return ScheduleDecision(event: active, nextTransition: nextTransition)
    }

    func overrideDeadline(
        requested: Date? = nil,
        decision: ScheduleDecision
    ) -> Date {
        min(requested ?? decision.nextTransition, decision.nextTransition)
    }

    func overrideIsActive(until deadline: Date?, at date: Date = Date()) -> Bool {
        deadline.map { $0 > date } ?? false
    }
}

enum SmartPauseOption {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case tomorrowMorning

    func minutes(from now: Date = Date(), calendar: Calendar = .current) -> Int {
        switch self {
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 60
        case .twoHours: return 120
        case .tomorrowMorning:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)
                ?? now.addingTimeInterval(86_400)
            let target = calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: tomorrow
            ) ?? tomorrow
            return max(1, Int(ceil(target.timeIntervalSince(now) / 60)))
        }
    }
}

struct DisplayConfiguration: Codable, Equatable {
    var isEnabled: Bool
    var preset: QuickPreset
    var mode: UserMode
    var intensity: Double
    var paperMode: Bool
    var focusEdges: Bool
    var focusIntensity: Double
    var warmth: Double
    var paperIntensity: Double
    var customPresetID: UUID?

    init(
        isEnabled: Bool = true,
        preset: QuickPreset = .soft,
        mode: UserMode? = nil,
        intensity: Double = 0.34,
        paperMode: Bool = true,
        focusEdges: Bool = false,
        focusIntensity: Double = 0.45,
        warmth: Double = 0.50,
        paperIntensity: Double = 0.50,
        customPresetID: UUID? = nil
    ) {
        self.isEnabled = isEnabled
        self.preset = preset
        self.mode = mode ?? preset.mode
        self.intensity = intensity
        self.paperMode = paperMode
        self.focusEdges = focusEdges
        self.focusIntensity = focusIntensity
        self.warmth = warmth
        self.paperIntensity = paperIntensity
        self.customPresetID = customPresetID
    }

    mutating func apply(_ preset: QuickPreset) {
        self.preset = preset
        mode = preset.mode
        intensity = preset.intensity
        paperMode = preset.paperMode
        focusEdges = preset.focusEdges
        focusIntensity = preset.focusIntensity
        warmth = preset.warmth
        paperIntensity = preset.paperIntensity
        customPresetID = nil
    }

    mutating func apply(_ preset: UserPreset) {
        mode = preset.mode
        intensity = preset.intensity
        paperMode = preset.paperMode
        focusEdges = preset.focusEdges
        focusIntensity = preset.focusIntensity
        warmth = preset.warmth
        paperIntensity = preset.paperIntensity
        customPresetID = preset.id
    }

    func matches(_ preset: QuickPreset) -> Bool {
        self.preset == preset &&
        mode == preset.mode &&
        abs(intensity - preset.intensity) < 0.001 &&
        paperMode == preset.paperMode &&
        focusEdges == preset.focusEdges &&
        abs(focusIntensity - preset.focusIntensity) < 0.001 &&
        abs(warmth - preset.warmth) < 0.001 &&
        abs(paperIntensity - preset.paperIntensity) < 0.001 &&
        customPresetID == nil
    }

    func presetLabel(customPresets: [UserPreset]) -> String {
        if let customPresetID,
           let preset = customPresets.first(where: { $0.id == customPresetID }) {
            return preset.matches(self) ? preset.name : "\(preset.name) · изменён"
        }
        if let preset = QuickPreset.allCases.first(where: { matches($0) }) {
            return preset.settingsTitle
        }
        return "\(preset.settingsTitle) · изменён"
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, preset, mode, intensity, paperMode, focusEdges
        case focusIntensity, warmth, paperIntensity, customPresetID
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try values.decode(Bool.self, forKey: .isEnabled)
        preset = try values.decode(QuickPreset.self, forKey: .preset)
        mode = try values.decodeIfPresent(UserMode.self, forKey: .mode) ?? preset.mode
        intensity = min(max(try values.decode(Double.self, forKey: .intensity), 0.10), 1.0)
        paperMode = try values.decode(Bool.self, forKey: .paperMode)
        focusEdges = try values.decode(Bool.self, forKey: .focusEdges)
        focusIntensity = min(max(
            try values.decodeIfPresent(Double.self, forKey: .focusIntensity) ?? 0.45,
            0.10
        ), 1.0)
        warmth = min(max(
            try values.decodeIfPresent(Double.self, forKey: .warmth) ?? 0.50,
            0.0
        ), 1.0)
        paperIntensity = min(max(
            try values.decodeIfPresent(Double.self, forKey: .paperIntensity) ?? 0.50,
            0.10
        ), 1.0)
        customPresetID = try values.decodeIfPresent(UUID.self, forKey: .customPresetID)
    }
}

struct DisplayInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let resolution: String
    let isBuiltIn: Bool
    let frameDescription: String
    let visibleFrameDescription: String
    let scaleFactor: Double
}

struct DisplayDiagnostic: Identifiable, Equatable {
    let id: String
    let name: String
    let frame: String
    let visibleFrame: String
    let scaleFactor: Double
    let overlayFrame: String?
    let overlayIsVisible: Bool
    let coversFullFrame: Bool
}

struct DisplayGeometry {
    static func fullyCovers(
        overlay: CGRect,
        display: CGRect,
        tolerance: CGFloat = 0.5
    ) -> Bool {
        abs(overlay.origin.x - display.origin.x) < tolerance &&
        abs(overlay.origin.y - display.origin.y) < tolerance &&
        abs(overlay.width - display.width) < tolerance &&
        abs(overlay.height - display.height) < tolerance
    }
}

enum ActiveProfile: String {
    case whiteboard = "Доска"
    case coding = "Код"
    case work = "Работа"
    case reading = "Чтение"
    case creative = "Цвет"
    case media = "Видео"
    case gaming = "Игры"
    case night = "Ночь"
    case neutral = "Обычный"

    var symbol: String {
        switch self {
        case .whiteboard: return "rectangle.and.pencil.and.ellipsis"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .work: return "briefcase.fill"
        case .reading: return "book.fill"
        case .creative: return "paintpalette.fill"
        case .media: return "play.rectangle.fill"
        case .gaming: return "gamecontroller.fill"
        case .night: return "circle.lefthalf.filled"
        case .neutral: return "display"
        }
    }
}

struct AdaptiveAppearance: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    let paperOpacity: Double
    let edgeOpacity: Double
}
