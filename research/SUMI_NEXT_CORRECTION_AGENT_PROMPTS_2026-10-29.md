# Sumi — Next Correction Prompts for the Implementation Agent

**Prepared:** 2026-10-29  
**Use:** Give the implementation agent one prompt at a time, in order. Do not combine all prompts into one turn. Each prompt requires implementation, tests, and an evidence-based handoff before the next begins.

## Product decision that overrides older assumptions

Sumi is not merely a static course app and not merely an offline model manager. Its core loop is:

1. The learner chooses any discipline and a concrete outcome.
2. Sumi gives a short baseline and returns a useful learning session containing mostly videos where suitable, plus questions, references, and practical work.
3. Sumi observes how the learner performs and which presentation approaches help them retain and apply knowledge.
4. An AI tutor uses that evidence to personalize explanations, questions, plans, and next steps in an ongoing conversation.
5. The learner can use a downloaded on-device model for private/general coaching or explicitly opt into cloud AI when the topic is specialized, source-heavy, or beyond the local model’s reliable capacity.

This decision supersedes the older blueprint restriction that network access is only for model downloads and external links. Cloud AI is now allowed, but only through explicit user choice and a privacy-safe architecture. The rest of `SUMI_EXPERIENCE_AGENT_BLUEPRINT.md`, `sumi-experience-agent-schema.json`, and `SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md` remains applicable unless this file explicitly changes it.

Do not describe a learner with fixed, unsupported labels such as “visual learner” or VARK categories. Model an evolving, editable set of observed preferences and performance patterns instead.

---

## Prompt 1 — Repair the foundation and prove one honest end-to-end learning loop

```text
Work in C:\Users\Ot\Downloads\OPEN-BUILD. This is a Flutter mobile app under app/. Read these files before editing:

- research/SUMI_EXPERIENCE_AGENT_BLUEPRINT.md
- research/sumi-experience-agent-schema.json
- research/SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md
- research/SUMI_NEXT_CORRECTION_AGENT_PROMPTS_2026-10-29.md
- app/lib/main.dart
- app/lib/models.dart
- app/lib/services.dart
- app/lib/practice.dart
- app/lib/assessment.dart
- app/lib/phone_model_types.dart
- app/lib/on_device_native.dart
- app/assets/disciplines.json
- all app tests

Implement and prove one honest vertical slice before further visual replication:

Choose discipline -> define outcome -> complete baseline -> receive a recommended learning session -> use one learning resource -> answer a related new-example question -> receive feedback -> complete a small practical task/reflection -> update capability evidence, points, and next step -> ask the AI tutor a contextual follow-up question.

The vertical slice must work for both Music and Fashion Design & Tailoring using reviewed content. It must continue to work without a model by using deterministic authored content. If a local model is installed, the AI follow-up must actually use it; do not display a pretend AI response.

First fix current correctness defects:

1. Preserve root tab state and confirm that the existing IndexedStack removes the blank transitions seen in the recording. Never show an empty white body for local navigation. Use a destination-shaped loading state only for real asynchronous work.
2. Remove residual Python/coding copy from Music and Fashion. In particular, replace “The prototype does not inspect uploaded code” with discipline-appropriate evidence disclosure.
3. Replace the reward idempotency logic. A source string plus a one-minute window is invalid: it suppresses different lessons completed quickly and permits the same lesson to be rewarded again later. Use a stable completion event ID such as disciplineId:goalId:activityId:attemptId:rewardType, persist it, and reject exact duplicates forever.
4. Make milestone completion, evidence update, reward ledger entry, and streak qualification one repository-level transaction with rollback/recovery semantics. UI widgets may not independently mutate these fields.
5. Do not award points for opening the app, viewing a resource, downloading a model, or merely asking the AI a question. Streak qualification requires a completed assessed action and must occur at most once per local calendar day.
6. Remove or correct unproven Settings claims. SharedPreferences is not “encrypted local guest storage.” A reminder is not enabled unless permission and a schedule exist. Accessibility text must reflect real controls.
7. Remove fabricated custom resources such as example.com. Until the custom-discipline pipeline is implemented, show an honest “Needs AI planning or learner-supplied resources” state rather than fake lessons and links.
8. Synchronize onboarding into the authoritative goal state. The selected outcome, daily minutes, constraints, prior experience and starting route may not live only in OnboardingState while buildCoachPrompt reads different default/empty LearningState fields. Introduce a real unique Goal record and ensure every custom goal has its own ID and isolated evidence.
9. Correct evidence promotion. Marking a milestone complete does not automatically mean “transferred.” Transfer requires successful application in a materially different context or assessed project evidence. A multiple-choice answer plus a checkbox may record exposure/supported/independent evidence as appropriate, but not transfer.
10. Upgrade persisted state with a versioned migration. Preserve all existing Music/Fashion progress and installed model files.

Create a small application/service layer so screens call use cases rather than directly mutating LearningState. At minimum introduce equivalents of:

- CompleteActivity
- RecordAttempt
- RecordResourceUse
- QualifyDailyGoal
- GetNextLearningSession
- AskTutor

Do not redesign every screen in this pass. Make the core flow correct and testable first.

Required tests:

- completing two different lessons within one minute awards both;
- reopening/replaying one completed lesson never duplicates its reward;
- persistence failure does not leave completion and points inconsistent;
- a viewed resource does not grant capability evidence or streak credit;
- Music and Fashion progress remain isolated;
- onboarding outcome and daily commitment are exactly the values supplied to the tutor/session assembler;
- two custom goals receive different stable IDs and never share progress;
- ordinary milestone completion does not automatically produce transferred evidence;
- local model absence still allows the complete deterministic learning loop;
- no custom resource uses example.com;
- no Music/Fashion screen contains Python/coding residue;
- switching tabs repeatedly never renders an empty root body;
- migration preserves an existing v3 learner record.

Run flutter analyze and flutter test. If the environment prevents a command, report the exact command and error; do not claim it passed. Return a concise file-by-file change summary, test evidence, migration notes, and remaining limitations. Do not begin Prompt 2 work.
```

