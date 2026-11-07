# Standalone Prompt — Forensic Sumi UI/UX Reconstruction

```text
Work in C:\Users\Ot\Downloads\OPEN-BUILD. Rebuild the current Flutter mobile UI under app/ using the supplied live-reference evidence. This is a strict reconstruction task, not a loose “Duolingo-inspired” redesign.

Read completely before editing:

- research/live-reference-2026-10-29/DUOLINGO_LIVE_REFERENCE_RECONSTRUCTION_SPEC.md
- every contact sheet and representative frame under research/live-reference-2026-10-29/
- research/SUMI_EXPERIENCE_AGENT_BLUEPRINT.md
- research/sumi-experience-agent-schema.json
- research/SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md
- research/SUMI_NEXT_CORRECTION_AGENT_PROMPTS_2026-10-29.md
- the current app/lib, app/assets and app/test implementation

Evidence priority:

1. The product owner’s latest request.
2. The observed states and transitions in DUOLINGO_LIVE_REFERENCE_RECONSTRUCTION_SPEC.md and its video frames.
3. Sumi’s learning purpose, data integrity, AI privacy and original-asset rules.
4. Older approximate layouts.

Do not ship or trace Duolingo characters, illustrations, animation files, sounds, wordmark, course text or proprietary runtime assets. Reproduce their interaction roles using original Sumi graphics, project objects and content. Do not use the runtime assets under research/ in the app.

The visible target is an exact reconstruction of the observed interaction system:

- persistent course/goal strip;
- rounded white path surface beneath it;
- compact status row;
- tactile unit card with guide action;
- serpentine path with multiple node types and contextual discipline scenes;
- anchored node-action cards;
- section overview;
- checkpoint/star detail;
- full-screen unit guide;
- one-challenge lesson shell;
- pinned Check/Continue action;
- correct, incorrect, near-correct and retry lower feedback panels;
- Explain My Mistake flow;
- lesson settings bottom sheet;
- result screens;
- streak, quests, Profile, Settings and add-discipline surfaces;
- the observed slide, sheet, popover and immediate-feedback cadence.

The content target remains Sumi:

- arbitrary practical disciplines;
- current reviewed Music and Fashion tracks;
- mostly video resources where appropriate;
- questions and practical tasks tied to capability evidence;
- adaptive learner profile;
- deterministic learning state and grading;
- optional local/cloud AI tutor;
- permanent Offline AI models settings section.

Map Duolingo roles to Sumi roles exactly as specified in the live-reference report. Do not blindly introduce language-course mechanics. Hearts/energy may become a non-punitive focus/attempt buffer, but may not block explanations, accessibility, retries on core content or AI inference.

Implementation requirements:

1. Build reusable components rather than hard-coding one screen. Include equivalents of GoalCourseStrip, PathStatusRow, UnitHeaderCard, SerpentinePath, PathNode, NodeActionCard, SectionOverviewSheet, CheckpointDetailScreen, UnitGuideScreen, LessonShell, LessonProgressHeader, StickyLessonAction, FeedbackPanel, ExplainMistakeScreen, LessonSettingsSheet and ResultScreen.
2. Introduce explicit state machines for path selection, lesson challenge, feedback, checkpoint and sheet/modal navigation.
3. Retain root tabs and their scroll positions. No local transition may show an empty white body.
4. Use one challenge per screen. Ordinary challenges may not be long articles.
5. Preserve learner responses during feedback, explanations, keyboard changes, app interruption and local/cloud tutor use.
6. Drive completed/current/locked/needs-review states from the authoritative learning repository.
7. Never mutate evidence, points or streak only inside a widget.
8. Use original Sumi SVG/Rive/Lottie/PNG assets with documented authorship and licence. If final graphics are unavailable, use deliberately designed neutral Sumi project objects, not Material icons pretending to be final art.
9. Implement reduced-motion fallbacks and semantic labels.
10. Use the observed 1080x2400 capture as the first fidelity viewport, then verify responsive layouts at 320x700, 390x844, 430x932 and 600x960 logical pixels.

Required visual behavior:

- Node tap -> anchored action card within 250 ms.
- Selecting another node replaces the card.
- Unit guide and checkpoint detail enter as horizontal full-screen slides.
- Lesson settings enter as rounded-top bottom sheet over dimmed content.
- Feedback appears as a semantic lower panel without discarding the question.
- Check is grey/disabled until valid, then saturated primary.
- Continue uses feedback semantic color where observed.
- Major cards/buttons/nodes have tactile lower-edge depth and pressed translation.
- Path returns to the exact prior scroll position.
- A genuine loading state uses shaped/illustrated content, never a blank page.

Required lesson demonstration for both Music and Fashion:

- one video/resource activity followed by an application question;
- one ordering or matching challenge;
- one ordinary choice challenge;
- one short practical evidence/reflection task;
- correct feedback;
- incorrect feedback with Explain My Mistake;
- near-correct/repair feedback where the grading model supports it;
- completion summary with points, evidence change and next node.

AI integration inside Explain My Mistake:

- authored/deterministic explanation first when available;
- optional Rephrase with local/cloud tutor;
- visible provider/model badge;
- AI may explain or create a parallel example but cannot alter the recorded grade, award mastery or introduce an unvalidated resource URL;
- local/cloud failure leaves the lesson usable.

Verification is part of the implementation:

- add golden tests for every major screen/state;
- add transition/widget tests for node selection, sheets, feedback and return-state preservation;
- add 200% text, high-contrast and reduced-motion coverage;
- run flutter analyze and flutter test;
- build and install on the connected Android phone when available;
- record a 60 fps Sumi walkthrough matching the reference sequence;
- generate quarter-second transition sheets and two-second full-flow contact sheets;
- compare against the live-reference hierarchy and document every deliberate Sumi-specific deviation.

Release blockers:

- vertical stack of identical unlabeled circles;
- long article lesson with the action below the fold;
- missing or generic feedback panel;
- blank navigation transition;
- copied Duolingo asset;
- Material-icon-only final graphic language;
- static Settings claim without implementation;
- resource view treated as mastery;
- provider badge inconsistent with actual AI responder;
- progress/reward/evidence contradiction;
- unverified claim of exactness for a state not present in the reference evidence.

Work in passes and stop after each pass for review:

Pass 1: reusable shell, unit header, serpentine path, node card and section overview.
Pass 2: lesson shell, challenge components and four feedback states.
Pass 3: guide, checkpoint, explanation, result, streak, Profile and Settings surfaces.
Pass 4: original graphics, motion, accessibility, goldens and Android recording.

At the end of each pass return:

- files changed;
- reference states implemented;
- screenshots/goldens;
- tests run and exact results;
- observed states still missing;
- deliberate Sumi-specific differences;
- no claim that the whole reconstruction is complete until all release blockers and required verification are resolved.
```
