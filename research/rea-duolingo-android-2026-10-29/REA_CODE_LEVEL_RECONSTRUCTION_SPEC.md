# REA Code-Level Reconstruction Specification for Sumi

**Analysis date:** 2026-10-29  
**Target:** Duolingo Android `6.103.6` (`versionCode 2488`)  
**Package:** `com.duolingo`  
**APK SHA-256:** `c4350eb27637e821f1dbaebd9988f23f270b4bbe5118b59cc01048fb9ac71c89`  
**Decompiler:** `jadx-headless-mcp 0.7.1` through REA  
**Purpose:** Translate verified implementation structure into an original Sumi implementation that preserves Sumi's arbitrary-discipline learning goal.

## 1. Evidence policy

This document separates:

- **Observed package facts:** class/member/resource information directly recovered from the shipped APK.
- **Observed runtime behavior:** behavior visible in the two supplied screen recordings.
- **Sumi decisions:** original implementation choices made to reproduce the interaction grammar without shipping Duolingo branding, characters, course content, artwork, sounds, or proprietary resource files.
- **Unknowns:** behavior that neither the APK pass nor the recordings establish sufficiently.

Static APK analysis does not prove runtime order, experiment selection, server policy, or reflective calls. Class presence proves that a capability is packaged, not that every user sees it.

## 2. REA evidence ledger

| Evidence ID | Scope | Main fact established |
|---|---|---|
| `ev_391f03b230b5bfaeac5fb2b4bbff0d3537989b546e7c1f599f77e91e0edec64b` | APK summary | JADX loaded 79,064 classes and 18,229 resources; package/version/SDK declarations verified. |
| `ev_91cfb4f13c894a6580a17a0a9edf0b371af119daebe8684416900fbf80bdf7ef` | Home/path class search | Home, path, section, reward, sound/haptic, and Rive view-holder class families are packaged. |
| `ev_7e1e3c5d8a6a9cc6167e7410bc30a8f08742d00116b130a384ab47e4403a627c` | `PathViewModel` | Path behavior is centralized and incorporates path level type/state, unit indices, scrolling, offline state, experiments, network status, and animation state. |
| `ev_a49989b903e1e6508757f50dd2374501780a963d170dd9a2a853b8b8e8799016` | Path animation scenario | Node animation scenarios are explicitly `UNLOCK`, `PROGRESS`, and `COMPLETE`. |
| `ev_d6a445282b205762ac9f69f8da07981cf640941c654d293ab4c774041c3ebdc7` | Rive trigger inputs | Exact triggers include `node_unlock_trig`, `node_complete_trig`, and `complete_trophy_trig`. |
| `ev_27801932397dc280cab939b0e49104da3789f913ac8acab928900b98dbb45097` | Rive boolean inputs | Path node rendering has explicit active, clicked, completed, dark-mode, legendary, pressed, ring, trophy, boost, arrow, combo, and icon-animation switches. |
| `ev_18c8cd21a6a14c73e15b5205f161f8ab12854e0b35806c1c66752e23ec462109` | Rive numeric inputs | Node animation supports color, source icon, destination icon, and star-flip mode parameters. |
| `ev_eb2e420ec508b9f583817f7f6c8610f866ffcdd699583ce17f0ca3090dd26e00` | Session class search | A shared session shell and a broad family of dedicated challenge renderers are packaged. |
| `ev_d9fbae6577fb61c85aee2200064fec61373a68fa854d8e462bbd9b8b49b4c6b0` | `SessionActivity` | One activity owns session start parameters, fragment replacement, page-transition selection, progress/health state, encouragement, vibration, and lifecycle persistence. |
| `ev_f379a03caed972254315d6d06e84a15f5c1aec6c268086d0a598295bcb0c0681` | `SessionHealthViewModel` | Attempt/energy state is a dedicated state owner, not a static counter in the app bar. |
| `ev_7fe0829295c3de3c52d9449dbca26474de8a19f7a481fa2cf4a2fa288e42d760` | Lesson failure references | Failure is represented by a dedicated `LessonFailFragment` with a ViewModel and multiple static callers. |
| `ev_9cf2525682f19bd6a03077a0b511fcfb242f000f37a5ab08b3ce7a1ff3405053` | Completion model | Completion uses a rich shared result model with duration, score/stat fields, session type, accolade, animation, combo, unit-check-in, and optional Music/Math/Chess payloads. |

