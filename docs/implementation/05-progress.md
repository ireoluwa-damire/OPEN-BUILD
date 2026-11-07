# 05 — Implementation progress

Updated: 1 November 2026 (WAT) · Applies to `app/` (Flutter package `sumi`)
Contract: `01-repository-assessment.md`, `02-requirements-matrix.md` (IDs), `03-implementation-plan.md`, `04-design-contract.md`.

## How verification was done

- **Toolchain.** The agent's cloud environment cannot download Flutter (Google storage and pub.dev are blocked), so every analyze and test run went through the owner's local runner (`scripts/agent-runner.ps1`, Flutter 3.47.8 / Dart 3.13.7 on Windows). Logs are in `.tooling/agent-queue/<id>-*.txt` (git-ignored).
- **Latest verified evidence:** `flutter analyze` → **No issues found** (job 127). `test-ui.ps1` full suite → **115 passed, 2 skipped, 0 failed** (job 128). The 2 skips are the pre-existing `session_recording_test` recordings, which only run when recording is requested. `flutter pub get` added `audioplayers 6.8.1` (job 117).
- **Unverified tail.** The owner's computer went offline at about 01:50 WAT while job 129/130 (analyze + full suite after the quests change) was running. Everything added after job 128 — daily quests, sparks spending, lesson loading screen and custom plan drafting — is synced to the repo but has **not** been analyzed or tested; those rows say so.
- **Not run:** goldens (no golden suite exists yet, QA-01), the phone suite (`test-phone.ps1`, needs the Android phone), APK build, and manual device scripts (S1 §20). Anything that needs those is marked *awaiting verification*, never *Verified*.
- **Git.** The repository still has no commits. No commit or push was made (plan rule: nothing is pushed before G0; commits wait for the owner).

## Status legend

| Status | Meaning |
|---|---|
| **Verified** | Code implemented, integrated, and an automated test that exercises the acceptance criteria passes on the owner's machine. |
| **Implemented, awaiting verification** | Code is in place and integrated; acceptance needs a golden, phone or manual check, or only part of the criteria has a test. |
| **In progress** | Partly implemented; the gap is stated. |
| **Not started** | No work yet in this pass. |
| **Blocked** | Cannot proceed; reason given. |

## Requirement status

### Governance

| ID | Status | Evidence / notes |
|---|---|---|
| GOV-01 | Verified | `.gitignore` covers every E-01 path; `git check-ignore` confirms the Duolingo APKs, decompiler, captures, reference pack and `Mascot concepts`; `scripts/check_repo_hygiene.sh` → "Repository hygiene OK". |
| GOV-02 | Verified | Analyzer 0 issues; full suite green (jobs 115/116). The 3 analyzer issues and the stale `Key ideas`/debug-paint failures from the assessment no longer occur. |
| GOV-03 | Verified | `lib/build_info.dart`; About and Settings read it; `test/build_info_test.dart` checks it against `pubspec.yaml`. `applicationId` unchanged (E-05). |
| GOV-04 | Implemented, awaiting verification | Phase 9 original graphics in `lib/graphics/sumi_graphics.dart` (code-drawn, no image files): wordmark and compact mark, onboarding route hero, Music/Fashion/Custom scenes, 24 glyphs (node set, rewards, exercise formats, model), 4 empty-state illustrations. All registered in `ASSETS.md`. Reviewed visually through a browser port of the painters (the Flutter golden `test/graphics_test.dart` has not run yet). Still missing: checkpoint scene (200) and guide heroes (160). |
| GOV-05 | Verified | Mascot gallery shows only in debug builds (`kDebugMode`); slot labels live only in `reference_slots_debug.dart`; `test/content_lint_test.dart` finds no `Duolingo`/`DUO_` in shipped code or content. |

### Architecture and data

