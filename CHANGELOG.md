# V10.1 — Timer & Showcase Fix

- Smart Pause is now visible directly in the menu bar.
- Break reminder interval is configurable: 25/50/75/90 minutes.
- Settings now have a dedicated “Таймер и паузы” section.
- README hero and demo GIF were rebuilt from the current V10 interface without broken crops.

# Changelog

## 4.0.0 — August 2026

- Новый минималистичный onboarding из трёх понятных шагов.
- Обновлён главный экран: текущий AI-профиль, приложение, яркость и длительность сеанса видны сразу.
- Добавлен Focus Edges: мягкое затемнение краёв экрана для концентрации.
- Paper Mode переработан и автоматически отключается для видео, игр и цветокритичных приложений.
- Добавлено ненавязчивое напоминание о паузе после 50 минут без системных уведомлений и разрешений.
- Улучшены AI-профили для кода, чтения, whiteboard, работы, дизайна, видео и игр.
- Новый компактный интерфейс в строке меню.
- Новая чёрно-белая иконка без луны, построенная вокруг идеи фокуса и адаптивного фильтра.
- Сохранена работа на нескольких дисплеях и во всех Spaces.

## v9.1 — Menu clarity update

- Полностью переработано окно в строке меню без обрезанных подписей.
- Режимы разложены в аккуратную сетку вместо тесного segmented control.
- Добавлены понятные описания Paper Mode и фокуса по краям.
- Добавлены popover-подсказки по кнопке информации.
- Онбординг расширен отдельными экранами про силу эффекта, Paper Mode и фокус.
- Исправлена несовместимая сигнатура SwiftUI `.frame` в `ContentView`.

## v9.2 — Compile fix

- Fixed `UserMode` cases in `MenuBarView`: `.reading` → `.read`, `.gaming` → `.play`.
- Kept `modeHelp(_:)` inside `MenuBarView`, matching the `.help(modeHelp(mode))` call.
- Rechecked all Swift source files with the Swift parser successfully.
