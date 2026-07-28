import SwiftUI

struct BrandFooterView: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            Link(destination: URL(string: "https://github.com/selfztt1337/-NightMode")!) {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Link(destination: URL(string: "https://t.me/selfztt1337")!) {
                Label("Telegram", systemImage: "paperplane")
            }
            Spacer(minLength: 4)
            Text("@selfztt1337 · NightMode")
        }
        .font(compact ? .caption2 : .caption)
        .foregroundStyle(.tertiary)
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
    }
}
