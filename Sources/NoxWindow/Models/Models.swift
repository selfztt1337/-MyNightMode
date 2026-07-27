import AppKit
import Foundation

enum UserMode: String, CaseIterable, Identifiable {
    case auto, work, read, play
    var id: String { rawValue }
    var title: String {
        switch self {
        case .auto: "AI"
        case .work: "Работа"
        case .read: "Чтение"
        case .play: "Игры"
        }
    }
    var symbol: String {
        switch self {
        case .auto: "sparkles"
        case .work: "briefcase.fill"
        case .read: "book.fill"
        case .play: "gamecontroller.fill"
        }
    }
}

enum ActiveProfile: String {
    case work = "Работа"
    case read = "Чтение"
    case play = "Игры"
    case neutral = "Обычный"
}