| ID | Status | Evidence / notes |
|---|---|---|
| ARC-01 | Verified | All learner writes go through use cases wrapping `LocalStore.transaction`; `LearningHome.persist()` removed; `test/transaction_guard_test.dart` (fault injection for onboarding, resource save/events, baseline attempt, setting, lesson completion; plus "no `store.save(` outside LocalStore"). The debug write-guard flag from the plan was not added (the grep test enforces the rule instead). |
| ARC-02 | Implemented, awaiting verification | `lib/application/use_cases.dart` (SaveOnboardingAnswer, FinishOnboarding, RecordAttempt, RecordRecallAttempt, RecordResourceUse, ToggleSaveResource, UpdateSetting, QualifyDailyGoal, GetNextLearningSession, CompleteActivity, RemoveSelfReportedEvidence). `LearningService` is now a façade. The import-lint test (screens must not import `services.dart`) is not written; some screens still receive `LocalStore` for the path controller. |
| ARC-03 | Verified | Schema v4 (`LearnerSettings`, nullable onboarding answers, `review_schedule`), v3→v4 upgrade keeping the v3 key, consent moved to `settings.cloudConsent`, unconfirmed defaults cleared, ledger adjustment preserves totals, unreadable data raises `MigrationException` → recovery screen. `test/migration_v4_test.dart` with fixtures `test/fixtures/v3_{fresh,mid_onboarding,completed}.json`. The fixtures are synthetic (no device export was available). |
| ARC-04 | Verified | `scripts/author_content.py` run: each track has 2 units, 13 nodes, all 7 node types, 44–46 per-node challenges with parallels, hints and transfer items; `challengesFor` is a pure loader; units come from `units[]`. `test/content_schema_test.dart`. |
| ARC-05 | Verified | No `catalog.id == 'music'/'fashion'` branches remain (scene painter uses the `scene` data key; evidence categories/celebration from data). Lint in `content_schema_test.dart`. |
| ARC-06 | Not started | Profile growth caps. |
| ARC-07 | Implemented, awaiting verification | Totals derive from the ledger (earlier session); itemised awards with stable source IDs. Random-sequence invariant test not written. |

### Shell

| ID | Status | Evidence / notes |
|---|---|---|
| SHL-01 | Implemented, awaiting verification | ≤ 600 px column kept; `SumiLayout.gutter` used on rebuilt screens. Golden check pending. |
| SHL-02 | Implemented, awaiting verification | `SumiBottomNav` (four labelled tabs, tinted selected tile, semantics "{label}, tab, i of 4"). Golden pending. |
| SHL-03 | Implemented, awaiting verification | `IndexedStack` kept; tab-retention test not written. |
| SHL-04 | Implemented, awaiting verification | Focused flows are pushed routes covering the nav (unchanged). |
| SHL-05 | Verified | `BootScreen` (copy after 1 s) and `RecoveryScreen` (TRY AGAIN, confirmed START A FRESH PROFILE); `MigrationException` routes there (`migration_v4_test.dart` covers the error path; onboarding tests cover boot). EXPORT RECOVERY FILE is not offered yet. |

### Onboarding

| ID | Status | Evidence / notes |
|---|---|---|
| ONB-01 | Implemented, awaiting verification | Promise screen with wordmark, one-shot mascot greet, exact copy, GET STARTED, CONTINUE MY PROGRESS when another track has finished onboarding. Original hero graphic pending (Phase 9). |
| ONB-02 | Verified | Two-column `DisciplineCard` grid + Something else; select then CONTINUE; custom sheet. `test/onboarding_flow_test.dart`. |
| ONB-03 | Verified | 20–200 chars with live count, prompt chips, deadline incl. Custom date, constraints; 19/201 disable, 20 enables (test). |
| ONB-04 | Verified | Exact eight motivations and support line; no default (test). |
| ONB-05 | Verified | Exact five levels; self-report only (no evidence change). |
| ONB-06 | Verified | Three rows from `preview_capabilities`; no raw IDs (test asserts "Discipline:" absent). |
| ONB-07 | Verified | Labels Casual/Regular/Serious/Intense; workload range sentence with PROVISIONAL tag; estimator always a range (test). |
| ONB-08 | Verified | Basics skips the baseline and adds three CHECK items to the first lesson; Find my level runs the baseline (two widget tests). |
| ONB-09 | Implemented, awaiting verification | Baseline logic unchanged and green; re-skin to the lesson-shell components not done. |
| ONB-10 | Verified | Route reveal always shown (CF-19 fixed); evidence line, confidence tag, mini path, Why this route?; START FIRST LESSON finishes in one transaction and opens lesson 1 (test). |
| ONB-11 | Verified | Back control, 10 px progress, sticky CONTINUE disabled until valid, every answer saved at once, kill-and-restore resumes the same step (test). Android back mapped via `PopScope`. |
| ONB-12 | Verified | Choosing Fashion switches the active track before the baseline; Fashion's record holds the answers; the baseline shows Fashion questions (test). |

### Learn path

