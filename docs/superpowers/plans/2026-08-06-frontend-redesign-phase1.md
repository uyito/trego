# Frontend Redesign Phase 1 — Implementation Plan (Navigation & IA)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Restructure navigation so features live where users expect — a 5-destination bottom bar (Home / Nutrition / Record / Feed / You), surfacing buried features, reviving the orphaned social hub, a real profile, and deleting dead code + crash-prone routes.

**Architecture:** `AppShell` + `_BottomNav` + `TregoTab` are the single source of nav truth. Each destination is one focused shell widget; existing feature screens are embedded as children unchanged. New shells are token-pure (`context.tokens`/`context.typo`/`Space`/`Radii`, `widgets/core` kit).

**Tech Stack:** Flutter 3.44, `provider`, token design system (`lib/shared/theme`), `flutter_test`.

## Global Constraints

- New shells MUST be token-pure (no raw hex, no `AppTheme`) and are ADDED to `scripts/check-tokens.sh`'s enforced list. Embedded legacy screens are not restyled in Phase 1.
- Bottom bar order is exactly: **Home, Nutrition, (center Record), Feed, You**. `enum TregoTab { home, nutrition, feed, you }` (Record is a modal, not a tab).
- Reuse existing feature screens (`RecipeScreen`, `TdeeScreen`, `SocialFeedScreen`, `FriendsScreen`, `ChallengesScreen`, `AchievementsScreen`, `EnhancedRecommendationsScreen`, `TrackerDashboardScreen`, `AdvancedAnalyticsDashboard`, `WorkoutHub`) — do not rewrite their internals.
- Keep the existing suite green. The 6 pre-existing `notifications_screen_test.dart` failures are unrelated (tracked on `main`) — do not touch them.
- No backend changes. Frontend only.
- Deep-link to Friends (`push_navigation.dart`, `notifications_screen.dart`) must still resolve after the Feed tab becomes a hub.

---

### Task 1: Nav skeleton — Nutrition replaces the Plan placeholder

**Files:**
- Modify: `lib/navigation/tab_config.dart`, `lib/navigation/app_shell.dart`
- Create: `lib/nutrition/nutrition_hub.dart`
- Delete: `lib/screens/plan_placeholder_screen.dart`
- Modify: `scripts/check-tokens.sh` (add `lib/nutrition`)
- Test: `test/nutrition/nutrition_hub_test.dart`, update/add `test/navigation/app_shell_test.dart`

