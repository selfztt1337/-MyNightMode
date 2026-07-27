import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            Text("MyNightMode").font(.title.bold())
            Text("Минималистичный eye-comfort фильтр для macOS")
                .foregroundStyle(.secondary)
            Text("created by @selfztt1337").font(.callout.weight(.semibold))
        }
        .padding(28)
        .frame(width: 380, height: 260)
    }
}
