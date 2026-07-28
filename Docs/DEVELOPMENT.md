# Разработка и проверка

Зависимости проекта системные: macOS 14+, Swift 5.10 и Xcode Command Line Tools. Внешних Swift-пакетов нет.

## Сборка

```bash
swift build -c debug
swift build -c release
./scripts/build_app.sh
```

`build_app.sh` создаёт, подписывает ad-hoc подписью, проверяет и запускает `dist/MyNightMode.app`.

## Проверка поведения

```bash
./scripts/test_core_logic.sh
./scripts/test_views.sh
```

Проверяются пресеты, выбранный пресет после ручной настройки, хоткей, Smart Pause, граничные значения адаптивного эффекта и стабильность одинакового render-state.

`test_views.sh` создаёт и layout-ит главное окно, menu bar, настройки и onboarding через `NSHostingView`. Тест не требует Screen Recording или Accessibility.

## Локальный performance benchmark

```bash
./scripts/benchmark_core_logic.sh
```

Benchmark выполняет миллион расчётов `AdaptiveEngine` и сравнивает количество render submissions до и после дедупликации одинакового состояния. Он не заменяет Instruments для измерения GPU/CPU реального приложения.

## Диагностика

```bash
./scripts/diagnose.sh
```

Для проверки нескольких дисплеев, Mission Control, fullscreen, кликов под overlay и субъективного качества эффекта требуется ручной прогон на Mac.