All findings inherit REA's limitations: static decompilation, no APK signature verification in this provider pass, no proof of dynamic/reflection coverage, and no proof that packaged experiments were active in the recordings.

## 3. Principal finding

Duolingo's perceived quality is not produced by green colors and circular buttons. It is produced by three coordinated systems:

1. A path presentation state machine that distinguishes stable state, transient press state, progress state, unlock state, completion state, icon transitions, trophy state, and layered effects.
2. A durable session controller that keeps progress, health, current challenge, response, page transition, feedback, settings, lifecycle, and exit behavior synchronized.
3. A shared completion contract that receives normalized session evidence and chooses the appropriate celebration, accolade, and discipline-specific result content.

The current Sumi build approximates the first screenshot of each system but does not yet implement these underlying contracts.

## 4. Verified path architecture

### 4.1 Path state ownership

`PathViewModel` is not a simple list controller. Its visible method signatures establish responsibilities for:

- path level type and path level state;
- path unit indices;
- section-list selection;
- scroll actions and snap priority;
- offline-mode/path-level compatibility;
- path component loading;
- node-coordinate handling;
- animation state, including score-flying node animation;
- network status and experiment treatment dependencies.

Sumi must use one `LearningPathController` as the source of truth. Widgets must not derive unlock, completion, current-node, or animation transitions independently.

### 4.2 Required Sumi node state contract

Implement an immutable presentation object similar to:

```text
PathNodePresentationState
  stableState: locked | available | current | inProgress | complete | mastered
  isActive: boolean
  isPressed: boolean
  isCompleted: boolean
  isMastered: boolean
  showProgressRing: boolean
  showCheckpointCrown: boolean
  showBoostEffect: boolean
  animateArrows: boolean
  runCompletionCombo: boolean
  animateIcon: boolean
  paletteIndex: number
  fromIconIndex: number
  toIconIndex: number
  starFlipMode: number
  pendingTrigger: none | unlock | completeNode | completeCheckpoint
```

The exact field names are Sumi decisions. The separation between persistent booleans/numbers and one-shot triggers is based on observed APK state-machine inputs.

### 4.3 Verified animation inputs

Observed one-shot Rive trigger names:

- `node_unlock_trig`
- `node_complete_trig`
- `complete_trophy_trig`

Observed persistent Rive boolean names:

- `isactive_bool`
- `is_clicked_bool`
- `iscompleted_bool`
- `dark_mode_bool`
- `islegendary_bool`
- `is_tapped_bool`
- `ringon_bool`
- `trophy_on_bool`
- `xp_boost_bool`
- `arrows_anim_bool`
- `combo_effects_bool`
- `icon_anim_bool`

Observed numeric names:

- `color_num`
- `from_icon_num`
- `to_icon_num`
- `star_flip_mode_num`

Sumi should create original Rive files or Flutter animations with equivalent semantic inputs. Do not extract or ship Duolingo `.riv` resources.

### 4.4 Path transition sequence

For a node that becomes available:

1. Persist the prerequisite completion.
2. Recompute the path model.
3. Mark the destination node available but visually inactive.
4. Fire `unlock` once.
5. Set active/current state after the unlock animation reaches its stable point.
6. Scroll only if the destination is outside the comfortable viewport.

For a completed node:

1. Persist evidence and points first.
2. Fire `completeNode` once.
3. Update ring/progress state.
4. If it is a checkpoint, fire `completeCheckpoint` and show the checkpoint crown/trophy layer.
5. If another icon replaces the prior icon, animate `fromIconIndex` to `toIconIndex` rather than swapping abruptly.

