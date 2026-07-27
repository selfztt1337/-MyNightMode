import Foundation

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
}

struct DisplayConfiguration: Codable, Equatable {
    var isEnabled: Bool
    var preset: QuickPreset
    var mode: UserMode
    var intensity: Double
    var paperMode: Bool
    var focusEdges: Bool

    init(
        isEnabled: Bool = true,
        preset: QuickPreset = .soft,
        mode: UserMode? = nil,
        intensity: Double = 0.34,
        paperMode: Bool = true,
        focusEdges: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.preset = preset
        self.mode = mode ?? preset.mode
        self.intensity = intensity
        self.paperMode = paperMode
        self.focusEdges = focusEdges
    }

    mutating func apply(_ preset: QuickPreset) {
        self.preset = preset
        mode = preset.mode
        intensity = preset.intensity
        paperMode = preset.paperMode
        focusEdges = preset.focusEdges
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, preset, mode, intensity, paperMode, focusEdges
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try values.decode(Bool.self, forKey: .isEnabled)
        preset = try values.decode(QuickPreset.self, forKey: .preset)
        mode = try values.decodeIfPresent(UserMode.self, forKey: .mode) ?? preset.mode
        intensity = try values.decode(Double.self, forKey: .intensity)
        paperMode = try values.decode(Bool.self, forKey: .paperMode)
        focusEdges = try values.decode(Bool.self, forKey: .focusEdges)
    }
}

struct DisplayInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let resolution: String
    let isBuiltIn: Bool
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

struct AdaptiveAppearance {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    let paperOpacity: Double
    let edgeOpacity: Double
}
