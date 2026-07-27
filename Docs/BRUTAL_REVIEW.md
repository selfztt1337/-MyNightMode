# Brutal engineering review

- Прямое перекрашивание стороннего приложения невозможно через публичные API.
- Захват отдельного окна исключает рекурсивный захват overlay.
- Click-through обеспечивается `ignoresMouseEvents`.
- Главный UX-риск: overlay может закрывать другие приложения. Поэтому он скрывается, когда владелец выбранного окна не frontmost.
- Главный performance-риск: рендер на main thread. В этой версии GPU-рендер выполняется на отдельной capture queue, а main thread только меняет `CALayer.contents`.
- Главный packaging-риск старой версии: отсутствующий `CFBundleExecutable`. В этой версии build-скрипт проверяет это явно.
