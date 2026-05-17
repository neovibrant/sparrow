# Sparrow

Sparrow is a minimalist macOS menu bar utility that maps configurable mouse side buttons to switch Spaces left and right.

The app is intentionally small: native Swift/SwiftUI, no third-party dependencies, no Dock icon, and only the permissions needed to observe global mouse input.

## Current Status

Sparrow is implemented as a macOS menu bar app.

- Global mouse side-button capture works through a Core Graphics event tap.
- Space switching works through synthetic Dock swipe gesture events.
- Button mappings are configurable in a native Settings window.
- Preferences are persisted with `UserDefaults`.
- The app has a custom menu bar icon, app icon, Settings UI, About menu item, and Quit menu item.
- The project builds successfully with Xcode using the `Sparrow` scheme.

## User-Facing Behavior

By default, Sparrow maps the detected side buttons as follows:

- `Move Space Left`: mouse button `4`
- `Move Space Right`: mouse button `3`

The defaults are intentionally swapped relative to the raw button order because that matched the desired behavior during real hardware testing.

The Settings window lets the user choose any button number from `0...20` for each action.

Button numbering notes shown in the UI:

- Button `0` is usually left click.
- Button `1` is usually right click.
- Button `2` is usually middle click.
- Extra mouse buttons commonly start at `3`.

## Menu Bar App

The app uses SwiftUI `MenuBarExtra` and is configured as a menu bar-only app with `LSUIElement = YES`, so it does not show a Dock icon.

Menu items:

- `About Sparrow`: opens the built-in macOS About panel via `NSApplication.shared.orderFrontStandardAboutPanel(nil)`.
- `Settings...`: opens the SwiftUI Settings scene.
- `Quit`: terminates the app.

The menu bar icon is loaded from the `SparrowMenuIcon` asset.

## Settings UI

The Settings window is implemented in SwiftUI.

It uses a macOS Settings-inspired layout:

- A rounded header card.
- A settings header icon loaded from `SettingsHeaderIcon`.
- A `Settings` title.
- Short explanatory text about mouse side buttons and numbered inputs.
- A grouped `Form` with controls for `Move Space Left` and `Move Space Right`.
- Footer hint text explaining common button numbers.

The `SettingsHeaderIcon` asset is currently a placeholder slot. If no asset image is present, the UI falls back to a temporary system gear icon.

## Technical Implementation

Primary files:

- `Sparrow/SparrowApp.swift`: app entry point, menu bar menu, Settings scene.
- `Sparrow/MouseRemapper.swift`: global mouse event tap and configurable button handling.
- `Sparrow/SpaceSwitcher.swift`: Space-switching backend using synthetic Dock swipe gesture events.
- `Sparrow/SparrowSettings.swift`: persisted button mapping settings.
- `Sparrow/SettingsView.swift`: Settings UI.
- `Sparrow/SparrowIcon.swift`: menu bar icon loading.
- `Sparrow/Assets.xcassets/SparrowMenuIcon.imageset/`: menu bar icon asset.
- `Sparrow/Assets.xcassets/SettingsHeaderIcon.imageset/`: Settings header icon slot.
- `Sparrow/Assets.xcassets/AppIcon.appiconset/`: app icon assets.

## Mouse Event Handling

Sparrow uses a Core Graphics event tap to observe global mouse events.

Validated hardware behavior:

- Side-button presses arrive as `CGEventType.otherMouseDown`.
- The raw event type logged during testing was `25`.
- Confirmed side-button IDs were `3` and `4`.

When a configured button is detected:

- Sparrow triggers the corresponding Space-switch action.
- The original mouse event is swallowed to avoid browser/Finder back/forward behavior.

## Space Switching Backend

Synthetic `Control + Left Arrow` and `Control + Right Arrow` keyboard events were tested first. They reached applications, but Mission Control did not treat them as Space-switching shortcuts reliably enough for this app.

Sparrow therefore uses synthetic Dock swipe gesture events. This works for local utility use, but it depends on private implementation details.

Important caveat:

- This private Dock gesture approach is not App Store safe.
- It is appropriate for a personal/local utility, but likely blocks Mac App Store distribution.

The current gesture implementation uses private `CGEventField(rawValue:)` fields observed to work with Dock-controlled Space switching:

- `55`: CGS event type
- `110`: gesture HID type
- `123`: swipe motion
- `124`: swipe progress
- `129`: velocity X
- `130`: velocity Y
- `132`: gesture phase

Current constants:

- Dock control event type: `30`
- Dock swipe HID type: `23`
- Horizontal motion: `1`
- Began phase: `1`
- Changed phase: `2`
- Ended phase: `4`

Current tuned animation values:

- `gestureVelocity = 950.0`
- `gestureAnimationDuration = 0.16`
- `gestureAnimationFrameCount = 10`
- Progress curve: `pow(t, 0.85)`
- Debounce interval: `0.16`

Multi-display behavior was validated and tuned to use the mouse event location/display rather than relying only on a global active Space.

## Permissions

Because Sparrow observes global mouse input, macOS requires the app to be allowed under Accessibility/Input Monitoring-style privacy controls depending on the OS version and build configuration.

If button mapping does not work after launch, check macOS privacy settings and grant Sparrow the relevant permission.

## Build

Known-good build command:

```sh
xcodebuild -project Sparrow.xcodeproj -scheme Sparrow -destination 'platform=macOS,arch=arm64' build
```

The build has been verified successfully after the current implementation changes.

## Design Principles

- Minimal native app surface area.
- Menu bar-first UX, no Dock icon.
- Native Swift/SwiftUI and AppKit where appropriate.
- No third-party dependencies.
- Simple persisted preferences through `UserDefaults`.
- Prefer system UI patterns for Settings and About.

## Known Limitations

- Space switching relies on private Dock gesture behavior and is therefore fragile across macOS releases.
- Mac App Store distribution is unlikely while the private gesture backend is required.
- The Settings header icon asset slot exists, but the final image still needs to be supplied.
- There is currently no validation preventing both actions from being assigned to the same mouse button.
- Debug logging may need to be reduced before a polished release.

## Possible Next Steps

- Add duplicate-mapping validation or warnings in Settings.
- Reduce or gate debug logs.
- Add a clearer first-run permissions explanation.
- Decide whether to keep the private backend for local distribution or explore non-App-Store alternatives.
