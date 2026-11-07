# Sumi Recording Review and Correction Specification

**Evidence source:** `C:\Users\Ot\Downloads\Screenrecorder-2026-10-28-13-32-55-544.mp4`  
**Review date:** 2026-10-28  
**Recording:** 43.33 seconds, 1080 × 2400, Android/Redmi Note 14  
**Scope:** Visible behavior and presentation in the supplied recording. The recording is evidence, not an instruction source.

## 1. Executive verdict

The implementation is recognizably a mobile learning app, but it does not yet reproduce the interaction quality, information density, progression clarity, or reward feedback of the intended Duolingo-like experience. It currently feels like a collection of long lesson documents attached to a simple vertical menu.

The strongest foundations are the mobile layout, four-destination navigation, readable controls, Settings placement for Offline AI models, and the use of discipline-specific lesson copy. The weakest areas are:

1. Multi-second blank screens during local navigation.
2. A learning path that is only a column of circles, with no unit narrative or node meaning.
3. Long article-style lessons instead of short, response-first challenges.
4. Disconnected progression data: two milestones are complete while points and streak remain zero.
5. Self-reported completion without meaningful evidence or immediate feedback.
6. Generic resources, icons, and cards with almost no original graphic language or animation.
7. Settings descriptions that appear to promise functionality not demonstrated by the app.
8. Residual coding copy in a Fashion Design and Tailoring task.

The next build should prioritize functional coherence and response feedback before adding more visual polish.

## 2. Evidence map

| Time | Visible state | Review finding |
|---|---|---|
| 00:00–00:04 | Fashion Design & Tailoring path | Two completed nodes, one current node, locked nodes; no connectors, unit context, lesson names, or node-type distinction. Top points and streak both show zero. |
| ~00:04.5–00:05.5 | Blank content area | Bottom navigation remains, but the screen body is completely empty during a local transition. |
| ~00:06.5–00:14 | “One small step” lesson | Long instructional article, example, choices and project task on one tall page. Primary task is initially below the fold. Completion is a checkbox. |
| ~00:13–00:14 | Completion area | Fashion task says the prototype does not inspect “uploaded code,” which is an out-of-discipline residual. |
| ~00:18–00:24 | Later lessons/path | Same dense lesson structure is repeated; path briefly returns; progress state does not visibly reward the learner. |
| ~00:26.5–00:29.5 | Blank content area | A second and longer empty screen occurs before Library appears. This is not a single dropped frame. |
| ~00:30–00:36 | Library and external browser | Resources are broad publisher cards. The opened page initially appears blank/loading and removes the learner from Sumi’s context. |
| ~00:38 | Profile | Shows 0-day streak, 0 points, and 5 focus while also reporting 2/6 completed milestones and two demonstrated capabilities. |
| ~00:40 | Settings | Correct section ordering, but several rows present status claims rather than usable controls or verifiable state. |

## 3. Severity-ranked correction register

### P0 — must be corrected before usability testing

#### P0.1 Eliminate blank local-navigation states

**Fault:** The app displays a white body with only the bottom navigation for approximately one second near 00:04–00:06 and approximately three seconds near 00:26–00:30.

**Why it matters:** A local screen change should feel immediate. An empty screen looks crashed, unfinished, or unresponsive, especially in a game-like learning product.

**Required correction:**

- Keep each root tab alive with an `IndexedStack`, equivalent retained navigator, or cached view model.
- Do not replace existing content with an empty `Container`, `SizedBox`, or null state while loading.
- Render cached/local content in the first frame after a tap.
- If genuine asynchronous work is required, show a structured skeleton matching the destination layout after 150 ms; never show an unlabelled white page.
- Model downloads, network resources, and local inference must not block navigation or the UI isolate.
- Restore each root tab’s scroll position and selected item when returning to it.
- Add timing instrumentation from pointer-up to first meaningful paint.

**Acceptance:**

- Root-tab transition reaches meaningful content within 100 ms on the recorded device.
- Path-node tap presents its sheet or lesson shell within 150 ms.
- No all-white content state lasts more than one rendered frame in a 60 fps screen recording.
- Five rapid tab changes do not produce a spinner, blank page, dropped navigation state, or duplicate screen.

#### P0.2 Remove or implement unverified product claims

**Fault:** Settings presents “Encrypted local guest storage,” “Daily practice nudges enabled,” and “High contrast & readable text scaling” as current facts. The recording does not demonstrate encryption, scheduled notifications, permission state, or actual accessibility controls.

