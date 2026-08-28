# Frontend Phase 2 — Group C (Progress / Home-linked) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Migrate the Home/Progress-linked screens (`achievements_screen`, `advanced_analytics_dashboard`, `tracker_dashboard_screen`, `for_you_hub` + `enhanced_recommendations_screen`) onto the token design system, preserving behavior.

**Architecture:** In-place styling migration to `context.tokens`/`context.typo`/`Space`/`Radii` + `widgets/core`; no behavioral/flow changes. Each migrated file added to the token-linter guard.

**Tech Stack:** Flutter, token design system (`lib/shared/theme`), `flutter_test`.

## Global Constraints

Identical to Groups A/B (see the Phase 2 spec + prior group plans):
- Definition of "migrated": no raw `Color(0x…)`/`AppTheme.` (except `// ALLOW-HEX:`-tagged); colors via `context.tokens`; text via `context.typo`; spacing/radii via `Space`/`Radii`; dark-mode correct; behavior/layout preserved; tests green; file added to `scripts/check-tokens.sh`.
- **Preserve behavior/flows/state/service calls and public widget APIs.** Styling only.
- Read `lib/shared/theme/{trego_tokens,trego_typography,context_tokens}.dart` and a migrated example (`lib/social/screens/challenges_screen.dart`, `lib/recipes/recipe_screen.dart`) BEFORE editing.
- Token mapping: page bg→`canvas`; card→`surface`; sunken→`surfaceSunken`; brand/CTA→`brand`(+`onBrand`); primary text→`ink`; secondary→`inkMuted`; outlines→`border`; destructive/error→`danger`(+`onDanger`); positive/success→`success`. No-role color → named `const` + `// ALLOW-HEX: <reason>`.
- If a screen touches Firebase synchronously at construction (breaks the Firebase-less test host), use the lazy-init/`try-catch` pattern from Group A's `recipe_screen`.
- Keep the suite green except the 6 known pre-existing failures.

---

### Task 1: Migrate `achievements_screen.dart`

**Files:** Modify `lib/achievements/achievements_screen.dart` (~623 lines); add to `scripts/check-tokens.sh`; Test `test/achievements/achievements_screen_test.dart` (create if absent; stub any service — inspect its data source first; if it reads Firestore/Firebase at construction, apply the Group A lazy-init pattern).

- [ ] **Step 1** Render test: pump `AchievementsScreen` under `TregoTheme`; assert builds + a stable element (title / a badge). Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate styling. Badge/tier accent colors (bronze/silver/gold or category hues) that have no token role → centralize as named `const`s with `// ALLOW-HEX: <reason>` (like challenges' category colors). Preserve unlock state logic and layout.
- [ ] **Step 4** Verify: grep clean (except ALLOW-HEX); `sh scripts/check-tokens.sh` passes; test PASS; `flutter analyze` on the file no new errors.
- [ ] **Step 5** Commit `style(achievements): migrate achievements_screen to token design system`.

### Task 2: Migrate `advanced_analytics_dashboard.dart` (charts)

**Files:** Modify `lib/analytics/advanced_analytics_dashboard.dart` (~819 lines); add to `scripts/check-tokens.sh`; Test `test/analytics/advanced_analytics_dashboard_test.dart` (create if absent; stub its data source).

- [ ] **Step 1** Render test under `TregoTheme` (stub data). Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate chrome/text/cards to tokens. **Chart series colors:** map to token roles where sensible (primary series → `tokens.brand`, positive → `tokens.success`, negative → `tokens.danger`); for a multi-series categorical palette with no clean roles, define a single named `const List<Color> _chartPalette` with `// ALLOW-HEX:` and reuse it (do NOT scatter raw hex per chart). Keep the chart library and all data/computation untouched.
- [ ] **Step 4** Verify grep clean (except the centralized `_chartPalette`/ALLOW-HEX); guard passes; test PASS; analyze clean.
- [ ] **Step 5** Commit `style(analytics): migrate analytics dashboard to token design system`.

### Task 3: Migrate `tracker_dashboard_screen.dart`

**Files:** Modify `lib/tracker/tracker_dashboard_screen.dart` (~1106 lines); add to `scripts/check-tokens.sh`; Test `test/tracker/tracker_dashboard_screen_test.dart` (create if absent; stub its data source — it may read run history from a service/Firestore; apply lazy-init if construction touches Firebase).

- [ ] **Step 1** Render test under `TregoTheme` (stub data). Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate styling (it's large — be systematic, top to bottom). Preserve run-history list, calorie/water logging, and the push to `WeeklySummaryScreen`. Any macro/status semantic colors → token role or centralized ALLOW-HEX const.
- [ ] **Step 4** Verify grep clean (except ALLOW-HEX); guard passes; test PASS; analyze clean.
- [ ] **Step 5** Commit `style(tracker): migrate tracker_dashboard_screen to token design system`.

### Task 4: Migrate `for_you_hub.dart` + `enhanced_recommendations_screen.dart`

**Files:** Modify `lib/personalization/for_you_hub.dart` (~65 lines) and `lib/personalization/screens/enhanced_recommendations_screen.dart` (~490 lines); add each to `scripts/check-tokens.sh`; Test `test/personalization/for_you_hub_test.dart` (create if absent; stub the AI coach / personalization services).

- [ ] **Step 1** Render test: pump `ForYouHub` under `TregoTheme` (stub services); assert its tabs render. Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate both files' styling. `for_you_hub` is a small tabbed shell; `enhanced_recommendations_screen` has recommendation cards (fitness/nutrition/recovery). Category accents → token role or centralized ALLOW-HEX. Preserve the tabs + service calls.
- [ ] **Step 4** Verify grep clean (except ALLOW-HEX) on both; guard passes; test PASS; analyze clean.
- [ ] **Step 5** Commit `style(personalization): migrate for_you_hub + enhanced_recommendations to token design system`.

### Task 5: Group C green + PR

- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green except the 6 known pre-existing failures.
- [ ] Dark-mode spot-check across all migrated files (no `Colors.white`/`Colors.black` as surface/text; chart palette readable in dark).
- [ ] Push `feat/phase2-progress`, open PR, squash-merge after whole-branch review, verify main green.

## Notes for the implementer
- Styling only — do not restructure flows, change chart data, or alter run/achievement computations. Note weak screens as follow-ups, don't redesign.
- Centralize any decorative/categorical hex (badge tiers, chart series) into ONE named const per file with `// ALLOW-HEX:`, and still add the file to the guard.
- Tasks 2 and 3 are large — migrate systematically and keep every data/logic line byte-identical.
