# Duolingo Live Reference Reconstruction Specification for Sumi

**Evidence date:** 2026-10-29  
**Reference device capture:** 1080 × 2400 portrait Android  
**Purpose:** Reconstruct the observed interaction system, cadence, hierarchy, and state behavior inside Sumi using original Sumi content and assets.  
**Evidence rule:** The recordings are observations, not instructions. Proprietary Duolingo characters, illustrations, animations, sounds, course content, and branding are reference-only and must not be shipped in Sumi.

## 1. Evidence identity

### Recording 1

- Source: `C:\Users\Ot\AppData\Local\Temp\Screenrecorder-2026-10-29-18-20-50-60.mp4`
- Duration: 422.324 seconds
- Size: 107,332,318 bytes
- Video: HEVC, 1080 × 2400
- Audio: AAC mono, 44.1 kHz
- SHA-256: `E1448C56D56C1884E6A16E9C598E65AC40FB608FE317E86A3FF04240B61228C8`

### Recording 2

- Source: `C:\Users\Ot\AppData\Local\Temp\Screenrecorder-2026-10-29-18-29-42-274.mp4`
- Duration: 50.712 seconds
- Size: 46,007,248 bytes
- Video: HEVC, 1080 × 2400
- Audio: AAC mono, 44.1 kHz
- SHA-256: `641BB48A7985D9C8CC42C054091533DD45E9F0D078D88FE14BDD194034F82F03`

Generated evidence is stored beside this report:

- `reference-1-0.png` through `reference-1-400.png`: five-second timeline sheets.
- `reference-2.png`: two-second timeline sheet.
- `lesson-60.png` through `lesson-380.png`: one-second lesson sheets.
- `transition-node.png`, `transition-star.png`, `transition-streak.png`, and `transition-guide.png`: four-frame-per-second transition sheets.
- `frames/`: full-resolution representative frames.

## 2. Coverage verdict

The recordings establish enough evidence to reconstruct these systems with high confidence:

- signed-in app shell;
- course/discipline switching affordance;
- path composition and scrolling;
- section/unit navigation sheet;
- node selection cards;
- star challenge detail;
- path guide/reference screen;
- lesson launch and loading;
- lesson progress and energy/hearts display;
- choice, word-bank, fill-blank, matching, listening, speaking, typing, drawing and tracing activities;
- disabled, ready, correct, incorrect, near-correct and speaking-retry feedback;
- detailed mistake explanation;
- lesson settings sheet;
- failed challenge result and return to path;
- energy screen;
- personal/friend streak screens;
- quests, feed, profile, settings, subscription and add-course screens;
- selected/unselected bottom navigation behavior;
- full-screen, sheet, popover, and anchored-card transitions.

The recordings do **not** establish:

- fresh-account onboarding;
- a normal successful lesson-completion summary;
- reward/chest opening sequence;
- daily-goal completion celebration;
- achievement-unlock animation;
- offline and network-error states;
- push-notification behavior;
- exact sound names or haptic patterns;
- accessibility screen-reader behavior;
- behavior at other viewport sizes;
- hidden backend scheduling or experiment rules.

Those areas remain unknown and must not be described as exact matches until separately recorded.

Android status/navigation bars, Dynamic Island/flashlight indicators, WhatsApp notifications, and other system overlays visible in some frames are excluded from the Duolingo UI specification.

## 3. Recording timelines

Timestamps are approximate because they are derived from passive video sampling.

### Recording 1 — broad application and lesson flow

