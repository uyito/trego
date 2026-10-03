# Phase 2 Polish Batch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Clear the small follow-ups logged during the redesign + activity work — token-migrate the one missed hub, lazy-load the Nutrition tab, show real achievements data on Home, give `TregoAppBar` a tab slot, and make `SocialSignInButtons` injectable.

**Architecture:** Independent, low-risk cleanups; each its own task + commit, all on one branch.

**Tech Stack:** Flutter, token design system, `flutter_test`.

## Global Constraints

- Token-pure for any migrated/new UI (`context.tokens`/`context.typo`/`Space`/`Radii`; no raw `Color(0x…)`, no `Theme.of(context)` colors, no `AppTheme`); migrated files added to `scripts/check-tokens.sh`.
- Preserve behavior; styling/structure cleanups only unless a task says otherwise.
- Keep the full suite green (currently 0 failures). Each task leaves it green.
- Read a migrated screen (`lib/social/screens/challenges_screen.dart`) + the theme files for the idiom before editing.

---

### Task 1: Token-migrate `workout_hub.dart`

**Files:** Modify `lib/workouts/workout_hub.dart`; add it to `scripts/check-tokens.sh`; Test: extend `test/workouts/workout_hub_test.dart` if needed (it already asserts tabs + actions + single app bar).

`workout_hub.dart` still uses `Theme.of(context).colorScheme.primary`, `Colors.white`, `Colors.white70` (a Phase-2 miss). Migrate its AppBar/TabBar styling to `context.tokens`/`context.typo` (brand surface, onBrand labels, etc.), preserving the 2 tabs + the History/PRs app-bar actions + Record-untouched. Add the file to the guard.

- [ ] Grep current raw colors; migrate to tokens; add to check-tokens FORBIDDEN_DIRS.
- [ ] `grep -nE "Color\(0x|AppTheme\.|Theme.of|Colors\.(white|black)" lib/workouts/workout_hub.dart` → empty (except any tagged ALLOW-HEX); `sh scripts/check-tokens.sh` passes.
- [ ] `flutter test test/workouts/workout_hub_test.dart` PASS; full suite green.
- [ ] Commit `style(workouts): migrate workout_hub to token design system`.

### Task 2: Lazy-load the Nutrition tab

**Files:** Modify `lib/navigation/app_shell.dart`; Test: extend `test/navigation/app_shell_test.dart`.

The shell's `IndexedStack` builds all tab children on first frame, so `NutritionHub` → `RecipeScreen` → `RecipeService`/Firestore run at cold start even for users who never open Nutrition. Make the Nutrition tab build lazily (only once first selected), without breaking the other tabs or the existing feed-reload wiring.

- [ ] Implement lazy build for the Nutrition slot (e.g. keep a `bool _nutritionVisited`; render a lightweight placeholder until first selected, then the real `NutritionHub`, and keep it alive after — OR use a lazy `IndexedStack` pattern). Home/Feed/You and Record behavior unchanged.
- [ ] Test: pump `AppShell`; assert `NutritionHub` is NOT built initially, and IS built after tapping the Nutrition tab (`find.byType(NutritionHub)` findsNothing → findsOneWidget after tap). Keep existing shell tests green.
- [ ] `flutter analyze` clean; full suite green.
- [ ] Commit `perf(nav): lazy-build Nutrition tab to avoid eager Firestore at cold start`.

### Task 3: Real achievements preview on Home

**Files:** Modify `lib/screens/home_screen.dart` (the `_AchievementsPreview` widget); Test: extend `test/screens/home_surfacing_test.dart`.

The Home achievements strip renders 3 hardcoded placeholder badges (`Streak`, `First 5K`, `Fast Pace`) regardless of real unlock state — misleading for a new user. Wire it to the real achievements source (the same one `AchievementsScreen` uses — inspect `lib/achievements/` for the service/model; likely an `AchievementService`). Show up to the first 3 EARNED achievements; if none earned, show an empty/encouraging state (e.g. "No badges yet — keep going"). Keep it token-pure; load safely (post-frame + mounted, service tolerant of the Firebase-less test host via the established try/catch pattern, or inject a service for the test).

- [ ] Inspect the achievements service/model; make `_AchievementsPreview` load real earned achievements (injectable service for testing).
- [ ] Test (with an injected fake achievements source): earned → names render; none → empty state.
- [ ] grep clean; `sh scripts/check-tokens.sh` passes; full suite green.
- [ ] Commit `feat(home): wire real achievements data into the Home preview`.

### Task 4: `TregoAppBar` optional tab/bottom slot

**Files:** Modify `lib/widgets/core/trego_app_bar.dart`; refactor `lib/social/screens/friends_screen.dart` to use it; Test: `test/widgets/core/trego_app_bar_test.dart` (extend) + keep `friends_screen_test` green.

`friends_screen.dart` hand-rolls a `PreferredSize(Material(Column([header, TabBar])))` because `TregoAppBar` has no tab slot. Add an optional `PreferredSizeWidget? bottom` (or `tabBar`) parameter to `TregoAppBar`, then refactor `friends_screen` to use `TregoAppBar(title: ..., bottom: TabBar(...))` instead of its inline header. Keep the visual result equivalent.

- [ ] Add the optional bottom slot to `TregoAppBar` (token-pure); test it renders the bottom widget when provided and omits it otherwise.
- [ ] Refactor `friends_screen` to use it; keep the Friends/Requests tabs + flows intact (friends_screen_test stays green).
- [ ] `sh scripts/check-tokens.sh` passes; full suite green.
- [ ] Commit `refactor(core): add optional bottom slot to TregoAppBar; adopt in FriendsScreen`.

### Task 5: Injectable `AuthService` in `SocialSignInButtons`

**Files:** Modify `lib/auth/social_sign_in_buttons.dart` (+ the login/register screens' guard added in Phase 2 Group D); Test: extend `test/auth/social_sign_in_buttons_test.dart`.

Phase 2 added a `try/catch` around `SocialSignInButtons` construction in login/register (because it constructs `AuthService()` eagerly, which touches Firebase in the test host). Make `SocialSignInButtons` accept an optional `AuthService` (default `AuthService()`), and remove the now-unneeded construction `try/catch` guards in `login_screen.dart`/`register_screen.dart` (the widget no longer throws at construction in tests when a fake is injected; in production the default is unchanged).

- [ ] Add optional `AuthService? authService` param (default to the real one). Update the button's test to inject a fake and render without the guard.
- [ ] Remove the `try/catch`-around-construction in login/register (restore direct `SocialSignInButtons(...)`), confirming their tests still pass (inject a fake if a test needs it).
- [ ] `sh scripts/check-tokens.sh` passes; full suite green.
- [ ] Commit `refactor(auth): make SocialSignInButtons AuthService injectable; drop construction guards`.

### Task 6: Batch green + PR

- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green (0 failures).
- [ ] Push `feat/phase2-polish`, open PR, squash-merge after whole-branch review, verify main green.

## Notes for the implementer
- These are independent; if any task uncovers more than a small cleanup (e.g. the achievements service is absent/complex), STOP and report rather than expanding scope.
- Don't touch Record/RecordFlow or the activity feature.