---

## Prompt 2 — Build the resource and video learning system

```text
Continue in C:\Users\Ot\Downloads\OPEN-BUILD after Prompt 1 is complete and verified. Preserve its application/service boundaries and migrations.

Implement Sumi’s resource system so a learner receives useful materials, with videos prioritized where they genuinely fit the objective. The current disciplines.json contains references but no real video-resource model, and Library currently renders every resource as the same generic card.

Build a versioned Resource model with at least:

- id and contentVersion;
- canonical URL and provider ID;
- title, publisher/channel, creator;
- type: video, article, interactive, audio, bookExcerpt, or learnerSupplied;
- discipline and capability tags;
- level and prerequisites;
- duration or reading time;
- language;
- captions/transcript availability;
- cost/access requirements;
- bandwidth/download characteristics;
- reviewedStatus: reviewed, externallyValidated, provisional, or learnerSupplied;
- reviewedAt and source provenance;
- licence/usage note where known;
- safety flags;
- an authored “why this helps” note;
- a related application/check activity ID.

For the demo, add a small set of real, currently reachable, directly relevant video resources for both Music and Fashion. Verify every URL and metadata against the source. Do not invent URLs, durations, transcripts, licences, or claims. Prefer stable educational sources and exact videos/lessons rather than publisher index pages. Retain useful non-video references as secondary resources.

Do not download, rehost, scrape, or bundle third-party video unless the licence explicitly permits it. Opening or watching a video is engagement evidence, not proof of learning. Mastery/evidence only changes after a related question, new example, or practical task.

Implement:

1. ResourceRepository with local reviewed catalogue support and an interface for remote search/catalogue connectors.
2. ResourceRanker that filters before ranking: safety, prerequisites, language, access/cost, device/bandwidth constraints, goal relevance, then learner adaptation evidence.
3. A “Recommended for this step” surface that explains why each item was chosen, its format, time, access needs, review status, and what the learner will do afterward.
4. Library groups: Recommended for you, Saved, Used recently, and Browse by discipline.
5. A resource detail screen before leaving Sumi. Preserve app state when returning from an external player/browser.
6. Resource-use events: impression, opened, returned, saved, learner-reported completion, and post-resource check result. Do not pretend to know watch percentage when using an external player.
7. If embedding YouTube or another provider, use the official player/API and follow its terms, privacy requirements, branding, and event limitations. If not embedding, launch externally and be explicit about what Sumi can and cannot observe.
8. Clear unavailable/offline states and a fallback to authored explanation/questions.

For arbitrary/custom disciplines, prepare a remote connector contract that can return provider-validated canonical metadata. A language model must never invent a URL or resource ID. If no validated resources exist, say so and use generated explanations plus learner-supplied links. Label remote candidates that have not been human reviewed as “External, not reviewed by Sumi.”

Required ranking behavior:

- mostly video does not mean video-only;
- choose format based on the capability and evidence, not a permanent learner label;
- if video has repeatedly led to stronger post-resource recall than text for comparable tasks, video may receive a modest evidence-backed boost;
- learner can override format and data-saving preferences;
- do not infer preference from one click or from time spent alone;
- show why a recommendation was made.

Required tests:

- all shipped resource URLs and IDs are non-placeholder and unique;
- every recommended resource maps to a known capability and application/check activity;
- unknown model-proposed URLs/IDs are rejected;
- resource view alone cannot complete a capability;
- offline/unavailable video falls back without blocking the lesson;
- ranking respects language, prerequisites, bandwidth and learner format override before soft preference scores;
- Library state survives external-app round trips;
- Music and Fashion each surface at least two verified videos and one non-video alternative in the demo data.

Run analyze/tests and report verified resource provenance, limitations, and screenshots or widget-test evidence. Do not implement cloud AI in this pass and do not begin Prompt 3.
```

