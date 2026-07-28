# NightMode development rules

- Keep the interface minimal, native and understandable without documentation.
- Never add Screen Recording or Accessibility permissions.
- Overlay windows must never intercept mouse or keyboard input.
- Preserve multi-display and Spaces support.
- Preserve the black-and-white NightMode identity.
- Never claim a build works until `./scripts/build_app.sh` exits with code 0 on macOS.
- Before git push, review `git diff` and exclude `.build`, `dist`, secrets and local editor files.
- Never force-push and never publish a GitHub Release without explicit approval.
