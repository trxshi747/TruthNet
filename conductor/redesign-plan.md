# TruthNet Redesign Plan: Glassmorphism & Floating UI

## Objective
Implement a comprehensive visual and structural redesign of the TruthNet application. The new design will utilize a **Glassmorphism** visual language paired with a **Modern Floating UI** structure, fundamentally changing layout, positioning, and navigation.

## Structural & Layout Changes
1. **Floating Navigation Dock:** Replace the standard bottom navigation bar or drawer with a translucent, floating pill-shaped dock at the bottom of the screen.
2. **Expanding Cards:** Transition from static feed items to dynamic cards that expand seamlessly into full-screen detail views using Hero animations.
3. **Immersive Scroll & Floating Overlays:** Content will scroll beneath floating UI elements (like headers, action buttons, and the nav dock). App bars will be replaced by floating, blurred top bars.
4. **Z-Index Layering:** Clear visual separation of layers: Background (Vibrant mesh gradient) -> Base Layer (Content/Feed) -> Floating Layer (Navigation, Contextual Actions, Overlays).

## Key Files & Context
- **Theme Definition:** `lib/core/theme/app_theme.dart`
- **Core Navigation:** Will require modifying `main.dart` or introducing a new `main_layout.dart` wrapper to hold the floating dock.
- **Core Widgets:**
  - Create `GlassCard`, `GlassButton`, and `FloatingNavDock`.
  - Update `dynamic_background.dart` to provide vibrant gradients.
- **Screens:** All files in `lib/screens/` need structural updates to accommodate full-screen bleed (ignoring safe areas for background, padding content appropriately).

## Implementation Steps

1. **Theme & Foundation:**
   - Update `AppTheme` for glassmorphism colors/typography.
   - Implement the new `DynamicBackground`.

2. **Core Components:**
   - Build `GlassCard` (BackdropFilter, border, soft shadow).
   - Build `FloatingNavDock` with animated item selection.

3. **Structural Overhaul (`MainLayout`):**
   - Create a central layout widget that hosts the background, the current active screen, and the floating dock layered on top.

4. **Screen Redesigns:**
   - **Feed/Home:** Convert lists to edge-to-edge padded glass cards. Implement Hero animations for post expansion.
   - **Profile/Details:** Use immersive scrolling where header images bleed to the edges and content scrolls over them as glass panels.

## Verification & Testing
- Test z-index and gesture detection on floating UI elements.
- Verify smooth Hero animations during card expansion.
- Ensure performant rendering of multiple blurred layers across devices.
