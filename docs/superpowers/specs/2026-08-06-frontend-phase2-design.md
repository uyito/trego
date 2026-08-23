# Frontend Redesign Phase 2 — Visual Consistency Migration — Design

**Date:** 2026-08-06
**Status:** Approved (user "go")
**Depends on:** Phase 1 IA overhaul (merged, PR #21).
**Scope:** Migrate the legacy feature screens onto the token design system so the whole app looks and feels consistent, and retire the old `AppTheme`. A consistency pass — not a per-screen redesign from scratch.

## Problem

After Phase 1, navigation and IA are coherent, but only the shells and ~4 areas use the token design system (`lib/shared/theme`: `context.tokens`, `context.typo`, `Space`, `Radii`, the `widgets/core` kit). The embedded legacy feature screens still use raw `Color(0x…)`, ad-hoc `Theme.of(context)` Material colors, and the old `lib/shared/app_theme.dart` (`AppTheme`). Measured surface: ~19 files with raw hex, 6 files referencing `AppTheme`, ~8,000 lines across the legacy screens. The result is a visually uneven app — spacing, colors, typography, and dark-mode behavior differ screen to screen.

## Definition of "migrated" (objective, per screen)

A screen is migrated when:
1. No raw `Color(0x…)` literals and no `AppTheme.` references remain (uses `context.tokens` color roles instead — `brand`, `canvas`, `surface`, `surfaceSunken`, `border`, `ink`, `inkMuted`, `danger`, etc.).
2. Text uses `context.typo` styles (`title`, `titleSmall`, `body`, `bodySmall`, `label`, `stat`) rather than ad-hoc `TextStyle`/`Theme.of(context).textTheme`.
3. Spacing/radii use `Space`/`Radii` scales; shells use `TregoScaffold`/`TregoAppBar` and cards/buttons use the `widgets/core` kit where they fit.
4. Dark mode renders correctly (token roles resolve per theme).
5. Behavior and layout intent are preserved; existing tests pass (and gain coverage where a screen had none for the changed surface).
6. The migrated file(s) are added to `scripts/check-tokens.sh`'s `FORBIDDEN_DIRS` so raw hex / `AppTheme` cannot regress.

This is a **consistency migration** — keep each screen's structure and flows; unify its styling. It is explicitly NOT a from-scratch redesign of each screen (targeted redesigns of genuinely weak screens can be separate follow-ups).

## Decomposition — groups by user-visibility, executed in order

Each group is its own implementation plan and PR. After each group, a build is flashed to the device for a visual look before proceeding.

| Group | Files | Rationale |
|---|---|---|
| **A — Nutrition** | `lib/recipes/recipe_screen.dart`, `lib/tdee/tdee_screen.dart` (+ the Phase 1 `_PantryTab` if any polish needed) | Now a top-level tab; most-visible legacy code |
| **B — Social** | `lib/social/screens/social_feed_screen.dart`, `friends_screen.dart`, `challenges_screen.dart` (+ social widgets: `comments_sheet`, `edit_post_dialog`, `report_dialog`, `mention_text`) | The Feed hub's contents |
| **C — Progress / Home-linked** | `lib/achievements/achievements_screen.dart`, `lib/analytics/advanced_analytics_dashboard.dart`, `lib/tracker/tracker_dashboard_screen.dart`, `lib/personalization/for_you_hub.dart` + `screens/enhanced_recommendations_screen.dart` | Surfaced from Home/Progress |
| **D — Auth** | `lib/auth/login_screen.dart`, `register_screen.dart`, `social_sign_in_buttons.dart` | First screens new users see |
| **E — Cleanup** | `lib/notifications/notifications_screen.dart`, `lib/workouts/workout_plan_screen.dart` + `workout_screen.dart`, remaining `lib/widgets/*` hex, and **delete `lib/shared/app_theme.dart`** once no references remain | Finish + retire the old theme |

Order rationale: highest-visibility-in-new-IA first (Nutrition and Social are the tab contents), then Home-linked, then the auth funnel, then the tail + AppTheme retirement.

## Architecture / approach

- Migrate in place, file by file within a group. No behavioral refactors beyond what styling requires.
- Reuse the existing token roles and `widgets/core` components; do not invent new tokens unless a genuine gap exists (if so, add to `trego_tokens.dart` deliberately, as its own small step).
- Charts/analytics (`advanced_analytics_dashboard`): map chart colors to token roles / a token-derived categorical palette; keep the chart library.
- Each group adds its migrated files/dirs to `scripts/check-tokens.sh`.
- `AppTheme` is deleted only in Group E, after grep confirms zero references.

## Testing

- Preserve existing tests; keep the suite green (the 6 pre-existing `notifications_screen`/`route_map` failures remain out of scope, tracked separately — Group E's notifications work may fix or leave them, noted in that plan).
- For each migrated screen with no existing widget test on the changed surface, add a lightweight render test (screen builds under `TregoTheme`, key elements present) — enough to catch a migration that breaks the build or removes a control.
- Visual verification: a release build to the device after each group.

## Out of scope

- Per-screen UX redesigns (structure changes, new flows) — separate follow-ups if a screen is genuinely weak.
- The multi-activity logging UI and watch companion (their own specs).
- New backend work.

## Phasing

One plan per group (A→E), each executed subagent-driven with per-task + whole-branch review, each its own PR, with a device build between groups. Group A (Nutrition) starts first.