**Interfaces:**
- Produces: `enum TregoTab { home, nutrition, feed, you }`; `class NutritionHub extends StatelessWidget` — a token-styled `DefaultTabController(length: 3)` scaffold with tabs **Recipes / Pantry / TDEE** whose bodies are `RecipeScreen`, a pantry view (reuse whatever `RecipeScreen`/pantry exposes; for v1 the Pantry tab may embed `RecipeScreen`'s pantry entry or a simple pantry list if one exists — if no standalone pantry screen exists, make Pantry tab a placeholder-free lightweight list backed by the existing pantry service), and `TdeeScreen`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/nutrition/nutrition_hub_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/nutrition/nutrition_hub.dart';

void main() {
  testWidgets('NutritionHub shows Recipes, Pantry, TDEE tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NutritionHub()));
    await tester.pump();
    expect(find.text('Recipes'), findsWidgets);
    expect(find.text('Pantry'), findsWidgets);
    expect(find.text('TDEE'), findsWidgets);
  });
}
```

```dart
// test/navigation/app_shell_test.dart — nav shows Nutrition, not Plan
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// (Wrap AppShell in the app's provider scope + TregoTheme as existing shell tests do;
//  follow the existing test harness if one exists, else pump within TregoTheme + the
//  required Providers: MetricsProvider, NotificationsProvider, SocialService.)
void main() {
  testWidgets('bottom nav shows Home, Nutrition, Feed, You (no Plan)', (tester) async {
    // pump AppShell within providers + TregoTheme
    // expect(find.text('Nutrition'), findsOneWidget);
    // expect(find.text('Plan'), findsNothing);
    // expect(find.text('Home'), findsOneWidget);
    // expect(find.byKey(const Key('shell-record-button')), findsOneWidget);
  }, skip: true); // enable once the provider harness is wired; see note below
}
```

> The shell test needs the full provider scope; if the repo has no existing AppShell widget-test harness, keep the assertions but build the minimal provider wrapper (MetricsProvider, NotificationsProvider, SocialService) rather than leaving it skipped. Prefer un-skipping. The NutritionHub test is the hard gate for this task.

- [ ] **Step 2: Run to verify they fail** — `flutter test test/nutrition/nutrition_hub_test.dart` → FAIL (hub missing).

- [ ] **Step 3: Implement**
  1. `tab_config.dart`: `enum TregoTab { home, nutrition, feed, you }`.
  2. `nutrition_hub.dart`: token-pure `DefaultTabController(length: 3)` + `TregoScaffold`/`TregoAppBar` (from `widgets/core`) titled "Nutrition", a `TabBar` (Recipes/Pantry/TDEE) and `TabBarView` bodies `[RecipeScreen(), <pantry>, TdeeScreen()]`. Use `context.tokens`/`context.typo`.
  3. `app_shell.dart`: replace the `plan` import/child/nav-item with Nutrition — `import '../nutrition/nutrition_hub.dart';`; in the `index` switch and `IndexedStack` children replace `TregoTab.plan`→`TregoTab.nutrition` and `const PlanPlaceholderScreen()`→`const NutritionHub()`; in `_BottomNav` change the second `_NavItem` to `label: 'Nutrition', icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, selected: current == TregoTab.nutrition, onTap: () => onSelect(TregoTab.nutrition)`. Remove the `plan_placeholder_screen.dart` import.
  4. Fix any other `TregoTab.plan` references (e.g. `home_screen.dart` "Browse plans" CTA that switches to the Plan tab — repoint it to open `WorkoutHub` via push, since there's no Plan tab now; grep `TregoTab.plan`).
  5. Delete `lib/screens/plan_placeholder_screen.dart`.
  6. `scripts/check-tokens.sh`: add `lib/nutrition` to `FORBIDDEN_DIRS`.

- [ ] **Step 4: Run to verify pass** — the hub test passes; `flutter analyze` clean; `grep -rn "TregoTab.plan\|PlanPlaceholderScreen" lib` → no matches; `flutter test` suite green.

- [ ] **Step 5: Commit** `feat(nav): Nutrition hub replaces Plan placeholder tab`.

---

### Task 2: Feed becomes a Social hub (Feed / Friends / Challenges)

**Files:**
- Create: `lib/social/screens/social_hub_screen.dart` (token-styled; the canonical Feed destination)
- Modify: `lib/navigation/app_shell.dart` (Feed child → `SocialHubScreen`, preserve `_feedKey` reload into its Feed tab)
- Modify deep-link targets if needed: `lib/push/push_navigation.dart`, `lib/notifications/notifications_screen.dart` (Friends still reachable)
- Delete: `lib/social/social_hub.dart` (old orphan) once its behavior is folded in
- Test: `test/social/social_hub_screen_test.dart`

**Interfaces:**
- Produces: `class SocialHubScreen extends StatefulWidget { const SocialHubScreen({super.key, this.service, this.initialTab = 0}); }` — `DefaultTabController(length: 3)` / `TabController`, tabs **Feed / Friends / Challenges** with bodies `SocialFeedScreen` (holds the existing `SocialFeedScreenState` key for reload), `FriendsScreen`, `ChallengesScreen`. Exposes a way for the shell to `reload()` the feed tab (keep a `GlobalKey<SocialFeedScreenState>` inside, or accept the shell's key).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/social_hub_screen.dart';
import 'package:trego/social/social_service.dart';
import 'package:trego/social/screens/friends_screen.dart';

class _StubSocial implements SocialService {
  @override Future<List<Map<String, dynamic>>> getFriends() async => const [];
  @override Future<List<Map<String, dynamic>>> getFriendRequests() async => const [];
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('Social hub shows Feed/Friends/Challenges and can open Friends tab', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SocialHubScreen(service: _StubSocial(), initialTab: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Feed'), findsWidgets);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Challenges'), findsWidgets);
    expect(find.byType(FriendsScreen), findsOneWidget); // initialTab=1 => Friends
  });
}
```

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Implement** `SocialHubScreen` (token-styled shell with the 3 tabs, embedding the existing screens). In `app_shell.dart` swap the Feed `IndexedStack` child from the bare `SocialFeedScreen` to `SocialHubScreen(service: ...)`, and route `_feedKey`/reload into its feed tab. Update deep-link code so a friend-request notification opens `SocialHubScreen(initialTab: 1)` (Friends) — or navigates the existing hub to the Friends tab — instead of pushing a standalone `FriendsScreen`, keeping behavior equivalent. Delete `lib/social/social_hub.dart`.

