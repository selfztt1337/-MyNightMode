# QA V7

## Проверено статически

- Нет зависимости от ScreenCaptureKit, Screen Recording и Accessibility.
- Полноэкранный overlay создаётся отдельно для каждого `NSScreen`.
- Overlay использует `ignoresMouseEvents = true` и не может стать key/main window.
- Overlay подключается ко всем Spaces через `canJoinAllSpaces` и `fullScreenAuxiliary`.
- При смене конфигурации дисплеев панели пересоздаются.
- AI-классификация имеет безопасный fallback `neutral`.
- Яркость имеет fallback, если IOKit не возвращает значение.
- `.gitignore` исключает build/dist артефакты.
- Shell-скрипты проходят `zsh -n`.
- JSON VS Code tasks проходит синтаксическую проверку.

## Требует проверки на реальном Mac

- Компиляция IOKit API на установленной версии macOS SDK.
- Чтение яркости встроенного дисплея на конкретной модели MacBook Air M2.
- Поведение поверх native full-screen приложений и игр.
- Визуальная интенсивность на конкретном дисплее.