---

## Prompt 3 — Implement an evidence-based adaptive learner profile

```text
Continue only after Prompts 1 and 2 pass. Implement adaptation based on observable evidence, not fixed “learning style” categories.

Create a versioned LearnerAdaptationProfile per goal/discipline. Keep user-declared preferences separate from inferred observations. Include enough structure to represent:

- format evidence for video, text, audio, interactive practice, worked example, and project work;
- performance: first-attempt accuracy, corrected accuracy, recall, transfer, and confidence/uncertainty;
- scaffolding need: hints, retries, explanation requests, example requests;
- pacing: active response time, preferred session length, abandonment and return behavior;
- explanation preferences: concise/detailed, example-first/steps-first, familiar analogy/direct explanation;
- accessibility and bandwidth constraints;
- topic-specific misconception tags;
- evidence count, confidence, and last updated time for every inference.

Do not store or display IQ, talent, “slow learner,” “fast learner,” or VARK-style identity labels. UI wording should say things like “Short worked examples have helped on your last 4 checks” and allow the learner to correct or reset the preference.

Add a normalized event model. At minimum record:

- session started/completed/abandoned;
- content format presented;
- resource opened/returned;
- question response, correctness, hints and retries;
- explanation variant shown and requested follow-up;
- recall result after delay;
- practical evidence/reflection result;
- learner feedback: helpful/not helpful and explicit preference changes.

Use a deterministic AdaptationEngine to update the profile. A language model may summarize evidence in human language, but it may not directly write authoritative scores, evidence states, or schedules.

Implement a SessionAssembler that uses:

1. prerequisites and due reviews;
2. current goal and next observable capability;
3. recent errors and uncertainty;
4. learner constraints and explicit preferences;
5. format performance with minimum evidence thresholds;
6. variety so the system continues testing alternatives rather than locking the learner into one format.

Use conservative thresholds. One event cannot create an inferred preference. Prefer rolling comparable evidence and reduce confidence as evidence becomes stale. Retain raw evidence needed to explain every adaptation.

Add a “How Sumi is adapting” screen or profile section showing:

- observed pattern;
- evidence count and date range;
- current effect on sessions;
- uncertainty/low-confidence language;
- learner override and reset.

The two-day demo should honestly label early observations as preliminary. It must not claim a durable learning style or long-term retention after two days.

Required tests:

- one video completion does not label a video preference;
- repeated stronger post-resource results can modestly alter ranking/session format;
- explicit accessibility/bandwidth/format choices override inferred soft preferences;
- a recent failure schedules repair without erasing earlier success;
- recall and transfer evidence are distinct from exposure and engagement;
- all displayed adaptation claims trace to recorded event IDs;
- resetting inferred preferences preserves learning progress and explicit accessibility settings;
- adaptation remains isolated between unrelated goals unless the learner explicitly permits cross-goal use.

Add fixtures that demonstrate two learners receiving meaningfully different sessions from the same capability while deterministic grading remains identical. Run analyze/tests and report the exact adaptation rules and evidence thresholds. Do not begin Prompt 4.
```

