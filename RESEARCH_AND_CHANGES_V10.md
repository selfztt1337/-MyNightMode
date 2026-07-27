# MyNightMode V10 — UX research and changes

## Product principles used

- Explain the current automatic behavior instead of hiding it behind an “AI” badge.
- Teach features in context through info buttons and interactive onboarding.
- Keep the default path automatic, but make temporary exceptions fast and reversible.
- Avoid requiring Screen Recording or intercepting input.

## Added

- Visible info buttons in the main application window for modes, intensity, Paper Mode, and Focus Edges.
- “Why AI?” popover that explains the inputs behind the selected profile.
- Versioned first-launch onboarding (`didFinishOnboarding.v10`) so it appears for this release.
- Onboarding can always be reopened from the `?` button and the “Обучение” footer action.
- Interactive Paper Mode and Focus Edges switches inside onboarding.
- Smart temporary pause for 15, 30, or 60 minutes with automatic resume.
- Clearer mode cards instead of a cramped segmented control.
- Expanded privacy explanation.

## Reference products and guidance

- Apple Human Interface Guidelines: teach onboarding interactively and explain features in context.
- Apple macOS design guidance: use hierarchy, materials, and native controls.
- f.lux: time-of-day adaptation and gentle transitions.
- Lunar: adaptive brightness and automatic behavior based on display context.