| Time | Observed state |
|---|---|
| 00:00–00:06 | Bright-green launch screen with centered white wordmark, followed by signed-in path. |
| 00:06–00:20 | Japanese path, top course tabs, learner counters, course-update unit card, event badge, character scene and blue path nodes. An event/promotion screen is opened and dismissed. |
| 00:20–00:45 | Path scrolling and section/course overview sheet with vertically stacked section cards, progress bars, section ranges and `JUMP HERE`. |
| 00:45–01:00 | Profile overview and grouped Settings list. |
| 01:00–01:06 | Return to path and select an orange `JUMP HERE` checkpoint. |
| ~01:06–01:10 | Full-screen checkpoint invitation followed by an explicit loading screen. |
| ~01:10–03:07 | Multi-question checkpoint lesson with repeated immediate feedback, progressive energy/heart loss, varied choice/fill/word-bank tasks and eventual failure. |
| ~03:07–03:12 | Centered failure result: challenge not unlocked, blue Continue action, then return to path. |
| ~03:12–03:25 | Section overview and event promotion revisited. |
| ~03:20–03:40 | Quests and friend-nudge sheet. |
| ~03:40–03:58 | Feed and subscription screen. |
| ~03:58–04:35 | Writing-system learning surface and draw/trace exercises. |
| ~04:35–05:25 | Typing, listening and matching activities. |
| ~05:25–05:32 | Interstitial advertising/reward screen. |
| ~05:32–05:42 | Friend-nudge interruption and return to course. |
| ~05:42–06:15 | Course switching: French, Korean, Chess and Add Course; searchable/grouped language catalogue; Chess matches screen. |
| ~06:15–06:20 | Return to Japanese path and launch another lesson. |
| ~06:20–07:02 | Speaking, chat completion, translation and matching. An incorrect response opens `Explain My Mistake`; lesson settings opens a pronunciation/system sheet with End Session. |

### Recording 2 — path controls and reference hierarchy

| Time | Observed state |
|---|---|
| 00:00–00:06 | Sequential taps on path nodes show anchored blue action cards: review learned words, start practice, and review another node. |
| ~00:06–00:09 | Section overview appears as a white sheet/page over the path. |
| ~00:09–00:14 | Star challenge opens as a full-height detail screen with three stars, animated character, level, potential points and energy price. |
| ~00:14–00:22 | Return to path, locked unit-review card and lower `JUMP HERE` area. |
| ~00:22–00:25 | Energy management screen. |
| ~00:25–00:31 | Streak screen switches between Personal and Friends themes, then scrolls into calendar, streak goal and society content. |
| ~00:31–00:38 | Course-score popover and return to path; path changes to an earlier unit. |
| ~00:38–00:41 | Unit star challenge and earlier-unit path. |
| ~00:41–00:51 | Unit guide opens as a full-screen slide-in detail with hero, key phrases and blue teaching/tip sections. |

## 4. Observed application shell

### 4.1 Top course navigation

Observed:

- A black top region remains visually separate from the white learning surface.
- Course names are horizontally arranged in uppercase.
- The selected course is bright white with a short underline.
- Unselected courses are muted grey.
- Tabs can extend beyond the viewport, implying horizontal scrolling.
- Course switching retains the same shell while replacing the path beneath it.

Sumi reconstruction:

- Map course tabs to active goals or disciplines.
- Use the same persistent horizontal-selection grammar.
- Show only a manageable recent set plus an Add/Manage destination.
- Preserve each goal’s path position and progress independently.

### 4.2 Main white surface

Observed:

- The content body is a large white surface with heavily rounded upper corners beneath the black course strip.
- The shell contains a compact row of learner/course status above the unit card.
- Path content scrolls underneath fixed or visually persistent top/bottom chrome.

Sumi reconstruction:

- Treat the path as the primary root surface, not a list of unrelated cards.
- Keep outer chrome stable when changing units or selecting nodes.
- Do not transition through blank white content.

### 4.3 Status row

Observed status roles:

- course/learner badge;
- course score/currency-like count;
- streak;
- energy/attempt count.

The course score can open a small anchored popover while dimming the path.

Sumi mapping:

- discipline/goal badge;
- points;
- streak;
- focus/attempt buffer only where pedagogically justified.

Do not use focus as a paywall for explanations, accessibility or core learning. If Sumi keeps a mistake buffer, it must have a learning purpose and a non-punitive recovery path.

### 4.4 Bottom navigation

Observed:

- Six icon-only destinations are visible in the captured variant.
- The selected destination uses a pale-blue rounded-square container and stronger outline.
- Unselected destinations remain colorful, not greyed out.
- Navigation sits above the Android gesture area and is separated by a thin top border.

Sumi reconstruction:

- Preserve Sumi’s approved destinations, but reproduce the compact icon rhythm, selected tile, stable bar, safe-area spacing and instant switching.
- Do not add Duolingo-only social/store tabs unless Sumi has a real equivalent.
- A four-item labelled navigation can remain if required for comprehension, but its tactile selected state and proportions should match the observed shell quality.

## 5. Path system

### 5.1 Unit header

Observed:

- Large saturated card, rounded corners and a darker bottom depth edge.
- Small uppercase section/unit eyebrow.
- Large outcome title.
- A right-side guide/notebook segment on standard units.
- Card color changes across course/unit contexts.
- The card remains the dominant anchor above its path cluster.

Sumi reconstruction:

- Eyebrow: phase/unit number and activity status.
- Title: practical capability outcome.
- Guide segment: open unit guide, reviewed videos/materials and key ideas.
- Use Sumi color tokens while preserving depth, proportion and hierarchy.

### 5.2 Serpentine nodes

Observed:

- Nodes alternate horizontally in a loose serpentine route.
- Nodes are thick circular discs with a darker lower edge, inner highlight and icon.
- Icons communicate activity type: star, character/writing symbol, video/camera, arrows/review and other course-specific forms.
- Characters and contextual scenes sit adjacent to nodes and visually connect several activities.
- Small three-star rows appear beneath challenge scenes.
- Locked nodes are greyed but retain form and icon.
- The viewport deliberately shows the current cluster and nearby future nodes.

Sumi reconstruction node families:

- short concept lesson;
- reviewed video/resource;
- guided practice;
- retrieval review;
- project step;
- checkpoint/star challenge;
- optional reward/resource unlock.

Use original discipline objects and scenes in place of characters. For example, a Fashion path can stage fabric swatches, measuring tape, pattern pieces and a garment mock-up; Music can stage pulse, note, instrument and recording objects. These should perform the same orienting/emotional role without copying Duolingo art.

### 5.3 Node-selection card

Observed from `transition-node.png`:

- Tapping a node does not immediately navigate.
- A saturated blue rounded card appears anchored near the selected node.
- The card contains a concise action title and a wide white inset action button.
- The button copy includes action and reward, such as Start/Review plus XP.
- Selecting another node moves/replaces the card rather than stacking cards.
- Tapping outside dismisses it.
- Appearance is fast, approximately within a few hundred milliseconds; no loading state is shown.

Sumi reconstruction:

- Title: exact activity outcome.
- Metadata: duration, activity type and reason it is recommended.
- Primary white inset action: Start/Review and point reward.
- Optional secondary line: video length, offline availability or due reason.
- Locked selection uses the same anchored grammar but explains prerequisites.

### 5.4 Section overview

Observed:

- Opens over the path as a tall white surface with close control and centered course title.
- Section cards contain illustration/conversation art, title, lesson-number range and a compact progress bar.
- `JUMP HERE` appears as a placement/skip option on eligible sections.
- Scrolling reveals past and future sections.

Sumi reconstruction:

- Show phases/units for the selected goal.
- Each card states the practical capability range and completion fraction.
- Placement/skip must require a checkpoint, not a simple confirmation.
- Keep reviewed and provisional units visibly distinct.

### 5.5 Star challenge

Observed from `transition-star.png`:

- Opens as a full-height white detail screen sliding from the right.
- Close icon and centered unit name at top.
- Three empty star silhouettes communicate a three-level challenge.
- Animated/expressive scene dominates the upper-middle area.
- Clear promise: all-correct performance earns a star.
- Small cards show current level and maximum reward.
- Full-width blue action states an energy price.
- Returning to path reverses the full-screen navigation.

Sumi reconstruction:

- Use a mastery/checkpoint challenge with three evidence levels.
- Explain the acceptance rule before starting.
- Use original Sumi project/capability graphics.
- Do not charge currency for core content. If an attempt/focus cost is retained, provide a fair recovery path and never block essential learning permanently.

### 5.6 Unit guide

Observed from `transition-guide.png`:

- Opens from the path via a horizontal full-screen slide.
- White page with close control, small hero scene and centered section/unit title.
- `KEY PHRASES` section uses repeated rounded audio cards.
- Further scrolling reveals blue teaching panels and compact tables/examples.
- It is reference material, visually different from a scored lesson.

Sumi reconstruction:

- Use `KEY IDEAS`, `WATCH`, `REFERENCE`, and `TRY` sections.
- Video/material cards appear here as reviewed reference, while the path contains scored application activities.
- Keep the guide available after lesson completion.

## 6. Lesson system

### 6.1 Lesson shell

Observed:

- White full-screen lesson surface with no bottom app navigation.
- Top row contains settings/exit control, horizontal progress bar and hearts/energy count.
- Prompt heading begins near the top with large heavy text.
- Main question occupies the upper-middle viewport.
- Large empty space separates prompt from response controls when content is short.
- The primary action is pinned just above the gesture safe area.
- The action is grey and disabled until a valid response exists, then becomes saturated green.

Sumi reconstruction:

- Close/back, lesson progress and focus/attempt state at top.
- One challenge per screen.
- Prompt and response remain in the first viewport.
- Sticky Check/Continue respects safe area and keyboard.
- No article-length scrolling during an ordinary challenge.

### 6.2 Activity families observed

1. Select one correct translation from large stacked options.
2. Build a sentence using word-bank chips.
3. Fill a blank using stacked options.
4. Match pairs in a two-column grid; completed pairs fade/turn green.
5. Tap what you hear using large audio controls and selectable tokens.
6. Repeat after a character using microphone capture and live waveform state.
7. Complete a chat using speech bubbles.
8. Type characters using the native keyboard.
9. Draw a character freehand.
10. Trace a character against a guided stroke path.
11. Select characters from a visual grid.

Sumi equivalents should use the same interaction diversity where pedagogically appropriate:

- order process steps;
- match tools/materials/concepts;
- identify an example from image/audio/video;
- record or imitate a rhythm/pitch/fashion explanation;
- annotate/draw a pattern or musical contour;
- answer a contextual chat;
- choose the next project action;
- write a short observation;
- submit a practical reflection or evidence item.

Do not force every discipline into language-style word tiles. Reproduce the response cadence and state design, not irrelevant content mechanics.

### 6.3 Word-bank behavior

Observed:

- Available tokens are rounded white chips with light-grey outline and lower-edge depth.
- Selecting a chip moves it into the answer area.
- A grey placeholder remains in the bank, preserving layout stability.
- Selected answer chips can be returned/reordered.
- Answer area uses horizontal guide lines.
- Check remains disabled until a minimally valid answer exists.
- Correct tokens turn green in the answer area; incorrect tokens turn red.

Sumi reconstruction:

- Reuse the same stable-placeholder pattern for sequencing procedures, arranging project steps and constructing plans.
- Preserve chip positions to avoid layout jumps.

### 6.4 Feedback states

#### Correct

Observed:

- Selected answer receives pale-green fill and green outline/text.
- A pale-green panel fills the lower portion of the screen.
- Strong green status row uses varying affirmative copy: `Correct!`, `Awesome!`, `Nicely done!`, `Amazing!`, `Nice catch!`, `Good!`, or `Nice!`.
- Some feedback includes a short meaning/explanation line.
- Primary action becomes `CONTINUE` in saturated green.
- Small report/share/feedback icons remain available at the right.
- Feedback appears immediately and does not navigate away.

Sumi reconstruction:

- Keep the panel shape, timing and hierarchy.
- Feedback must say what was correct and connect it to the capability.
- Add points/evidence animation only after the assessed event is persisted.

#### Incorrect

Observed:

- Selected tokens/options turn pale red.
- Lower panel turns pale red with a strong red `Incorrect` title.
- The correct answer is displayed explicitly.
- Standard incorrect state shows solid red `GOT IT`.
- In the later lesson, an outlined `EXPLAIN MY MISTAKE` action appears above `GOT IT`.
- Energy/heart count decreases.

Sumi reconstruction:

- Preserve the answer and draft while showing the error.
- State the specific misconception or missing step.
- Provide Explain/Show another example and Continue/Retry.
- Never silently mark the capability complete.

#### Near-correct / repair

Observed:

- Amber/yellow lower panel.
- Copy such as `So close! Try again.`
- Continue action is amber.
- Used when the response is close enough to distinguish from fully wrong.

Sumi reconstruction:

- Use for minor ordering, spelling, measurement-unit or partially correct process errors.
- Do not promote this directly to independent evidence.

#### Speaking retry

Observed:

- Microphone button changes to active waveform while listening.
- Character expression changes across listening/result states.
- Unsuccessful capture shows amber feedback: `Hmm... that doesn't sound right. Give it another try.`
- Success shows green panel and a concise meaning/explanation.
- `CAN'T SPEAK NOW` remains a visible escape.

Sumi reconstruction:

- Music can use clap/rhythm/pitch or spoken reflection capture where technically supported.
- Fashion can use a spoken rationale or process explanation.
- Always provide a non-audio alternative.

### 6.5 Explain My Mistake

Observed:

- Opens as a dedicated white screen from the incorrect feedback panel.
- Back arrow and `Explain My Mistake` title.
- The learner’s incorrect token/phrase remains visible as compact chips.
- A large rounded explanation card uses highlighted terms, a plain-language explanation and examples.
- Thumbs-down/up controls collect explanation feedback.
- Full-width blue `CONTINUE LESSON` action.
- Returning restores the lesson rather than restarting it.

Sumi reconstruction:

- This is the correct location for AI assistance.
- Deterministic/authored explanation loads first when available.
- Local or cloud AI may rephrase or add a parallel example, with its provider badge.
- The AI cannot change the recorded grade or insert unapproved resources.
- Preserve the original attempt and resume at the next repair item.

### 6.6 Lesson settings

Observed:

- Opens as a rounded-top bottom sheet over a dimmed lesson.
- Pronunciation-system toggle/cards are presented visually.
- Full-width blue Done action.
- `END SESSION` is a lower-emphasis destructive/exit action.
- Closing restores the same exercise state.

Sumi reconstruction:

- Sound, haptics, captions/transcript, explanation density, data-saving mode and accessibility controls.
- Preserve unsent learner input.
- End Session requires confirmation when progress would be lost.

### 6.7 Failure result

Observed:

- When the attempt limit is exhausted, the challenge is not unlocked.
- Minimal centered white result screen with expressive illustration.
- Direct message: the unit was not unlocked and can be tried later.
- Single full-width blue Continue action.
- Continue restores the path around the attempted checkpoint.

Sumi reconstruction:

- Do not shame the learner.
- Explain that evidence was insufficient and identify one repair activity.
- Preserve every attempt and schedule targeted review.
- Core authored learning remains accessible even if a checkpoint is not passed.

## 7. Secondary systems

### 7.1 Energy

Observed:

- Separate white screen with current charge bar and recharge time.
- Subscription/unlimited option and multiple recovery mechanisms.
- Energy is visible from the path and lessons.

Sumi decision:

- Copying monetized energy gating would conflict with Sumi’s learning mission.
- If focus exists, use it as an attempt/recovery teaching device, not a paywall.
- Never charge for accessibility, explanations, retries on core material or local/cloud inference.

### 7.2 Streak

Observed:

- Full-screen overlay with close and share.
- Personal and Friends tabs.
- Personal theme is pale blue and includes streak count, freeze state, calendar, goal and society unlock.
- Friends theme switches to orange, changes hero art and lists friend streak slots.
- Tab switches recolor the major header surface quickly.

Sumi reconstruction:

- Personal streak and calendar are appropriate.
- Friends/social elements remain hidden until accounts and consent exist.
- Daily streak qualification must be tied to assessed learning, not opening the app or asking AI questions.

### 7.3 Quests

Observed:

- Purple header with illustration and concise reward promise.
- Friend quest card with shared progress and Nudge/Gift actions.
- Daily quest with progress and reward object.

Sumi reconstruction:

- Use personal daily/weekly learning quests first.
- Example: watch one reviewed demonstration and pass its application check; complete one due recall; add one project reflection.
- Do not reward video opening alone.

### 7.4 Profile

Observed:

- Large colorful identity header.
- Overview stats in a compact row.
- Friend-streak slots, monthly badges and achievement cards.
- Cards use vivid original artwork to prevent a stats-only appearance.

Sumi reconstruction:

- Goal identity/discipline header.
- Points, streak and project progress.
- Capability evidence and achievements separated from engagement totals.
- Original discipline badges and project milestones.

