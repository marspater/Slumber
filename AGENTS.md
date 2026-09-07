# AGENTS.md

## Repository

Slumber is a native macOS menu bar application written in Swift 6 and SwiftUI.

The repository is a Swift Package Manager project with:

- `Sources/SlumberCore` - timer/domain logic and platform sleep integration
- `Sources/Slumber` - macOS AppKit/SwiftUI UI, menu bar integration, animations, theme, assets
- `Tests/SlumberTests` - XCTest coverage for `SlumberCore`
- `Assets` - app icon, audio, and image resources
- `build.sh` - local `.app` bundle construction and code-signing
- `.github/workflows/swift.yml` - CI tests and build

`Package.swift` is the source of truth for the supported platform and language version.

## Environment Requirements

Use a macOS host with Xcode/Apple command-line developer tools installed.

Required toolchain characteristics:

- Swift 6 / Swift Package Manager
- macOS 26 SDK/runtime compatibility
- Apple platform tooling available on the PATH (`xcrun`, `actool`, `iconutil`, `sips`, `codesign`, `security`, `xattr`)

Do not attempt to build this project on Linux or Windows. Do not replace Apple frameworks with cross-platform substitutes.

Before making changes, inspect the current repository state and existing scripts. Work from the checked-out branch exactly as provided by the environment.

## Canonical Validation Commands

Run these from the repository root:

```bash
swift --version
swift package describe
swift test
swift build -c release
chmod +x build.sh
./build.sh
```

For faster iteration during source-only changes, `swift test` is the minimum validation gate. Changes touching packaging, assets, signing, app lifecycle, AppKit integration, or SwiftUI rendering should also run `./build.sh`.

When a change affects the actual app behavior, prefer validating the built `.app` rather than relying only on compilation.

## Swift 6 Concurrency Rules

Treat Swift 6 strict concurrency diagnostics as real defects, not noise.

- Preserve `@MainActor` isolation on UI and timer state.
- Do not weaken actor isolation merely to silence compiler errors.
- Avoid introducing `@unchecked Sendable` unless the invariant is explicit, narrowly scoped, and unavoidable.
- Keep AppKit/Carbon operations on the appropriate actor/thread.
- Be careful when bridging callback-based AppKit/Dispatch APIs into `MainActor` code.
- Do not introduce retain cycles through timers, notification observers, event monitors, or escaping closures.
- Preserve deterministic testability through dependency injection such as the existing date provider/sleep action pattern.

## Architecture Rules

Keep the separation between `SlumberCore` and the UI target intact.

- Put timer/state/business logic in `SlumberCore` when it does not inherently depend on SwiftUI UI rendering.
- Keep UI composition, animations, menu bar behavior, popover lifecycle, theme, and presentation concerns in `Slumber`.
- Avoid moving platform logic into views simply because it is convenient.
- Do not add third-party dependencies without a strong technical reason.
- Prefer native Apple APIs and existing project patterns.

## UI / Design Rules

Slumber has an intentional visual language. Preserve it.

The design system is centralized in `Sources/Slumber/Theme/SlumberTheme.swift` and uses shared tokens for:

- Display P3 colors and semantic HDR/EDR levels
- Typography
- 320pt popover / 272pt content grid
- Spacing
- Corner radii
- Tactile interaction behavior

Do not introduce arbitrary one-off dimensions, colors, fonts, shadows, radii, or animation timings when an existing token/pattern should be reused.

Preserve the existing wide-gamut P3 and EDR/HDR rendering behavior. Do not silently convert rendering to generic sRGB or SDR.

Do not reintroduce the custom slider focus-ring/accessibility problems that previous work explicitly addressed. The visual interaction layer and accessibility layer are intentionally decoupled in `SlumberSlider`.

Respect accessibility behavior while keeping the visual control free from unwanted system focus chrome.

## AppKit / Menu Bar Rules

Slumber is a menu bar application and uses AppKit APIs such as:

- `NSStatusItem`
- `NSPopover`
- `NSEvent` global/local monitors
- Carbon global hotkey APIs
- `NSWorkspace` wake notifications