---

## Prompt 4 — Integrate the conversational AI tutor and hybrid local/cloud routing

```text
Continue only after the deterministic core, resource pipeline, and adaptation profile are verified. The current on-device model is only used by “Test local inference”; integrate real tutoring into the learning experience.

Build a provider-neutral TutorService with these separations:

- TutorOrchestrator: prepares bounded context and chooses an allowed task;
- LocalTutorProvider: uses the existing GGUF/llama.cpp-compatible mobile runtime;
- CloudTutorProvider: calls a configurable Sumi backend endpoint, never a provider secret embedded in the APK;
- DeterministicTutorFallback: uses authored hints/explanations when no model is available;
- TutorOutputValidator: validates schema, IDs, citations, safety, length, and allowed actions;
- RoutingPolicy: recommends local/cloud but honors explicit user choice and consent.

Add learner-visible AI modes:

- Ask every time;
- Prefer on-device;
- On-device only;
- Prefer cloud for specialist questions;
- Cloud off.

Never silently upload learner content. Before first cloud use, explain what will be sent, why cloud is recommended, retention policy supplied by the configured backend, and what remains on device. Provide Cancel and “Use on-device instead.” Remember consent separately from routing preference. Do not silently fall back from local to cloud.

Routing policy:

- use deterministic/authored logic for grading, prerequisites, rewards, evidence state, and review scheduling;
- local model is appropriate for rephrasing reviewed material, generating a small parallel example, summarizing the current plan, reflective prompts, and general coaching;
- recommend cloud for specialized or source-heavy planning, larger context, custom-discipline capability mapping, and questions requiring stronger reasoning or current referenced information;
- high-risk medical, legal, financial, dangerous machinery, weapons, or other safety-sensitive goals must be narrowed to safe educational information and expert-supervised contexts; “cloud” does not make unsafe instruction acceptable;
- if neither provider is safely grounded, say what is unknown and ask for a source or expert input.

Add a real tutor entry point from lessons and the path, not from Settings only. The chat must be contextual to discipline, goal, current capability, recent attempts, adaptation summary, and approved resource IDs. The learner may ask follow-up questions and request another explanation style. Keep conversations per goal and make clear when the model/provider changes.

Do not send the entire learner database. Build a minimal context envelope with:

- schema version and request ID;
- selected discipline/goal;
- current reviewed capability/activity;
- relevant recent evidence summary with no unsupported label;
- learner’s explicit preferences and necessary constraints;
- approved resource IDs/notes, not arbitrary model URLs;
- requested tutor action;
- safety flags;
- maximum output length.

Require structured TutorResponse output with:

- responseId;
- providerType and model identifier;
- answer;
- uncertainty statement when needed;
- referenced approved resource IDs;
- optional suggested follow-up actions from an allow-list;
- no direct mutations to grades, rewards, progress, or route.

For custom disciplines, the cloud provider may draft a provisional capability graph and session plan, but the existing plan validator must enforce acyclic prerequisites, observable outcomes, workload, safety and canonical resources. The learner confirms or edits the result before it becomes active.

Cloud architecture requirements:

- mobile app calls a configurable authenticated Sumi relay/backend;
- API/provider keys stay server-side;
- request timeouts, cancellation, retry rules and clear offline errors;
- no fabricated citations;
- telemetry/logging redacts learner text by default;
- provider and retention disclosures are surfaced in Settings;
- app remains functional when cloud is absent.

The exact production cloud provider is not yet selected. Do not hardcode one. Implement the provider contract and a development adapter only if credentials/configuration are available. Do not fake a successful cloud reply. Surface “Cloud AI not configured” honestly.

Required tests:

- local model response works from an actual lesson/tutor screen and streams with Stop/Retry;
- airplane mode plus installed local model supports a contextual follow-up;
- no local model and no cloud still produces authored fallback guidance;
- cloud cannot be used before explicit consent;
- cancelling consent sends no request;
- local failure never silently uploads to cloud;
- provider/model badge matches the actual responder;
- unknown resource IDs and route/grade/reward mutations in model output are rejected;
- custom plan validation rejects cycles, impossible workloads, unsafe steps and invented links;
- removing a model preserves chat and learning progress while future local requests show a recoverable state;
- logs do not contain raw learner answers in release mode.

Run analyze/tests. If possible, run the local provider on the connected Android device and capture model name, offline proof, time to first token and total time. Return an architecture diagram in Markdown, changed files, test evidence, privacy limitations, and the one remaining configuration choice needed to activate production cloud AI. Do not begin Prompt 5.
```