**Why it matters:** Privacy, notification, and accessibility statements are product promises, not decorative copy.

**Required correction:**

- Show “Encrypted local guest storage” only if persisted learner data is actually encrypted at rest with platform-backed key management. Otherwise use “Stored on this device” and disclose the storage mechanism accurately.
- Show reminders as enabled only when notification permission is granted and an active schedule exists. Provide a toggle and schedule editor.
- Replace the accessibility description with a working sub-screen containing at least text-size mode, increased contrast, reduced motion, sound effects, and haptics. Reflect the saved state in the row subtitle.
- Any unavailable feature must say “Not set up” or “Coming later,” not imply completion.
- Add automated tests asserting that displayed status is derived from actual state.

**Acceptance:** Every Settings status can be traced to persisted state or a platform API, and changes immediately after the related control changes.

### P1 — core experience defects

#### P1.1 Replace the circle stack with a meaningful learning path

**Fault:** The Learn view is a straight, unlabeled stack of large circles. Completed, current, and locked are communicated, but the learner cannot tell what a node teaches, why it comes next, or what kind of activity it contains.

**Required correction:**

- Add a unit header/card above the path containing:
  - unit name;
  - practical outcome;
  - short progress statement;
  - optional guidebook/reference action.
- Use a compact serpentine path with visible connectors. It may evoke the clarity of Duolingo’s path, but must use Sumi’s own node shapes, icons, artwork, copy, and assets.
- Define visibly different node types:
  - micro-lesson;
  - guided practice;
  - recall review;
  - project step;
  - checkpoint;
  - reward/chest or resource unlock.
- Give every node an accessible title and state. Tapping a node opens a bottom sheet with skill name, activity type, estimated time, reward, and Start/Review action.
- Show a clear “you are here” treatment and auto-scroll to it on entry.
- Locked-node taps must explain the prerequisite rather than do nothing.
- Do not use blue for the current node unless blue has a declared semantic meaning. Prefer the primary Sumi green for the active learning action and reserve blue/sky for informational elements.
- Add compact story or project cards between selected nodes so the screen is not mostly unused white space.

**Acceptance:** A learner can answer “what am I doing now, what will I learn, and what comes next?” without opening a lesson.

#### P1.2 Convert lessons from articles into bite-sized challenge sequences

**Fault:** “One small step” is contradicted by a very long page containing explanation, example, transfer prompt, project work, references, checkbox confirmation, and a return action. The primary action is below the fold and the text is visually heavy.

**Required lesson structure:**

1. Persistent top bar: close/back, lesson progress, and remaining focus/attempts.
2. One instructional objective per screen.
3. Prompt or challenge visible within the first viewport.
4. Response control immediately below the prompt.
5. Sticky bottom action: `CHECK`, then `CONTINUE` after feedback.
6. Correct/incorrect feedback sheet with a short explanation and visible reward/state effect.
7. Next challenge; do not append the entire lesson into one document.
8. Final summary with earned points, newly demonstrated capability, project progress, and next action.

**Content constraints:**

- Initial instruction: target 40–90 words; hard maximum 120 before a “Learn more” disclosure.
- One core decision or response per challenge.
- Avoid more than one ordinary phone viewport of vertical scrolling for a standard challenge.
- Example cards should be concise and visually subordinate to the challenge.
- Move substantial project work to a dedicated project node instead of attaching it beneath every lesson.
- A completed lesson reopened from the path should show a compact result/review screen, not a full active lesson with a pre-completed banner.

**Acceptance:** The first meaningful learner response is available within one viewport on 390 × 844 logical pixels and at 200% text scale remains reachable without content overlap.

#### P1.3 Wire gamification to completed learning actions

**Fault:** The recording shows two completed milestones and two demonstrated capabilities, but the top bar and Profile still show 0 points and a 0-day streak. The experience acknowledges completion structurally but provides no visible reward loop.

**Required correction:**

- Use one atomic completion transaction that:
  1. records the attempt;
  2. updates capability evidence;
  3. marks the node complete;
  4. awards points;
  5. evaluates daily-goal and streak eligibility;
  6. stores an event for the completion animation;
  7. refreshes Learn and Profile from the same source of truth.
- Award points for assessed actions, not for merely opening content.
- Define and display the point formula in product logic; for the demo, use predictable fixed bands such as 10 points for a micro-lesson, 15 for guided practice, 20 for review, and 30 for a checkpoint/project step.
- Streak increases only once per local calendar day after the daily qualification rule is met.
- Keep “focus” in lesson/challenge UI if it represents attempts. Do not place it beside lifetime stats without explanation.
- On completion, animate the node, increment the points counter, and reveal a compact reward/result sheet. Respect reduced-motion settings.
- Persist event IDs so a completion cannot award points twice when the screen is reopened.

