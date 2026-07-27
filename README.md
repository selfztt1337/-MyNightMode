<p align="center">
  <img src="Resources/AppIcon1024.png" width="96" alt="MyNightMode icon">
</p>

<h1 align="center">MyNightMode</h1>

<p align="center">
  <strong>Адаптивный ночной режим для macOS.</strong><br>
  Мягче белый фон, меньше визуального шума, быстрые паузы и автоматические профили.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-native-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/Local--first-100%25-238636?style=flat-square" alt="Local-first">
</p>

<p align="center">
  <img src="Docs/assets/main-window-current.png" width="760" alt="Актуальное окно MyNightMode на macOS">
</p>

## Что делает

- **AI Auto** подбирает профиль под активное приложение, время и яркость.
- **Paper Mode** смягчает белые поверхности в документах, браузере и таблицах.
- **Focus Edges** слегка затемняет периферию и оставляет центр спокойнее.
- **Smart Pause** отключает эффект на 15–120 минут или до завтра 09:00.
- **Быстрые пресеты** переключают готовые сценарии в один клик.
- **Настройки по дисплеям** позволяют независимо выбрать режим, пресет и силу эффекта для каждого монитора.
- Работает локально, без Screen Recording и Accessibility.

## Интерфейс

<p align="center">
  <img src="Docs/assets/interface-current.gif" width="760" alt="Реальные клики в MyNightMode: чтение, фокус и Smart Pause">
</p>

GIF показывает реальные клики в актуальной release-сборке: выбор пресетов «Чтение» и «Фокус», затем открытие Smart Pause.

## Комфорт при чтении и работе

<p align="center">
  <img src="Docs/showcase/comfort-modes.gif" width="760" alt="Реальное переключение Paper Mode и Focus Edges">
</p>

## Smart Pause

<p align="center">
  <img src="Docs/showcase/smart-pause.png" width="760" alt="Актуальное меню Smart Pause в MyNightMode">
</p>

## Сборка

Требования: macOS 14+ и Xcode Command Line Tools.

```bash
chmod +x scripts/*.sh
./scripts/build_app.sh
```

Готовое приложение появится в:

```text
dist/MyNightMode.app
```

## Управление

- Выберите дисплей в главном окне или menu bar — все параметры ниже применяются именно к нему
- Активный быстрый пресет подсвечивается; ручное изменение его параметров снимает подсветку
- Главное окно и menu bar используют одинаковое компактное управление Smart Pause
- Горячую клавишу включения и выключения можно назначить самостоятельно в настройках
- `⌃⌥⌘N` — сочетание по умолчанию
- `?` — открыть обучение
- `ⓘ` — объяснение конкретной функции

Overlay каждого дисплея покрывает всю его площадь, не перехватывает мышь или клавиатуру и работает во всех Spaces. MyNightMode не меняет настройки Dock и не перекрывает системный интерфейс.

## Приватность

MyNightMode не записывает экран, не читает содержимое окон и не отправляет данные в облако.

<p align="center">
  <sub>Made for calmer nights on macOS 🌙</sub><br>
  <sub>© 2026 <strong>@selfztt1337</strong>. All rights reserved.</sub>
</p>