---

## Prompt 5 — Rebuild the lesson, path, Practice, Library, Profile and Settings experience around the working core

```text
Continue only after Prompts 1–4 have produced a working vertical slice. Now implement the visible correction specification without replacing real services with decorative UI.

Use research/SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md as the screen-level acceptance contract. Preserve Sumi’s goal and use original Sumi assets only; Duolingo research is interaction reference, not an asset library.

Implement:

1. Learn/path
   - unit/outcome header;
   - original serpentine path and connectors;
   - distinct micro-lesson, video/resource, guided practice, recall, project, checkpoint and reward node types;
   - current-node auto-scroll;
   - node bottom sheet with skill, reason, estimated time, reward and Start/Review;
   - locked-node prerequisite explanation;
   - completed/current/needs-review states from the repository, not local widget state.

2. Lessons
   - one short challenge per screen;
   - progress and focus/attempt header;
   - response visible in the first viewport;
   - sticky Check then Continue action;
   - correct/retry feedback panel;
   - resource/video screen as a deliberate activity, followed by an application question;
   - project evidence/reflection as its own node;
   - final summary with points, evidence change, daily-goal effect and next step.

3. Practice
   - show only due repair/recall/transfer items selected by the scheduler;
   - explain why each item is due;
   - useful empty state;
   - never list every milestone as generic “Practice.”

4. Library
   - use the Resource system and groups from Prompt 2;
   - video-first where evidence and objective support it;
   - expose why recommended, time, format, access, review state and application task;
   - preserve saved/recent state.

5. Profile
   - separate engagement stats from capability evidence;
   - evidence states: unseen, exposed, supported, independent, recalled, transferred and needs review;
   - “Why Sumi believes this” details backed by event IDs;
   - “How Sumi is adapting” from Prompt 3;
   - clear current AI mode/provider and privacy link.

6. Settings
   - real controls for daily goal, reminders, accessibility, sound, haptics, reduced motion, data saver and AI routing;
   - truthful storage/privacy wording;
   - permanent Offline AI models section;
   - Cloud AI section with provider/configuration status, consent and data disclosure;
   - actual build/version metadata;
   - export/reset/delete controls with scoped confirmations.

7. Motion and graphics
   - original discipline graphics, node icons, feedback graphics, progress objects and reduced-motion fallbacks;
   - no mascot and no mascot-shaped empty area;
   - no copied Duolingo runtime assets;
   - no blank navigation transitions;
   - typography and spacing requirements from the correction spec.

Use accessibility semantics, 44x44 minimum targets, non-color correctness cues, 200% text compatibility and screen-reader feedback announcements.

Required tests and goldens:

- 320x700, 390x844, 430x932 and 600x960 logical sizes;
- 200% text scale;
- reduced motion and high contrast;
- path state and node-sheet behavior;
- challenge correct, retry, Continue and completion;
- video/resource return and post-resource check;
- Practice due reasons and empty state;
- Profile evidence explanations and adaptation evidence;
- truthful Settings statuses and toggles;
- AI mode/provider/consent presentation;
- no all-white root body during local navigation.

Run analyze/tests, update snapshots intentionally, and provide before/after screenshots. Do not start release packaging or claim on-device success without Prompt 6.
```

