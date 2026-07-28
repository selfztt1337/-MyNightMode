# QA checklist — MyNightMode 1.0

## Проверено статически в проекте

- Overlay создаётся как `.nonactivatingPanel`.
- `canBecomeKey` и `canBecomeMain` всегда возвращают `false`.
- `ignoresMouseEvents = true`.
- Overlay не передаётся в системный шаринг: `sharingType = .none`.
- Эффект не использует ScreenCaptureKit, Screen Recording или Accessibility.
- Изменения режима и интенсивности применяются без перезапуска.
- Интенсивность выбранного дисплея можно настроить до включения эффекта.
- Для каждого `NSScreen` создаётся независимая панель полного размера.
- Одинаковое состояние не создаёт повторную Core Animation транзакцию.
- Скрипты сборки проходят shell syntax check.
- Info.plist проходит `plutil` на macOS через build script.
- Tracked-файлы проходят автоматический аудит приватности и секретов.

## Требует ручной проверки на Mac

- клики, скролл, drag-and-drop и ввод текста под overlay;
- глобальный пользовательский хоткей;
- выбор режимов и пресетов в главном окне и menu bar;
- Smart Pause и автоматическое возобновление;
- Paper Mode и Focus Edges;
- несколько мониторов;
- Mission Control и полноэкранный режим;
- субъективная комфортность режимов.
