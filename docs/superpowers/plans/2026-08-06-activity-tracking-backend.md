# Activity Tracking — Backend Implementation Plan (Phase 1, Part 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose a backend API that persists multi-activity workout sessions (strength / distanceCardio / sport / duration) into the existing `WorkoutSession` model and computes per-activity personal records.

**Architecture:** Extend `WorkoutSession` with a small set of activity fields (`activityType`, `logKind`, `distance`, `elevationGain`, `avgPace`, `stroke`). Add a focused `ActivitySessionService` (log, history, detail, PRs) over the existing `WorkoutSessionRepository`, and a `WorkoutController` at `/api/workouts` returning flat `{success, ...}` JSON, auth-scoped via `FirebaseUserPrincipal`.

**Tech Stack:** Spring Boot 3.2 / Java 17, Firestore (`FirestoreRepository`), JUnit 5 + Mockito + `@WebMvcTest`.

## Global Constraints

- Java 17; Spring Boot 3.2.0; build/test via `./mvnw`.
- All endpoints under context-path `/api`; controller mapping `/workouts` → `/api/workouts`.
- Flat `{success: true, ...}` / `{success: false, message}` JSON bodies (match existing controllers).
- Auth via `@AuthenticationPrincipal FirebaseUserPrincipal`; uid from `principal.getFirebaseUid()`; unauthenticated → 401.
- Units: distance km, elevation m, weight kg (unit-agnostic `Double` storage).
- Keep the existing suite green (135 tests) — additions only.
- Do NOT modify the existing `WorkoutService` (workout *plans*); this feature adds a separate `ActivitySessionService`.

---

### Task 1: Extend `WorkoutSession` with activity fields

**Files:**
- Modify: `src/main/java/com/trego/model/WorkoutSession.java`
- Test: `src/test/java/com/trego/model/WorkoutSessionActivityTest.java`

**Interfaces:**
- Produces: `WorkoutSession` getters/setters `getActivityType/setActivityType` (String), `getLogKind/setLogKind` (String), `getDistance/setDistance` (Double), `getElevationGain/setElevationGain` (Double), `getAvgPace/setAvgPace` (Double), `getStroke/setStroke` (String); round-tripped by `toFirestoreMap()`/`fromFirestoreMap()`.

- [ ] **Step 1: Write the failing test**

```java
package com.trego.model;

import org.junit.jupiter.api.Test;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

class WorkoutSessionActivityTest {

    @Test
    void activityFieldsRoundTripThroughFirestoreMap() {
        WorkoutSession s = new WorkoutSession("uid-1", "cardio");
        s.setActivityType("hiking");
        s.setLogKind("distanceCardio");
        s.setDistance(12.5);
        s.setElevationGain(430.0);
        s.setAvgPace(360.0);
        s.setStroke(null);

        Map<String, Object> map = s.toFirestoreMap();
        assertEquals("hiking", map.get("activityType"));
        assertEquals("distanceCardio", map.get("logKind"));
        assertEquals(12.5, map.get("distance"));
        assertEquals(430.0, map.get("elevationGain"));
        assertEquals(360.0, map.get("avgPace"));

        WorkoutSession back = WorkoutSession.fromFirestoreMap(map);
        assertEquals("hiking", back.getActivityType());
        assertEquals("distanceCardio", back.getLogKind());
        assertEquals(12.5, back.getDistance());
        assertEquals(430.0, back.getElevationGain());
        assertEquals(360.0, back.getAvgPace());
    }

    @Test
    void swimmingKeepsStroke() {
        WorkoutSession s = new WorkoutSession("uid-1", "cardio");
        s.setActivityType("swimming");
        s.setLogKind("distanceCardio");
        s.setStroke("freestyle");
        WorkoutSession back = WorkoutSession.fromFirestoreMap(s.toFirestoreMap());
        assertEquals("freestyle", back.getStroke());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./mvnw test -Dtest=WorkoutSessionActivityTest`
Expected: FAIL — `setActivityType`/`getStroke` etc. do not exist (compile error).

