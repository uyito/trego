# Frontend Phase 2 — Group D (Auth) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Migrate the auth screens (`login_screen`, `register_screen`, `social_sign_in_buttons`) onto the token design system — the first screens new users see — preserving behavior.

**Architecture:** In-place styling migration to `context.tokens`/`context.typo`/`Space`/`Radii` + `widgets/core`; no behavioral/flow changes; each migrated file added to the token-linter guard.

**Tech Stack:** Flutter, token design system, `flutter_test`.

## Global Constraints

Identical to Groups A–C (Phase 2 spec):
- Definition of "migrated": no raw `Color(0x…)`/`AppTheme.` (except `// ALLOW-HEX:`); colors via `context.tokens`; text via `context.typo`; spacing/radii via `Space`/`Radii`; dark-mode correct; behavior/layout preserved; tests green; file added to `scripts/check-tokens.sh`.
- **Preserve behavior/flows/state and auth logic exactly.** Styling only. Do NOT change any Firebase Auth / Google / Apple sign-in calls, validation, or navigation.
- Read `lib/shared/theme/{trego_tokens,trego_typography,context_tokens}.dart` + a migrated example (`lib/recipes/recipe_screen.dart`) BEFORE editing.
- Token mapping: page bg→`canvas`; card→`surface`; sunken→`surfaceSunken`; brand/CTA→`brand`(+`onBrand`); primary text→`ink`; secondary→`inkMuted`; outlines→`border`; error→`danger`. Google/Apple brand button colors (Google white/multicolor, Apple black) are BRAND-MANDATED — keep them as named `const`s with `// ALLOW-HEX: <reason>` (their brand guidelines require specific colors), do not tokenize.
- Keep the suite green except the 6 known pre-existing failures.

---

### Task 1: Migrate `login_screen.dart` + `register_screen.dart`

**Files:** Modify `lib/auth/login_screen.dart` (~305 lines) and `lib/auth/register_screen.dart` (~343 lines); add both to `scripts/check-tokens.sh`; Tests `test/auth/login_screen_test.dart`, `test/auth/register_screen_test.dart` (create if absent; stub the auth service / avoid real Firebase — apply the try/catch guard pattern if construction touches Firebase).

- [ ] **Step 1** Render tests: pump each screen under `TregoTheme`; assert it builds + key fields (email/password inputs, the primary sign-in/register button, the toggle link) render. Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate styling. Preserve every auth call (`signInWithEmail`, social sign-in), form validation, error display (→ `tokens.danger`), and navigation between login/register and into the app. Input fields → token-styled (border `tokens.border`, focus `tokens.brand`, error `tokens.danger`).
- [ ] **Step 4** Verify: `grep -nE "Color\(0x|AppTheme\." lib/auth/login_screen.dart lib/auth/register_screen.dart` empty (except ALLOW-HEX); `sh scripts/check-tokens.sh` passes; both tests PASS; `flutter analyze` on both no new errors.
- [ ] **Step 5** Commit `style(auth): migrate login + register screens to token design system`.

### Task 2: Migrate `social_sign_in_buttons.dart`

**Files:** Modify `lib/auth/social_sign_in_buttons.dart`; add to `scripts/check-tokens.sh`; Test `test/auth/social_sign_in_buttons_test.dart` (create if absent).

- [ ] **Step 1** Render test: pump the buttons widget under `TregoTheme`; assert the Google + Apple buttons render. Run → PASS.
- [ ] **Step 2** Baseline → PASS.
- [ ] **Step 3** Migrate the surrounding chrome/text to tokens; keep the Google/Apple **brand colors** as named `const`s with `// ALLOW-HEX: brand guideline` (they must match each provider's brand spec). Preserve the `onPressed` callbacks / sign-in triggers exactly.
- [ ] **Step 4** Verify grep clean (except the brand ALLOW-HEX consts); guard passes; test PASS; analyze clean.
- [ ] **Step 5** Commit `style(auth): migrate social sign-in buttons to token design system`.

### Task 3: Group D green + PR

- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green except the 6 known pre-existing failures.
- [ ] Dark-mode spot-check: the auth screens read correctly in dark mode (inputs, text, background); brand buttons keep their mandated colors.
- [ ] Push `feat/phase2-auth`, open PR, squash-merge after whole-branch review, verify main green.

## Notes for the implementer
- Styling only — do NOT touch auth logic, validation, or provider sign-in calls.
- Google/Apple brand colors stay as tagged ALLOW-HEX consts (brand guidelines mandate them); everything else tokenizes.
- Add every migrated file to the guard.
