# Compile fix V3

Исправлена несовместимость с текущим AppKit SDK: удалён некорректный override `acceptsFirstMouse(for:)` у `NSPanel`.

Поведение click-through overlay сохраняется через:

- `panel.ignoresMouseEvents = true`
- `panel.acceptsMouseMovedEvents = false`
- `canBecomeKey = false`
- `canBecomeMain = false`