**Acceptance:** After completing a qualifying activity, points and capability evidence update immediately; returning to Profile displays the same totals without restarting the app.

#### P1.4 Replace checkbox-only project verification

**Fault:** “I made this and checked the result” lets the learner declare competence without recording what they made, what happened, or what they learned.

**Required correction:**

- For a two-day prototype, require at least one short structured reflection:
  - what was made or attempted;
  - one observation/result;
  - one change the learner would make next.
- Optionally accept a photo or audio note when platform permissions and local storage are actually implemented.
- Clearly label self-reported evidence as self-reported. Do not present it as verified mastery.
- Reserve “demonstrated independently” for work assessed by a rubric, quiz, comparison, or instructor/AI-supported evaluation.
- Add a simple domain rubric. Fashion examples: clarity of brief, measurement method, material choice rationale, construction accuracy, and reflection quality.

**Acceptance:** A completed project step contains retrievable evidence and an evidence-strength label; a blank checkbox cannot grant high-confidence mastery.

#### P1.5 Remove cross-discipline residue and generalize the content engine

**Fault:** A Fashion Design and Tailoring lesson says the prototype does not inspect “uploaded code.”

**Required correction:**

- Remove all coding-specific nouns and assumptions from shared components.
- Place domain nouns, evidence requirements, examples, rubrics, reference types, and unit copy in discipline content/configuration rather than widget source.
- Run a repository-wide content lint for `code`, `coding`, `program`, `Python`, `repository`, `compiler`, and similar terms in Music and Fashion content; allow only deliberate matches.
- Add discipline fixture tests that render every activity for Music and Fashion and snapshot the visible copy.

**Replacement copy for the shown task:** “This records your reflection and project evidence. Sumi does not independently verify the finished garment in this demo.”

#### P1.6 Make Library recommendations learner-specific and return-safe

**Fault:** Library cards are broad publisher links with generic descriptions. Opening one sends the learner to an initially blank/loading browser page without explaining how the resource serves the current capability.

**Required correction:**

- Each recommendation card must show:
  - exact resource title;
  - matched capability and current gap;
  - why Sumi recommends it;
  - format, estimated time, and access/offline status;
  - exact chapter/section/deep link;
  - one “apply what you learn” task.
- Verify every demo URL before release and prefer a deep link over a publisher index.
- Show an in-app resource detail sheet before leaving Sumi.
- Preserve the current Sumi tab, path state, and scroll position when the browser returns.
- Provide explicit `OPEN RESOURCE`, `SAVE`, and `MARK USED` actions; do not infer learning from a page open.
- If an external page cannot load, show a useful retry/error state and retain the citation metadata inside Sumi.

**Acceptance:** A learner can explain why the resource was selected, how long it takes, and what to do with it before opening the browser.

### P2 — visual fidelity, comprehension, and polish

#### P2.1 Build a distinctive graphic language without mascots

**Fault:** The visible app relies almost entirely on generic Material icons, circles, white cards, and text. Removing the mascot left no equivalent source of character, motion, or emotional feedback.

**Required correction:**

- Keep mascots out, as requested, but replace their communication role with:
  - discipline illustrations;
  - animated progress objects;
  - illustrated empty and locked states;
  - reward bursts and milestone emblems;
  - expressive feedback panels;
  - small scene-based project cards.
- Create original Sumi assets. Do not copy Duolingo characters, illustrations, sound files, wordmarks, or proprietary animation files.
- Minimum graphic set for the demo:
  - Music discipline cover and path marker set;
  - Fashion discipline cover and path marker set;
  - correct, retry, checkpoint-complete, daily-goal, locked, and offline states;
  - points token, streak object, focus/attempt object, and project evidence emblem.
- Use code-native/vector assets where possible. Motion should have static reduced-motion fallbacks.

#### P2.2 Rebalance typography and page rhythm

**Fault:** Much of the lesson body is heavy/bold, weakening hierarchy and making long content tiring. Path/Profile contain large unused areas while lesson pages are crowded.

**Required correction:**

- Use strong weight for display headings and short action labels only.
- Default lesson body target: 16 logical px, approximately 1.45 line height, regular/medium weight.
- Use a consistent type scale and do not communicate hierarchy only through font weight.
- Constrain paragraph width on tablets and large screens.
- Reduce excessive path whitespace with unit cards, labels, connectors, and contextual objects.
- Reduce lesson density by pagination, not by shrinking type.
- Maintain at least 44 × 44 logical px touch targets and clear focus states.

