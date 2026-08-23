# Frontend Phase 2 — Group B (Social) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Migrate the three Social-hub screens (`social_feed_screen`, `friends_screen`, `challenges_screen`) + their sheets/dialogs onto the token design system, preserving behavior.

**Architecture:** In-place styling migration to `context.tokens` / `context.typo` / `Space` / `Radii` + `widgets/core`; no behavioral/flow changes. Each migrated file added to the token-linter guard.

**Tech Stack:** Flutter, token design system (`lib/shared/theme`), `flutter_test`.

## Global Constraints

Identical to Group A (see `2026-08-06-frontend-phase2-groupA-nutrition.md` and the Phase 2 spec):
- Definition of "migrated": no raw `Color(0x…)`/`AppTheme.` (except `// ALLOW-HEX:`-tagged); colors via `context.tokens` roles; text via `context.typo`; spacing/radii via `Space`/`Radii`; dark-mode correct; behavior/layout preserved; tests green; file added to `scripts/check-tokens.sh`.
- **Preserve behavior/flows/state/service calls and public widget APIs.** Styling only.
- Read `lib/shared/theme/{trego_tokens,trego_typography,context_tokens}.dart` and a migrated example (`lib/recipes/recipe_screen.dart` from Group A, `lib/social/screens/social_hub_screen.dart` which is already token-pure) BEFORE editing, to match the idiom.
- Token mapping: page bg→`canvas`; card→`surface`; sunken→`surfaceSunken`; brand/CTA→`brand`(+`onBrand`); primary text→`ink`; secondary→`inkMuted`; outlines→`border`; destructive/error→`danger`; positive/success→`success`. No-role color → named `const` + `// ALLOW-HEX: <reason>`.
- If a legacy screen touches Firebase synchronously at construction (breaks the Firebase-less test host), use the lazy-init/`try-catch` pattern established in Group A's `recipe_screen`.
- Keep the suite green except the 6 known pre-existing failures (5 `notifications_screen` + 1 `route_map`).

---

### Task 1: Migrate `social_feed_screen.dart`

**Files:** Modify `lib/social/screens/social_feed_screen.dart` (~529 lines); modify `scripts/check-tokens.sh` (add the file); Test `test/social/social_feed_screen_test.dart` (create if absent — a fake `SocialService` keeps it off the network, mirror `test/push/push_navigation_test.dart`'s `_StubSocial`).

- [ ] **Step 1** Write/extend a render test that pumps `SocialFeedScreen(service: stub)` under `TregoTheme`; assert it builds + a stable element renders. Run → PASS (baseline).
- [ ] **Step 2** Run baseline → PASS.
- [ ] **Step 3** Migrate styling per the mapping. Preserve the feed load/refresh, post actions (like/comment/edit/report), and the `SocialFeedScreenState.reload()` API the shell depends on.
- [ ] **Step 4** Verify: `grep -nE "Color\(0x|AppTheme\." lib/social/screens/social_feed_screen.dart` empty (except ALLOW-HEX); `sh scripts/check-tokens.sh` passes; focused test PASS; `flutter analyze` no new errors.
- [ ] **Step 5** Commit `style(social): migrate social_feed_screen to token design system`.

### Task 2: Migrate `friends_screen.dart`

**Files:** Modify `lib/social/screens/friends_screen.dart` (~475 lines); add to `scripts/check-tokens.sh`; Test `test/social/friends_screen_test.dart` (create if absent; stub `SocialService`).

- [ ] **Step 1** Render test: pump `FriendsScreen(service: stub, initialTab: 0)` under `TregoTheme`; assert builds + Friends/Requests tabs render. Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate styling. Preserve `initialTab`, friend search/add/request-accept flows, and the (Phase-1-added) "view profile" snackbar stub.
- [ ] **Step 4** Verify (grep clean, guard passes, test PASS, analyze clean).
- [ ] **Step 5** Commit `style(social): migrate friends_screen to token design system`.

### Task 3: Migrate `challenges_screen.dart` + social widgets

**Files:** Modify `lib/social/screens/challenges_screen.dart` (~613 lines) and the social widgets that carry raw hex: `lib/social/widgets/comments_sheet.dart`, `edit_post_dialog.dart`, `report_dialog.dart` (check each with `grep -nE "Color\(0x|AppTheme\."` first — migrate only those with raw hex/AppTheme; `mention_text.dart` is already token-pure per Phase 1, skip if clean); add each migrated file to `scripts/check-tokens.sh`; Test `test/social/challenges_screen_test.dart` (create if absent; stub any service).

- [ ] **Step 1** Render test for `ChallengesScreen` under `TregoTheme` (stub its data source). Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate `challenges_screen` + the raw-hex social widgets per the mapping. Preserve challenge list/join flows and the sheets/dialogs' behavior.
- [ ] **Step 4** Verify grep clean across all touched files; `sh scripts/check-tokens.sh` passes; tests PASS; analyze clean.
- [ ] **Step 5** Commit `style(social): migrate challenges_screen + social widgets to token design system`.

### Task 4: Group B green + PR

- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green except the 6 known pre-existing failures.
- [ ] Dark-mode spot-check: no `Colors.white`/`Colors.black` used as surface/text across the migrated files.
- [ ] Push `feat/phase2-social`, open PR, squash-merge after whole-branch review, verify main green.

## Notes for the implementer
- Styling only — do not restructure flows or remove features. Note any genuinely weak screen as a follow-up, don't redesign it here.
- Use `// ALLOW-HEX: <reason>` for any color with no token role, and still add the file to the guard.
- Match the exact idiom of the already-migrated `social_hub_screen.dart` and Group A's `recipe_screen.dart`.
