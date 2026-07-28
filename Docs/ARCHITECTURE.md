# Архитектура

1. `AppModel` связывает настройки, глобальный хоткей, Login Item и жизненный цикл эффекта.
2. `SettingsStore` сохраняет глобальные и отдельные настройки дисплеев через `UserDefaults`.
3. `OverlayController` создаёт независимый пассивный `NSPanel` для каждого `NSScreen`.
4. Панели покрывают полный `screen.frame`, работают во всех Spaces и никогда не становятся key/main.
5. `OverlayView` отображает tint, Paper Mode и Focus Edges слоями Core Animation.
6. `AdaptiveEngine` рассчитывает внешний вид по режиму, яркости, времени и длительности сессии.
7. Одинаковые состояния не отправляются в Core Animation повторно; текстура Paper Mode создаётся один раз на процесс.
8. `ContentView`, `MenuBarView` и `SettingsView` используют одну модель и одинаковые конфигурации дисплеев.

Приложение не использует ScreenCaptureKit, Screen Recording или Accessibility и не перехватывает ввод.
