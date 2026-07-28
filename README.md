<p align="center">
  <img src="Resources/AppIconLight1024.png" width="96" alt="NightMode icon">
</p>

<h1 align="center">NightMode</h1>

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
  <img src="Docs/showcase/hero.png" alt="NightMode on macOS">
</p>

## Что делает

- **AI Auto** подбирает комфортное изображение с учётом активного приложения, яркости, времени суток и длительности работы.
- **Профили дисплеев** сохраняют отдельные параметры для каждого монитора.
- **Готовые и пользовательские пресеты** переключают сценарий в один клик.
- **Paper Mode и Focus Edges** смягчают белый фон и уменьшают визуальный шум.
- **Расписание** автоматически включает нужный режим утром, вечером или от заката до рассвета.
- **Smart Pause и свой хоткей** позволяют быстро остановить или вернуть эффект.
- Всё работает локально, без записи экрана и отправки данных.

## Интерфейс

<p align="center">
  <img src="Docs/assets/interface-current.gif" width="760" alt="NightMode: выбор режима, пресета, интенсивности и Smart Pause">
</p>

## Комфорт при чтении и работе

<p align="center">
  <img src="Docs/showcase/comfort-modes.gif" alt="Paper Mode and Focus Edges demonstration">
</p>

## Основные возможности

<p align="center">
  <img src="Docs/showcase/smart-pause.png" alt="NightMode: отдельные настройки дисплеев, свой хоткей и Smart Pause">
</p>

- Выберите дисплей и настройте режим, пресет и интенсивность.
- В AI-режиме параметры подбираются автоматически.
- Создайте до пяти собственных пресетов и проверьте их до сохранения.
- При необходимости поставьте эффект на паузу или назначьте свой хоткей.

## Установка

1. Скачайте `NightMode.app` или `.dmg` из раздела **Releases**:
   [github.com/selfztt1337/-MyNightMode/releases](https://github.com/selfztt1337/-MyNightMode/releases).
2. Если скачали `.dmg`, откройте его.
3. Переместите `NightMode.app` в папку **Applications** / «Программы».
4. Запустите NightMode из **Applications**.
5. Если macOS покажет предупреждение для локально подписанной сборки, откройте **Системные настройки → Конфиденциальность и безопасность** и подтвердите запуск.

NightMode не требует разрешений **Screen Recording** и **Accessibility**.

Для самостоятельной сборки нужны macOS 14+ и Xcode Command Line Tools:


```bash
chmod +x scripts/*.sh
./scripts/build_app.sh
```

Подробности: [BUILD.md](BUILD.md) · [TESTING.md](TESTING.md) · [PRIVACY.md](PRIVACY.md)

## Приватность

NightMode не записывает экран, не читает содержимое окон и не отправляет данные в облако.

<p align="center">
  <sub><a href="https://github.com/selfztt1337/-MyNightMode">GitHub</a> · <a href="https://t.me/selfztt1337">Telegram</a> · @selfztt1337</sub><br>
  <sub>Made for calmer nights on macOS 🌙</sub>
</p>
