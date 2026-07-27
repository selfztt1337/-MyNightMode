import AppKit
import Foundation

struct AppClassifier {
    func profile(for app: NSRunningApplication?) -> ActiveProfile {
        guard let app else { return .neutral }
        let id = (app.bundleIdentifier ?? "").lowercased()
        let name = (app.localizedName ?? "").lowercased()
        let value = id + " " + name

        let playTokens = ["steam", "epicgames", "gog", "battle.net", "minecraft", "wine", "whisky", "crossover", "game"]
        if playTokens.contains(where: value.contains) { return .play }

        let readTokens = ["books", "kindle", "preview", "pdf", "reader", "pocket", "reeder", "news"]
        if readTokens.contains(where: value.contains) { return .read }

        let workTokens = ["miro", "figma", "visual studio code", "vscode", "cursor", "xcode", "notion", "slack", "mattermost", "zoom", "teams", "telegram", "excel", "word", "powerpoint", "obsidian", "terminal", "iterm", "warp", "github"]
        if workTokens.contains(where: value.contains) { return .work }

        let browserTokens = ["safari", "chrome", "arc", "firefox", "opera", "brave", "edge"]
        if browserTokens.contains(where: value.contains) { return .read }

        return .neutral
    }
}