- [ ] **Step 3: Add the fields, map entries, and accessors**

In `WorkoutSession.java`, add fields alongside the existing private fields:

```java
    private String activityType;
    private String logKind;
    private Double distance;
    private Double elevationGain;
    private Double avgPace;
    private String stroke;
```

In `toFirestoreMap()`, before `return map;`, add:

```java
        map.put("activityType", activityType);
        map.put("logKind", logKind);
        map.put("distance", distance);
        map.put("elevationGain", elevationGain);
        map.put("avgPace", avgPace);
        map.put("stroke", stroke);
```

In `fromFirestoreMap(...)`, before `return session;`, add:

```java
        session.setActivityType((String) data.get("activityType"));
        session.setLogKind((String) data.get("logKind"));
        if (data.get("distance") != null) session.setDistance(((Number) data.get("distance")).doubleValue());
        if (data.get("elevationGain") != null) session.setElevationGain(((Number) data.get("elevationGain")).doubleValue());
        if (data.get("avgPace") != null) session.setAvgPace(((Number) data.get("avgPace")).doubleValue());
        session.setStroke((String) data.get("stroke"));
```

Add getters/setters with the other accessors:

```java
    public String getActivityType() { return activityType; }
    public void setActivityType(String activityType) { this.activityType = activityType; }

    public String getLogKind() { return logKind; }
    public void setLogKind(String logKind) { this.logKind = logKind; }

    public Double getDistance() { return distance; }
    public void setDistance(Double distance) { this.distance = distance; }

    public Double getElevationGain() { return elevationGain; }
    public void setElevationGain(Double elevationGain) { this.elevationGain = elevationGain; }

    public Double getAvgPace() { return avgPace; }
    public void setAvgPace(Double avgPace) { this.avgPace = avgPace; }

    public String getStroke() { return stroke; }
    public void setStroke(String stroke) { this.stroke = stroke; }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./mvnw test -Dtest=WorkoutSessionActivityTest`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/trego/model/WorkoutSession.java src/test/java/com/trego/model/WorkoutSessionActivityTest.java
git commit -m "feat(activity): add activity fields to WorkoutSession model"
```

---

### Task 2: `ActivitySessionService` — log, history, detail

**Files:**
- Create: `src/main/java/com/trego/service/ActivitySessionService.java`
- Test: `src/test/java/com/trego/service/ActivitySessionServiceTest.java`

**Interfaces:**
- Consumes: `WorkoutSessionRepository` (`save(WorkoutSession)` inherited from `FirestoreRepository`, `findByUserId(String)`), `WorkoutSession` (Task 1).
- Produces:
  - `WorkoutSession logSession(String uid, Map<String,Object> payload)` — builds a `WorkoutSession` from the payload (`activityType`, `logKind`, `sessionName`, `duration`, `distance`, `elevationGain`, `stroke`, `notes`, `perceivedExertion`, `exercises[]`), sets `userId`, marks completed, persists, returns it.
  - `List<WorkoutSession> getHistory(String uid)` — user's sessions, newest first by `createdAt`.
  - `WorkoutSession getSession(String uid, String id)` — one session owned by uid, or null.

- [ ] **Step 1: Write the failing test**

```java
package com.trego.service;

