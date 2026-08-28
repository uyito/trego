# Frontend Phase 2 — Group E (Cleanup + retire AppTheme) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Finish the token migration — notifications, workouts, and the remaining shared/tracker widgets — then delete the dead legacy widgets and **retire `lib/shared/app_theme.dart`** entirely.

**Architecture:** In-place styling migration to `context.tokens`/`context.typo`/`Space`/`Radii`; delete confirmed-dead legacy files; remove `AppTheme` once nothing references it. Each migrated file added to the token-linter guard.

**Tech Stack:** Flutter, token design system, `flutter_test`.

## Global Constraints

Identical to Groups A–D (Phase 2 spec):
- Definition of "migrated": no raw `Color(0x…)`/`AppTheme.` (except `// ALLOW-HEX:`); colors via `context.tokens`; text via `context.typo`; spacing/radii via `Space`/`Radii`; dark-mode correct; behavior/layout preserved; tests green; file added to `scripts/check-tokens.sh`.
- **Preserve behavior/flows/state/service calls and public widget APIs.** Styling only.
- Read `lib/shared/theme/{trego_tokens,trego_typography,context_tokens}.dart` + a migrated example BEFORE editing.
- Token mapping: page bg→`canvas`; card→`surface`; sunken→`surfaceSunken`; brand/CTA→`brand`(+`onBrand`); primary text→`ink`; secondary→`inkMuted`; outlines→`border`; error→`danger`; positive→`success`. No-role color → named `const` + `// ALLOW-HEX: <reason>`.
- Apply the Firebase try/catch guard (as in Group A/C) if a screen touches Firebase at construction.
- Keep the suite green. NOTE: the 6 pre-existing failures are 5 in `notifications_screen_test.dart` + 1 in `route_map_test.dart`. Task 1 migrates `notifications_screen` and should update that test to the `TregoTheme` harness — this may RESOLVE some/all of the 5 notifications failures (a bonus), but must not introduce new failures. Preserve each existing assertion's intent.

---

### Task 1: Migrate `notifications_screen.dart` + `notification_badge.dart`

**Files:** Modify `lib/notifications/notifications_screen.dart` (~210 lines) and `lib/notifications/widgets/notification_badge.dart`; add both to `scripts/check-tokens.sh`; Modify `test/notifications/notifications_screen_test.dart` (update to `testApp()`/`TregoTheme` harness); Test `test/notifications/notification_badge_test.dart` (already exists — keep green).

- [ ] **Step 1** Update `test/notifications/notifications_screen_test.dart` to pump under `testApp()`/`TregoTheme` (it currently uses a bare `MaterialApp`, which is one cause of its failures). Preserve each existing assertion. Run → see how many of the 5 now pass; note any that fail for a genuine reason (e.g. the ListTile/ColoredBox bug the reviews mentioned) and fix if it's a real bug surfaced by the migration, else leave with a documented reason.
- [ ] **Step 2** Migrate `notifications_screen.dart` + `notification_badge.dart` styling per the mapping. Preserve the notification list, mark-read, and deep-link-tap behavior (which routes into the social hub Friends tab).
- [ ] **Step 3** Verify: `grep -nE "Color\(0x|AppTheme\." lib/notifications/notifications_screen.dart lib/notifications/widgets/notification_badge.dart` empty (except ALLOW-HEX); `sh scripts/check-tokens.sh` passes; the notifications tests run (report pass/fail count vs the prior 5-failing baseline); `flutter analyze` on both no new errors.
- [ ] **Step 4** `flutter test` full suite; report the failure count (goal: ≤ prior 6; ideally fewer if notifications tests now pass).
- [ ] **Step 5** Commit `style(notifications): migrate notifications_screen + badge to token design system`.

### Task 2: Migrate `workout_plan_screen.dart` + `workout_screen.dart`

**Files:** Modify `lib/workouts/workout_plan_screen.dart` (~746 lines) and `lib/workouts/workout_screen.dart` (~153 lines); add both to `scripts/check-tokens.sh`; Tests `test/workouts/workout_plan_screen_test.dart`, `test/workouts/workout_screen_test.dart` (create if absent; stub any service).