| ID | Status | Evidence / notes |
|---|---|---|
| PTH-01 | Not started | Goal/course strip. |
| PTH-02 | Verified | `PathStatusRow` (streak and points pills, 48 px targets; points opens "{n} points this week · Points measure practice, not mastery."). `test/path_card_result_test.dart`. |
| PTH-03 | In progress | Unit colours promoted to tokens (CF-13); depth edge and two tap zones not done. |
| PTH-04 – PTH-07 | Not started | Serpentine connectors, node matrix, breathing ring (existing node animations kept). |
| PTH-08 | In progress | Card shows type · minutes and "START +{n} POINTS" from `PointsPolicy.baseReward` (AMB-02), PRACTISE AGAIN / START CHECKPOINT / REVIEW variants (test). Content-fit height and DC §7.15 re-skin not done. |
| PTH-09 | Verified | Locked card: "LOCKED", "Finish “{prerequisite}” to unlock this step.", GO TO {PREREQUISITE} opens that node's card (test). |
| PTH-10 – PTH-12, PTH-14 | Not started | Section sheet, guide re-skin, checkpoint detail, auto-scroll. |
| PTH-13 | Implemented, awaiting verification | `DisciplineScene` at 120 px, full opacity, token colours, faint ink route; Music (pulse grid, note, metronome), Fashion (swatch, pattern piece, tape), Custom (blocks). Golden pending. |
| TUT-01 | In progress | Path tutor icon removed (test asserts it is gone); tutor stays reachable from the guide and lessons. Resource-detail and Profile entry points not added. |

### Lesson and feedback

| ID | Status | Evidence / notes |
|---|---|---|
| LES-01 | Implemented, awaiting verification | `LessonProgressHeader` with Focus semantics "Focus n of 5" and PRACTICE MODE (earlier session). Test asserts the semantics label. |
| LES-02 | Implemented, awaiting verification | Session state machine; covered by `session_contract_test.dart`. |
| LES-03 | Implemented, awaiting verification | White footer with CHECK (+ skip action). Golden pending. |
| LES-04 | Implemented, awaiting verification | Correct panel with S1 headings. |
| LES-05 | Verified | Incorrect → CONTINUE advances and requeues the parallel variant; progress counts originals only (`session_contract_test.dart`, `correction_spec_test.dart`). |
| LES-06 | Verified | Near-correct allows one revision (`session_contract_test.dart`). |
| LES-07 | Verified | Ungraded retry (`session_contract_test.dart`). |
| LES-08 | Implemented, awaiting verification | Explain My Mistake screen with CONTINUE LESSON (test taps it). AI rephrase goes through the tutor chat, not inline (TUT-02 inline badge pending). |
| LES-09, LES-10 | Implemented, awaiting verification | Settings sheet (DONE, REFILL FOCUS, END SESSION) and exit confirmation copy present. |
| LES-11 | Verified | Focus drops once, on the first persisted incorrect attempt (`session_contract_test.dart`). |
| LES-12 | Verified | All nine kinds valid/gradeable across authored content (`session_contract_test.dart`, `content_schema_test.dart`). |
| LES-13, LES-14 | In progress | `ChoiceRow` component built and used in onboarding/settings; lesson renderers not yet moved onto it. |
| LES-15 | Verified | Per-node content mix (see ARC-04). |
| LES-16 | Implemented, awaiting verification | Hints and I DON'T KNOW YET / CAN'T DO THIS NOW wired where data has them. |
| LES-17 | Implemented, awaiting verification | `lesson_loading_screen.dart`, pushed only if opening takes > 150 ms. **Not yet analyzed/tested** (added while the computer was offline). |
| LES-18 | Verified | Persist before feedback/points (`session_contract_test.dart`, `transaction_guard_test.dart`). |
| LES-19 | Verified | Lifecycle restore (`session_contract_test.dart`). |
| LES-20 | Implemented, awaiting verification | Re-entry awards nothing (test); compact review card not built. |
| LES-21 | Implemented, awaiting verification | Project reflection kind with three fields and SAVE EVIDENCE. |

### Result, gamification, evidence, practice

