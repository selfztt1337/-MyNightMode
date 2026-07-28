# Changelog

## 1.1.3 — July 28, 2026

- Added a compact onboarding button to the main window header.
- Settings can now open onboarding immediately instead of waiting for the next launch.
- Added a Telegram Stories visual asset for the 1.1.x release.

## 1.1.2 — July 28, 2026

- Fixed the README and generated preview icon by using the light icon asset for GitHub.
- Kept the in-app icon adaptive: light icon in light appearance and dark icon in dark appearance.
- Built the app bundle icon from the light icon asset so Finder and Dock previews stay readable.

## 1.1.1 — July 28, 2026

- Restored transparent macOS app icon assets so the Dock, Finder and in-app appearance render correctly.

## 1.1.0 — July 28, 2026

- Added matching light and dark app icons that follow the active macOS appearance.
- Added full native light-mode support across the main window, settings and menu bar.
- Main and settings windows now open at their intended content widths and useful default heights.
- Added compact GitHub, Telegram and author links to the application footer.
- Fixed-time and manual sunrise/sunset schedules with morning and evening actions.
- Manual schedule override until the next transition.
- Adjustable Focus Edges intensity per display.
- Persistent per-display profiles with copy and apply-to-all actions.
- Display geometry diagnostics, full-frame coverage checks and visual identification.
- Manual preset editor for mode, dimming, warmth, Paper Mode and Focus Edges intensity.
- Custom presets can extend the quick-preset carousel or replace any built-in slot.
- Backward-compatible preset migration plus rename, update and versioned JSON import/export.
- Improved menu bar parity, accessibility, Reduce Motion and display lifecycle recovery.
- Fixed the menu bar popover collapsing into a thin horizontal strip.
- AI mode now classifies every foreground app using bundle metadata and macOS categories, with a safe fallback for unknown apps.
- Hardware brightness is resolved against each display's vendor, model and serial metadata when macOS exposes it.
- AI mode automatically tunes dimming, color balance, Paper Mode and Focus Edges; manual presets are unavailable until a manual mode is selected.
- Manual warmth, Paper Mode and Focus Edges controls are locked while AI mode is active; effect strength remains available as the user's overall AI scale.
- Custom presets now support icon selection, full editing, a visible 5-preset limit and a native light-scene preview.
- Onboarding pages can be navigated with a two-finger horizontal trackpad swipe or a horizontal drag.
- “Try” now previews an unsaved preset on the selected real display for eight seconds without changing its saved profile; the light test scene remains available separately.
- The preset carousel remains horizontally scrollable in AI mode while its preset actions stay disabled.
- The main window now opens at and stays locked to its native 520 × 820 pt content size.
- Preset preview is isolated to the selected display when protection was previously off, and repeated previews safely replace the previous timer.
- The latest custom-preset slot assignment now wins deterministically; the previous preset returns to the additional carousel.
- Imported numeric preset values are normalized to supported ranges.
- Main-window and menu-bar status now report the effective profile of the selected display.
- Preset imports reject files larger than 1 MB before decoding.
- Diagnostic exports no longer include user-assigned display names.

## 1.0.0 — July 2026

- Adaptive modes for work, reading, night use, games and automatic selection.
- Independent mode, preset, intensity and comfort settings for each display.
- Paper Mode and Focus Edges.
- Smart Pause for 15, 30, 60 or 120 minutes, or until 09:00 the next day.
- Customizable global keyboard shortcut.
- Native menu bar controls and a full settings window.
- Local-only processing without Screen Recording or Accessibility permissions.