- [ ] **Step 4: Run to verify pass** — test passes; deep-link path still resolves (run `test/push/push_navigation_test.dart` and adjust it if it asserted a standalone `FriendsScreen` push — update to the hub while preserving intent); suite green; `flutter analyze` clean.

- [ ] **Step 5: Commit** `feat(social): Feed tab becomes Feed/Friends/Challenges hub`.

---

### Task 3: You → real profile + clean settings

**Files:**
- Modify: `lib/screens/you_screen.dart`
- Test: `test/screens/you_screen_test.dart`

**Interfaces:**
- Produces: reworked `YouScreen` — a profile header (`TregoAvatar`, display name, `@username`, a 3-up key-stat row from `MetricsProvider` snapshot: total runs / this-week km / streak), an Achievements preview row (tap → `AchievementsScreen`), and Settings groups: **Account** (username → `UsernameEditScreen`), **Preferences** (Appearance, Recording, Notifications), **Sign out**. Removes the Recipes/TDEE/For You/Run History "tools" rows (now in Nutrition, Home, Progress).

- [ ] **Step 1: Write the failing test**

```dart
// Pump YouScreen within TregoTheme + the providers it reads (AppStateProvider, MetricsProvider).
// Assert: profile header present; 'Appearance'/'Recording'/'Sign out' rows present;
// 'Recipes' and 'TDEE Calculator' rows are GONE (moved to Nutrition).
// expect(find.text('Recipes'), findsNothing);
// expect(find.text('Sign out'), findsOneWidget);
```
Write it concretely against the actual provider harness used by other `test/screens` tests (read one first for the wrapper pattern).

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Implement** the reworked `YouScreen` (token-pure; it already lives in the enforced `lib/screens`). Keep sign-out calling `auth.signOut()`. Pull stats from `context.watch<MetricsProvider>()` snapshot (guard nulls with an empty state).

- [ ] **Step 4: Run to verify pass** — test passes; suite green; analyze clean.

- [ ] **Step 5: Commit** `feat(you): real profile header + grouped settings; move tools out`.

---

### Task 4: Home surfacing — Achievements, For You, Progress, Training

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Create: `lib/screens/progress_screen.dart` (tabs: Run History = `TrackerDashboardScreen`, Analytics = `AdvancedAnalyticsDashboard`)
- Test: `test/screens/home_surfacing_test.dart`, `test/screens/progress_screen_test.dart`

**Interfaces:**
- Produces: `HomeScreen` gains (a) an **Achievements preview** strip (`SectionHead` "Achievements" + horizontal cards; tap → `AchievementsScreen`), (b) a **"For You" AI coach card** (tap → `EnhancedRecommendationsScreen`), (c) the metrics `SectionHead` "This Week" gets a "See all" that pushes `ProgressScreen`, (d) a **Training** entry (row/card) that pushes `WorkoutHub`. `ProgressScreen` is a token-styled `DefaultTabController(length: 2)` embedding `TrackerDashboardScreen` and `AdvancedAnalyticsDashboard`.

- [ ] **Step 1: Write the failing tests** — pump `HomeScreen` in its provider harness; assert the "For You" card and "Achievements" section render, and tapping "See all" / a Progress entry pushes `ProgressScreen`. Separate `progress_screen_test.dart` asserts the two tabs render. (Write against the existing Home test harness — read `test/screens/` for the wrapper.)

