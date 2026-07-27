# Compile fix v9.2

Исправлена причина последних ошибок компиляции в `MenuBarView.swift`:

- `UserMode` реально содержит: `auto`, `work`, `read`, `night`, `play`.
- Подсказки теперь используют существующие варианты `.read` и `.play`.
- Вызов `.help(modeHelp(mode))` и функция `modeHelp(_:)` находятся в одной структуре `MenuBarView`.

Все Swift-файлы успешно прошли синтаксический разбор (`swiftc -frontend -parse`) в доступной среде.
Полную AppKit-сборку необходимо подтвердить на macOS через `⌘⇧B` или `./scripts/build_app.sh`.
