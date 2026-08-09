# Activity Tracking (Strava-comparable) — Design

**Date:** 2026-08-06
**Status:** Approved (user "go")
**Scope:** Phone-side multi-activity logging. Watch companion is a separate, deferred Phase 2 spec.

## Problem

Trego today tracks only **running** richly (live GPS via `lib/tracker/` + run PRs via `MetricsService`). Other workouts have only a crude `SimpleWorkoutTracker` (a manual timer + a hardcoded type dropdown + sets/reps written straight to Firestore, bypassing the backend model).

The user wants Trego to track **most activities people care about** — cardio, sports, and strength — with coverage comparable to Strava: running, cycling, walking, hiking, swimming, rowing, workouts/strength, yoga, plus team sports (soccer, basketball, tennis), climbing, skiing, etc.

## Core insight: one model can't fit all activities

A strength lift (per-set reps × weight) and a bike ride (distance + duration + elevation) and a soccer match (duration + notes) have different data. The design uses a **discriminated union keyed by activity type**, with each activity declaring a **logKind** that drives its logging form.

### Logging shapes (logKind)

| logKind | Fields captured | Example activities |
|---|---|---|
| `strength` | `exercises[]` → sets (reps × weight, RPE, rest timer) | Weight Training, Push-ups, Squats |
| `distanceCardio` | distance + duration + elevationGain + derived avgPace (+ stroke for swimming) | Running, Walking, Hiking (elevation on all three), Cycling, Swimming, Rowing |
| `sport` | duration + intensity (RPE) + notes | Soccer, Basketball, Tennis |
| `duration` | duration + notes | Yoga, Stretching, general |

- **Hiking** is included — `distanceCardio` with elevation.
- **Elevation gain is standard on Running, Walking, Hiking** (and Cycling), per user. Swimming/Rowing capture distance+duration without elevation; swimming adds `stroke`.

### Activity library

~30–40 activities, bundled in Flutter as a const list (offline, no backend catalog), grouped into **Cardio / Sport / Strength / Mind-body**. Each entry: `{ id (slug), name, category, logKind, tracksElevation, tracksStroke }`. Strava-comparable coverage.

## Boundary: v1 is manual logging, not live GPS

The app already has live GPS run recording + run PRs. To avoid duplicating that, **v1 of this feature is manual entry** — the user logs an activity after doing it (types distance/duration/sets/etc.). Live wrist/GPS capture is exactly what Phase 2 (watch) adds.

- The new logger's PRs are scoped to what is logged **in this feature**.
- Integration/reconciliation with the existing run-tracker `MetricsService` is explicitly **deferred** (avoid double-counting in v1).

## Backend (extend, don't duplicate)

The existing `WorkoutSession → ExerciseLog → ExerciseSet` already has `duration, gpsRoute, exercises, notes, perceivedExertion, startTime, endTime, location`. Extend `WorkoutSession` into the umbrella **ActivitySession**:

- **Add fields:** `activityType` (slug, e.g. `hiking`), `logKind` (discriminator), `distance` (km), `elevationGain` (m), `avgPace` (sec/km), `stroke` (swimming).
- **Population by logKind:** strength → `exercises[]`; distanceCardio → distance/duration/elevationGain/avgPace; sport → duration/perceivedExertion/notes; duration → duration/notes.
- **New `WorkoutController`** at `/api/workouts`, flat `{success, ...}` JSON, auth-scoped to the user:
  - `POST /sessions` — save a logged session; returns it with computed totals + id
  - `GET /sessions` — history, newest first
  - `GET /sessions/{id}` — detail
  - `GET /prs` — PRs: strength → heaviest weight + estimated 1RM (Epley `w × (1 + reps/30)`); distanceCardio → longest distance, best pace, most elevation (per activityType)
- **Persistence:** Firestore repo impl (`@Primary`) + in-memory fake (project pattern). Sessions under the user's scope.
- **Tests:** WebMvc controller tests (`authenticatedAs()`), service tests (PR computation, ExerciseLog totals). Keep the suite green.

## Flutter

- **Activity library** (`lib/workouts/activity_library.dart`): const categorized list (above). Pure data, no deps.
- **Models:** `ActivitySession`, `ExerciseLog`, `ExerciseSet`, `Activity` (library item) mirroring the flat backend JSON.
- **`WorkoutService`** (injectable, dio `ApiClient`, testable with a fake client — project pattern): `logSession`, `getHistory`, `getSessionDetail`, `getPRs`.
- **Logging flow:** pick activity (browse by category) → the form for its logKind:
  - strength → add exercises → per exercise add sets (reps × weight) with a **rest timer** between sets; running volume shown
  - distanceCardio → distance + duration + elevation (+ stroke for swimming); derived pace
  - sport → duration + intensity + notes
  - duration → duration + notes
  - Finish → `POST /sessions` → success summary.
- **Replace `SimpleWorkoutTracker`:** WorkoutHub "Log" tab becomes this flow; old Firestore-direct write removed (one way to log).
- **History view:** list past sessions (date, activity, key metric — volume or distance) → detail.
- **PRs view:** per-activity/per-exercise bests from `GET /prs`.
- **Tests:** model JSON round-trips, `WorkoutService` with fake client, picker / set-logging / cardio-form / history widgets, token-guarded widgets.

## Defaults (metric v1)

- Units: distance **km**, elevation **m**, weight **kg**. A kg/lb + mi preference is deferred.
- Est. 1RM = Epley. Rest timer = strength only.

## Design for isolation

- Activity library = pure const data.
- `WorkoutService` = thin API wrapper (mirrors `SocialService`/`MetricsApiClient`).
- PR computation lives backend-side (single source of truth); Flutter renders.
- Rest timer = self-contained widget, no backend.
- Per-logKind forms are separate widgets behind a common "save session" call.

## Phasing

**Phase 1 — phone-side activity logging (this spec):**
1. **Backend PR** — `WorkoutSession` extension + `WorkoutController` + repo impl/fake + PR logic + tests → *deploy checkpoint*.
2. **Flutter PR A** — activity library + models + `WorkoutService` + per-logKind logging forms + replace `SimpleWorkoutTracker` + rest timer + tests.
3. **Flutter PR B** — history view + PRs view + tests.

**Phase 2 — `feat/watch-companion` (SCOPED, DEFERRED — separate spec, after Phase 1 ships):**
A major platform addition, its own multi-PR effort, NOT bundled into Phase 1:
- Native **watchOS** app (Swift/SwiftUI — Flutter can't target watchOS)
- Native **Wear OS** app (Kotlin/Compose)
- Bridge layer (iOS App Groups / Wear DataLayer)
- **HealthKit / Health Connect** for background workout + HR capture
- Live GPS + HR + distance + elevation from the wrist → phone → backend sync

## Out of scope (v1)

- Live GPS/wrist capture (Phase 2), unit preferences (kg/lb, mi), backend exercise catalog/search, reconciliation with the existing run `MetricsService`, calorie estimation, social sharing of activities (existing share flow can be extended later).