### 7.5 Settings

Observed:

- Plain grouped list with chevrons and section labels.
- Account, Preferences, Profile, Notifications, Courses, privacy, subscription and support are separated.
- Settings is information-dense and visually quiet relative to learning screens.

Sumi reconstruction:

- Retain the approved order, including first-class Offline AI models and Cloud AI/privacy.
- Every subtitle must reflect actual state.
- Use quiet list styling rather than promotional cards.

### 7.6 Add Course

Observed:

- Full-screen white selection screen.
- Mascot prompt at top.
- Featured options first, then grouped expandable language categories.
- Selection enables a persistent Continue action.

Sumi reconstruction:

- Discipline/goal chooser with reviewed disciplines first.
- “Something else” opens custom-goal intake.
- Continue remains disabled until a valid selection/outcome exists.
- Custom goals are provisional until AI output passes validation and the learner confirms it.

## 8. Motion and navigation grammar

Observed motion families:

1. **Anchored node card:** appears next to the tapped node in a few hundred milliseconds; replaces the prior node card.
2. **Horizontal full-screen slide:** star challenge, unit guide and mistake explanation enter from the right; previous screen remains briefly visible at the edge.
3. **Bottom sheet:** lesson settings and nudge controls rise from below with dimmed background and rounded upper corners.
4. **Top/anchored popover:** course score appears over a dimmed path while visually attached to the metric row.
5. **Immediate lesson swap:** Continue changes to the next challenge without returning to the path.
6. **Feedback rise/fill:** colored lower feedback panel appears immediately after Check while retaining the question above.
7. **Tab recolor/content swap:** streak Personal/Friends changes the header palette and content without leaving the modal.
8. **Loading state:** lesson start uses a deliberate centered loading illustration and text; it does not show an empty white body.
9. **Path animation:** character/object scenes change pose or state while nodes remain spatially stable.

Sumi timing targets inferred from the recording, to be validated by frame measurement:

- press response: 70–110 ms;
- anchored card: 160–240 ms;
- feedback panel: 180–260 ms;
- bottom sheet: 220–320 ms;
- full-screen slide: 220–320 ms;
- tab color/content transition: 150–240 ms;
- completion/reward animation: not established by these recordings.

These timings are design inferences, not directly measured implementation constants.

## 9. Visual construction rules

High-confidence observations:

- Very large corner radii are reserved for major cards/sheets.
- Buttons and path nodes use a darker lower edge to create tactile depth.
- Disabled controls use light grey fill and low-contrast white/grey label.
- Ready primary actions are highly saturated.
- Feedback uses pale semantic surface plus saturated text/action.
- Typography is heavy for prompt titles, compact and regular for supporting copy.
- Screens normally have one dominant primary action.
- White space is deliberately generous inside lessons, but path whitespace is occupied by nodes, scenes and progress context.
- Illustration communicates state, not merely decoration.
- Color is reinforced by icons, copy and state changes.

Sumi must reproduce these construction rules with its own token palette, icons and artwork.

## 10. Exact Sumi role mapping

| Observed Duolingo role | Sumi equivalent |
|---|---|
| Course tab | Goal/discipline tab |
| Course score/XP | Sumi points and goal progress |
| Streak | Qualified learning-day streak |
| Hearts/energy | Optional focus/attempt buffer with non-punitive recovery |
| Section/unit | Goal phase/unit |
| Unit guide | Key ideas, reviewed videos/materials and project references |
| Standard lesson node | Micro-lesson/challenge |
| Audio/video/story node | Reviewed media activity followed by application check |
| Star challenge | Evidence checkpoint/mastery challenge |
| `JUMP HERE` | Placement/skip checkpoint |
| Chest/reward | Resource pack, project badge or cosmetic reward |
| Explain My Mistake | Authored explanation plus optional local/cloud tutor rephrase |
| Quests | Daily/weekly assessed learning tasks |
| Feed | Private learning/evidence activity feed; social only after account approval |
| Add Course | Add discipline/goal |
| Character scenes | Original discipline illustrations and animated project objects |

## 11. Direct implications for the current Sumi implementation

The current Sumi vertical circle stack is not a close reconstruction. It lacks:

- the unit header as a path anchor;
- alternating node placement;
- multiple node families;
- contextual scenes;
- node-selection cards;
- section overview;
- guide/reference hierarchy;
- checkpoint detail;
- persistent lesson shell;
- one-screen challenge cadence;
- fixed Check/Continue action;
- semantic lower feedback panels;
- mistake explanation flow;
- explicit loading treatment;
- focused motion families;
- rich but controlled secondary systems.

The implementation agent should build these as reusable components and state machines rather than hard-code one Music or Fashion screen.

Required reusable Flutter components should include equivalents of:

- `GoalCourseStrip`
- `PathStatusRow`
- `UnitHeaderCard`
- `SerpentinePath`
- `PathNode`
- `NodeActionCard`
- `SectionOverviewSheet`
- `CheckpointDetailScreen`
- `UnitGuideScreen`
- `LessonShell`
- `LessonProgressHeader`
- `StickyLessonAction`
- `FeedbackPanel`
- `ExplainMistakeScreen`
- `LessonSettingsSheet`
- `ResultScreen`
- `StreakScreen`
- `QuestCard`
- `DisciplinePicker`

Every component must receive authoritative state from the learning repository and expose semantic accessibility labels.

## 12. Reconstruction acceptance criteria

### Path

- At 1080 × 2400, the shell, unit card, current cluster, bottom navigation and safe areas reproduce the observed hierarchy and density.
- Tapping a node presents an anchored action card within 250 ms without navigation or blank frames.
- Selecting a different node replaces the card.
- Standard, video, review, project, checkpoint, reward and locked nodes are visibly distinct.
- Unit guide and section overview open through the appropriate slide/sheet grammar.
- Returning preserves exact scroll position.

### Lesson

- No ordinary challenge requires article-length scrolling.
- Check is disabled until response validity is satisfied.
- Ready Check and Continue are pinned above the safe area.
- Correct, incorrect, near-correct and retry feedback match the observed lower-panel hierarchy.
- Incorrect state preserves the response and offers explanation/repair.
- Explain My Mistake returns to the same lesson session.
- Keyboard, microphone and external-resource round trips preserve state.
- A deliberate loading screen appears only for genuine work; no empty body is shown.

### Sumi learning integrity

- Resource/video viewing does not mark capability completion.
- Evidence, rewards and path state update only after successful persistence.
- Local/cloud AI can explain or propose but cannot award evidence directly.
- AI provider identity and reviewed/generated content are visible.
- Original assets replace every proprietary character/illustration role.

### Visual regression

- Create golden frames for the same 1080 × 2400 reference viewport and Sumi’s logical test viewports.
- Compare component geometry, not Duolingo copyrighted pixels.
- Establish masks for system status/navigation bars and dynamic text.
- Reject unexpected blank regions, shifted sticky actions, clipped prompts and missing feedback panels.
- Record all major transitions at 60 fps and generate quarter-second contact sheets.

## 13. Additional recordings needed for complete coverage

Please capture these separately if exact coverage is still the goal:

1. Fresh installation and complete onboarding.
2. A normal lesson completed successfully through its reward/result sequence.
3. Chest/reward opening.
4. Daily-goal and streak milestone celebration.
5. Review/Practice session selected from a due queue.
6. Offline launch and resource/network failure.
7. Notification/reminder settings and notification arrival.
8. Accessibility settings at large text and reduced motion.
9. Any video/story/adventure activity available in the account.
10. Press-and-hold, back gesture and interrupted/resumed lesson behavior.

Until captured, those states should use the existing Sumi contract and original design decisions, labelled as designed rather than observed.

## 14. Final reconstruction directive

The target is not “make Sumi green and round.” The target is:

> Reproduce the observed hierarchy, state transitions, one-action cadence, path orientation, challenge rhythm, feedback immediacy, tactile component depth, persistent navigation, and emotional reinforcement of the recorded Duolingo build—while replacing the language-learning content, proprietary art, branding, sounds and hidden commercial rules with Sumi’s arbitrary-discipline learning model, original assets, validated resources and evidence-based AI tutoring.

Any agent implementation that only adds circular buttons, bright colors and points has failed this specification.
