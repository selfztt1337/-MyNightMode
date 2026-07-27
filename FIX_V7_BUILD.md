# V7 build fix

Исправлено:
- `kNilOptions` заменён на `IOOptionBits(0)` для Command Line Tools SDK.
- `settings` сделан изменяемым для SwiftUI bindings.
- callbacks NotificationCenter переведены в `Task { @MainActor ... }`.
