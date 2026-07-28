import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    let finish: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "sparkles",
            eyebrow: "AI AUTO",
            title: "Включи и забудь о настройках",
            text: "MyNightMode сам выбирает профиль по активному приложению, яркости, времени суток и длительности работы. Нажми «Почему AI?» в интерфейсе, чтобы увидеть логику выбора."
        ),
        OnboardingPage(
            symbol: "slider.horizontal.3",
            eyebrow: "ОДИН РЕГУЛЯТОР",
            title: "Настрой общую силу эффекта",
            text: "Это не системная яркость, а масштаб смягчения изображения. Начни с 35–50%. Режим AI продолжит адаптировать итог под ситуацию."
        ),
        OnboardingPage(
            symbol: "doc.text",
            eyebrow: "PAPER MODE",
            title: "Белые страницы становятся мягче",
            text: "Paper Mode снижает ощущение резкого белого фона и глянца. Он полезен для браузера, PDF, таблиц и документов, но почти не вмешивается в видео и цветокоррекцию."
        ),
        OnboardingPage(
            symbol: "scope",
            eyebrow: "ФОКУС ПО КРАЯМ",
            title: "Меньше визуального шума",
            text: "Очень мягкая виньетка слегка затемняет периферию, оставляя рабочую область в центре светлее. Все окна и кнопки продолжают работать как обычно."
        ),
        OnboardingPage(
            symbol: "timer",
            eyebrow: "SMART PAUSE",
            title: "Пауза без риска забыть включить обратно",
            text: "Через кнопку с таймером эффект можно остановить на 15, 30 или 60 минут. Затем MyNightMode автоматически продолжит работу."
        ),
        OnboardingPage(
            symbol: "lock.shield",
            eyebrow: "ПРИВАТНОСТЬ",
            title: "Локально и без записи экрана",
            text: "Приложение не видит содержимое окон, не перехватывает клики и не требует Screen Recording. Для адаптации используются только название активного приложения и локальные параметры Mac."
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                if page > 0 {
                    Button("Пропустить") { finish() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 11) {
                Text(pages[page].eyebrow)
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Image(systemName: pages[page].symbol)
                    .font(.system(size: 27, weight: .medium))
                    .frame(width: 52, height: 52)
                    .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                Text(pages[page].title)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(pages[page].text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 405)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if page == 2 {
                Toggle("Paper Mode", isOn: Binding(
                    get: { model.settings.paperMode },
                    set: { model.settings.paperMode = $0 }
                ))
                .toggleStyle(.switch)
                .frame(width: 180)
            } else if page == 3 {
                Toggle("Фокус по краям", isOn: Binding(
                    get: { model.settings.focusEdges },
                    set: { model.settings.focusEdges = $0 }
                ))
                .toggleStyle(.switch)
                .frame(width: 210)
            }

            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.primary : Color.secondary.opacity(0.28))
                        .frame(width: index == page ? 22 : 7, height: 7)
                }
            }

            HStack(spacing: 10) {
                if page > 0 {
                    Button("Назад") {
                        withAnimation(.easeInOut(duration: 0.2)) { page -= 1 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(page == pages.count - 1 ? "Начать работу" : "Дальше") {
                    if page == pages.count - 1 {
                        finish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .controlSize(.large)
            }

            Spacer()

            Text("Обучение всегда доступно через кнопку ? и пункт «Обучение»")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(26)
    }
}

private struct OnboardingPage {
    let symbol: String
    let eyebrow: String
    let title: String
    let text: String
}
