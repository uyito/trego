# Frontend Phase 2 — Group A (Nutrition) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Migrate the two Nutrition-tab screens (`recipe_screen.dart`, `tdee_screen.dart`) onto the token design system so they match the rest of the app, preserving behavior.

**Architecture:** In-place styling migration — replace raw `Color(0x…)`, ad-hoc `Theme.of(context)` colors, and any `AppTheme` refs with `context.tokens` roles, `context.typo` text styles, `Space`/`Radii`, and `widgets/core` components where they fit. No behavioral/flow changes. Add each migrated file to the token-linter guard.

**Tech Stack:** Flutter, token design system (`lib/shared/theme`), `flutter_test`.

## Global Constraints

- Definition of "migrated" (from the Phase 2 spec): no raw `Color(0x…)`, no `AppTheme.`; colors via `context.tokens` roles (`brand`, `onBrand`, `canvas`, `surface`, `surfaceSunken`, `border`, `ink`, `inkMuted`, `danger`); text via `context.typo`; spacing/radii via `Space`/`Radii`; dark mode correct; behavior & layout intent preserved; tests green; file added to `scripts/check-tokens.sh`.
- **Preserve behavior and structure** — this is a consistency pass, not a redesign. Do not change flows, remove features, or rename public widgets/routes.
- Read `lib/shared/theme/trego_tokens.dart`, `trego_typography.dart`, `context_tokens.dart`, and skim a already-migrated screen (`lib/screens/you_screen.dart` or `lib/nutrition/nutrition_hub.dart`) to learn the idiom BEFORE editing.
- Keep the suite green (the 6 pre-existing `notifications_screen`/`route_map` failures are out of scope — leave them).
- Token role mapping guidance (map the legacy intent, don't invent):
  - page background → `tokens.canvas`; card/sheet surface → `tokens.surface`; subtle/sunken fill → `tokens.surfaceSunken`
  - primary/brand accents, CTAs → `tokens.brand` (text on it → `tokens.onBrand`)
  - primary text → `tokens.ink`; secondary/hint text → `tokens.inkMuted`; dividers/outlines → `tokens.border`; destructive → `tokens.danger`
  - If a legacy color has no clean token role (e.g. a semantic macro color in TDEE, a chart hue), keep it but centralize it as a named local `const` with an `// ALLOW-HEX: <reason>` comment (the check-tokens escape hatch) rather than scattering raw hex. Prefer a token role whenever one fits.

---

### Task 1: Migrate `recipe_screen.dart`

**Files:**
- Modify: `lib/recipes/recipe_screen.dart` (750 lines)
- Modify: `scripts/check-tokens.sh` (add `lib/recipes/recipe_screen.dart` to `FORBIDDEN_DIRS`)
- Test: `test/recipes/recipe_screen_test.dart` (create if absent)

**Interfaces:**
- Produces: same public `RecipeScreen` widget/constructor (unchanged API); internally token-styled.

- [ ] **Step 1: Write a render/smoke test first**
  Create `test/recipes/recipe_screen_test.dart` that pumps `RecipeScreen` inside the repo's `TregoTheme` + provider harness (copy the wrapper from an existing `test/` widget test; stub any service it calls so it doesn't hit the network — inspect `RecipeScreen`'s service usage and provide a stub/fake). Assert the screen builds and a couple of stable key elements render (e.g. the app-bar title, a primary action). Run it → it should PASS on the current (pre-migration) code (this is the behavior baseline).

- [ ] **Step 2: Run the baseline test** — `flutter test test/recipes/recipe_screen_test.dart` → PASS (baseline green before migration).

- [ ] **Step 3: Migrate styling**
  Replace every raw `Color(0x…)`, `Colors.<x>` used as theme color, ad-hoc `TextStyle`, and `Theme.of(context)` color access with the token equivalents per the mapping above. Use `widgets/core` components (`TregoScaffold`/`TregoAppBar`, cards, `TregoButton`) where the existing structure maps cleanly — but do not restructure flows. Keep all logic, state, and service calls identical.

- [ ] **Step 4: Verify**
  - `grep -nE "Color\(0x|AppTheme\." lib/recipes/recipe_screen.dart` → empty (or only `// ALLOW-HEX:`-tagged lines).
  - `sh scripts/check-tokens.sh` → passes (after adding the file to `FORBIDDEN_DIRS`).
  - `flutter test test/recipes/recipe_screen_test.dart` → PASS (behavior preserved).
  - `flutter analyze lib/recipes/recipe_screen.dart` → no new errors.

- [ ] **Step 5: Commit** `style(recipes): migrate recipe_screen to token design system`.

---

### Task 2: Migrate `tdee_screen.dart`

**Files:**
- Modify: `lib/tdee/tdee_screen.dart` (915 lines)
- Modify: `scripts/check-tokens.sh` (add `lib/tdee/tdee_screen.dart`)
- Test: `test/tdee/tdee_screen_test.dart` (create if absent)

**Interfaces:**
- Produces: same public `TdeeScreen` widget/constructor; internally token-styled.

- [ ] **Step 1: Write a render/smoke test first**
  Create `test/tdee/tdee_screen_test.dart` — pump `TdeeScreen` in `TregoTheme` + harness; assert it builds and key elements render (app-bar title, the calculate action, an input field). TDEE is largely local computation, so it likely needs no network stub — verify. Run → PASS on current code (baseline).

- [ ] **Step 2: Run the baseline test** → PASS.

- [ ] **Step 3: Migrate styling** — same approach as Task 1. TDEE may use semantic result colors (e.g. calorie-goal categories); where a token role doesn't fit, centralize each as a named `const` with `// ALLOW-HEX: <reason>` rather than inline raw hex. Preserve all calculation logic and the results UI structure.

- [ ] **Step 4: Verify** — grep clean (or ALLOW-HEX-tagged); `sh scripts/check-tokens.sh` passes; `flutter test test/tdee/tdee_screen_test.dart` PASS; `flutter analyze lib/tdee/tdee_screen.dart` clean.

- [ ] **Step 5: Commit** `style(tdee): migrate tdee_screen to token design system`.

---

### Task 3: Group A green + PR

- [ ] `flutter analyze` clean (info-lints ok); `flutter test` green except the known pre-existing failures.
- [ ] Confirm dark mode: both screens use token roles only (no hardcoded light-mode assumptions) — spot-check by reading for any remaining `Colors.white`/`Colors.black` used as surfaces/text.
- [ ] Push `feat/phase2-nutrition`, open PR to main, squash-merge after whole-branch review, verify main green.
- [ ] (Controller flashes a device build after merge for a visual look before Group B.)

## Notes for the implementer
- Do NOT redesign — if you find a screen genuinely confusing, note it in your report as a follow-up; don't restructure it here.
- If the token-linter flags a color you truly can't map to a role, use the `// ALLOW-HEX: <reason>` escape hatch (as the script documents) rather than leaving the file off the guard — the file MUST be added to the guard.
- Read the two theme files + one migrated screen first so your token usage matches the established idiom exactly.
