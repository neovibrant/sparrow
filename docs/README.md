# sparrow

A minimalist macOS utility to remap mouse side buttons for space switching.

## Goal
Map Mouse Button 4 and 5 to "Switch Space Left" and "Switch Space Right" (Ctrl + Left/Right Arrow) with the smallest possible attack surface.

## Design Principles
- **Minimalism**: Lightweight Menu Bar app with no main window; minimal dependencies.
- **Trust**: Native Swift implementation using system APIs; auditable code.
- **Efficiency**: Low CPU/RAM footprint via `CGEventTap`.

## Technical Implementation
- **Language**: Swift / SwiftUI
- **API**: CoreGraphics (`CGEventTap`) & AppKit (`NSStatusItem` for Menu Bar)
- **Logic**: 
  - Intercept `kCGEventMouseButtonPressed` events.
  - Filter for button IDs 3 (Back) and 4 (Forward).
  - Post synthetic keyboard events: `.maskControl` + `kVK_ArrowLeft`/`kVK_ArrowRight`.
  - Swallow the original event to prevent default browser/finder behavior.

## Roadmap
1. [ ] Set up Xcode Project (macOS App).
2. [ ] Implement Menu Bar icon and basic "Quit" functionality.
3. [ ] Implement core `CGEventTap` logic for mouse remapping.
4. [ ] Verify button IDs for the target hardware.
5. [ ] Test Accessibility permission flow.
6. [ ] Build and verify as a signed `.app` bundle.
7. [ ] (Optional) Add simple settings window via SwiftUI.