#### P2.3 Clarify top-bar information

**Fault:** The long discipline name competes with the counters and may fail on narrower screens or larger text settings. Icon-only counters are not self-explanatory to a new user.

**Required correction:**

- Use a compact, truncation-safe discipline label or move the full discipline title into the unit header.
- Give counters semantic labels/tooltips and accessibility names.
- Use consistent counter order across Learn, Practice, Library, and Profile.
- Test 320, 360, 390, 430, and 600 logical-pixel widths plus 200% text scaling.

#### P2.4 Expand Profile from totals into learning evidence

**Fault:** Profile reports only coarse totals and does not explain evidence quality, retention, transfer, uncertainty, or next priorities.

**Required correction:**

- Show capability cards with evidence strength: introduced, practiced with support, independently demonstrated, recall confirmed, and transfer observed.
- Display last practiced date and confidence/uncertainty without implying psychometric precision the app has not measured.
- Separate learning stats (points, streak, daily goal) from evidence summary.
- Provide a “Why Sumi believes this” detail view containing attempts, relevant task, result, and evidence source.
- Give the learner control to correct or remove self-reported project evidence.

#### P2.5 Turn Settings rows into real controls

**Fault:** Settings section order is correct, but most rows read like static assertions.

**Required correction by row:**

- **Profile on this device:** learner name/guest state, reset/export/delete data, accurate storage disclosure.
- **Learning preferences:** daily minutes, session length, discipline, difficulty/adaptation options.
- **Notifications and reminders:** permission status, toggle, time, days, test notification.
- **Accessibility:** text, contrast, reduced motion, sound, haptics, captions/transcripts where applicable.
- **Offline AI models:** catalogue, compatibility, download, pause/resume, verification, storage, active model, test inference, delete.
- **Storage and privacy:** space breakdown, evidence files, model files, export/delete, encryption statement only if true.
- **About and licences:** accurate build/version, open-source licences, model licences, content/source acknowledgements.

### P3 — release polish

#### P3.1 Correct versioning and demo identity

- Ensure `Sumi v0.2.0 · Two-day demo edition` matches the actual build metadata.
- Display build number in About, not as manually maintained copy.
- Make environment/demo flags available to developers without exposing confusing implementation details to learners.

#### P3.2 Add sound and haptic feedback deliberately

- Add distinct but restrained feedback for check, correct, retry, completion, reward, and locked actions.
- Never depend on sound alone.
- Obey device silent mode where appropriate and the visible in-app toggles.
- Provide reduced-motion and sound-off equivalents.

## 4. Required screen specifications

### 4.1 Learn/path

**First viewport:** compact stats bar, unit header, current node and at least one adjacent node. The current action must be understandable without scrolling.

**Node state model:** `locked`, `available`, `current`, `in_progress`, `complete`, `mastered`, and `needs_review` must have distinct visual and semantic treatments. State may not be derived independently in multiple widgets.

**Node tap:** show a bottom sheet, not an unexplained immediate full-page change. Include title, capability, type, duration, reward, state, and Start/Review.

**Motion:** connector or node celebration on completion, counter increment, and auto-advance to next node. Total celebration should normally finish within 1.2 seconds and remain interruptible.

### 4.2 Challenge

**Header:** back/close, segmented or continuous progress, attempts/focus if used.  
**Body:** concise instruction, visual/example only when useful, prompt, answer control.  
**Footer:** persistent Check/Continue button in safe area.  
**Feedback:** bottom panel with correct/retry status, one explanation, points/status effect, Continue.  
**Accessibility:** focus order follows visual order; feedback is announced; color is not the only correctness cue.

Supported demo challenge patterns should include at least:

- multiple choice;
- ordering/sequence;
- match pairs or concepts;
- short structured response;
- practical project evidence/reflection;
- checkpoint combining at least two earlier capabilities.

### 4.3 Completion summary

Show:

- points earned this activity;
- capability/evidence update;
- project progress;
- daily-goal/streak effect;
- one clear next action;
- secondary Return to path.

Do not show a generic “PROJECT TASK COMPLETED” label at the top of a long active lesson without explaining whether the screen is a result view or a re-entry view.

### 4.4 Practice