import com.trego.model.WorkoutSession;
import com.trego.repository.WorkoutSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.*;
import java.util.concurrent.ExecutionException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ActivitySessionServiceTest {

    WorkoutSessionRepository repo;
    ActivitySessionService service;

    @BeforeEach
    void setUp() {
        repo = mock(WorkoutSessionRepository.class);
        service = new ActivitySessionService(repo);
    }

    @Test
    void logSessionPersistsWithUserAndFields() throws Exception {
        Map<String, Object> payload = new HashMap<>();
        payload.put("activityType", "hiking");
        payload.put("logKind", "distanceCardio");
        payload.put("sessionName", "Morning hike");
        payload.put("duration", 95);
        payload.put("distance", 12.5);
        payload.put("elevationGain", 430.0);

        WorkoutSession saved = service.logSession("uid-1", payload);

        assertEquals("uid-1", saved.getUserId());
        assertEquals("hiking", saved.getActivityType());
        assertEquals("distanceCardio", saved.getLogKind());
        assertEquals(12.5, saved.getDistance());
        assertTrue(saved.isCompleted());
        verify(repo).save(any(WorkoutSession.class));
    }

    @Test
    void getHistoryReturnsNewestFirst() throws Exception {
        WorkoutSession older = new WorkoutSession("uid-1", "cardio");
        older.setId("a");
        older.setCreatedAt(java.time.LocalDateTime.of(2026, 1, 1, 8, 0));
        WorkoutSession newer = new WorkoutSession("uid-1", "strength");
        newer.setId("b");
        newer.setCreatedAt(java.time.LocalDateTime.of(2026, 2, 1, 8, 0));
        when(repo.findByUserId("uid-1")).thenReturn(new ArrayList<>(List.of(older, newer)));

        List<WorkoutSession> out = service.getHistory("uid-1");
        assertEquals("b", out.get(0).getId());
        assertEquals("a", out.get(1).getId());
    }

    @Test
    void getSessionReturnsNullWhenNotOwned() throws Exception {
        WorkoutSession s = new WorkoutSession("other-uid", "cardio");
        s.setId("x");
        when(repo.findByUserId("uid-1")).thenReturn(new ArrayList<>());
        assertNull(service.getSession("uid-1", "x"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./mvnw test -Dtest=ActivitySessionServiceTest`
Expected: FAIL — `ActivitySessionService` does not exist.

- [ ] **Step 3: Implement the service**

```java
package com.trego.service;

import com.trego.model.ExerciseLog;
import com.trego.model.ExerciseSet;
import com.trego.model.WorkoutSession;
import com.trego.repository.WorkoutSessionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/** Persists and reads manually-logged multi-activity sessions. */
@Service
public class ActivitySessionService {

    private final WorkoutSessionRepository repo;

    @Autowired
    public ActivitySessionService(WorkoutSessionRepository repo) {
        this.repo = repo;
    }

    public WorkoutSession logSession(String uid, Map<String, Object> p) throws Exception {
        String logKind = str(p.get("logKind"));
        WorkoutSession s = new WorkoutSession(uid, categoryFor(logKind));
        s.setActivityType(str(p.get("activityType")));
        s.setLogKind(logKind);
        s.setSessionName(str(p.get("sessionName")));
        s.setNotes(str(p.get("notes")));
        s.setDuration(intOrNull(p.get("duration")));
        s.setDistance(dblOrNull(p.get("distance")));
        s.setElevationGain(dblOrNull(p.get("elevationGain")));
        s.setStroke(str(p.get("stroke")));
        s.setPerceivedExertion(intOrNull(p.get("perceivedExertion")));
        if (s.getDistance() != null && s.getDuration() != null && s.getDistance() > 0) {
            s.setAvgPace((s.getDuration() * 60.0) / s.getDistance()); // sec per km
        }
        s.setExercises(parseExercises(p.get("exercises")));
        s.setCompleted(true);
        s.setStatus("COMPLETED");
        repo.save(s);
        return s;
    }

    public List<WorkoutSession> getHistory(String uid) throws Exception {
        return repo.findByUserId(uid).stream()
                .sorted(Comparator.comparing(WorkoutSession::getCreatedAt,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .collect(Collectors.toList());
    }

    public WorkoutSession getSession(String uid, String id) throws Exception {
        return repo.findByUserId(uid).stream()
                .filter(s -> id.equals(s.getId()))
                .findFirst().orElse(null);
    }

    @SuppressWarnings("unchecked")
    private List<ExerciseLog> parseExercises(Object raw) {
        List<ExerciseLog> out = new ArrayList<>();
        if (!(raw instanceof List)) return out;
        for (Object eo : (List<Object>) raw) {
            if (!(eo instanceof Map)) continue;
            Map<String, Object> em = (Map<String, Object>) eo;
            ExerciseLog log = new ExerciseLog(str(em.get("exerciseId")), str(em.get("name")));
            List<ExerciseSet> sets = new ArrayList<>();
            Object rawSets = em.get("sets");
            if (rawSets instanceof List) {
                int n = 1;
                for (Object so : (List<Object>) rawSets) {
                    if (!(so instanceof Map)) continue;
                    Map<String, Object> sm = (Map<String, Object>) so;
                    ExerciseSet set = new ExerciseSet();
                    set.setSetNumber(intOrNull(sm.getOrDefault("setNumber", n)));
                    set.setReps(intOrNull(sm.get("reps")));
                    set.setWeight(dblOrNull(sm.get("weight")));
                    set.setRpe(intOrNull(sm.get("rpe")));
                    set.setRestTime(intOrNull(sm.get("restTime")));
                    sets.add(set);
                    n++;
                }
            }
            log.setSets(sets);
            out.add(log);
        }
        return out;
    }

    private static String categoryFor(String logKind) {
        return logKind != null ? logKind : "duration";
    }
    private static String str(Object o) { return o != null ? o.toString() : null; }
    private static Integer intOrNull(Object o) { return o instanceof Number ? ((Number) o).intValue() : null; }
    private static Double dblOrNull(Object o) { return o instanceof Number ? ((Number) o).doubleValue() : null; }
}
```

> API confirmed: `ExerciseLog.setSets(List<ExerciseSet>)`, the `ExerciseSet()` no-arg constructor, and `setSetNumber/setReps/setWeight/setRpe/setRestTime` all exist — the code above compiles against the current model.

- [ ] **Step 4: Run test to verify it passes**

Run: `./mvnw test -Dtest=ActivitySessionServiceTest`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/trego/service/ActivitySessionService.java src/test/java/com/trego/service/ActivitySessionServiceTest.java
git commit -m "feat(activity): ActivitySessionService log/history/detail"
```

---

### Task 3: Personal records in `ActivitySessionService`

**Files:**
- Modify: `src/main/java/com/trego/service/ActivitySessionService.java`
- Test: `src/test/java/com/trego/service/ActivitySessionPrsTest.java`

**Interfaces:**
- Produces: `List<Map<String,Object>> computePRs(String uid)` — one entry per `activityType` (or exercise for strength): `{activityType, bestDistance, bestPace, bestElevation}` for cardio; `{exerciseId, name, heaviestWeight, estimatedOneRepMax}` for strength (Epley `w*(1+reps/30)`).

- [ ] **Step 1: Write the failing test**

```java
package com.trego.service;

import com.trego.model.*;
import com.trego.repository.WorkoutSessionRepository;
import org.junit.jupiter.api.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ActivitySessionPrsTest {

    WorkoutSessionRepository repo;
    ActivitySessionService service;

    @BeforeEach void setUp() {
        repo = mock(WorkoutSessionRepository.class);
        service = new ActivitySessionService(repo);
    }

    @Test
    void cardioPrsPickBestDistanceAndElevation() throws Exception {
        WorkoutSession a = new WorkoutSession("u", "cardio");
        a.setActivityType("running"); a.setLogKind("distanceCardio");
        a.setDistance(5.0); a.setElevationGain(50.0); a.setAvgPace(300.0);
        WorkoutSession b = new WorkoutSession("u", "cardio");
        b.setActivityType("running"); b.setLogKind("distanceCardio");
        b.setDistance(10.0); b.setElevationGain(120.0); b.setAvgPace(330.0);
        when(repo.findByUserId("u")).thenReturn(new ArrayList<>(List.of(a, b)));

        Map<String, Object> pr = findByActivity(service.computePRs("u"), "running");
        assertEquals(10.0, pr.get("bestDistance"));
        assertEquals(120.0, pr.get("bestElevation"));
        assertEquals(300.0, pr.get("bestPace")); // lower = better
    }

    @Test
    void strengthPrsComputeHeaviestAndEpley() throws Exception {
        WorkoutSession s = new WorkoutSession("u", "strength");
        s.setActivityType("bench-press"); s.setLogKind("strength");
        ExerciseLog log = new ExerciseLog("bench-press", "Bench Press");
        ExerciseSet set1 = new ExerciseSet(); set1.setReps(5); set1.setWeight(80.0);
        ExerciseSet set2 = new ExerciseSet(); set2.setReps(10); set2.setWeight(70.0);
        log.setSets(new ArrayList<>(List.of(set1, set2)));
        s.setExercises(new ArrayList<>(List.of(log)));
        when(repo.findByUserId("u")).thenReturn(new ArrayList<>(List.of(s)));

        Map<String, Object> pr = findByExercise(service.computePRs("u"), "bench-press");
        assertEquals(80.0, pr.get("heaviestWeight"));
        // Epley best of: 80*(1+5/30)=93.33 vs 70*(1+10/30)=93.33 -> ~93.33
        assertEquals(93.33, (double) pr.get("estimatedOneRepMax"), 0.1);
    }

    private static Map<String,Object> findByActivity(List<Map<String,Object>> prs, String at) {
        return prs.stream().filter(m -> at.equals(m.get("activityType"))).findFirst().orElseThrow();
    }
    private static Map<String,Object> findByExercise(List<Map<String,Object>> prs, String id) {
        return prs.stream().filter(m -> id.equals(m.get("exerciseId"))).findFirst().orElseThrow();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./mvnw test -Dtest=ActivitySessionPrsTest`
Expected: FAIL — `computePRs` does not exist.

- [ ] **Step 3: Implement `computePRs`**

Add to `ActivitySessionService`:

```java
    public List<Map<String, Object>> computePRs(String uid) throws Exception {
        List<WorkoutSession> sessions = repo.findByUserId(uid);
        Map<String, Map<String, Object>> cardio = new LinkedHashMap<>();
        Map<String, Map<String, Object>> strength = new LinkedHashMap<>();

        for (WorkoutSession s : sessions) {
            if ("strength".equals(s.getLogKind()) && s.getExercises() != null) {
                for (ExerciseLog log : s.getExercises()) {
                    if (log.getSets() == null) continue;
                    for (ExerciseSet set : log.getSets()) {
                        if (set.getWeight() == null || set.getReps() == null) continue;
                        Map<String, Object> pr = strength.computeIfAbsent(log.getExerciseId(), k -> {
                            Map<String, Object> m = new LinkedHashMap<>();
                            m.put("exerciseId", log.getExerciseId());
                            m.put("name", log.getName());
                            m.put("heaviestWeight", 0.0);
                            m.put("estimatedOneRepMax", 0.0);
                            return m;
                        });
                        double w = set.getWeight();
                        double epley = round2(w * (1 + set.getReps() / 30.0));
                        if (w > (double) pr.get("heaviestWeight")) pr.put("heaviestWeight", w);
                        if (epley > (double) pr.get("estimatedOneRepMax")) pr.put("estimatedOneRepMax", epley);
                    }
                }
            } else if ("distanceCardio".equals(s.getLogKind()) && s.getActivityType() != null) {
                Map<String, Object> pr = cardio.computeIfAbsent(s.getActivityType(), k -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("activityType", s.getActivityType());
                    m.put("bestDistance", 0.0);
                    m.put("bestElevation", 0.0);
                    m.put("bestPace", null);
                    return m;
                });
                if (s.getDistance() != null && s.getDistance() > (double) pr.get("bestDistance"))
                    pr.put("bestDistance", s.getDistance());
                if (s.getElevationGain() != null && s.getElevationGain() > (double) pr.get("bestElevation"))
                    pr.put("bestElevation", s.getElevationGain());
                if (s.getAvgPace() != null && (pr.get("bestPace") == null || s.getAvgPace() < (double) pr.get("bestPace")))
                    pr.put("bestPace", s.getAvgPace());
            }
        }
        List<Map<String, Object>> out = new ArrayList<>(cardio.values());
        out.addAll(strength.values());
        return out;
    }

    private static double round2(double v) { return Math.round(v * 100.0) / 100.0; }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./mvnw test -Dtest=ActivitySessionPrsTest`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/trego/service/ActivitySessionService.java src/test/java/com/trego/service/ActivitySessionPrsTest.java
git commit -m "feat(activity): per-activity PRs (heaviest, Epley 1RM, distance, pace, elevation)"
```

---

### Task 4: `WorkoutController` endpoints

**Files:**
- Create: `src/main/java/com/trego/controller/WorkoutController.java`
- Test: `src/test/java/com/trego/controller/WorkoutControllerTest.java`

**Interfaces:**
- Consumes: `ActivitySessionService` (Task 2/3).
- Produces REST: `POST /workouts/sessions`, `GET /workouts/sessions`, `GET /workouts/sessions/{id}`, `GET /workouts/prs`. Bodies: `{success:true, session|sessions|prs: ...}` or `{success:false, message}`; 401 when unauthenticated.

- [ ] **Step 1: Write the failing test** (harness copied from `PushControllerTest`)

```java
package com.trego.controller;

import com.trego.config.SecurityConfig;
import com.trego.model.User;
import com.trego.model.WorkoutSession;
import com.trego.security.FirebaseAuthenticationFilter;
import com.trego.security.FirebaseUserPrincipal;
import com.trego.security.JwtAuthenticationEntryPoint;
import com.trego.service.ActivitySessionService;
import jakarta.servlet.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.*;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(WorkoutController.class)
@Import(SecurityConfig.class)
@TestPropertySource(properties = "cors.allowed-origins=http://localhost:3000")
class WorkoutControllerTest {

    @Autowired MockMvc mvc;
    @MockBean ActivitySessionService service;
    @MockBean FirebaseAuthenticationFilter firebaseAuthenticationFilter;
    @MockBean JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    private static RequestPostProcessor authenticatedAs(String uid) {
        User user = new User();
        user.setId(uid);
        user.setEmail(uid + "@test.example");
        user.setActive(true);
        user.setEmailVerified(true);
        user.setRoles(Collections.singletonList("USER"));
        FirebaseUserPrincipal principal = new FirebaseUserPrincipal(user, uid);
        return SecurityMockMvcRequestPostProcessors.authentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }

    @BeforeEach
    void setUp() throws Exception {
        doAnswer(inv -> { ((FilterChain) inv.getArgument(2))
                .doFilter(inv.getArgument(0), inv.getArgument(1)); return null; })
            .when(firebaseAuthenticationFilter)
            .doFilter(any(ServletRequest.class), any(ServletResponse.class), any(FilterChain.class));
    }

    @Test
    void postSessionRequiresAuth() throws Exception {
        mvc.perform(post("/workouts/sessions").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
           .andExpect(status().isUnauthorized());
    }

    @Test
    void postSessionSavesAndReturnsIt() throws Exception {
        WorkoutSession saved = new WorkoutSession("u", "cardio");
        saved.setId("s1"); saved.setActivityType("hiking");
        when(service.logSession(eq("u"), any())).thenReturn(saved);

        mvc.perform(post("/workouts/sessions").with(csrf()).with(authenticatedAs("u"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"activityType\":\"hiking\",\"logKind\":\"distanceCardio\",\"distance\":12.5}"))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.success").value(true))
           .andExpect(jsonPath("$.session.activityType").value("hiking"));
        verify(service).logSession(eq("u"), any());
    }

    @Test
    void getHistoryReturnsSessions() throws Exception {
        WorkoutSession s = new WorkoutSession("u", "strength"); s.setId("s1");
        when(service.getHistory("u")).thenReturn(List.of(s));
        mvc.perform(get("/workouts/sessions").with(authenticatedAs("u")))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.success").value(true))
           .andExpect(jsonPath("$.sessions[0].id").value("s1"));
    }

    @Test
    void getPrsReturnsList() throws Exception {
        Map<String,Object> pr = new LinkedHashMap<>();
        pr.put("activityType", "running"); pr.put("bestDistance", 10.0);
        when(service.computePRs("u")).thenReturn(List.of(pr));
        mvc.perform(get("/workouts/prs").with(authenticatedAs("u")))
           .andExpect(status().isOk())
           .andExpect(jsonPath("$.prs[0].activityType").value("running"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./mvnw test -Dtest=WorkoutControllerTest`
Expected: FAIL — `WorkoutController` does not exist.

- [ ] **Step 3: Implement the controller**

```java
package com.trego.controller;

import com.trego.model.WorkoutSession;
import com.trego.security.FirebaseUserPrincipal;
import com.trego.service.ActivitySessionService;
import org.slf4j.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/** Manually-logged multi-activity sessions at {@code /workouts} (→ {@code /api/workouts}). */
@RestController
@RequestMapping("/workouts")
public class WorkoutController {

    private static final Logger logger = LoggerFactory.getLogger(WorkoutController.class);

    @Autowired private ActivitySessionService service;

    @PostMapping("/sessions")
    public ResponseEntity<Map<String, Object>> log(
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal FirebaseUserPrincipal principal) {
        if (unauth(principal)) return status(HttpStatus.UNAUTHORIZED, "Authentication required");
        try {
            WorkoutSession s = service.logSession(principal.getFirebaseUid(), body);
            Map<String, Object> m = ok();
            m.put("session", s.toFirestoreMap());
            return ResponseEntity.ok(m);
        } catch (Exception e) {
            logger.error("Log session failed: {}", e.getMessage());
            return status(HttpStatus.BAD_REQUEST, "Failed to log session");
        }
    }

    @GetMapping("/sessions")
    public ResponseEntity<Map<String, Object>> history(
            @AuthenticationPrincipal FirebaseUserPrincipal principal) {
        if (unauth(principal)) return status(HttpStatus.UNAUTHORIZED, "Authentication required");
        try {
            List<Map<String, Object>> out = new ArrayList<>();
            for (WorkoutSession s : service.getHistory(principal.getFirebaseUid())) out.add(s.toFirestoreMap());
            Map<String, Object> m = ok(); m.put("sessions", out);
            return ResponseEntity.ok(m);
        } catch (Exception e) {
            logger.error("History failed: {}", e.getMessage());
            return status(HttpStatus.BAD_REQUEST, "Failed to load history");
        }
    }

    @GetMapping("/sessions/{id}")
    public ResponseEntity<Map<String, Object>> detail(
            @PathVariable String id,
            @AuthenticationPrincipal FirebaseUserPrincipal principal) {
        if (unauth(principal)) return status(HttpStatus.UNAUTHORIZED, "Authentication required");
        try {
            WorkoutSession s = service.getSession(principal.getFirebaseUid(), id);
            if (s == null) return status(HttpStatus.NOT_FOUND, "Session not found");
            Map<String, Object> m = ok(); m.put("session", s.toFirestoreMap());
            return ResponseEntity.ok(m);
        } catch (Exception e) {
            logger.error("Detail failed: {}", e.getMessage());
            return status(HttpStatus.BAD_REQUEST, "Failed to load session");
        }
    }

    @GetMapping("/prs")
    public ResponseEntity<Map<String, Object>> prs(
            @AuthenticationPrincipal FirebaseUserPrincipal principal) {
        if (unauth(principal)) return status(HttpStatus.UNAUTHORIZED, "Authentication required");
        try {
            Map<String, Object> m = ok(); m.put("prs", service.computePRs(principal.getFirebaseUid()));
            return ResponseEntity.ok(m);
        } catch (Exception e) {
            logger.error("PRs failed: {}", e.getMessage());
            return status(HttpStatus.BAD_REQUEST, "Failed to compute PRs");
        }
    }

    private static boolean unauth(FirebaseUserPrincipal p) { return p == null || p.getUser() == null; }
    private static Map<String, Object> ok() { Map<String, Object> m = new LinkedHashMap<>(); m.put("success", true); return m; }
    private static ResponseEntity<Map<String, Object>> status(HttpStatus st, String msg) {
        Map<String, Object> m = new LinkedHashMap<>(); m.put("success", false); m.put("message", msg);
        return ResponseEntity.status(st).body(m);
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./mvnw test -Dtest=WorkoutControllerTest`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add src/main/java/com/trego/controller/WorkoutController.java src/test/java/com/trego/controller/WorkoutControllerTest.java
git commit -m "feat(activity): WorkoutController (log/history/detail/prs)"
```

---

### Task 5: Full-suite green + boot smoke + PR

**Files:** none (verification)

- [ ] **Step 1: Run the whole suite**

Run: `./mvnw test`
Expected: `BUILD SUCCESS`, previous count + ~11 new tests, 0 failures.

- [ ] **Step 2: Boot smoke (Firebase creds present)**

Run: `./mvnw spring-boot:run` (background), then `curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/actuator/health` → `200`; `curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/workouts/sessions` → `401`. Stop the server.

- [ ] **Step 3: Push branch + open PR**

```bash
git push -u origin feat/activity-tracking-backend
gh pr create --base main --head feat/activity-tracking-backend \
  --title "feat(activity): activity-tracking backend (sessions + PRs)" \
  --body "Extends WorkoutSession with activity fields; adds ActivitySessionService + WorkoutController (/api/workouts sessions + prs). Tests green. Implements docs/superpowers/specs/2026-08-06-activity-tracking-design.md (Phase 1, backend)."
```

- [ ] **Step 4: Squash-merge after review, delete branch, verify `main` green (deploy checkpoint)**

Merge, then `git checkout main && git fetch origin --prune && git reset --hard origin/main`. **STOP for user to deploy the backend to Render** before starting the Flutter parts.

---

## Phase 1, Parts 2 & 3 — Flutter (outline; own plan after backend deploys)

Expanded into `docs/superpowers/plans/2026-08-06-activity-tracking-flutter.md` once the backend is live on Render (so the Flutter service can be smoke-tested against real endpoints). Task outline:

**Part 2 — logging + replace SimpleWorkoutTracker (`feat/activity-logging`):**
- `lib/workouts/activity_library.dart` — const `Activity {id, name, category, logKind, tracksElevation, tracksStroke}` list (~30–40; Cardio/Sport/Strength/Mind-body; incl. running/walking/hiking with elevation, cycling, swimming+stroke, rowing, soccer, basketball, tennis, yoga, weight-training).
- `lib/workouts/models/` — `ActivitySession`, `ExerciseLog`, `ExerciseSet` Dart models (flat JSON mirrors) + round-trip tests.
- `lib/workouts/workout_service.dart` — injectable `WorkoutService(apiClient)` with `logSession/getHistory/getSessionDetail/getPRs`; tests with a fake `ApiClient` (mirror `push_api_test.dart`).
- Logging UI: activity picker (by category) → per-logKind form (strength sets w/ rest timer; distanceCardio distance+duration+elevation(+stroke); sport duration+RPE+notes; duration+notes) → save → summary.
- Replace `SimpleWorkoutTracker` in `workout_hub.dart:54`; remove the Firestore-direct file; widget tests; token-guard (`scripts/check-tokens.sh`).

**Part 3 — history + PRs (`feat/activity-history-prs`):**
- `WorkoutHistoryScreen` (list from `getHistory`, tap → detail) + `PRsScreen` (from `getPRs`); wire into WorkoutHub; widget tests.

## Phase 2 — Watch companion (`feat/watch-companion`) — DEFERRED, separate spec

Not part of this plan. watchOS (Swift/SwiftUI) + Wear OS (Kotlin/Compose) + bridge (App Groups / DataLayer) + HealthKit / Health Connect + live GPS/HR/elevation → phone → backend sync. Authored as its own spec after Phase 1 ships.