The ordering above is a Sumi reconstruction decision informed by the state-machine separation. The APK pass did not establish exact millisecond timing.

## 5. Verified lesson/session architecture

### 5.1 Shared shell, specialized challenge renderers

The APK contains one central `SessionActivity` and dedicated fragments/views for many interaction families, including:

- select and text-only select;
- translate and reverse-translate;
- tap-complete and word-bank writing;
- gap fill and cloze;
- short and extended matching;
- listening, listen-complete, listen-tap, and listening comprehension;
- speaking, repeat, recall, and listen/speak combinations;
- dialogue and chat completion;
- character selection, freehand writing, guided tracing, and stroke display;
- chess puzzles;
- math number lines, fractions, expressions, multi-select, matching, and typed fill;
- music-specific input and feedback surfaces.

This confirms that fidelity requires a renderer registry, not one multiple-choice layout reused for every activity.

### 5.2 Required Sumi session contract

Implement a single durable `LearningSessionController` with:

```text
LearningSessionState
  sessionId
  goalId
  unitId
  nodeId
  orderedChallengeIds
  currentChallengeIndex
  persistedProgress
  healthOrFocus
  currentResponseDraft
  submissionState: idle | grading | persisted | failedToPersist
  feedbackState: hidden | correct | incorrect | nearCorrect | retry
  explanationState: closed | authored | localAI | cloudAI
  settingsState: closed | open
  exitState: none | confirm | ending
  lifecycleState: foreground | backgrounded | restoring
```

Challenge widgets receive state and emit typed intents. They must not mutate points, completion, health, or navigation directly.

### 5.3 Required challenge renderer registry

Minimum two-day-demo renderers:

1. `SingleSelectChallengeRenderer`
2. `SequenceTokensChallengeRenderer`
3. `MatchPairsChallengeRenderer`
4. `TypedReflectionChallengeRenderer`
5. `MediaObservationChallengeRenderer`
6. `MusicListenOrImitateChallengeRenderer`
7. `FashionProcedureOrderChallengeRenderer`
8. `DrawingOrAnnotationChallengeRenderer`

Every renderer must support:

- untouched;
- response-valid/Check-ready;
- grading;
- correct;
- incorrect;
- near-correct where meaningful;
- restored after backgrounding;
- read-only review.

### 5.4 Feedback contract

Feedback is a session state, not an inline message card. It must:

- preserve the submitted response;
- color the response and the lower feedback region consistently;
- state the outcome and the reason;
- provide Continue, Retry, or Explain as dictated by the grading result;
- persist the graded attempt before points, streak, evidence, or path progress animates;
- restore the same challenge after settings or explanation round trips.

The recordings establish green, red, amber, and speaking-retry visual states. The APK confirms a shared session owner and dedicated challenge families; it does not expose a trustworthy unobfuscated enum that proves every feedback label.

### 5.5 Session health/focus

`SessionHealthViewModel` and `EnergyIncentiveType` prove that health/energy is separately modeled in the reference app. Sumi should not copy monetized energy rules. If Sumi keeps Focus:

- store it in `LearningSessionController` or a dedicated `SessionFocusController`;
- derive the top indicator from real state;
- decrement only after a persisted incorrect attempt;
- allow non-punitive recovery;
- never block accessibility, authored explanations, or essential learning.

## 6. Verified completion architecture

`SessionCompleteModel` carries common result data plus discipline-specific state. Its constructor signatures include:

- durations;
- several integer/float statistics;
- session-complete session type;
- a list payload;
- lesson accolade type;
- completion animation selection;
- Music song state;
- Math match state;
- Chess match, mini-match, bot, and avatar state;
- combo-run state;
- unit-check-in end state;
- optional integer and string values.

The packaged accolade hierarchy includes semantic categories such as:

- committed;
- first-lesson celebration;
- high scorer;
- listening star;
- mistake eraser;
- perfect lesson;
- speaking star;
- super fast;
- word wizard.

Sumi must use a shared `SessionResult` with optional discipline evidence, for example:

```text
SessionResult
  duration
  correctCount
  incorrectCount
  nearCorrectCount
  firstAttemptAccuracy
  pointsAwarded
  completedNode
  unlockedNode
  accolade: consistency | accuracy | recovery | listening | making | reflection
  celebrationType
  evidencePayload:
    music: tempo/rhythm/listening/reflection evidence
    fashion: procedure/measurement/material/reflection evidence
    general: concept/application/recall evidence
```

The result screen reads this object. It must not invent completion by reading widget-local booleans.

## 7. Current Sumi implementation verdict

### P0 — structural mismatches

1. **Node interaction uses the wrong navigation grammar.**  
   `app/lib/main.dart:976-995` launches `showModalBottomSheet`, and `app/lib/path_widgets.dart:309` defines `NodeBottomSheet`. The recorded reference uses an anchored node action card that replaces itself when another node is selected. Replace the modal sheet with an overlay positioned relative to the selected node.

2. **The guide is not implemented.**  
   `app/lib/main.dart:1028-1031` displays a Snackbar instead of a full guide/reference screen. Build a real `UnitGuideScreen` with Watch, Key Ideas, Reference, and Try sections.

3. **The tutor FAB breaks the reference hierarchy.**  
   `app/lib/main.dart:1016-1021` floats `Ask Tutor` above the path. The captured shell has no equivalent dominant FAB. Move AI assistance into mistake explanation, guide/resource detail, and an explicit tutor destination.

4. **The lesson engine is a fixed three-page script.**  
   `app/lib/challenge_screen.dart:32` hard-codes concept, reflection, and summary. Replace it with the session controller and renderer registry described above.

5. **The lesson is article-shaped and scroll-first.**  
   `app/lib/challenge_screen.dart:104` wraps the ordinary challenge in `SingleChildScrollView` and includes idea, body, worked example, prompt, choices, and tutor action. Normal challenges should fit one primary task in the first viewport. Put reference content in the guide or an explanation surface.

6. **Focus is decorative rather than authoritative.**  
   `app/lib/challenge_screen.dart:94` displays `Focus 5` as static text. Bind it to session state or remove it for the demo.

7. **The feedback state machine is incomplete.**  
   `app/lib/challenge_screen.dart:118-168` supports only checked/not-checked and correct/incorrect. It lacks near-correct, retry, explanation, preserved wrong selection styling, persistence gating, and state restoration.

8. **Completion is widget-local.**  
   `app/lib/challenge_screen.dart:388-430` renders a static summary and returns to path. Replace it with a result assembled from persisted attempt/evidence data.

### P1 — path fidelity mismatches

1. `PathNodeWidget` uses a conventional blur shadow. Reference nodes use a tactile lower depth edge plus controlled highlights.
2. Node titles are printed under every node. In the captured path, nodes rely mainly on icons/scenes and reveal detail in the anchored card.
3. `PathConnectorPainter` draws explicit connecting lines. The captured path is primarily a spatial serpentine composition; connectors must be validated against the specific recorded unit before being retained.
4. All current/current-progress nodes share mostly the same static appearance. Add stable and transient node states from Section 4.
5. `UnitHeaderCard` is fixed to `UNIT 1 · FOUNDATIONS` and an ink-black surface. Unit identity, outcome, palette, guide affordance, and progress must come from the active unit model.
6. No original discipline scene occupies the emotional/orienting role beside path nodes.
7. Returning from a lesson must restore exact path scroll position and selected unit.

### P2 — code health issue discovered during integration review

`app/lib/main.dart:1060-1069` contains a stray fragment after the `ListView` closing bracket. Confirm this is not unreachable or malformed generated residue, remove it if invalid, and run formatting/analyzer/tests before visual work continues.

## 8. Required Flutter component/state rewrite

Create or refactor toward these boundaries:

```text
learning_path/
  learning_path_controller.dart
  learning_path_state.dart
  path_screen.dart
  unit_header.dart
  path_node.dart
  node_animation_controller.dart
  node_action_overlay.dart
  unit_guide_screen.dart
  section_overview_screen.dart

learning_session/
  learning_session_controller.dart
  learning_session_state.dart
  challenge_definition.dart
  challenge_renderer_registry.dart
  lesson_shell.dart
  feedback_panel.dart
  mistake_explanation_screen.dart
  lesson_settings_sheet.dart
  renderers/

session_result/
  session_result.dart
  session_result_assembler.dart
  session_result_screen.dart
  accolade_resolver.dart
```

The exact folder migration is optional. The ownership boundaries are mandatory.

## 9. State-transition requirements

### Path node tap

```text
idle
  -> press visual
  -> selected node overlay appears
  -> outside tap dismisses
  -> selecting another node replaces overlay
  -> Start persists selected node/session parameters
  -> full-screen lesson transition
```

### Challenge submission

```text
answering
  -> valid response enables Check
  -> grading locks inputs
  -> persist attempt
  -> correct | incorrect | nearCorrect | retry
  -> optional Explain preserves challenge/session
  -> Continue advances only after persistence succeeds
```

### Completion

```text
last challenge feedback
  -> persist final attempt
  -> assemble SessionResult
  -> persist evidence/points/streak/path mutation atomically
  -> completion screen
  -> accolade/discipline-specific animation
  -> Continue returns to exact path position
  -> node completion trigger
  -> optional next-node unlock trigger
```

## 10. Acceptance tests

### Path

- Tapping a node never opens a bottom sheet.
- The action card is anchored to the selected node and is replaced, not stacked.
- Press, active, progress, completion, and unlock are independently testable states.
- Unlock and completion triggers fire once after persistence, never on rebuild.
- Guide and section overview are real navigable surfaces.
- Exact scroll position survives lesson, guide, settings, and app backgrounding.

### Lesson

- A single session controller owns progress and Focus.
- At least four genuinely different renderers are demonstrated across Music and Fashion.
- Check is disabled until response validity is satisfied.
- Correct, incorrect, near-correct, and retry panels are visually and behaviorally distinct.
- Explain My Mistake returns to the same session state.
- Settings preserves the draft response.
- No points or path progress animate before persistence succeeds.

### Completion

- Completion reads a `SessionResult`, not widget-local state.
- Music and Fashion populate different evidence payloads while using the same shell.
- Failure does not mark the node complete.
- Continue restores the attempted node's path context.

### Visual/motion

- Record golden videos at 1080×2400 and the target logical Android viewport.
- Compare the transition grammar and geometry to the supplied recordings, not copyrighted pixels.
- No blank route frames, clipped sticky action, or full-page jump when feedback appears.
- Reduced-motion mode reaches the same stable states without essential information loss.

## 11. Unknowns and remaining REA work

Still unresolved:

- the exact experiment branch active during each recording;
- exact duration/easing constants embedded in resources or animation files;
- exact order of the normal successful lesson-end screen stack, because that flow was not recorded;
- server-provided path scheduling and challenge selection rules;
- reflection/dynamic-loading call sites not recovered by static references;
- accessibility announcements and haptic/sound timing during the recorded flow.

Recommended next focused REA passes:

1. Trace the specific `SessionActivity` fragment-switch methods after selecting their decompiled bodies.
2. Inspect `SessionCompleteAnimation`, `SessionCompleteSessionType`, and `UnitCheckInEndState` subclasses.
3. Inventory only original resource names and dimensions needed to infer layout roles; never copy proprietary resource bytes.
4. Correlate controlled on-device navigation with class/reference evidence for successful completion, reward, offline, and restoration flows.

## 12. Agent directive

The correction agent must implement the ownership and state-transition changes before polishing colors or illustrations. It may modify any Sumi screen or architecture, but it must preserve Sumi's goal: personalized learning for arbitrary disciplines using reviewed resources plus optional local/cloud AI tutoring.

The agent must not claim “exact Duolingo replication” merely because screenshots look similar. Fidelity is accepted only when path state, challenge cadence, feedback, persistence ordering, return behavior, and animation triggers behave consistently under interaction, restoration, and failure.