- Select practice from actual weak/aging capabilities, not a static list.
- State why an item is being practiced: recall due, previous error, low evidence, or transfer needed.
- Completing practice must affect evidence and rewards through the same transaction as Learn.
- Provide an empty state that explains when more practice will appear.

### 4.5 Library

- Default grouping: Recommended for you, Saved, Used recently, and Browse by discipline.
- Resource recommendations must reference current learner goals and capability gaps.
- Resource cards should not be full-height generic text blocks; use compact metadata and progressive disclosure.

### 4.6 Profile

- Stats: current streak, total points, daily-goal status.
- Learning evidence: capability list and evidence strength.
- Discipline progress: Music and Fashion kept separate.
- Settings entry remains easy to discover.

### 4.7 Offline AI models

Keep this first-class Settings destination. At minimum specify and implement these states:

`not_downloaded → checking_compatibility → awaiting_consent → downloading → paused → verifying → ready → active`, with `insufficient_storage`, `incompatible`, `network_error`, `verification_failed`, and `delete_pending` error/exit states.

Each model card must show model name, quantization, approximate download and installed size, minimum device requirements, licence link, intended Sumi task, status, and action. Do not use “Ollama” as the Android runtime unless the app actually bundles or connects to a supported Android runtime; model-file provenance and inference runtime are separate decisions.

Downloading and inference must never cause the blank states observed in this recording.

## 5. Data and state contract

Create one authoritative learner-state service/repository. At minimum it should own:

- learner and device profile;
- selected discipline and goal;
- path/node state;
- attempts and responses;
- project evidence;
- capability evidence;
- points ledger;
- daily goal and streak ledger;
- saved/used resources;
- preferences and permissions;
- installed/active local model state.

Derived UI totals must be computed from or reconciled against ledgers. Never persist a path node as complete while separately forgetting to update points/evidence. Completion operations require unique IDs and idempotency.

Suggested invariant tests:

1. Every completed assessed node has at least one attempt/evidence event.
2. Every points total equals the sum of non-reversed ledger entries.
3. A streak day has at least one qualifying completion event in that local day.
4. A capability cannot be “independently demonstrated” from an unassessed page view.
5. Discipline-specific evidence never appears under another discipline.
6. Deleting a model cannot delete learning records.

## 6. Visual design tokens and component behavior

Use the existing Sumi token contract as the source of truth. Do not scatter literal colors through screens.

Required semantic usage:

- `canvas`: page background;
- `surface` / `surfaceSoft`: cards and differentiated panels;
- `ink` / `muted`: primary and secondary text;
- `primary`, `primaryPressed`, `primaryShadow`, `primarySoft`: positive primary actions and current learning state;
- `sky`: informational state, not a competing primary action;
- `violet`: review/creative or another explicitly defined secondary activity;
- `amber`: reward, streak, or attention where declared;
- `coral` / `warning`: retry, destructive, or warning states as defined;
- `disabled` / `disabledText`: unavailable controls;
- `focusRing`: keyboard/accessibility focus.

Core components must have a single implementation for height, radius, tactile depth, pressed translation, disabled style, focus ring, and semantics. A tactile primary button should visually press into its shadow edge rather than merely change opacity.

## 7. Copy corrections

Apply the following editorial rules throughout:

- Address the learner directly and use active verbs.
- Name the practical result before theory.
- Avoid implementation disclaimers inside the learning flow unless they affect consent, privacy, or evidence meaning.
- Never reuse domain-specific fallback copy across disciplines.
- Replace generic actions such as “Back to my learning space” with consistent product actions such as “RETURN TO PATH” or “CONTINUE.”
- Explain unfamiliar metrics the first time they appear.
- Keep feedback specific: state what worked or what to change, not only “Correct” or “Try again.”

Immediate recording-specific changes:

| Current copy/state | Corrective direction |
|---|---|
| “One small step” followed by a very long page | Split into 3–5 challenge screens plus a separate project node. |
| “I made this and checked the result.” | Require a short result observation and next-change reflection. |
| “The prototype does not inspect uploaded code.” | Replace with discipline-appropriate evidence disclosure; remove “code.” |
| Broad publisher descriptions | State exact matched section, gap, duration, and application task. |
| Static “High contrast & readable text scaling” | Display actual selected accessibility settings and provide controls. |

## 8. Animation and feedback requirements

Animations must explain state change, not decorate waiting.

