# Implementation Plan: TruthNet Glassmorphism Redesign

## Phase 1: Foundation & Theme Updates
- **Goal:** Update the app's foundational theme and dynamic background to support the new vibrant glassmorphism aesthetic.
- **Files:** `lib/core/theme/app_theme.dart`, `lib/widgets/dynamic_background.dart`

## Phase 2: Core Components Creation
- **Goal:** Build the new reusable glassmorphism components.
- **Files:** `lib/widgets/glass_card.dart`, `lib/widgets/glass_button.dart`, `lib/widgets/custom_floating_nav_bar.dart`

## Phase 3: Structural Layout Overhaul
- **Goal:** Introduce a new `main_layout.dart` that manages the Z-index layering, floating dock, and background.
- **Files:** `lib/main.dart`, `lib/screens/main_layout.dart`

## Phase 4: Screen Refactoring
- **Goal:** Refactor existing screens to utilize the new components and edge-to-edge immersive layout.
- **Files:** `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/post_screen.dart`

## Phase 5: Verification & Cleanup
- **Goal:** Ensure all routing works, remove old Claymorphism files, and verify no regressions.
- **Files:** `lib/widgets/clay_card.dart`, `lib/widgets/clay_button.dart`