| ID | Status | Evidence / notes |
|---|---|---|
| RES-01 | Verified | Sequence retimed to 1,200 ms (confetti too) and tap-to-skip; Today row ({m}/{goal} min, streak, +1 DAY); Next card; CONTINUE + RETURN TO PATH + Review saved responses. Data captured on `SessionResult` at completion, so the screen reads only the result (test). Golden pending. |
| RES-02 | Verified | `session_result/accolade_resolver.dart` with the six rules in order (`test/accolade_test.dart`). |
| RES-03 | Not started | Checkpoint failure result. |
| RES-04 | Implemented, awaiting verification | CONTINUE pops with `openNext`; the path plays its events and then opens the new current node's card; RETURN TO PATH skips the card. Callback wiring is tested; the end-to-end path widget test is not written. |
| GAM-01 | Verified | S1 §11.1 itemised points; completion test checks the exact total. |
| GAM-02 | Verified | Replay/re-entry awards nothing (`session_contract_test.dart`). |
| GAM-03 | Implemented, awaiting verification | Streak + recovery tokens + qualifying days (earlier session); streak screen added. Midnight/missed-day tests not written. |
| GAM-04 | Implemented, awaiting verification | `engagement/quests.dart` derives the three quests from saved sessions; +10 points each and a +5-spark chest, paid idempotently inside the completion transaction; `QuestCard` above the unit header; `test/quests_test.dart`. **Not yet analyzed/tested** (job 130 result unknown). |
| GAM-05 | Implemented, awaiting verification | `BuyRecoveryToken` (30 sparks, max 2 tokens) from the streak screen; nothing gates learning on sparks. **Not yet analyzed/tested.** |
| GAM-06 | Implemented, awaiting verification | `engagement/streak_screen.dart` (14-day view, tokens, rules); opened from Profile. |
| GAM-08 | Implemented, awaiting verification | No leaderboard/league/friend UI exists. |
| EVD-01 | Verified | Promotion rules in `getEvidenceState`; `test/evidence_promotion_test.dart`. |
| EVD-02 | Verified | Transfer only from a first-try `context: transfer` pass (test). |
| EVD-03 | Verified | `review/review_scheduler.dart` (+1/+1/+2/+5/+10, pull-forward, reasons), scheduled on completion, feeds `needsReview` and Practice (tests). |
| EVD-04 | Implemented, awaiting verification | `profile/evidence_detail_screen.dart` lists every attempt with date, task, outcome icon + text, hint use, source and event ID; learner can remove a self-reported project entry (use case). Widget test not written. |
| PRA-01 | Verified | Five sections in order, reasons, empty state "You're caught up … Next one: {date}" (`test/practice_tab_test.dart`). |
| PRA-02 | Implemented, awaiting verification | Practice opens normal sessions that complete through `CompleteActivity`. |

### Library, profile, settings, AI

| ID | Status | Evidence / notes |
|---|---|---|
| LIB-01 – LIB-03 | Implemented, awaiting verification | Library moved to `tabs/library_tab.dart`; saves and preferences via use cases; empty states per DC §11.6. Card re-skin to DC §7.31 not done. |
| LIB-04 | Verified | Resource events via `RecordResourceUse`; never evidence/points/streak (`resource_system_test.dart`, `foundation_test.dart`, `transaction_guard_test.dart`). |
| PRO-01 | Implemented, awaiting verification | Rebuilt Profile: identity header, THIS WEEK (streak, points this week, steps, sparks), WHAT YOU'VE SHOWN, adapting card, AI row, disciplines. Focus removed from Profile (CF-15). Quests tile shows sparks until GAM-04 exists. |
| PRO-02 | Implemented, awaiting verification | AI row shows the real model state and "Cloud AI: Not configured". |
| SET-01 | Verified | Exact section order (`test/settings_truth_test.dart`). |
| SET-02 | Verified | Every subtitle derived from state (test). |
| SET-03 | Implemented, awaiting verification | Daily goal, goal/deadline (read-only), exercise mix, sounds, haptics, disciplines. Editing the goal text is not offered. |
| SET-04 | Verified | Disabled toggle with honest copy; `reminders_enabled` no longer stored (test). |
| SET-05 | Verified | Accessibility screen; high contrast re-themes live via `appSettings`; text size ×1.15/×1.3; reduced motion also sets `disableAnimations` (test covers persistence). |
| SET-06 | Implemented, awaiting verification | Storage summary per track, copy JSON export, import with validation, clear one / clear all with scoped confirmations; models untouched. Export copies to the clipboard (file save is not supported by `file_selector` on Android). |
| SET-07 | Implemented, awaiting verification | About screen, `showLicensePage`, model/content/font acknowledgements, AI-assistance disclosure. |
| AIM-01 | Implemented, awaiting verification | Model manager logic unchanged; regression on phone not run. |
| TUT-02 | Verified | Consent read from `settings.cloudConsent`; the misleading cloud consent dialog is removed; every tutor reply shows a `ProviderBadge` that matches the responder (`test/tutor_badge_test.dart`). Inline "explain another way" inside Explain My Mistake still routes through the tutor chat. |
| TUT-03 | Verified | `SumiCloudTutorProvider` always throws `CloudNotConfigured`; no canned text (test). |
| CUS-01 | Verified | Unique ID + isolated record + registry; honest provisional screen; no fake lessons or links (`foundation_test.dart`, `onboarding_flow_test.dart`). |
| CUS-02 | Implemented, awaiting verification | `custom/custom_plan.dart` (prompt, parse, fail-closed validator: 3–8 steps, links, unsafe content, workload, cycles; high-risk topics narrowed to theory; generic formats with no answer keys) and `custom_plan_screen.dart` (draft on device, Stop, trim, confirm, redraft). Confirm saves the plan and finishes the goal's onboarding. `test/custom_plan_test.dart`. **Not yet analyzed/tested**, and on-device drafting needs the phone with a model installed. |