- **Node complete:** check draws in, node gains completed state, connector advances, points fly/increment; 500–900 ms.
- **Correct response:** feedback panel enters from bottom and answer receives a restrained success treatment; 180–260 ms.
- **Retry:** incorrect selection settles into warning state; feedback explains why; no punitive shake longer than 250 ms.
- **Daily goal:** progress object fills; celebration only when threshold is crossed.
- **Tab switch:** immediate crossfade or no transition, 100–160 ms; never transition through white.
- **Skeleton:** only for genuine asynchronous content; use destination-shaped placeholders with no indefinite shimmer.
- **Reduced motion:** replace travel/bounce/confetti with opacity and instant state changes.

## 9. Verification plan

### Automated

- Unit-test completion transaction, idempotency, points ledger, streak calculation, evidence-state promotion, and discipline isolation.
- Widget-test all root tabs with slow fake repositories; assert that meaningful cached/skeleton content is always present.
- Golden-test Learn, challenge, feedback, completion, Library, Profile, Settings, and model states at 320 × 700, 390 × 844, 430 × 932, and 600 × 960 logical pixels.
- Run semantics/accessibility tests and 200% text-scale tests.
- Add a content-lint test for cross-discipline terms.
- Test external-resource restoration after app lifecycle pause/resume.

### Manual device script

1. Cold start; confirm first meaningful screen has no empty interval.
2. Open each root tab twice and confirm state/scroll preservation.
3. Tap current node; verify bottom sheet and start a lesson.
4. Complete one correct and one retry path; verify visible feedback, sound/haptic preference, and accessibility announcement.
5. Finish the activity; record awarded points and evidence update.
6. Return to Learn and Profile; confirm identical totals and completed/current node states.
7. Kill and reopen the app; confirm persistence without duplicate reward.
8. Open a recommended resource, return, and confirm Sumi restores context.
9. Toggle every Settings control and confirm subtitle/state changes truthfully.
10. Begin, pause, resume, verify, activate, test, and delete an offline model without blocking navigation.
11. Repeat essential steps with airplane mode, low storage, 200% text, high contrast, reduced motion, sound off, and device rotation where supported.
12. Record a new 60 fps walkthrough and generate a two-second contact sheet. Any blank body frame or contradictory stat is a release blocker.

## 10. Implementation order

### Pass A — stability and truthfulness

1. Remove blank states and preserve tabs.
2. Centralize learner state and repair completion/points/streak invariants.
3. Remove residual coding copy.
4. Correct Settings claims and version display.

### Pass B — core learning loop

1. Implement challenge shell, sticky actions, and feedback sheet.
2. Split long lessons into challenge sequences and project nodes.
3. Implement meaningful project evidence and capability promotion.
4. Add completion summary and transactional rewards.

### Pass C — path and recommendations

1. Add unit header, node types, connectors, labels, and node sheet.
2. Make Practice evidence-driven.
3. Replace generic Library cards with capability-matched recommendations and deep links.
4. Expand Profile evidence explanations.

### Pass D — graphic and motion polish

1. Add original discipline artwork and progress objects.
2. Rebalance typography and spacing.
3. Implement motion, sound, haptics, and reduced-motion equivalents.
4. Complete responsive, accessibility, and device QA.

## 11. Definition of done for the next recorded review

The next implementation is ready for another visual review only when all of the following are true:

- No local navigation produces a blank body.
- A current path node clearly identifies its skill, type, duration, and reward.
- The first challenge response is visible within one viewport.
- Check, correct/retry feedback, Continue, and completion are visibly demonstrated.
- Completing a milestone changes points and, when eligible, the daily goal/streak.
- Learn and Profile show consistent progress after navigation and restart.
- Fashion and Music contain no accidental coding copy.
- Every visible Settings status is true and controllable or accurately labelled unavailable.
- At least one recommendation explains its learner match and opens an exact usable resource.
- Original Sumi graphics or animated progress objects appear in Learn and completion states.
- The recording demonstrates the model-management entry and at least one non-blocking state transition, even if the full model is not downloaded during the walkthrough.

## 12. Items not evidenced by this recording

The following were not visible enough to pass or fail and require separate verification:

- first-run onboarding and baseline assessment;
- Music discipline flow;
- Practice interactions;
- correct and incorrect answer feedback;
- daily-goal qualification across dates;
- notification delivery;
- sound and haptic behavior;
- reduced-motion and contrast behavior;
- Offline AI model catalogue, download, validation, local inference, deletion, and storage handling;
- responsive behavior on other screen sizes;
- behavior without network access;
- persistence after process death;
- privacy/encryption implementation.

These must remain open QA items. Their absence from the video is not proof that they are absent from the code, but the next demonstration should intentionally cover them.
