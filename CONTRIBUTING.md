# Contributing to ArchHUD-CC

Thank you for your interest in ArchHUD-CC — the maintained fork of ArchHUD for **The Third Verse**!

## Ways to Contribute

- **Report bugs**: Open an issue with clear reproduction steps, your ship type/setup, and The Third Verse context if relevant.
- **Request features**: Describe the use case and expected benefit.
- **Submit pull requests**:
  1. Create a focused branch from `master`.
  2. Make small, testable changes.
  3. Update `docs/Changelog.md` for any user-facing or behavioral changes.
  4. Test in-game where possible (especially autopilot, rendering, and board add-ons).
  5. Open a PR with a clear title and description.

## Code Style & Guidelines

- Keep the modular `require` structure (see `src/requires/` and `src/builtin/`).
- Document all user-configurable variables with `--export:` comments and include them in the appropriate `saveableVariables*` tables.
- Use `pcall` / safe loading for optional devices (radar, shield, etc.) and file operations.
- Prefer clarity and safety over micro-optimizations unless profiling shows a real bottleneck.
- Update documentation in `docs/` alongside code changes.

## Suggested Improvements

A detailed list of recommendations (code quality, performance, documentation, testing, repo hygiene, and potential features) has been prepared. See the associated pull request or open issues for the full list. Many are quick documentation wins or small refactors that improve maintainability without changing core behavior.

Examples of high-value areas:
- Reduce duplication in saveable variable registration.
- Add lightweight validation for exported settings.
- Expand tests/ coverage for math and autopilot logic.
- Enhance CI with linting.
- Keep Changelog and README up to date with The Third Verse specifics.

## License

This project is licensed under the GNU General Public License v3.0 — the same as the original ArchHUD.

Happy flying! o7