### Motion, sound, typography, accessibility, QA

| ID | Status | Evidence / notes |
|---|---|---|
| MOT-01 | Implemented, awaiting verification | `SumiMotion` tokens (earlier session), used by new components. |
| MOT-02 | Not started | Event-to-animation contract completion. |
| MOT-03 | Implemented, awaiting verification | Reduced motion from settings or platform; new screens and the onboarding slide honour it. |
| MOT-04 | Implemented, awaiting verification | `loopsEnabled` false under test; suite settles. |
| SND-01 | Verified | `effects/effects_service.dart` plays the 11 original sounds through `audioplayers`, only when sound is on; silent under test/web. Called from the lesson controller (after persistence), path events, the result screen and model verification. Five new sounds generated by `scripts/make_sounds.py` (`effects_service_test.dart`). Device listening check pending. |
| SND-02 | Verified | Haptics go through the same service and obey the haptics setting; no widget calls `HapticFeedback` directly (`effects_service_test.dart`). Device vibration check pending. |
| TYP-01 | Implemented, awaiting verification | Nunito 500–900 bundled and registered (earlier session); tabular figures on stats. |
| A11Y-01 – A11Y-03 | In progress | New components carry semantics, 48 px targets and icon + text + colour; older screens not audited. |
| A11Y-04 | In progress | Text-size setting works; fixed heights remain on the path card. |
| A11Y-05 | Implemented, awaiting verification | Feedback live region (earlier session); onboarding support lines are live regions. |
| A11Y-06 | Implemented, awaiting verification | High-contrast palette applied to buttons and text styles. |
| A11Y-07 | In progress | Focus ring on `TactileButton` and nav slots. |
| QA-01, QA-02 | Not started | Golden suite; device script. |
| QA-03 | Verified | `test/content_lint_test.dart` (banned copy, coding residue, placeholder links). |

## Deliberate deviations

1. **Progress export** copies JSON to the clipboard instead of saving a file, because `file_selector` cannot save files on Android. Import uses `openFile`.
2. **Profile "THIS WEEK"** shows sparks where DC §8.12 lists quests, because quests (GAM-04) are not built yet.
3. **v3 fixtures** are synthetic records shaped like the real v3 schema; no device export was available.
4. **Path card test geometry.** `correction_spec_test.dart` now picks a node the open card does not cover, because the new data-driven path places a video node between the first two lessons.
5. **Intentional test updates** (plan §13 and ARC-04): copy assertions (`Not quite yet.`, `CONTINUE`, `EXPLAIN MY MISTAKE`, `CONTINUE LESSON`, `DONE`, Focus semantics), v4 storage keys, itemised points totals, and data-driven node order.

## 6 November update

- Lesson settings sheet now republishes sound/haptics/motion settings after saving (bug found by the architecture review).
- Fixed the quest card overflow that job 130 caught (9 failures, all from one unconstrained row).
- Phase 9 graphics drawn and wired into onboarding (wordmark, hero, discipline cards, choice icons, mini path), boot screen, path (node glyphs, status row, scenes), Practice, Profile, streak screen, quest card, result screen, and empty states (Practice, Library saved, custom goal). Interface chrome (back, close, chevrons, settings) keeps interim Material Symbols, as DC §5 allows.
- **None of this has been analyzed or tested**: the local runner was not running. Run `analyze` and `test` (including `test/graphics_test.dart --update-goldens` once to create the review golden).

## Outstanding work (next steps)

1. **Re-run verification** when the computer is back: `analyze`, then the full `test` suite, to clear the unverified tail (GAM-04, GAM-05, LES-17, CUS-02).
2. Path visuals still to do: PTH-01, PTH-03–08 re-skin, PTH-10–14.
3. RES-03 checkpoint failure; LES-20 compact review card; LES-13/14 renderer re-skin; inline "explain another way" in Explain My Mistake.
4. ARC-06 profile growth caps; ARC-02 import-lint test; random-sequence ledger invariants (ARC-07).
5. QA-01 golden suite and QA-02 phone script; AIM-01 phone regression; APK build.
6. Phase 9 original graphics (GOV-04 completion, PTH-13).
7. Retire `lib/practice.dart` and `lib/two_day_review.dart` (unused) once deletion is approved — the session cannot delete files in your folder without permission.
