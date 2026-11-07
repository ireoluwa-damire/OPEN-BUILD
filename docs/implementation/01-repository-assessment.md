# 01 — Repository assessment (discovery phase)

Repository: `OPEN-BUILD/` (local folder on the owner's Windows machine)
Assessed: 31 October 2026, 08:30–09:00 WAT
Scope: discovery only. **No application code was changed while preparing this document.**

## How to read this document

Every finding carries a tag:

- **[V] Verified.** I read the relevant source or data and the behaviour is visible in the code.
- **[R] Recorded.** Taken from logs or reports already in the repository. I did not re-run them.
- **[I] Inferred.** A reasoned conclusion from reading code. I did not execute it, so it needs confirming before anyone acts on it.

Two limits apply to the whole assessment:

1. **No build or test was run.** Flutter is installed only as a Windows SDK in `.tooling/flutter`. The Linux environments I can reach cannot download a Flutter or Dart SDK (Google's storage host is blocked), so test status comes from the logs in `.tooling/`.
2. **Several files changed this morning and have never been compiled.** These are the path-node animations, the lesson-complete screen, the code-drawn Sumi mascot, and the sound assets (see §8). Treat them as unverified until `flutter analyze` and the test suite have run.

---

## 1. Summary

Sumi is an **offline-first Flutter mobile app**, targeting Android first, for learning practical disciplines through a Duolingo-style loop: path, short challenges, feedback, rewards. Two disciplines ship as authored content: **Music** and **Fashion Design & Tailoring**. Optional AI coaching runs **on the device** through llama.cpp (`llamadart`) using downloaded Qwen GGUF models. There is no account, no server dependency, and no cloud sync.

The architecture is sound and recent. In the last 48 hours it was refactored into controller-plus-immutable-state modules:

- **Path:** `LearningPathController`
- **Lessons:** `LearningSessionController`
- **Results:** `SessionResult`

All persistence goes through one serialized, transactional `LocalStore`, and learner data is versioned with migration from v2 to v3.

The main weaknesses are:

- **Content breadth.** Every lesson in a discipline replays the same fixed challenge sequence; only the first concept question changes.
- **Arbitrary disciplines don't work.** The "Something else" path is wired into the UI but is broken.
- **Unbuilt engagement features.** Several are present in the data model only: quests, sparks, sound playback, reminders.
- **Repository hygiene.** The folder is not a git repository, and it contains third-party Duolingo files (APKs and animation exports) that must not be published.

---

## 2. Repository layout [V]

| Path | What it is | Status |
|---|---|---|
| `app/` | Flutter application (package `sumi`, v0.2.0+2) | Active product |
| `app/lib/` | 46 Dart files, about 15.4k lines including tests | Active |
| `app/test/` | 11 unit and widget test files, about 63 test cases | Active |
| `app/integration_test/`, `app/test_driver/` | On-device inference smoke test and phone suite | Active (phone only) |
| `app/assets/` | `disciplines.json` (content), `model_catalog.json` (GGUF catalogue), `catalog.json` (legacy v0.1), `sounds/` (new today) | Mixed (see §6) |
| `app/android`, `app/ios`, `app/web` | Platform shells; web is a phone-sized preview only | Android validated; iOS never built |
| `backend/` | FastAPI v0.1 planner and Ollama personalisation | **Historical. Not called by the app** (README) |
| `scripts/` | PowerShell build and test wrappers; Python generators for disciplines, model catalogue, icons, sounds | Active tooling |
| `research/` | Teardowns, specs, agent blueprints, captures, mascot and animation references, **Duolingo APKs** | Reference only; legal risk (§7) |
| `preview/`, `dist/` | Screenshots, recordings, built APK | Generated |
| `.tooling/` | Windows Flutter SDK, Android runtime parts, build and test logs | Local only (git-ignored) |
| `tools/` | `jadx-headless-mcp` decompiler jar, session integration script | Research tooling |
| `docs/` | Did not exist before this document | New |

There is **no `.git` directory**: `git status` fails ("not a git repository") [V]. A root `.gitignore` exists but has never been used.

---

## 3. Technology and dependencies [V]

| Area | Choice | Source |
|---|---|---|
| Language and framework | Dart ≥3.10.7, Flutter (workspace SDK 3.47.8 / Dart 3.13.7 per README) | `app/pubspec.yaml`, README |
| UI | Material 3 with a custom `ThemeData` (`sumiTheme()`), font `Arial` | `lib/theme.dart` |
| Persistence | `shared_preferences` (`SharedPreferencesAsync`), JSON blobs per discipline | `lib/services.dart` |
| External links | `url_launcher` (opens in an external app) | `lib/main.dart` |
| On-device AI | `llamadart` 0.16.5 pinned, CPU backend, 2,048-token context | `lib/phone_runtime.dart`, `pubspec.yaml` hooks |
| Model files | `path_provider`, `crypto` (SHA-256 check), `file_selector` (GGUF import) | `lib/on_device_native.dart` |
| Lints | `flutter_lints` ^6 with `prefer_const_constructors: false` | `analysis_options.yaml` |
| State management | Built-in `ChangeNotifier` plus `ListenableBuilder`. **No Provider, Riverpod or Bloc** | All controllers |
| Routing | Imperative `Navigator.push(MaterialPageRoute)`. **No named routes, no go_router** | `main.dart`, screens |
| Audio, notifications, Rive or Lottie | **None installed** | `pubspec.yaml` |
| Android | `applicationId com.example.sumi`, NDK 29, ABIs arm64-v8a and x86_64, `allowBackup=false`, INTERNET permission only | `android/app/*` |

---

## 4. Current architecture

### 4.1 Entry and shell [V]

- `main()` → `SumiApp` → `MaterialApp`. A `builder` frames the app as a single column at most 600 px wide (phone-shaped on larger screens).
- `LearningHome` (stateful) is the **composition root**. It owns:
  - `LocalStore`, `LearningService`, `ResourceRepository`, `ResourceRanker`, `PhoneModelController`;
  - the active `Catalog` and the `LearningState` for the active discipline;
  - the tab index;
  - the navigation callbacks: `openMilestone`, `openResourceDetail`, `openTutorChat`, `toggleSaveResource`, `persist`.
- Boot sequence: load `disciplines.json` → read the active track → load that track's `LearningState`. It shows a progress view or a retryable error, then either `OnboardingFlow` (if not completed) or the four-tab shell.
- The tab shell is an `IndexedStack` (state is kept per tab) with a Material `NavigationBar`: **Learn, Practice, Library, Profile**. Settings opens from Profile.

### 4.2 Module map [V]

| Module | Key files | Responsibility |
|---|---|---|
| **Domain model** | `lib/models.dart` (1,112 lines) | `Catalog`, `Milestone` (path node), `Question`, `Resource`, `GoalModel`, `OnboardingState`, `EngagementState` (points, streak, idempotent rewards), `LearningState` (the whole learner profile, JSON v3, `fromV2` migration, evidence-state derivation) |
| **Persistence** | `lib/services.dart` | `LocalStore`: per-track keys `sumi.learning.v3.<track>`, a serialized write queue, and `transaction()` (clone → mutate → write → apply), so a failed write never mutates live state. `LearningService` holds helper operations, some of them unused (§6.4) |
| **Onboarding** | `main.dart` `OnboardingFlow` | 10 persisted steps: promise → discipline → outcome → motivation → level → outcome preview → daily minutes → starting route → baseline → done. Writes `GoalModel` |
| **Baseline assessment** | `lib/assessment.dart` | Six authored multiple-choice questions per track, with hints, skips, timing and resume |
| **Learning path** | `lib/learning_path/{learning_path_controller,learning_path_state,path_screen}.dart` | Unit grouping (3 nodes per unit), a node presentation state machine (`PathNodePresentationState`), one-shot path events (`unlock`, `completeNode`, `completeCheckpoint`) claimed from persisted `pathEvents`, a card anchored to the tapped node, section overview, scroll restore |
| **Unit guide** | `lib/unit_guide_screen.dart` | Full-screen guide (Watch, Key ideas, Reference, Try) |
| **Lesson session** | `lib/learning_session/*` | `LearningSessionController` (durable state, commit through store transaction, focus buffer, lifecycle restore, atomic completion), `ChallengeDefinition` plus `challengesFor()` (content and grading), `ChallengeRendererRegistry` (8 renderers), `LessonShell` (top bar, settings sheet, explanation), `FeedbackPanel` |
| **Session result** | `lib/session_result/*` | `SessionResult` model, `assembleSessionResult()` (rebuilt from saved attempts), `SessionResultScreen` (celebration) |
| **Resources** | `lib/resource_system.dart`, `lib/resource_detail_screen.dart`, `LibraryTab` | Repository over the local catalogue, deterministic ranker (capability, level, cost, bandwidth), detail sheet before leaving the app, resource-use events |
| **Adaptation** | `lib/adaptation_system.dart`, `lib/adaptation_screen.dart` | Event-based `LearnerAdaptationProfile` (observed preferences, editable, no fixed "learner type" labels), `AdaptationEngine.processEvents`, `SessionAssembler` |
| **AI tutor** | `lib/tutor_system.dart`, `lib/tutor_chat_screen.dart` | `TutorOrchestrator` with routing modes, context envelope, output validator, deterministic authored fallback. Local model through `PhoneModelController.reply` |
| **On-device models** | `lib/on_device*.dart`, `phone_runtime.dart`, `phone_models_screen.dart`, `phone_model_types.dart` | Conditional import (stub on web). Download with resume and SHA-256 check against the pinned catalogue, select, remove, import GGUF. Inference loads per reply and unloads after, with a 3-minute timeout and cancel when the app backgrounds |
| **Mascot and motion** (new today, uncompiled) | `lib/mascot/{sumi_rig,sumi_mascot}.dart`, `lib/motion/celebration.dart` | Code-drawn chameleon (36 animations, Duo-slot metadata, skins), confetti, burst, rays |
| **Theme and shared widgets** | `lib/theme.dart`, `lib/widgets.dart` | `SumiColors` tokens, `ActionButton` (raised 3D button), `Surface`, `Tag`, `SectionTitle` |
| **Shims** | `challenge_screen.dart`, `learning_session.dart`, `path_widgets.dart`, `mascot.dart` | 1–11 line re-exports or compatibility aliases (for example `ChallengeScreen` → `LessonShell`) |

### 4.3 Dependency relationships [V]

```
main.dart (LearningHome)
 ├─ services.dart (LocalStore, LearningService) ─ models.dart, adaptation_system.dart, on_device.dart
 ├─ learning_path/path_screen.dart ─ learning_path_controller ─ learning_path_state ─ models, services
 │                                 └─ unit_guide_screen, motion/celebration
 ├─ challenge_screen.dart → learning_session/lesson_shell.dart
 │     ├─ learning_session_controller ─ challenge_definition, learning_session_state,
 │     │                                session_result_assembler, adaptation_system, services
 │     ├─ challenge_renderer_registry, feedback_panel (→ mascot)
 │     └─ session_result_screen (→ mascot, motion)
 ├─ resource_system.dart, resource_detail_screen.dart
 ├─ tutor_chat_screen.dart ─ tutor_system.dart ─ on_device.dart (PhoneModelController)
 ├─ assessment.dart, adaptation_screen.dart, phone_models_screen.dart
 └─ mascot/sumi_mascot.dart (Settings gallery)
```

Key couplings:

- **`LearningState` is a single mutable aggregate** passed by reference to almost every screen. `LocalStore.transaction` copies a snapshot back into it, so screens must rebuild after commits. Today that happens through `setState` in `LearningHome` and `ListenableBuilder` in the controllers.
- **Completion is atomic** inside `LearningSessionController.advance()`. A single transaction records completion, demonstrated evidence, the idempotent reward (20 points and 5 sparks, keyed per goal and node), the streak, the adaptation event, the session result, and the path events. The path controller then plays the path events.
- **Discipline specifics leak into code.** `challengesFor()` branches on `catalog.id == 'music' / 'fashion'`, and `assembleSessionResult()` hard-codes discipline evidence categories.

### 4.4 Data and content [V]

- `disciplines.json`, produced by `scripts/build_disciplines.py`, defines two tracks. Each has:
  - 6 skills (path nodes) with an optional `lesson` (prompt, options, correct, explanation);
  - 6 baseline questions and 6 day-2 recall questions;
  - 8 reviewed resources (6 articles, 2 videos each), carrying provenance and licence notes;
  - a 2-day calibration description.
- Skills have **no `type` field**, so the node type is guessed from the ID (`create`, `brief`, `seam` → project step). No checkpoint, review or reward nodes exist in the data, so the checkpoint and trophy animation paths are never reached with real content [V].
- `model_catalog.json` pins three GGUF models (Qwen3 0.6B and 1.7B Q8_0, a DeepSeek-R1-Distill 1.5B community conversion) with revisions, SHA-256 hashes and sizes [V].

---

## 5. Existing functionality

| Feature | State | Notes |
|---|---|---|
| Onboarding (10 steps, persisted per step, resumable) | **Working** [V] | Matches the observed Duolingo onboarding order |
| Baseline (6 questions, hint, skip, timing) | **Working** [V][R] | |
| Learning path with units, anchored node card, guide, section overview, scroll restore, node animations | **Working**, animations new [V] | Last recorded run: the guide test failed (§5.1) |
| Lesson shell: Check then Continue, correct, incorrect, near-correct and retry, explain-my-mistake, settings sheet, exit confirm, background restore | **Working** [V][R] | Strong contract test coverage |
| 8 challenge renderers (select, sequence, match, typed reflection, media observation, music tap or imitate, fashion procedure, drawing) | **Working** [V] | Content is fixed per discipline (§6.1) |
| Atomic completion: points, streak, evidence, path events, idempotency | **Working** [V][R] | `session_contract_test.dart` |
| Lesson-complete screen | **Working**, redesigned today [V] | Uncompiled |
| Practice tab (recall due, hinted, needs-practice lists that open lessons) | **Partial** [V] | No scheduler; recall is the fixed day-2 set |
| Library (ranked reviewed resources, filters, detail sheet, save, events) | **Working** [V] | |
| Profile (streak, points, evidence states per milestone, adaptation view) | **Working** [V] | |
| Settings (minutes, reminders toggle, reduced motion, sound toggle, mascot gallery, offline models, cloud relay, privacy, reset) | **Partial** [V] | Reminders and sound are stored settings with no effect (§6.3) |
| Offline model manager (download, resume, verify, select, remove, import) | **Working** [R] | Phone inference smoke test recorded in README and VALIDATION |
| Tutor chat (local model, authored fallback, consent gate) | **Partial** [V] | Cloud provider is a canned stub (§6.3) |
| Adaptive profile (observed preferences, editable) | **Partial** [V] | Profile updates, but nothing uses it to choose lesson content |
| Arbitrary discipline ("Something else") | **Broken** [I] | §6.2 |
| Mascot and sounds | **New today** [V] | Sounds are not wired; there is no audio package |

### 5.1 Test status [R]

- **Last full recorded run** (`.tooling/session-final-tests.log`, 30 Oct 09:26): **65 passed, 3 failed**.
  - `correction_spec_test`: "guide and sections navigate…" could not find the text `Key ideas`. `unit_guide_screen.dart` now contains `Text('Key ideas')`, so this may be stale.
  - `session_recording_test` (music and fashion): "a painting debug variable was changed by the test". This is a test-harness hygiene bug, not a product bug.
- **Last analyzer run** (`session-analyze.log`, 30 Oct 09:21): no issues.
- **Since then:**
  - `path_screen.dart`, `learning_path_controller.dart`, `session_result_screen.dart`, `feedback_panel.dart` and `main.dart` were modified;
  - `mascot/`, `motion/` and the sound assets were added;
  - **none of this has been analysed or tested.**

---

## 6. Gaps found in the existing implementation

### 6.1 Lesson content is the same for every node [V] — high impact

In `challengesFor(catalog, node)`, only the first `singleSelect` comes from the node's `lesson`. Every Music node then appends the same sequence: "Build one bar of 4/4", the same match pairs, the same tap rhythm, then generic media observation and typed reflection. Fashion works the same way. A learner who completes node 2 replays node 1's practice. Neither the content nor the session length adapts to the node, the adaptation profile, or earlier mistakes.

### 6.2 "Something else" (arbitrary discipline) is broken [I] — high impact

- Onboarding offers `selectedDisciplineId = 'custom'` (`main.dart` around line 734).
- At the last step it sets `learning.trackId = 'custom'` and saves, but the active `Catalog` stays the previously loaded track.
- `LocalStore.save` writes to `sumi.learning.v3.custom`, while `activeTrack` still points at the old track.
- **Likely result:** the next launch reloads the old track's half-finished onboarding, and the current session runs Music or Fashion content under a profile labelled `custom`.
- `Catalog.custom()` exists in `models.dart`, but it is called only from tests.
- The arbitrary-discipline plan contract (blueprint §12) is not implemented.

### 6.3 Settings and features that are stored but do nothing [V]

- **Sound effects toggle:** saved, but there is no audio package and the WAVs in `assets/sounds/` are **not listed in `pubspec.yaml` assets**.
- **Practice reminders toggle:** saved, but there is no notifications package. The subtitle text is honest ("no active schedule").
- **Cloud AI relay:** `SumiCloudTutorProvider.queryCloud` returns a fixed string and calls no backend. If it is shown to users as "Cloud AI", that misrepresents the product. It should stay hidden or be labelled as not available.
- **Quests and sparks:** `completedQuestIds` and `sparksBalance` exist in the model. There is no quest UI or logic, and nothing spends sparks.

### 6.4 Code that nothing calls [V]

These are referenced only by their own definitions, or only by tests:

- `PracticeScreen` (`practice.dart`) and `TwoDayReview` (`two_day_review.dart`). Neither is reachable from the UI.
- `LearningService.completeActivity`, `getNextLearningSession`, `qualifyDailyGoal`, `recordAdaptationEvent`.
- `CustomPlanValidator`, `DefaultRemoteResourceConnector`.
- `Catalog.custom`.

Some of these are worth reusing (§9); the rest can be retired once that's confirmed.

### 6.5 Path data lacks node types [V]

There are no `type` fields in `disciplines.json`, so there are no checkpoints, reviews, rewards or chests. Units are formed mechanically, 3 nodes per unit, with a unit's title taken from its first node.

### 6.6 Review scheduling is absent [V]

There is no due-date model. `recallDone()` checks whether the fixed day-2 question set has been attempted. Blueprint §12.4 schedules (+1, +2, +5 and +10 days) are not implemented.

### 6.7 Points model is simpler than specified [V]

Points are a flat 20 per newly completed node. The blueprint's per-challenge, first-try, review and project values are not implemented. Streak qualification is correct for the "lesson completed" rule.

---

## 7. Technical constraints and risks

| # | Constraint or risk | Type | Detail |
|---|---|---|---|
| 1 | **No version control** | Process [V] | There is no repository, history or rollback, and the challenge brief requires a public GitHub repository. Initialise git before any further implementation |
| 2 | **Third-party Duolingo material** | Legal [V] | Not covered by the root `.gitignore`:<br>• `research/rea-duolingo-android-2026-10-29/duolingo-6.103.6-*.apk` (decompiled APKs)<br>• `tools/jadx-headless-mcp`<br>• screenshots and recordings<br>`research/animation-reference/.gitignore` covers its own media, but the APKs are not excluded. Publishing them would distribute copyrighted binaries. The decompilation itself may breach Duolingo's terms |
| 3 | **Uncompiled changes from today** | Build [V] | Mascot, motion, result screen, path animations, feedback panel, `main.dart` (§5.1). Run `.\scripts\flutter.ps1 analyze` and `.\scripts\test-ui.ps1` before anything else |
| 4 | **Toolchain only on Windows** | Environment [V] | Flutter is a local Windows SDK. CI or other machines need Flutter ≥3.47 / Dart ≥3.10.7, NDK 29.0.14206865 and CMake 3.31.6 |
| 5 | **Native AI runtime** | Platform [V][R] | `llamadart` requires 64-bit Android. iOS needs macOS and Xcode and has never been validated. The web build has no inference (stub). The debug APK is about 141–155 MB |
| 6 | **Tests rely on `pumpAndSettle`** | Testing [V] | Any infinite animation, such as an idle mascot loop or a breathing ring, will hang tests. The mascot and motion code is one-shot by design; keep it that way, or gate loops behind a test-safe flag |
| 7 | **SharedPreferences JSON blob** | Data [V] | The whole profile is rewritten on every commit. Sessions, attempts and events grow without bound (`sessions` map, `resourceEvents`, `adaptationEvents`). Fine for a demo; it will slow down and risk size limits with long use |
| 8 | **Single mutable aggregate** | Architecture [V] | `LearningState` is shared by reference, and controllers call `notifyListeners` independently. New features must commit through `LocalStore.transaction` and rely on its snapshot copy-back. Ad-hoc mutation plus `store.save` exists in `LearningHome` (resource events, saves) and bypasses the transaction guarantee |
| 9 | **Discipline logic in code** | Architecture [V] | `challengesFor`, `assembleSessionResult` and parts of `main.dart` hard-code `music` and `fashion`. Adding a discipline needs code changes, which blocks arbitrary disciplines |
| 10 | **Default app ID** | Release [V] | `com.example.sumi` is a placeholder and cannot be published |
| 11 | **Colour closeness** | Brand [V] | `SumiColors.primary #50C86A` and `sky #2AA8E8` sit close to Duolingo's palette. The approved mascot is emerald (`#22C08B`). Align the theme with the mascot to avoid looking like Duolingo |
| 12 | **AI output trust** | Safety [V] | `TutorOutputValidator` sanitises responses, and local failure falls back to authored text (no silent cloud upload). Keep this invariant for any new AI feature |

---

## 8. Changes made today

These were made in this session, before the discovery phase. All are **uncompiled**.

| File | Change |
|---|---|
| `lib/learning_path/path_screen.dart` | `PathNodeWidget` became stateful, with one-shot unlock, complete and checkpoint animations, a START bubble and haptics |
| `lib/learning_path/learning_path_controller.dart` | Unlocking nodes look locked until their event plays; event delay 520 → 720 ms |
| `lib/session_result/session_result_screen.dart` | New celebration layout (Sumi, rays, confetti, count-up stat tiles, evidence card). Button text kept as `RETURN TO PATH` because a test depends on it |
| `lib/learning_session/feedback_panel.dart` | 52 px Sumi reaction next to the feedback title |
| `lib/main.dart` | Settings entry for "Sumi animation library" (CRLF line endings preserved) |
| `lib/motion/celebration.dart`, `lib/mascot/sumi_rig.dart`, `lib/mascot/sumi_mascot.dart` | New |
| `assets/sounds/*.wav`, `scripts/make_sounds.py` | New; not registered in pubspec and not played |
| `research/mascot/sumi-rig.js` | Browser twin of the mascot rig, used for visual review |

---

## 9. Opportunities to reuse or improve

**Reuse as-is (do not rewrite):**

- `LocalStore.transaction` and the write queue. It is the correct place for every new mutation.
- The `LearningSessionController` state machine, `ChallengeRendererRegistry`, `FeedbackPanel` and `SessionResult` contract. New challenge types should plug into the registry.
- The `LearningPathController` event claiming (`pathEvents`) for any new path animation or celebration.
- The `PhoneModelController` and `TutorOrchestrator` routing, validator and fallback chain.
- `ResourceRanker` and `ResourceDetailScreen` for any resource-driven feature.
- `ActionButton`, `Surface`, `Tag` and the `SumiColors` tokens.

**Improve in place:**

1. **Make lesson content data-driven.** Move the per-node challenge lists into `disciplines.json` (or a sibling content file) and make `challengesFor` a pure loader. This fixes §6.1 and is a prerequisite for arbitrary disciplines.
2. **Fix the custom-discipline flow.**
   - Build a `Catalog.custom` (or a model-generated plan validated by `CustomPlanValidator`).
   - Persist it alongside the profile.
   - Call `setActiveTrack`.
   - Keep `trackId` and `catalog.id` consistent.
3. **Add node `type` to the content data** so checkpoint, review and reward nodes (and their existing animations) are actually used.
4. **Add a small review scheduler** (due dates per capability, based on blueprint §12.4) and feed the Practice tab from it. `PracticeScreen` may be reusable as the destination for a due item.
5. **Wire sound effects.** Add one audio package, register `assets/sounds/`, honour `soundEffectsEnabled`, and play sounds from controller events, not widgets.
6. **Decide on cloud AI.** Either remove it from Settings and chat, or implement a real relay behind the existing consent gate.
7. **Repository hygiene.** Run `git init`, extend `.gitignore` to cover `research/rea-duolingo-android-*/`, `tools/jadx-*`, the APK bundles and the Duolingo captures, and change the `applicationId`.
8. **Profile growth.** Cap or roll up the `sessions` map and the event logs.

---

## 10. Preliminary comparison with the in-repo agent breakdowns

The breakdowns already in the repository:

- `research/SUMI_EXPERIENCE_AGENT_BLUEPRINT.md` (v1.0, 28 Oct)
- `research/SUMI_NEXT_CORRECTION_AGENT_PROMPTS_2026-10-29.md` (which overrides it on cloud AI and resources)
- `research/SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md`
- `research/rea-duolingo-android-2026-10-29/REA_CODE_LEVEL_RECONSTRUCTION_SPEC.md`

This is a first pass. Full reconciliation will use the breakdown you send next.

| Spec area | Status | Evidence |
|---|---|---|
| Flutter, offline-first, ≤600 px single column, 4 tabs, Settings from Profile | **Implemented** | `main.dart` shell [V] |
| Onboarding stack (blueprint §9.1–9.10), persisted per step | **Implemented**; route reveal is minimal | `OnboardingFlow` [V] |
| Path with unit header, serpentine nodes, anchored card, guide, section overview, scroll restore | **Implemented, partly different**: the blueprint says a bottom sheet, but the REA spec (later) says an anchored card, and the code follows REA | `path_screen.dart` [V] |
| Node states (review due, project, checkpoint, perfect) | **Partial**: the presentation model supports them; the data never produces review, checkpoint or reward | §6.5 |
| Current-node breathing ring (looping) | **Different**: a static START bubble, because looping animation breaks tests | Risk 6 |
| Lesson state machine, Check then Continue, partial and incorrect panels, focus buffer that never locks | **Implemented** | `learning_session_*` [V] |
| Challenge formats per discipline | **Partial**: 8 renderers exist; content is not per node | §6.1 |
| Points table (§11.1) | **Different**: flat 20 per lesson | §6.7 |
| Streak rules | **Implemented**; recovery tokens are stored but never awarded | `EngagementState` [V] |
| Quests, achievements, sparks spending | **Missing** | §6.3 |
| Evidence states unseen → transferred | **Implemented** (`EvidenceState`) | `models.dart` [V] |
| Review scheduling (§12.4) | **Missing** | §6.6 |
| Arbitrary discipline plan and validator (§12.2–12.3) | **Missing / broken** | §6.2 |
| Offline AI models in Settings (§13) | **Implemented** | `phone_models_screen.dart` [V][R] |
| Hybrid local and cloud tutor with consent (correction prompt 4) | **Partial**: routing and consent exist; cloud is a stub | §6.3 |
| Adaptive profile with no fixed learner-type labels (prompt 3) | **Implemented** as a profile; **not yet used** for session assembly | `adaptation_system.dart` [V] |
| Video-first sessions (prompt 2) | **Partial**: 2 videos per track; sessions are not video-first | `disciplines.json` [V] |
| Sounds and haptics (§8.4) | **Partial**: haptics added today; sounds created but not played | §8 |
| "No mascot" (blueprint §0, §8.3) | **Incompatible with the current owner decision**: the owner approved a mascot today. The owner's instruction overrides the blueprint | Conversation, 31 Oct |
| Cloud network restriction (blueprint §3) | **Superseded** by correction prompts (cloud allowed with consent) | Prompts file §0 |

**Conflicts between the breakdowns themselves:**

- Bottom sheet (blueprint) or anchored card (REA): the code follows REA.
- No network (blueprint) or opt-in cloud (prompts): prompts win.
- No mascot (blueprint) or mascot (owner, today): the owner wins.

Reconciliation must settle each of these explicitly instead of following whichever document comes first.

---

## 11. Before implementation starts

1. Run `.\scripts\flutter.ps1 analyze` and `.\scripts\test-ui.ps1` to verify today's uncompiled changes. Fix any failures first.
2. Initialise git and exclude the Duolingo materials.
3. Confirm the target breakdown (yours) and settle the three conflicts in §10.

*Next step: specification reconciliation (`02-…`) against the breakdown you provide.*