- [ ] **Step 1** Render tests under `TregoTheme` (stub data). Run → PASS (baseline).
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate styling. Preserve the plan browser, the push to `WorkoutScreen`, and the workout/exercise runner flow. Note: `workout_plan_screen.dart` references the now-renamed `WorkoutWeeklySummaryScreen` — if that reference is dead per Task 4's deletion, coordinate (Task 4 deletes the dead file; if `workout_plan_screen` still imports/pushes it, keep that flow working or confirm it's unused — grep before Task 4 deletes).
- [ ] **Step 4** Verify grep clean (except ALLOW-HEX); guard passes; tests PASS; analyze clean.
- [ ] **Step 5** Commit `style(workouts): migrate workout_plan + workout screens to token design system`.

### Task 3: Migrate remaining shared/tracker widgets

**Files:** Modify (only those with raw hex — grep each first) `lib/shared/top_bar.dart`, `lib/tracker/weekly_recap_widget.dart`, `lib/tracker/weekly_summary_screen.dart` (the TRACKER `WeeklySummaryScreen`, still used by `tracker_dashboard_screen`); add each migrated file to `scripts/check-tokens.sh`; add/extend a render test for each screen-level widget (`weekly_summary_screen` at least).

- [ ] **Step 1** Render test for `WeeklySummaryScreen` (tracker) under `TregoTheme` (stub data). Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate the three files' styling. `top_bar.dart` and `weekly_recap_widget.dart` are widgets — migrate their colors/text. Preserve behavior. (If `top_bar.dart` turns out to be unused/orphaned, confirm with `grep -rn "TopBar\|top_bar" lib` and note it for possible deletion instead — but only delete if truly unreferenced.)
- [ ] **Step 4** Verify grep clean across the three (except ALLOW-HEX); guard passes; tests PASS; analyze clean.
- [ ] **Step 5** Commit `style(cleanup): migrate top_bar + tracker weekly widgets to token design system`.

### Task 4: Retire `AppTheme` (delete dead legacy) + final sweep

**Files:** Delete (after confirming each is unreferenced) `lib/widgets/nike_animations.dart`, `lib/widgets/nike_components.dart`, `lib/widgets/nike_dashboard.dart`, `lib/widgets/nike_run_tracker.dart`, `lib/workouts/weekly_summary_screen.dart` (dead `WorkoutWeeklySummaryScreen`), then `lib/shared/app_theme.dart`; Test `test/cleanup/no_apptheme_test.dart` (a guard test).

- [ ] **Step 1** For EACH nike file, grep every public class it declares (`grep -nE "^class [A-Z]"` the file, then `grep -rn "<ClassName>" lib test` for each) to confirm ZERO references outside the file itself. For `weekly_summary_screen.dart`, confirm `WorkoutWeeklySummaryScreen` has zero references. If ANY is referenced, STOP and report — do not delete a used file.
- [ ] **Step 2** Write the guard test `test/cleanup/no_apptheme_test.dart`: a `dart:io` test that scans `lib/**/*.dart` and asserts no file contains `AppTheme` and `lib/shared/app_theme.dart` does not exist. Run → it FAILS now (AppTheme still present).
- [ ] **Step 3** Delete the confirmed-dead nike files + dead `workouts/weekly_summary_screen.dart`. Then `grep -rn "AppTheme" lib` → should be only `lib/shared/app_theme.dart`. Delete `lib/shared/app_theme.dart`. Remove any now-dangling imports (`flutter analyze` must be clean — fix any import of a deleted file).
- [ ] **Step 4** Run the guard test → PASS. `flutter analyze` → clean (no broken imports). `flutter test` full suite → green (≤ prior failure count).
- [ ] **Step 5** Commit `chore(theme): delete dead Nike widgets + retire AppTheme`.

### Task 5: Phase 2 complete — final sweep + PR

- [ ] Final sweep: `grep -rn "AppTheme" lib` → empty; `grep -rlnE "Color\(0x" lib | grep '\.dart$'` → only files that are in `check-tokens.sh` with tagged `// ALLOW-HEX` lines (spot-check a couple). Confirm `sh scripts/check-tokens.sh` passes.
- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green (report final count; the notifications failures may now be resolved).
- [ ] Push `feat/phase2-cleanup`, open PR, squash-merge after whole-branch review, verify main green. **This completes Phase 2.**

## Notes for the implementer
- Deletions: grep-confirm zero references for EVERY class before deleting any file. If in doubt, keep it and report.
- The notifications test was pre-existing-failing partly due to a bare `MaterialApp` (no TregoTheme); moving it to `testApp()` should help — but if a genuine `ListTile`/`ColoredBox` assertion bug remains, fix it if small and real, else document it.
- Styling only for migrations; deletion only for confirmed-dead files.
