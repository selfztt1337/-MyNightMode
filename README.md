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
  <img src="Docs/showcase/hero.png" alt="MyNightMode on macOS">
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
  <img src="Docs/assets/interface-current.gif" width="760" alt="MyNightMode: выбор режима, пресета, интенсивности и Smart Pause">
</p>

Плавная демонстрация показывает основной путь: выбор режима и пресета, настройку силы эффекта и запуск Smart Pause. Весь интерфейс остаётся в кадре.

## Комфорт при чтении и работе

<p align="center">
  <img src="Docs/showcase/comfort-modes.gif" alt="Paper Mode and Focus Edges demonstration">
</p>

## Управление и Smart Pause

<p align="center">
  <img src="Docs/showcase/smart-pause.png" alt="MyNightMode: отдельные настройки дисплеев, свой хоткей и Smart Pause">
</p>

- Отдельные режим, пресет и интенсивность для каждого подключённого дисплея.
- Назначаемая пользователем глобальная горячая клавиша.
- Smart Pause на 15, 30, 60 или 120 минут — либо до завтра, 09:00.

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
  <sub>© 2026 MyNightMode contributors.</sub>
</p>
