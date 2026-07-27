import AppKit
import Foundation

struct AppClassifier {
    func profile(for app: NSRunningApplication?) -> ActiveProfile {
        guard let app else { return .neutral }
        let value = "\(app.bundleIdentifier ?? "") \(app.localizedName ?? "")".lowercased()

        if containsAny(value, ["miro", "figma", "figjam", "whimsical", "mural", "freeform"]) {
            return .whiteboard
        }
        if containsAny(value, ["visual studio code", "vscode", "cursor", "xcode", "zed", "sublime", "nova", "terminal", "iterm", "warp", "github desktop"]) {
            return .coding
        }
        if containsAny(value, ["photoshop", "lightroom", "illustrator", "affinity", "capture one", "davinci", "final cut", "premiere", "blender", "cinema 4d"]) {
            return .creative
        }
        if containsAny(value, ["steam", "epicgames", "gog", "battle.net", "minecraft", "wine", "whisky", "crossover", "geforce now", "game"]) {
            return .gaming
        }
        if containsAny(value, ["vlc", "iina", "quicktime", "tv.app", "netflix", "plex", "infuse", "music"]) {
            return .media
        }
        if containsAny(value, ["books", "kindle", "preview", "pdf", "reader", "pocket", "reeder", "news", "calibre"]) {
            return .reading
        }
        if containsAny(value, ["safari", "chrome", "arc", "firefox", "opera", "brave", "edge", "orion"]) {
            return .reading
        }
        if containsAny(value, ["notion", "slack", "mattermost", "zoom", "teams", "telegram", "excel", "word", "powerpoint", "obsidian", "linear", "jira", "mail", "calendar"]) {
            return .work
        }
        return .neutral
    }

    private func containsAny(_ value: String, _ tokens: [String]) -> Bool {
        tokens.contains(where: value.contains)
    }
}
