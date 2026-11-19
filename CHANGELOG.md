# Changelog

Notable changes are recorded here so the README can stay focused on installing and using Slumbr.

## v4.0

### Changed

- The app is now called Slumbr. Its bundle identifier is `com.marspater.slumbr`, so macOS treats it as a new app: the "Show in Dock" setting and the menu bar icon position reset, and macOS asks once more for permission to control System Events. Delete the previous app from `/Applications` after installing Slumbr.
- The project is a native Xcode project (`Slumbr.xcodeproj`) built with `xcodebuild`, replacing the Swift package. `build.sh` is now a thin wrapper around it. Built with the macOS 27 SDK, it still runs on macOS 26 and later, and the packaged app is now universal (Apple silicon and Intel).
- CI builds with Xcode 27 on GitHub's `xcode-27` runner. CodeQL stays on the `macos-26` runner (Xcode 26) because its Swift analysis does not support macOS 27 or Xcode 27 yet.
- Deprecated and soft-deprecated APIs are replaced: `foregroundStyle` instead of `foregroundColor`, closure-based `overlay`/`background`, and `NSApp.activate()`. The timer model uses the Observation framework (`@Observable`) instead of `ObservableObject`. The macOS 27 SDK deprecates nothing else the app uses, so no macOS 27-only code paths were needed.
- Tests use Swift Testing instead of XCTest. They add parameterized formatter and path-parsing cases, and check the sky phases, the 320/272pt layout grid, and that every artwork path parses.
- Logging uses `os.Logger` (subsystem `com.marspater.slumbr`), so timer and sleep events persist and can be read with `log show --predicate 'subsystem == "com.marspater.slumbr"'`.

### Fixed

- The Mac no longer silently stays awake when the timer ends. A tick that ran more than 2 seconds late was treated as "the Mac slept through the deadline" and finished without sleeping; the timer now checks the system's real sleep time instead.
- A sleep request that reports success but never sleeps the Mac now shows a retryable "Your Mac didn't go to sleep" error after 15 seconds instead of claiming success. If the sleep lands later, the error clears itself.

## v3.5

Everything since the `v3.2` tag.

### Added

- Central design reference in `docs/DESIGN.md`, documenting theme tokens, artwork, motion, components, P3 colors, and EDR levels (#22).
- Repository guidance in `AGENTS.md` for architecture, testing, packaging, accessibility, and Swift 6 concurrency.
- SVG-style vector path data and parsing for the moon, clouds, fox, cat, and dodo, with dedicated vector-path tests (#17).
- CodeQL scanning workflow for Swift and pull requests.

### Changed

- The Start button is 38pt tall like Cancel and Quit, and uses the same accent-to-cyan gradient as a translucent tint with a stroke and a white label.
- Consolidated UI, motion, component, sky, and artwork values under `Sources/Slumbr/Theme/` without intentionally changing the visual output (#22).
- Reworked EDR rendering to use exposure adjustment for real brightness above SDR white while allowing macOS to tone-map the same P3 colors on displays without headroom (#21).
- Smoothed companion travel for 60 Hz displays and raised shooting-star updates to 60 fps (#21).
- Updated the menu bar symbol sizing to better match native macOS status items (#18).
- Refreshed the Icon Composer asset and vector artwork while preserving the native asset pipeline.
- Simplified release packaging so `Slumbr.zip` is rebuilt only with `./build.sh --package`.
- Build signing now prefers a Developer ID identity when one is available and otherwise falls back to ad-hoc signing (#21).

### Fixed

- The Dock icon could show another project's app icon: `build.sh` now passes `actool` an absolute path, because its shared compiler daemon resolved the relative one against a concurrent build's folder.
- The sky no longer washes out to grey when macOS is in light mode; a dark scrim keeps light windows behind the popover from showing through.
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
- CodeQL uses GitHub's Swift analysis on macOS with a manual release build. A newer push to `main` no longer cancels a running `main` scan, which had surfaced as "CodeQL exited with errors".
- The repository's Sponsor button links to Ko-fi (`.github/FUNDING.yml`).

## v3.2

Tagged release. Earlier release history remains available through the Git tags and GitHub history.