---

## Prompt 6 — On-device verification, failure testing and demo packaging

```text
Perform a release-candidate verification of the Sumi Flutter app on the connected Android phone. Do not add major features in this pass; fix only defects revealed by verification.

Build a release or profile APK from the current source, record its version/build hash, install through adb, and run the following evidence-driven script:

1. Fresh install and first-run onboarding.
2. Select Music, define a concrete outcome and complete the baseline.
3. Receive a session containing a recommended video, a question and a practical task.
4. Open the video/resource, return without losing state, complete the related new-example check and view feedback.
5. Ask the contextual tutor for a different explanation. Record whether deterministic, local or cloud answered.
6. Complete the activity and verify points, evidence and next path node update consistently in Learn and Profile.
7. Switch to Fashion and verify discipline isolation.
8. Kill and reopen the app; verify persistence and no duplicate reward.
9. With network off, use deterministic learning and an installed local model for a follow-up question.
10. With cloud preference selected but no connection, verify clear failure and local/deterministic alternatives; never imply a cloud response occurred.
11. If a cloud backend is configured, review consent, send one specialist question, verify provider badge and return. If it is not configured, show the honest unavailable state and mark cloud E2E as pending.
12. Download/pause/resume/verify/activate/test/delete an on-device model; learning progress must remain intact.
13. Exercise low-storage, bad-hash, cancellation, external-link failure, 200% text, reduced motion, sound off and repeated rapid tab switching.

Capture:

- adb device/model/Android version;
- APK absolute path, SHA-256, version and build number;
- flutter analyze and flutter test output;
- integration-test output;
- screen recording showing the complete learning loop;
- two-second contact sheet for blank-frame review;
- local inference model, offline proof, time to first token, total generation time and cancellation;
- cloud provider/configuration state without exposing secrets;
- unresolved defects ranked P0–P3.

Release blockers:

- any multi-second blank body;
- fabricated or dead demo resource;
- cross-discipline progress leakage;
- reward/evidence inconsistency or duplicate reward;
- fixed unsupported learning-style claim;
- AI provider badge not matching the responder;
- learner data sent to cloud without consent;
- model-generated link not resolved through the validated resource system;
- local inference represented as successful when it did not run;
- Settings privacy/security claim not backed by implementation;
- essential flow inaccessible at 200% text.

Copy the verified APK to dist/ with a new versioned filename. Do not overwrite the prior APK. Return the exact adb install command, artifact hash, test evidence, video/contact-sheet paths, and a candid list of anything not verified.
```

---

## Missing production decisions that do not block the prompts

The architecture can be implemented provider-neutrally, but production activation still requires the product owner to choose:

1. The cloud AI provider/model and the server-side relay/deployment location.
2. The cloud retention/logging policy presented during consent.
3. The remote video catalogue/search source for arbitrary disciplines, such as a reviewed Sumi catalogue only or an official video-provider API with externally validated results.
4. Whether third-party videos open externally or use an official embedded player.

Until those decisions are made, the implementation must remain honest: reviewed local catalogue and on-device tutor work; cloud/search features report “not configured” rather than simulating success.
