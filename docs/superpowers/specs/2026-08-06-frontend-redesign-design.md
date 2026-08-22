# Frontend Redesign — Navigation & IA Overhaul — Design

**Date:** 2026-08-06
**Status:** Approved (user "go")
**Scope:** Restructure the app's information architecture and navigation so features live where users expect them, using industry-standard mobile patterns. Phase 1 (this spec's focus) is the IA/navigation overhaul; Phase 2 (outlined) is a visual design-system consistency pass.

## Problem

The current app buries and orphans much of what it can do:
- **The "Plan" tab is a dead placeholder** — 1 of 4 primary destinations does nothing but link out to `WorkoutHub` (itself otherwise unreachable).
- **Core features are buried in "You"** (a settings-style list): Recipes, TDEE, the AI Coach ("For You"), Run History, Achievements, Analytics.
- **A fully-built Social hub (Feed/Friends/Challenges) is orphaned** (`lib/social/social_hub.dart` never constructed); `ChallengesScreen` is unreachable.
- **Dead/duplicate code and crash-prone routes:** three unused profile screens (`lib/profile/*`), orphaned personalization screens, unused `AuthScreen`, `Navigator.pushNamed` calls to routes never registered in `app.dart` (`/personalization/settings`, `/workouts`, `/dashboard`, `/privacy/personalization`), two different `WeeklySummaryScreen` classes, and stray `.!NNNNN!` sync-artifact files.
- **Inconsistent styling:** only Home, You, Plan-placeholder, the shared widget kit, and metrics widgets use the token design system (`lib/shared/theme`); everything else (recipes, social, workouts, tdee, achievements, analytics, personalization, notifications, auth) is ad-hoc legacy Material / `AppTheme`, so the app looks and feels uneven.

## New information architecture

Industry-standard 5-destination bottom bar with a center action button (Strava / Nike Run Club pattern):

**`Home` · `Nutrition` · `( ⏺ Record )` · `Feed` · `You`**

`enum TregoTab` changes from `{ home, plan, feed, you }` to `{ home, nutrition, feed, you }` (Record stays a non-tab center button that opens `RecordFlow`).

### Home (dashboard)
Greeting → today's plan hero → this-week metrics + PRs + goals (existing `_MetricsSection`) → **achievements preview** (new: horizontal strip, tap → Achievements) → **"For You" AI coach card** (new: entry to `EnhancedRecommendationsScreen`) → recent friend activity. A **"See all" on the metrics section opens a Progress/Stats detail** that hosts `TrackerDashboardScreen` (run history) + `AdvancedAnalyticsDashboard` (analytics) as tabs. Achievements and analytics thus become reachable from Home, not only from deep in You.

### Nutrition (replaces the dead Plan tab)
A new `NutritionHub` (token-styled shell, tabbed): **Recipes** (`RecipeScreen`) · **Pantry** (surfaced from the recipe/pantry services) · **TDEE** (`TdeeScreen`). Nutrition is half the app's stated identity and is currently hidden in You — this makes it first-class.

### Record (center button)
Unchanged behavior — opens `RecordFlow` as a full-screen flow. It remains the primary action and will grow into the multi-activity picker when the activity-tracking Flutter work (separate spec) lands.

### Feed (Social hub)
Replace the feed-only tab with a proper social hub, tabbed **Feed / Friends / Challenges** — reviving the already-built `SocialFeedScreen`, `FriendsScreen`, and `ChallengesScreen` (the orphaned `SocialHub` is the model; rebuild it token-styled as the Feed destination). Deep-links (notification → Friends with `initialTab`) continue to work by routing into this hub.

### You (real profile + settings)
- **Profile header:** avatar, display name, `@username`, and a few key stats (total runs / this-week km / streak) pulled from `MetricsProvider`.
- **Achievements** preview row (tap → Achievements).
- **Settings** grouped cleanly: Appearance, Recording, Notifications, Account (username), Sign out.
- Remove the "tools" grab-bag (Recipes/TDEE/For You/Run History) — those now live in Nutrition, Home, and the Progress detail.

### Workout plans
`WorkoutHub` / `WorkoutPlanScreen` / `WorkoutScreen` move to a "Training" entry reachable from Home (and later from Record's pre-start), not a top-level tab.

## Cleanup (part of Phase 1)

Delete now-dead code and fix land-mines as the IA is rewired:
- Remove orphans: `lib/profile/profile_screen.dart`, `simple_profile_screen.dart`, `settings_screen.dart`; `lib/social/social_hub.dart` (after its tabs are folded into the new Feed hub); `lib/auth/auth_screen.dart`; orphaned personalization screens `recommendations_screen.dart` (plain), `insights_screen.dart`, `personalization_settings_screen.dart` — unless a new IA entry point is created for them (none planned in Phase 1).
- Remove/replace the unregistered `pushNamed` targets so no navigation can crash.
- Resolve the duplicate `WeeklySummaryScreen` class-name collision (rename the workouts-side one).
- Delete stray `.!NNNNN!` artifact files (confirm with `git status`/`git clean -n` first).
- Delete `PlanPlaceholderScreen` once the tab is gone.

## Design-system consistency (Phase 1 minimum, Phase 2 full)

- **Phase 1:** all *new* shells (NutritionHub, the Feed/Social hub, the new You/profile, the Progress detail) are built token-pure (`context.tokens`, `context.typo`, `Space`, `Radii`, the `widgets/core` kit) and added to `scripts/check-tokens.sh`'s enforced list. Existing legacy screens are *reparented* into the new nav without a full restyle yet.
- **Phase 2 (separate spec/plan):** migrate the legacy feature screens (recipes, social feed/friends/challenges, workouts, tdee, achievements, analytics, notifications, auth) onto the token system group-by-group for visual consistency and smoothness, retiring `lib/shared/app_theme.dart`.

## Architecture / isolation

- `AppShell` + `_BottomNav` + `TregoTab` are the single source of nav truth — update the enum, the bar, and the `IndexedStack` children together.
- Each new destination is one focused shell widget with a clear responsibility (`NutritionHub`, `SocialHub` reworked, `YouScreen` reworked, `ProgressScreen`). Legacy screens are embedded as children, unchanged internally.
- Deep-link routing (`push_navigation.dart`, `notification_destination.dart`) is updated to target the new Feed/Social hub's Friends tab.

## Testing

- Widget tests for the new shells: nav shows 4 tabs + center Record; each destination renders its hub; Nutrition hub shows Recipes/Pantry/TDEE tabs; Feed hub shows Feed/Friends/Challenges; You shows profile header + settings groups; Home shows the achievements preview + For You card; deep-link to Friends still resolves.
- A guard test / grep asserting no `Navigator.pushNamed` to unregistered routes remains.
- Keep the existing suite green (the 6 pre-existing `notifications_screen_test.dart` failures are unrelated and tracked separately).

## Phasing

- **Phase 1 — IA & navigation overhaul (this spec):** new 5-destination nav; Nutrition hub; reworked Social/Feed hub (revive Challenges/Friends); reworked You profile; Home achievements + For You + Progress detail; move Workout plans off a top-level tab; delete dead code + fix broken routes. One implementation plan, likely split into a few PRs (nav+shells, hubs, cleanup).
- **Phase 2 — visual consistency pass (separate spec):** token-migrate legacy screens group-by-group; retire `AppTheme`.

## Out of scope (Phase 1)

- Full visual restyle of legacy screens (Phase 2).
- The multi-activity logging UI (its own spec/plan already written).
- New backend endpoints (this is frontend-only; reuses existing services).
- Watch companion (deferred Phase 2 of the activity feature).
