# Changelog

Notable changes are recorded here so the README can stay focused on installing and using Slumber.

## Unreleased

Changes currently on `main` after the `v3.2` tag.

### Added

- Central design reference in `docs/DESIGN.md`, documenting theme tokens, artwork, motion, components, P3 colors, and EDR levels (#22).
- Repository guidance in `AGENTS.md` for architecture, testing, packaging, accessibility, and Swift 6 concurrency.
- SVG-style vector path data and parsing for the moon, clouds, fox, cat, and dodo, with dedicated vector-path tests (#17).
- CodeQL scanning workflow for Swift and pull requests.

### Changed

- Consolidated UI, motion, component, sky, and artwork values under `Sources/Slumber/Theme/` without intentionally changing the visual output (#22).
- Reworked EDR rendering to use exposure adjustment for real brightness above SDR white while allowing macOS to tone-map the same P3 colors on displays without headroom (#21).
- Smoothed companion travel for 60 Hz displays and raised shooting-star updates to 60 fps (#21).
- Updated the menu bar symbol sizing to better match native macOS status items (#18).
- Refreshed the Icon Composer asset and vector artwork while preserving the native asset pipeline.
- Simplified release packaging so `Slumber.zip` is rebuilt only with `./build.sh --package`.
- Build signing now prefers a Developer ID identity when one is available and otherwise falls back to ad-hoc signing (#21).

### Fixed

- Waking after a timer deadline no longer immediately sends the Mac back to sleep (#21).
- Companion species no longer changes while visible; selection happens after the popover closes (#21).
- Companion launch and landing no longer jump when the trail appears or disappears (#20).
- Initial sound preparation no longer blocks the main actor during the first Start action (#19).
- AppleScript sleep fallback runs off the main actor and ignores stale asynchronous completions (#19).
- Packaging includes the Apple Events entitlement and usage description required by the sleep fallback (#19, #21).
- Settings reports when another application already owns the global `⌃⌥S` shortcut (#21).
- Accessibility labels, Reduce Motion behavior, error announcements, and several interaction states were corrected across the UI (#19, #21).
- Restored the verbatim GPL-3.0 license text after an earlier accidental modification (#21).

### Repository maintenance

- Historical implementation notes were removed from the README and replaced with links to this changelog and the design reference.
- Swift CI now uses explicit least-privilege permissions, current checkout action versions, concurrency cancellation, and a job timeout.
- CodeQL uses GitHub's Swift analysis on macOS with a manual release build.

## v3.2

Tagged release. Earlier release history remains available through the Git tags and GitHub history.