- [ ] **Step 2: Run to verify they fail.**

- [ ] **Step 3: Implement** — add the sections to `HomeScreen` (token-pure), create `ProgressScreen`. Repoint the old "Browse plans" hero CTA (which switched to the dead Plan tab) to push `WorkoutHub` or `ProgressScreen` as appropriate.

- [ ] **Step 4: Run to verify pass** — tests pass; suite green; analyze clean.

- [ ] **Step 5: Commit** `feat(home): surface achievements, AI coach, progress, training`.

---

### Task 5: Delete dead code + fix crash-prone routes

**Files:**
- Delete: `lib/profile/profile_screen.dart`, `lib/profile/simple_profile_screen.dart`, `lib/profile/settings_screen.dart`, `lib/auth/auth_screen.dart`, `lib/personalization/screens/recommendations_screen.dart`, `lib/personalization/screens/insights_screen.dart`, `lib/personalization/screens/personalization_settings_screen.dart`
- Modify: any remaining `Navigator.pushNamed` to unregistered routes (`friends_screen.dart:406` and the deleted screens' targets) — remove or replace with a real push
- Resolve: duplicate `WeeklySummaryScreen` class — rename `lib/workouts/weekly_summary_screen.dart`'s class to `WorkoutWeeklySummaryScreen` (update its one referencing site in `workout_plan_screen.dart`)
- Delete: stray `.!NNNNN!` artifact files (confirm with `git status --porcelain` / they should be untracked — remove only untracked `.!` files, never real source)
- Test: `test/navigation/no_unregistered_routes_test.dart` (guard)

**Interfaces:**
- Produces: no unreferenced orphan screens remain; no `pushNamed` to a route absent from `app.dart`'s `routes`.

- [ ] **Step 1: Write the failing guard test**

```dart
// A source-scan test: read app.dart to collect registered route names, then grep lib/
// for Navigator.pushNamed('...') targets and assert every target is registered.
// (Implement as a Dart test that reads files via dart:io, or a simpler assertion listing
//  the known-bad targets are gone. Keep it deterministic.)
```
If a file-scanning test is awkward, implement it as an explicit test asserting the specific previously-broken route strings no longer appear in `lib/` (via `dart:io` file reads).

- [ ] **Step 2: Run to verify it fails** (broken routes still present).

- [ ] **Step 3: Implement** — delete the orphan files; confirm each is truly unreferenced first (`grep -rn ClassName lib test`); remove/replace the unregistered `pushNamed` calls; rename the duplicate `WeeklySummaryScreen`; remove untracked `.!NNNNN!` files. Run `grep -rn "SocialHub\b" lib` to confirm the old orphan (deleted in Task 2) is gone.

- [ ] **Step 4: Run to verify pass** — guard test passes; `flutter analyze` clean (no broken imports); `flutter test` suite green.

- [ ] **Step 5: Commit** `chore(ia): delete orphan screens, fix unregistered routes, dedupe class names`.

---

### Task 6: Phase-1 green + PR(s)

- [ ] `flutter analyze` clean; `flutter test` green (minus the 6 known `notifications_screen_test.dart` pre-existing failures).
- [ ] Push and open PR(s). Tasks 1–5 may land as one branch `feat/ia-redesign-phase1` (reviewed per-task via SDD) or split (nav+nutrition / social / you / home / cleanup) if the diff is large. Squash-merge after the whole-branch review; verify `main` green.

---

## Notes for the implementer
- Read one existing `test/screens/*_test.dart` first to copy the exact provider + `TregoTheme` wrapper used for widget tests — reuse it verbatim for the new shell/screen tests rather than inventing a harness.
- Embedded legacy screens (RecipeScreen, TdeeScreen, FriendsScreen, ChallengesScreen, AchievementsScreen, EnhancedRecommendationsScreen, TrackerDashboardScreen, AdvancedAnalyticsDashboard, WorkoutHub) are used as-is — do not restyle them in Phase 1 (that's Phase 2).
- If a screen requires a provider/service not in scope when embedded in a new hub, provide it at the hub level the same way the current shell provides `SocialService`.