Changes to these areas must be lifecycle-safe.

- Install monitors/observers only when needed.
- Remove them when no longer needed.
- Do not leak event monitors.
- Do not create recursive menu/status-item behavior.
- Keep status bar actions and popover state transitions deterministic.
- Preserve the existing accessory-mode behavior unless the task explicitly changes it.

## Timer / Sleep Rules

`SlumberTimer` is user-visible core behavior. Preserve these invariants:

- Invalid or non-finite durations must not start a timer.
- Countdown state is derived from an absolute deadline rather than accumulated tick error.
- Sleep failure is represented explicitly and remains retryable.
- Wake handling recalculates remaining time from the original deadline.
- Timer resources, activity assertions, and wake observers are cleaned up reliably.
- Blocking sleep fallbacks must not stall the main actor/UI.
- Countdown formatting must not skip visible seconds due to floating-point truncation.

Never replace deadline-based timing with naive decrementing counters merely because it is simpler.

## Build / Packaging Rules

`build.sh` creates the distributable `.app` bundle. Treat packaging as production code.

Important:

- Do not ignore command failures that can produce a broken application bundle.
- If an Apple tool is optional because of SDK/toolchain differences, verify the fallback is actually valid before keeping the fallback.
- Keep `Info.plist` deployment metadata aligned with `Package.swift`.
- Do not claim support for an OS version that the package cannot actually compile for.
- Preserve bundle identifier/versioning unless the task explicitly requires changing them.
- Preserve code-signing behavior, but never commit certificates, private keys, provisioning profiles, or other signing secrets.

If packaging metadata conflicts with `Package.swift`, stop and report the inconsistency rather than silently choosing whichever value is more convenient.

## Testing Expectations

Before declaring a task complete:

1. Run `swift test`.
2. Run `swift build -c release` when source changes could affect production compilation.
3. Run `./build.sh` for app-bundle or packaging changes.
4. Add or update XCTest coverage for behavioral changes in `SlumberCore`.
5. Prefer deterministic tests over real wall-clock sleeps.

When fixing a bug, first reproduce it or create a regression test where practical. The regression test should fail before the fix and pass after it.

Do not delete or weaken tests simply to make CI green.

## Asset Rules

Treat assets as intentional product files.

Do not delete, rename, recompress, or regenerate artwork/audio unless the task specifically concerns those assets.

The `Assets/AppIcon.icon` package is an Apple Icon Composer asset and should be preserved as-is unless icon work is explicitly requested.

## Dependency / File Hygiene

Keep the repository clean.

- Do not commit `.build`, derived data, generated `.app` bundles, `.dSYM`, temporary iconsets, editor caches, or local machine files.
- Do not add generated artifacts unless they are intentionally part of the release workflow.
- Before adding a new helper/file, check whether an existing abstraction already serves the same purpose.
- Remove dead code only when it is demonstrably unused and the removal is safe.
- Do not perform broad refactors during a focused bug fix.

## Change Scope

Prefer the smallest correct change.

Do not:

- rewrite unrelated files
- redesign the UI during a bug fix
- replace established architecture with a new framework
- add dependencies for trivial functionality
- change public APIs without checking all call sites/tests
- change deployment targets casually

When a task is ambiguous, infer intent from the existing architecture and README, then make the narrowest safe change.

## Git / Jules Workflow

Before editing:

```bash
git status --short
git branch --show-current
git log -5 --oneline
```

After editing:

```bash
git diff --check
git diff --stat
git status --short
```

Do not reset, rebase, force-push, or discard unrelated user changes.

Do not modify generated or unrelated files merely to make the diff look tidy.

## Definition of Done

A task is complete only when:

- The requested behavior is implemented correctly.
- Existing architecture and design language remain intact.
- Swift 6 concurrency constraints are respected.
- Relevant automated tests pass.
- Production compilation succeeds when applicable.
- Packaging succeeds when applicable.
- No unrelated changes are introduced.
- The final summary identifies what changed and exactly what validation was run.

If a check cannot run because the environment lacks macOS/Xcode/Apple tooling, state that clearly and do not pretend the change was fully validated.
