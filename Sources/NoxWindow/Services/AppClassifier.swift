import AppKit
import Foundation

final class AppClassifier {
    private var cachedProfiles: [String: ActiveProfile] = [:]

    func profile(for app: NSRunningApplication?) -> ActiveProfile {
        guard let app else { return .neutral }
        let cacheKey = app.bundleIdentifier ?? app.bundleURL?.path ?? app.localizedName ?? "unknown"
        if let cached = cachedProfiles[cacheKey] { return cached }
        let category = app.bundleURL
            .flatMap(Bundle.init(url:))?
            .object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        let result = profile(
            bundleIdentifier: app.bundleIdentifier,
            name: app.localizedName,
            category: category
        )
        if cachedProfiles.count >= 128 { cachedProfiles.removeAll(keepingCapacity: true) }
        cachedProfiles[cacheKey] = result
        return result
    }

    func profile(
        bundleIdentifier: String?,
        name: String?,
        category: String?
    ) -> ActiveProfile {
        let value = "\(bundleIdentifier ?? "") \(name ?? "") \(category ?? "")".lowercased()

        if containsAny(value, ["miro", "figma", "figjam", "whimsical", "mural", "freeform", "graphics-design"]) {
            return .whiteboard
        }
        if containsAny(value, ["visual studio code", "vscode", "cursor", "xcode", "zed", "sublime", "nova", "terminal", "iterm", "warp", "github desktop", "developer-tools"]) {
            return .coding
        }
        if containsAny(value, ["photoshop", "lightroom", "illustrator", "affinity", "capture one", "davinci", "final cut", "premiere", "blender", "cinema 4d", "photography", "video"]) {
            return .creative
        }
        if containsAny(value, ["steam", "epicgames", "gog", "battle.net", "minecraft", "wine", "whisky", "crossover", "geforce now", "game", "games"]) {
            return .gaming
        }
        if containsAny(value, ["vlc", "iina", "quicktime", "tv.app", "netflix", "plex", "infuse", "music", "entertainment"]) {
            return .media
        }
        if containsAny(value, ["books", "kindle", "preview", "pdf", "reader", "pocket", "reeder", "news", "calibre", "reference"]) {
            return .reading
        }
        if containsAny(value, ["safari", "chrome", "arc", "firefox", "opera", "brave", "edge", "orion"]) {
            return .reading
        }
        if containsAny(value, ["notion", "slack", "mattermost", "zoom", "teams", "telegram", "excel", "word", "powerpoint", "obsidian", "linear", "jira", "mail", "calendar", "business", "productivity", "finance", "social-networking"]) {
            return .work
        }
        // Любое неизвестное foreground-приложение получает безопасный рабочий
        // профиль вместо зависимости от закрытого списка bundle identifier.
        return .work
    }

    private func containsAny(_ value: String, _ tokens: [String]) -> Bool {
        tokens.contains(where: value.contains)
    }
}
