# QA checklist — Interactive Overlay v2

## Проверено статически в проекте

- Overlay создаётся как `.nonactivatingPanel`.
- `canBecomeKey` и `canBecomeMain` всегда возвращают `false`.
- `ignoresMouseEvents = true`.
- Overlay не захватывается и не сохраняется: `sharingType = .none`.
- Эффект больше не использует видеопоток ScreenCaptureKit.
- Изменения режима и интенсивности применяются без перезапуска.
- Закрытие или исчезновение выбранного окна выключает overlay.
- Скрипты сборки проходят shell syntax check.
- Info.plist проходит `plutil` на macOS через build script.

## Требует ручной проверки на Mac

- клики и двойные клики в Miro;
- скролл, pinch-to-zoom и pan;
- drag-and-drop объектов;
- ввод текста и горячие клавиши;
- перемещение и resize окна;
- несколько мониторов;
- Mission Control и полноэкранный режим;
- субъективная комфортность четырёх фильтров.
