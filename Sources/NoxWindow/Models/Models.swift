import Foundation

enum UserMode: String, CaseIterable, Identifiable {
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
