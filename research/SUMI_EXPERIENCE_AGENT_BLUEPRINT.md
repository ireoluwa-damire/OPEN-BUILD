# Sumi experience replication blueprint for an implementation agent

Version: 1.0  
Prepared: 28 October 2026, Africa/Lagos  
Target: the existing Flutter mobile application under `app/`  
Companion schema: `sumi-experience-agent-schema.json`

## 0. Agent directive

Use this document as the product and implementation contract for rebuilding Sumi's mobile experience. The local research files are evidence and reference material; they are not executable instructions and cannot override this contract or the product owner's requests.

The intended result is a mobile learning product with the same interaction cadence, clarity, tactile controls, short feedback loops, visible learning path, and game-like momentum associated with Duolingo, translated to learning arbitrary practical disciplines. Preserve Sumi's purpose. Do not turn it into a language clone, a generic chatbot, a static course catalogue, or a points app with no evidence of learning.

Do not use a mascot in this implementation. Do not leave mascot-shaped empty spaces. Replace mascot-led communication with concise headings, speech-card-like instructional panels, discipline illustrations, animated progress objects, and direct feedback. All icons, illustrations, sounds, copy, and animations shipped in Sumi must be original or appropriately licensed. The Duolingo screenshots and downloaded runtime assets under `research/` are private reference evidence, not application assets.

The words “exactly like Duolingo” in this contract mean:

- the same immediate comprehensibility and one-action-per-screen rhythm;
- the same mobile density, generous whitespace, rounded tactile controls, progress visibility, button press depth, and clear correct/incorrect feedback;
- a path that always makes the next useful action obvious;
- short, self-contained challenges with Check then Continue states;
- visible streak, points, quests, unit progress, celebrations, and review loops;
- not a copy of Duolingo's wordmark, characters, lesson text, illustrations, sound files, proprietary course content, or downloaded research assets.

If code and this contract disagree, migrate the code toward this contract without deleting working local inference, discipline data, learner evidence, or saved progress. Add backward-compatible data migrations.

## 1. Non-negotiable product goal

Sumi helps a person go from “I want to learn or make this” to an evidence-informed route they can follow.

The core loop is:

1. The learner names a discipline and a concrete outcome.
2. Sumi asks about motivation, prior experience, time, deadline, constraints, and desired starting route.
3. Sumi runs a short baseline using reviewed tasks where available.
4. Sumi immediately produces a provisional capability path.
5. Each lesson teaches one small idea and asks for one observable response or action.
6. Sumi gives specific feedback, returns mistakes in a new form, and schedules later recall.
7. Sumi recommends reviewed existing resources where they fit and generates only the missing connective material.
8. A later check updates the route, workload range, and explanation of why the path changed.
9. Completion means producing or demonstrating something, not merely tapping through lessons.

Current demo disciplines are:

- Music: pulse, duration, pitch, phrase, deliberate practice, and creation/review.
- Fashion Design & Tailoring: design brief, fabric choice, measurement, pattern/seam allowance, sample seam, finish/review.

The current evaluation window is a two-day product demonstration:

- Day 1: choose, assess, receive a provisional route, learn, practise, and try a project step.
- Day 2: complete new-example recall, compare evidence, revise the route, test offline coaching, and record usability feedback.

Never describe the two-day flow as proof of mastery, long-term retention, intelligence, or a stable learning speed. When the second check occurs before 24 hours, label it “early follow-up” or “accelerated demo check,” not “24-hour retention.”

The architecture must support a later seven-day calibration and continuing use without rewriting the data model.

## 2. Evidence used and confidence boundary

### Directly observed in the saved guest-mobile research

- A 390 × 844 mobile viewport.
- Landing screen with centered brand, large illustration, short promise, large primary action, and outlined returning-user action.
- Subject picker with one question and large selectable cards.
- A linear onboarding flow with back control, top progress bar, one primary decision per screen, and a disabled Continue button until the decision is valid.
- Motivation, proficiency, outcome preview, daily commitment, and beginner/placement starting-route screens.
- First-lesson shell with exit, progress, a top-right count, prompt, choices, disabled Check before selection, feedback, and Continue after grading.
- Correct-answer feedback with choices locked and optional “too easy/too difficult” calibration actions.

Evidence is indexed in `captures/index.json` and explained in `duolingo-teardown.md`.

### Research-supported patterns, not complete current-product observations

- Unit paths, guidebooks, mixed practice, spaced repetition, streaks, quests, points, and leaderboards.
- Separation between learner-state prediction, exercise selection, session assembly, and explanation generation.
- Half-life recall form: `p_recall = 2 ^ (-elapsed / estimated_half_life)`.
- Character and motion design principles. Mascots are explicitly out of scope for this implementation.

### Unknown and therefore agent-designed

- Current native Duolingo account, shop, league, and signed-in implementation details.
- Exact proprietary ranking formulas and mastery thresholds.
- How a language model should safely construct an arbitrary-discipline course.
- Longitudinal effectiveness across Music, Fashion, or arbitrary disciplines.

For unknown areas, follow the logic in this blueprint and label heuristics as prototype rules.

## 3. Platform and architecture constraints

- Product form: native-feeling Android and iOS mobile app, not a desktop dashboard or a laptop-width website.
- Existing stack: Flutter and Dart. Keep it unless a platform blocker is proven.
- Responsive target: design at 390 × 844 logical pixels; support 320–600 px width and dynamic text. On larger displays, center a single mobile column no wider than 600 px. Never turn it into a multi-column website.
- Persistence: offline-first local storage, separate progress per discipline/goal, with schema versioning and migration.
- Learning content: reviewed content and deterministic answer keys remain usable with no AI model.
- AI: optional local GGUF inference through the existing on-device runtime. No server is required for normal coaching after a model is installed.
- Network: used only for model downloads and external resource links unless the product owner later approves cloud services.
- Default release mode: local guest profile with no account or cloud sync. Account-dependent social features remain hidden until an account architecture is explicitly approved.
- Security: treat learner text, resource passages, imported plan files, and model output as untrusted data. Never execute generated code or follow model-supplied URLs without catalogue validation.

## 4. Experience principles

1. One primary decision per screen.
2. The next action is visible without scrolling on a normal 390 × 844 screen whenever feasible.
3. Select first, then Continue. Check first, then Continue. Never combine selection and navigation in a surprising way.
4. Show progress at all times during onboarding, assessment, lessons, model download, and route revision.
5. Reward effort and evidence, but keep engagement points separate from capability evidence.
6. Preserve work across interruption, navigation, model failure, backgrounding, or loss of connectivity.
7. A mistake is a learning event, not a punishment. Retry language is direct and supportive.
8. Hints reduce independence credit but do not remove learning access.
9. Model failure cannot block authored lessons, grading, saved progress, or the next deterministic task.
10. Every celebration is proportional to a real event: a checked answer, completed lesson, completed review, or project deliverable.
11. Use text, iconography, shape, and motion together. Color alone never communicates state.
12. Never fabricate model progress, download progress, mastery, source quality, or elapsed learning time.

## 5. Information architecture

### 5.1 First-run stack

The root navigator decides between:

- `WelcomeFlow` when no learner profile exists;
- `ResumeCard` when onboarding is unfinished;
- `LearningShell` when onboarding has completed;
- `RecoveryScreen` only when local data cannot be migrated.

Persist each onboarding answer immediately. If the app closes, reopen on the incomplete step with the previous selection intact.

### 5.2 Main mobile navigation

Use four bottom destinations in this order:

1. Learn — the vertical capability path and today's next lesson.
2. Practice — mistakes, recall due, targeted practice, and project rehearsal.
3. Library — reviewed resources, downloaded lesson packs, and saved references.
4. Profile — evidence summary, achievements, settings, and discipline switching.

Navigation bar behavior:

- 64–72 px height plus safe-area inset.
- Filled original icons at 24 px; label at 11–12 px, weight 700.
- Selected item uses a soft tinted rounded rectangle and tinted icon/text.
- Unselected items use muted gray.
- Keep state for every tab; do not rebuild the path scroll position on tab changes.
- Hide the bar during onboarding, lessons, assessments, modal project submissions, and model import.

### 5.3 Settings hierarchy

Open Settings from the Profile tab. Use these sections in this order:

1. Profile on this device.
2. Learning preferences.
3. Notifications and reminders.
4. Accessibility.
5. Offline AI models.
6. Storage and privacy.
7. About, licences, research acknowledgement, and build information.

“Offline AI models” is a permanent first-class settings section, not an onboarding blocker and not a card buried in the Learn tab.

## 6. Visual system

The application should feel bright, tactile, optimistic, and highly legible. Use a white canvas for core learning screens, large blank zones around primary content, thick rounded outlines, and a visible bottom edge/shadow on pressable controls.

### 6.1 Sumi palette

Use the following new Sumi-owned palette. It intentionally reproduces the emotional hierarchy of the reference while remaining a Sumi system:

| Token | Value | Use |
| --- | --- | --- |
| `canvas` | `#FFFFFF` | Main screen background |
| `surface` | `#FFFFFF` | Cards and sheets |
| `surfaceSoft` | `#F7F9FB` | Secondary panels |
| `ink` | `#3D4654` | Primary text |
| `muted` | `#737E8C` | Secondary text |
| `border` | `#E2E6EA` | Control borders and separators |
| `borderShadow` | `#D4D9DE` | Static raised-card bottom edge |
| `primary` | `#50C86A` | Primary action, progress, success |
| `primaryPressed` | `#3EA955` | Pressed/active primary |
| `primaryShadow` | `#319248` | Primary button 4 px bottom edge |
| `primarySoft` | `#DDF7E4` | Success/selected background |
| `sky` | `#2AA8E8` | Links, informational choices, streak recovery |
| `skyShadow` | `#1688C4` | Blue button depth |
| `violet` | `#A86BE8` | Challenge/review category |
| `amber` | `#FFBE3F` | Streaks, rewards, checkpoint stars |
| `coral` | `#FF6670` | Incorrect/error emphasis |
| `coralSoft` | `#FFE7EA` | Incorrect feedback background |
| `warning` | `#E99522` | Storage/thermal warnings |
| `disabled` | `#E5E8EB` | Disabled button |
| `disabledText` | `#A7AFB8` | Disabled labels |
| `focusRing` | `#2A8FD4` | 3 px accessibility focus |

Dark theme is deferred unless the product owner requests it. Do not ship an untested automatic inversion.

### 6.2 Typography

Use an original, redistributable rounded sans family with at least Regular, Semibold, Bold, and ExtraBold. If no bundled font is selected, use the platform sans during development and keep metrics stable.

| Role | Size / line height | Weight | Notes |
| --- | --- | --- | --- |
| Display promise | 30 / 37 | 800 | Centered, maximum 3 lines |
| Screen heading | 24 / 30 | 800 | Left or centered by template |
| Section heading | 20 / 26 | 800 | Unit headers and feedback |
| Card title | 17 / 22 | 700 | Choice labels |
| Body | 16 / 24 | 500 | Main instructions |
| Secondary | 14 / 20 | 500 | Explanations and metadata |
| Button | 14 / 18 | 800 | Uppercase only for the strongest primary action |
| Caption | 12 / 16 | 700 | Tags and stats |

Rules:

- Maximum body line length: 38–44 characters on the target phone.
- Never use less than 12 px rendered text.
- Support system text scaling through 200% without clipping.
- Avoid all-caps paragraphs; all-caps is limited to short button labels and category tags.
- Numbers in streaks and point counters use tabular figures.

### 6.3 Geometry and spacing

- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48.
- Screen horizontal padding: 16 px on 320–359 width, 20 px on 360–419, 24 px on 420+.
- Minimum touch target: 48 × 48 px.
- Primary button: full width, 56 px visual height plus 4 px bottom edge.
- Choice row: minimum 64 px, 16 px radius, 2 px outline, 3 px bottom edge.
- Subject card: minimum 156 × 180 px in a two-column grid at 390 px width.
- Standard card radius: 16 px; large sheet: 24 px; pill: 999 px.
- Path node: 72 × 72 px main circle with a 6 px visual bottom edge; checkpoint nodes may be 82 × 82.
- Avoid blur-heavy floating shadows. Use crisp bottom edges and subtle ambient shadow only for modals.

### 6.4 Button states

Every button has explicit enabled, pressed, focused, disabled, loading, and success states.

- Enabled: full color, 4 px bottom edge.
- Pressed: translate down 3 px, reduce bottom edge to 1 px, 80–120 ms.
- Focused: add 3 px focus ring outside layout.
- Disabled: flat disabled fill, no bottom edge, disabled text, no tap semantics.
- Loading: preserve width; replace leading icon with 18 px spinner; keep readable verb.
- Success: briefly show check icon, then navigate; do not delay more than 350 ms.

## 7. Graphic asset specification

Mascots are excluded. Do not import, redraw, trace, recolor, or animate Duolingo characters. Do not use the downloaded Lottie or Rive research assets in `app/assets`.

### 7.1 Required original graphic families

1. Sumi wordmark and compact app mark.
2. Discipline tiles:
   - Music: abstract beat grid with note/pulse shapes, not a character.
   - Fashion Design & Tailoring: thread path, needle/pattern lines, and fabric swatch.
   - General/custom goal: modular blocks connecting into a path.
3. Onboarding hero: small knowledge tiles flowing into a curved route ending at a project object.
4. Outcome icons:
   - build capability;
   - finish a project;
   - sustain a learning habit.
5. Path node icon set:
   - lesson/star;
   - review/rewind;
   - project/tool;
   - story/case study/book;
   - checkpoint/flag;
   - reward/chest;
   - locked/lock;
   - completed/check.
6. Exercise-format icons: select, type, order, diagnose, apply, submit artifact, listen, compare.
7. Reward icons: streak flame, points burst, spark currency, shield/recovery token, quest target.
8. Model icons: chip, download, pause, verify, ready/offline, warning, delete, import file.
9. Empty states for no reviews, no downloaded model, offline resource link, and completed path.

### 7.2 Asset delivery rules

- Prefer SVG for static icons and illustrations.
- Use Rive or Lottie only for original motion built for Sumi.
- Provide 1×/2×/3× raster fallbacks only when vector export is not reliable.
- Every animation has a poster frame and reduced-motion equivalent.
- Every asset includes author, licence, editable source, runtime export, logical size, and intended semantic label.
- Icons use a consistent 2.25–2.75 px stroke at 24 px with rounded joins.
- Never use emoji as final product icons because platform rendering is inconsistent.
- Do not convey a discipline with stereotypes or gendered assumptions.

## 8. Motion, feedback, haptics, and sound

Motion explains state change; it never blocks input or fabricates progress.

### 8.1 Global motion tokens

| Token | Duration | Curve | Use |
| --- | ---: | --- | --- |
| `press` | 100 ms | ease-out | Button depth |
| `micro` | 160 ms | ease-out | Check, icon, chip |
| `screen` | 220 ms | ease-in-out | Forward/back onboarding |
| `sheet` | 240 ms | decelerate | Feedback panel |
| `pathReveal` | 420 ms | emphasized decelerate | New path/section |
| `celebrationSmall` | 650 ms max | spring then settle | Correct/lesson complete |
| `celebrationLarge` | 1200 ms max | staged | Milestone/project only |

### 8.2 Event-to-animation contract

| Event | Visual | Haptic | Sound | Reduced motion |
| --- | --- | --- | --- | --- |
| Choice selected | Border recolors, soft fill, check slides in, 1.015 scale settle | selection click | soft tick | Instant fill/check |
| Primary pressed | Button translates down and shadow collapses | light impact | optional tap | Same short depth change |
| Answer correct | Choice turns green, check draws, feedback sheet rises, 6–10 small particles | success pattern | short two-note rise | No particles; instant sheet |
| Answer partial | Amber outline, rubric chips reveal | light impact | neutral tone | Instant chips |
| Answer incorrect | Correct answer highlighted after grading; selected card makes a 4 px two-cycle horizontal nudge | warning pattern | soft low tone | No shake; icon/text change |
| Hint shown | Hint card unfolds under prompt | selection click | none | Instant card |
| Lesson complete | Progress ring completes, points count up, one star expands | success pattern | short completion sting | Static completed badge |
| Unit checkpoint | Node ring traces clockwise and flag raises | medium impact | larger sting | Static completed node |
| Path revised | Old node positions fade to 60%; changed nodes slide to new locations; “why changed” card appears | none | none | Crossfade only |
| Streak maintained | Flame makes one 8% pulse; day count increments | light impact | short warm chime | Count changes only |
| Reward chest | Lid opens and reward rises; skip available | medium impact | reward chime | Instant reward panel |
| Download | Circular/linear indicator follows actual bytes only | none | none | Same real indicator |
| Model verified | Hash/ready check draws and offline badge appears | success pattern | short ready tone | Instant check/badge |
| Model error | Progress stops, warning card appears, retry remains enabled | warning pattern | none | Same static state |

### 8.3 Motion rules

- Pause loops when the application backgrounds.
- Cancel or error interrupts “thinking” immediately.
- Generation animation may show activity but cannot imply percentage unless the engine provides real progress.
- Preserve controls while animations run.
- Never auto-play sound after the user has disabled effects.
- Respect `reduceMotion`; replace spatial transitions with crossfades under 120 ms or immediate state changes.
- Do not use mascot reactions. Feedback lives in controls, path objects, particles, typography, and discipline graphics.

### 8.4 Sound system

Create original or licensed sounds for: tap, select, correct, partial, incorrect, lesson complete, streak, reward, and model ready. Each is under 1.5 seconds except the optional large milestone cue. Default sound effects on, with a first-class Settings toggle. Never use audio as the only feedback.

## 9. Complete screen and flow specification

### 9.1 Launch / promise

Purpose: explain the product before technology.

Layout from top to bottom:

- Safe area.
- Centered Sumi wordmark, 132–160 px wide.
- Flexible whitespace.
- 220–250 px original onboarding hero.
- Centered promise: “Learn anything by doing it, one clear step at a time.”
- Optional one-line support: “A route that adapts to what you can show.”
- Flexible whitespace.
- Full-width primary “GET STARTED”.
- Full-width outlined “CONTINUE MY PROGRESS” only when recoverable local progress exists; otherwise “I ALREADY HAVE A PROFILE” remains hidden until accounts exist.
- 20 px bottom safe spacing.

No carousel, feature list, model explanation, or permission prompt on this screen.

### 9.2 Choose a discipline

Heading: “What do you want to learn?”

Cards:

- Music — “Rhythm, pitch, practice, and creation.”
- Fashion Design & Tailoring — “Design, measure, construct, and refine.”
- Something else — “Describe any skill or project.”

Each card contains an original 72 px discipline graphic, title, and one concise subtitle. Use a two-column grid; the custom goal card may span two columns. Selecting a card advances immediately only when the choice does not need free text; custom opens a bottom sheet and then continues.

### 9.3 Define the outcome

Heading: “What would you like to be able to do?”

Inputs:

- Multiline outcome, 20–200 characters.
- Optional deadline: none, 2 weeks, 1 month, 3 months, custom date.
- Optional constraints chips: phone only, low bandwidth, no equipment, beginner materials, accessibility need, other.

Show 2–4 track-specific prompt chips. Examples:

- Music: “Keep a steady rhythm”, “Write a four-bar pattern”, “Understand basic notation”, “Practise a song effectively”.
- Fashion: “Make a simple tote”, “Draft a basic pattern”, “Learn accurate measurements”, “Build clean seams”.

Primary action: “CONTINUE”; disabled until outcome is valid. Never generate a route on every keystroke.

### 9.4 Motivation

Heading: “Why does this goal matter to you?”

Single-choice rows:

1. Finish a real project.
2. Support my education.
3. Improve my career.
4. Spend time productively.
5. Express myself creatively.
6. Build a lasting habit.
7. Just for fun.
8. Something else.

Each has an original 28–32 px icon. Continue stays disabled until selection. After selection, update one support line without adding another screen, for example: “We’ll keep each task connected to your project.”

### 9.5 Self-reported starting level

Heading: “How much experience do you have with this?”

Single-choice rows:

1. I’m completely new.
2. I know a few terms or basic ideas.
3. I can complete simple tasks with guidance.
4. I can work independently on familiar tasks.
5. I can handle varied tasks and explain my choices.

Use self-report only to choose the first baseline difficulty. It never directly grants mastery.

### 9.6 Outcome preview

Heading: “Here’s what your route will help you do.”

Show exactly three outcome rows with 48 px icons:

1. Understand the essential ideas for the named outcome.
2. Complete a small observable project or performance.
3. Build a repeatable practice and review habit.

For reviewed disciplines, replace generic labels with track-specific capabilities. For custom disciplines, label the list “provisional” until validated.

Primary action: “CONTINUE”. This is a reassurance screen, so no selection is required.

### 9.7 Daily commitment

Heading: “What’s your daily learning goal?”

Choices:

- 5 min/day — Casual.
- 10 min/day — Regular.
- 15 min/day — Serious.
- 20 min/day — Intense.

Default: none. Continue disabled until selection. On selection, show a workload sentence calculated from the current provisional route, e.g. “At 10 minutes a day, the first project is roughly 7–10 sessions.” Always use a range and label it provisional.

### 9.8 Starting route

Heading: “Let’s find the best place to start.”

Choices:

- Start from the basics — “Begin with the first foundation and still answer a few light checks.”
- Find my level — “Try a short baseline so Sumi can recommend a starting point.”

Both routes collect some evidence. Basics gets three lower-difficulty checks embedded in the opening lesson. Find my level gets the six-question baseline. Neither skips the project goal.

### 9.9 Baseline

Use the lesson shell described in section 10. For the current reviewed tracks, present six questions. Include multiple choice, an “I don’t know yet” action, and at most one optional hint per item.

Baseline scoring rules:

- Record the first response permanently.
- Correct, unhinted first response: independent evidence.
- Correct after hint: supported evidence.
- Incorrect then corrected: repair evidence, not independent evidence.
- Skip: no evidence; never count as wrong for identity labels.
- Active time excludes model wait, background time, and feedback-reading time.
- Do not display a single intelligence percentage.

After the last item, show a route-reveal screen rather than a grade screen.

### 9.10 Route reveal

Heading: “Your first route is ready.”

Show:

- goal summary;
- “Based on 6 starting checks” or exact evidence count;
- 3–6 visible capability nodes;
- first milestone deliverable;
- estimated session range;
- confidence label: low/early, growing, or supported;
- “Why this route?” expandable card listing observed evidence and assumptions;
- primary “START FIRST LESSON”.

Run the short path-reveal animation. Do not mention a model unless a model actually contributed. If no local model is installed, use deterministic route logic and continue normally.

### 9.11 Learn path

Top stats row:

- discipline switcher icon;
- streak days with flame;
- points with star/burst;
- focus buffer with heart/shield icon.

The focus buffer preserves the familiar top-right count but cannot lock learning. Start each lesson at 5. A first-try incorrect answer reduces the session buffer by one and reduces only the optional flawless-session bonus. At zero, the learner continues with the same content and receives a “Practice mode” label. Do not demand payment, ads, or waiting.

Path layout:

- A full-width colored unit header with unit number, title, short outcome, and guidebook icon.
- A vertical serpentine path with nodes alternating center, left, center, right.
- Connectors are 6–8 px soft gray; completed segments become primary color.
- The current node has a looping 2 px breathing ring unless reduced motion is on.
- Tapping a locked node explains the missing prerequisite.
- Tapping a current/unlocked node opens a bottom sheet with lesson title, objective, reward, and “START”.
- Path objects include lessons, targeted practice, a case/story node, reward chest, checkpoint, and project task.
- The page auto-scrolls once to the current node on entry, then respects user position.

Node states:

- locked: gray fill, lock icon, no bottom shadow;
- available: primary fill, white icon, dark primary shadow;
- current: available plus white outer ring and small “START” flag;
- completed: white/primary-soft fill, primary outline, check/star;
- review due: violet fill, rewind icon;
- project: amber or sky fill, tool icon;
- checkpoint: larger ring with flag;
- perfect: optional gold crown/star, never required for route progress.

### 9.12 Daily quests

Show three small quests in a collapsible card above the current unit or in Practice:

- Complete one lesson.
- Answer three challenges independently.
- Spend the selected daily minutes in active learning or complete one project step.

Quests refresh at local midnight. Missing a quest does not damage capability evidence. Completion awards engagement points and a small chest. Use transparent values and no random paid loot.

### 9.13 Practice tab

Sections in order:

1. Review due — scheduled recall items.
2. Repair mistakes — new examples for recent errors.
3. Strengthen a capability — learner chooses a node.
4. Rehearse the project — one integrated task.
5. Early follow-up / Day 2 check — only during the demo window.

When there is no due practice, show “You’re caught up” and offer a non-penalizing optional practice button.

### 9.14 Library tab

Resource cards show:

- title and publisher;
- exact capability match;
- format, level, estimated time, and access requirement;
- why Sumi recommends it;
- canonical link;
- “Try a related task” action.

Filter first by prerequisites, language, cost, device/bandwidth constraints, and goal relevance. Semantic ranking is secondary. Reject model-invented URLs or resource IDs. Opening a resource never marks a capability complete. After returning, offer an application check.

### 9.15 Profile and evidence

Show engagement and learning evidence separately.

Engagement panel:

- streak days;
- points this week;
- lessons completed;
- quest completion.

Evidence panel:

- capabilities first exposed;
- supported successes;
- independent successes;
- delayed/early follow-up results;
- transfer/project evidence;
- uncertainty and evidence count.

Use sentences such as “You solved 3 rhythm-counting examples without a hint” rather than “You are a fast learner.”

### 9.16 Settings

Learning preferences:

- daily minutes;
- current goal/deadline;
- exercise mix;
- reminder window;
- sounds and haptics;
- discipline management.

Accessibility:

- use system text size;
- reduced motion;
- high contrast;
- always show captions/transcripts;
- color-independent feedback;
- screen-reader verbosity.

Storage and privacy:

- local progress storage summary;
- export progress JSON;
- import compatible progress;
- clear one discipline;
- clear all progress;
- explicit note that model downloads are separate from learner progress.

## 10. Lesson and challenge shell

### 10.1 Layout

Header:

- 48 px exit button at left.
- 8–10 px rounded progress bar filling remaining width.
- focus-buffer icon and count at right.

Body:

- optional 12 px category tag such as NEW IDEA, PRACTICE, REVIEW, PROJECT;
- heading prompt, 24 px/30 px, weight 800;
- optional concise context, example, audio, image, or diagram;
- one response format only;
- flexible whitespace so controls do not feel crowded.

Footer:

- sticky bottom action area over white surface with top divider;
- “CHECK” disabled until response is valid;
- after grading, feedback sheet replaces the neutral footer and contains “CONTINUE”.

### 10.2 Explicit lesson state machine

`loading -> unanswered -> selected -> submitting -> correct | partial | retry | error -> continuing -> next | completed`

Rules:

- `loading`: content skeleton only; no fake selectable choices.
- `unanswered`: Check disabled.
- `selected`: chosen response visibly highlighted; Check enabled.
- `submitting`: choices locked; preserve response.
- `correct`: show explanation, points, and Continue.
- `partial`: show passed/failed rubric chips and one specific next action.
- `retry`: show supportive explanation; queue a parallel item later in the same lesson.
- `error`: preserve response; Retry grading and Continue offline only if deterministic grading exists.
- `completed`: commit lesson summary transactionally before celebration.

Exit behavior:

- If no response is in progress, exit immediately.
- If a response or artifact is unsaved, confirm: “Keep progress and leave?” with “KEEP LEARNING” and “SAVE & EXIT”.
- Never discard completed checked items.

### 10.3 Challenge formats

Every capability may use:

1. Multiple choice — recognition and misconception check.
2. Short explanation — teach-back; model-suggested rubric with uncertainty.
3. Order steps — process knowledge.
4. Diagnose a mistake — causal understanding.
5. Apply to a new case — transfer.
6. Submit an artifact or self-review — practical production.
7. Listen/perform/observe — only when the app has a real input/evaluation path; otherwise clearly self-reviewed.

For Music in the current demo, do not claim the app listens to or grades audio. Use beat grids, counting, note/pitch diagrams, self-recorded observations, and optional playback tools.

For Fashion in the current demo, do not claim image inspection or professional construction grading. Use paper mockups, measurement calculations, sequence decisions, seam diagrams, and structured self-review.

### 10.4 Correct feedback panel

- Background: `primarySoft`.
- Heading: “Correct!” or “Nice work.”
- Explanation: 1–3 sentences, no more than 240 characters before expansion.
- Points chip: `+10` plus earned bonus breakdown on tap.
- Calibration actions: Too easy, Too hard, Report issue. These affect selection difficulty, not recorded correctness.
- Full-width primary Continue.

### 10.5 Incorrect feedback panel

- Background: `coralSoft`.
- Heading: “Not quite yet.”
- Show the correct principle, not merely the letter/index.
- One specific explanation and optional “Show hint”.
- Continue button moves on and requeues a parallel item near the lesson end.
- Never display shame language, angry imagery, or a forced wait.

### 10.6 Partial feedback

- Background: pale amber.
- Heading: “Almost—one part needs work.”
- Rubric rows with passed, missing, and uncertain states.
- Learner may revise once or continue; preserve both attempts.

## 11. Gamification system

### 11.1 Points

Points measure participation, not mastery.

- Checked challenge: +10.
- First-try correct: +5.
- Correct without hint: +5.
- Completed lesson: +20.
- Completed due review: +15.
- Completed project step: +25.
- Daily quest: +10 each.
- Perfect lesson bonus: +20 when focus buffer remains 5 and no hints were used.

Do not award duplicate points for reopening a completed challenge. Store immutable reward transactions with source IDs.

### 11.2 Streak

A streak day is earned by either:

- completing one lesson or due review; or
- recording one real project step with required reflection.

Opening the app, downloading a model, viewing a resource, or asking the AI a question does not count.

Use learner-local calendar days. Provide one recover token after a seven-day streak and at most two stored tokens. A token covers a missed day but does not fabricate learning evidence. Show the exact action that maintained the streak.

### 11.3 Focus buffer

- Starts each lesson at 5.
- First-try incorrect response: minus 1.
- Hint use: no loss, but perfect bonus becomes unavailable.
- At zero: switch label to Practice mode; learning remains available.
- Reset at the next lesson.

This gives the familiar visible count without imposing a learning paywall.

### 11.4 Sparks currency

Optional engagement currency. Earn through quests, checkpoints, and projects. Spend only on cosmetic themes, optional celebration styles, or streak-recovery tokens. Never spend it to unlock core content, retries, explanations, accessibility, or model inference.

### 11.5 Quests and achievements

Daily quests use the three transparent templates in section 9.12. Weekly achievements may include:

- three days active;
- first independent transfer task;
- first finished project step;
- first model-assisted plan that passes validation;
- first offline session.

Do not use a fake leaderboard while the app is guest-only. Keep leaderboard UI hidden behind an explicit future account/social feature flag.

### 11.6 Mastery/evidence states

These states are separate from points:

1. `unseen`.
2. `exposed` — content viewed or first attempt made.
3. `supported` — success with hint/scaffold or after correction.
4. `independent` — first-try success without hint on a reviewed item.
5. `recalled` — independent success on a new item after a meaningful delay; label early checks honestly.
6. `transferred` — capability applied in a different context or project artifact.
7. `needs_review` — evidence decayed or a recent new example failed.

Never collapse these into a single IQ, talent, or learning-speed label.

## 12. Adaptive learning and AI logic

### 12.1 Required separation of responsibilities

- Learner-state service: records evidence and uncertainty.
- Scheduler: deterministic prerequisite and review rules.
- Session assembler: chooses format, difficulty, and ordering.
- Local generative model: drafts explanations, parallel items, and plans under a schema.
- Validator: rejects missing capabilities, cycles, unapproved resources, impossible workload, malformed grading, and unsupported claims.

The model is never the only source of truth for deterministic multiple-choice grading or current reviewed course structure.

### 12.2 Arbitrary-discipline creation

When the learner chooses Something else:

1. Collect outcome, context, deadline, available minutes, equipment, constraints, and prior experience.
2. Ask the model for a provisional capability graph with observable outcomes.
3. Validate IDs, acyclicity, workload, safety flags, and no invented links.
4. Show the learner a plain-language summary and ask them to confirm or edit the outcome.
5. Start with low-confidence labels and authored generic assessment formats.
6. Add external resources only from a reviewed catalogue. If none exist, state that Sumi will use generated explanations and learner-supplied references.
7. Require an observable project/demonstration at the final milestone.

For high-risk disciplines such as medical procedures, weapons, dangerous machinery, financial decisions, or legal representation, the plan must narrow to safe educational theory or request expert-supervised context. Never create dangerous hands-on instructions merely because a local model suggested them.

### 12.3 Plan output contract

Required fields:

```text
goal_id
plan_version
evidence_cutoff
discipline
outcome
assumptions[]
missing_information[]
confidence {level, explanation, evidence_count}
capabilities[] {id, title, observable_outcome, prerequisite_ids[], safety_notes[]}
units[] {
  id, title, description, capability_ids[],
  lessons[] {
    id, objective, instruction_summary, challenge_ids[], resource_ids[],
    estimated_minutes_min, estimated_minutes_max, reward_points
  },
  checkpoint {challenge_ids[], acceptance_criteria[]}
}
reviews[] {capability_id, due_rule, item_pool_ids[]}
project {title, deliverables[], acceptance_criteria[], self_review_questions[]}
estimated_completion_window {min_sessions, max_sessions, assumptions[]}
next_recalibration
change_reason
```

Validation:

- all referenced IDs exist;
- no prerequisite cycles;
- every lesson maps to at least one capability;
- every capability has an observable outcome;
- every checkpoint uses a different example from instruction;
- only approved resource IDs are used;
- workload fits the learner's daily minutes or the app asks to change scope/deadline;
- safety flags are resolved;
- no mastery claim is produced from engagement data alone.

### 12.4 Review scheduling

Prototype deterministic schedule:

- incorrect: parallel repair item in the same lesson and review next day;
- correct with hint: review next day;
- independent correct: review in 2 days;
- independent recall: review in 5 days;
- transfer success: review in 10 days or at the next project dependency;
- new failure: bring review forward and keep earlier evidence.

HLR may later prioritize within a due queue, but do not copy language-model parameters into unrelated disciplines without validation. Always expose why an item is due.

## 13. Offline AI models in Settings

Route: `Profile -> Settings -> Offline AI models`.

### 13.1 Model landing screen

Header: “Offline AI models”.

Intro card:

- “Download once. Use privately on this device.”
- Explain that authored lessons work without a model.
- Explain that the model drafts plans/explanations and can be wrong.
- Show total device RAM, free app storage, and supported runtime/ABI.

Recommended card appears first based on device checks, never solely model popularity.

### 13.2 Initial catalogue

- Qwen3 0.6B GGUF, Q8_0, about 639 MB, suggested 3 GB total RAM.
- Qwen3 1.7B GGUF, Q8_0, about 1.83 GB, suggested 5 GB total RAM.
- DeepSeek R1 Distill Qwen 1.5B GGUF, Q4_K_M, about 1.12 GB, suggested 4 GB total RAM.

Show exact repository, revision, filename, size, quantization, licence, hash-verification status, and plain-language capability note. State clearly that DeepSeek V4.1 is not the small phone model.

### 13.3 Model state machine

`not_downloaded -> confirming -> queued -> downloading <-> paused -> verifying -> installed -> loading -> ready`

Failure branches:

- insufficient storage;
- network unavailable;
- interrupted download;
- hash mismatch;
- incompatible architecture;
- insufficient memory/load failure;
- generation cancelled;
- runtime error;
- imported file unverified.

Every failure has a human-readable cause, preserved partial download when safe, and one primary recovery action.

### 13.4 Download interaction

Before download show:

- exact size and current free storage;
- Wi-Fi recommendation and cellular confirmation;
- RAM guidance as estimate, not guarantee;
- source/repository and licence;
- note that the app must remain open if background download is unsupported.

During download show:

- model name;
- bytes downloaded / total and percent based on bytes;
- speed and estimated time only when measured over a stable interval;
- Pause/Stop control;
- safe navigation warning if the platform cannot continue in background.

After bytes complete:

- separate “Verifying file…” state;
- SHA-256 comparison;
- then “Installed”; not “Ready” until the runtime loads successfully.

### 13.5 Installed model actions

- Use this model.
- Test local inference.
- View licence and source.
- Rename imported display label only.
- Remove model with confirmation.
- Import compatible single-file GGUF up to the tested app limit.

Removing a model never removes learning progress. Clearing learner progress never removes models unless the user explicitly selects both.

### 13.6 Local inference test

The test:

- loads the selected model;
- sends a fixed, harmless two-sentence coaching prompt;
- displays time to first token, total generation time, cancellation, model name, and local/offline badge;
- does not mark any learning task complete;
- can be repeated after the user disables connectivity.

Generation UI shows streaming text, Stop, Retry, and Copy. If generation fails, deterministic lessons and route remain usable.

### 13.7 Runtime and privacy

- Use the existing llama.cpp-compatible phone runtime.
- Hugging Face may supply model files; Ollama is not required inside the Android app.
- Store models in app-private storage.
- Verify known catalogue models by hash.
- Never upload learner prompts, attempts, or model output by default.
- Display thermal/battery warning after sustained generation if platform signals are available.
- Cap prompt and generation tokens to prevent runaway latency and memory usage.

## 14. Data model

Use stable string IDs and version every mutable content entity.

### LearnerProfile

- `id`, `schema_version`, `created_at`, `locale`, `timezone`.
- `onboarding_step`, `onboarding_complete`.
- `daily_minutes`, `motivation`, `notification_window`.
- `sound_enabled`, `haptics_enabled`, `reduced_motion`, `high_contrast`.
- `active_goal_id`, `active_track_id`.

### Goal

- `id`, `discipline_id`, `outcome`, `acceptance_criteria[]`.
- `deadline`, `weekly_available_minutes`, `context`, `constraints[]`.
- `status`, `created_at`, `updated_at`.

### DisciplineTrack

- `id`, `version`, `title`, `description`, `graphic_asset_id`.
- `review_status`: reviewed or provisional.
- `capability_ids[]`, `resource_catalogue_version`.

### Capability

- `id`, `version`, `title`, `observable_outcome`.
- `prerequisite_ids[]`, `milestone_id`, `item_pool_ids[]`, `resource_tags[]`.
- `safety_notes[]`.

### Unit / Lesson / Challenge

- Unit: path grouping, guidebook content, checkpoint, display order.
- Lesson: objective, capability IDs, challenge pool, reward, workload range.
- Challenge: format, prompt, choices/input schema, answer key/rubric, concept tags, difficulty, source IDs, version.

### Attempt

- `id`, `challenge_id`, `challenge_version`, `session_id`.
- `first_response`, `revisions[]`, `answer_index`, `rubric_results[]`.
- `used_hint`, `first_try_correct`, `grader_type`, `grader_model_id`.
- `active_duration_ms`, `started_at`, `submitted_at`.
- `connectivity_state`, `app_build`.

### CapabilityEvidence

- `capability_id`, `state`, `supporting_attempt_ids[]`.
- `independence`, `recall_kind`, `transfer_kind`.
- `last_practised_at`, `review_due_at`, `uncertainty`.

### EngagementState

- `points_total`, `points_week`, `streak_days`, `last_streak_date`.
- `recovery_tokens`, `sparks_balance`, `completed_quest_ids[]`.
- immutable `reward_transactions[]`.

### Resource

- `id`, `title`, `publisher`, `canonical_url`, `format`, `level`.
- `prerequisite_ids[]`, `capability_ids[]`, `language`, `cost`, `access_conditions`.
- `licence`, `provenance`, `last_checked_at`.

### PlanVersion

- plan contract in section 12.3 plus `supersedes_plan_id` and `change_reason`.

### ModelArtifact

- `catalogue_id`, `display_name`, `repo`, `revision`, `filename`, `path`.
- `bytes_total`, `bytes_downloaded`, `quantization`, `licence`, `sha256`.
- `verified`, `download_state`, `load_state`, `last_error`, `last_test_at`.

## 15. Accessibility contract

- All interactive controls have explicit semantic labels, roles, values, and selected/disabled state.
- Reading and focus order matches visual order.
- Screen-reader announcement occurs after answer feedback and download status change, not on every animation frame.
- All taps are at least 48 × 48 px.
- Text reflows at 200% without horizontal scrolling.
- Keyboard and IME never cover the active field or primary action.
- Correct, partial, incorrect, locked, selected, and completed states use icon + text + color.
- Reduced motion is respected immediately and persisted.
- Decorative graphics are excluded from semantics.
- Music tasks provide visible beat counts/transcripts; fashion diagrams have concise descriptions.
- Haptics and sounds can be independently disabled.
- External resource links announce that they leave the app and may require connectivity.

## 16. Error, offline, and recovery UX

- No connection during authored lesson: continue normally.
- No connection opening external resource: keep the card and show “Connection needed for this source.”
- No model installed: show deterministic coaching fallback and Settings link, never a dead end.
- Model download interrupted: preserve resumable bytes and show Resume.
- Model hash mismatch: quarantine/delete corrupt file and require fresh download; never load it.
- Model load out of memory: unload safely, recommend smaller model, preserve prompt.
- Generation cancelled: keep learner prompt, mark response incomplete, allow Retry.
- Local data migration error: retain original data, export recovery file if possible, never silently reset.
- Grading error: preserve answer and retry deterministic grading; if subjective, mark “Not graded yet.”
- Invalid custom goal: explain what observable outcome is missing and provide examples.

## 17. Analytics and evaluation

Default analytics are local and privacy-preserving. The demo evidence record contains:

- discipline and task ID;
- app build and device class;
- expected and actual result;
- connectivity state;
- active task time separate from model wait;
- hint use, first attempt, and follow-up type;
- model ID and measured latency when used;
- usability note and reproduction steps.

Do not claim efficacy from the two-day test. Report correctness against reviewed items, unsupported-link rate, plan-schema failures, model latency, crashes, frame drops, battery/heat observations, and user confusion.

## 18. Implementation phases for the coding agent

### Phase 1 — foundations

- Add versioned profile, goal, plan, evidence, gamification, and model state models.
- Add migration from current `LearningState` and preserve Music/Fashion progress.
- Replace broad desktop-responsive compositions with a constrained mobile shell.
- Implement visual tokens, tactile buttons, choice rows, progress bar, and accessibility primitives.

Exit criteria: existing progress loads, tests pass, and all primitives render at 320, 390, 430, and 600 px widths.

### Phase 2 — onboarding

- Implement screens 9.1–9.10 and immediate persistence.
- Use current reviewed discipline data.
- Route Start from basics and Find my level correctly.
- Omit mascots entirely.

Exit criteria: clean install reaches first lesson; interrupted onboarding resumes exactly; Continue states and back behavior are correct.

### Phase 3 — path and lessons

- Build Learn path, nodes, unit header, current-node bottom sheet, challenge shell, feedback sheets, and path revision.
- Keep current deterministic grading and reviewed content.
- Add project/self-review item type.

Exit criteria: each reviewed track has a navigable path; locked prerequisites explain themselves; mistakes reappear as parallel items; progress survives relaunch.

### Phase 4 — gamification

- Add points ledger, streak logic, focus buffer, daily quests, small rewards, and celebrations.
- Keep points separate from evidence.
- Hide leaderboard/social features.

Exit criteria: rewards are idempotent, streaks use local dates correctly, and no gamification mechanic blocks learning.

### Phase 5 — Practice, Library, Profile, Settings

- Implement the four-tab shell and secondary settings.
- Move phone model management to Offline AI models in Settings.
- Add evidence summary and safe per-discipline reset/export.

Exit criteria: navigation preserves scroll/state; models and progress have separate removal flows.

### Phase 6 — arbitrary disciplines

- Implement provisional capability-graph generation and validation.
- Add user confirmation, safety classification, and low-confidence UI.
- Never invent external resources.

Exit criteria: malformed model plans fail closed; app remains usable without model; user can revise the goal.

### Phase 7 — polish and verification

- Add original graphics, motion, haptics, and sound.
- Verify reduced motion, TalkBack/VoiceOver semantics, large text, small phones, keyboard, offline, cancellation, corrupted model, and low storage.
- Build release APK and record exact hash.

## 19. Required automated tests

- Onboarding Continue disabled until valid selection.
- Back and resume preserve each selection.
- Track data and goal progress remain separate.
- Basics and placement routes produce different first sessions.
- First attempt cannot be overwritten.
- Hint success is not independent success.
- Correct/partial/incorrect feedback states have semantic text.
- Wrong item is requeued as a different challenge.
- Points cannot be duplicated by reopen/retry.
- Streak cannot be earned by app open, resource view, or model download.
- Focus reaches zero without locking the lesson.
- Locked nodes provide prerequisite explanation.
- Early Day 2 check gets the early label.
- Model bytes complete does not equal model ready.
- Hash mismatch prevents load.
- Remove model preserves progress; clear progress preserves models.
- No-model fallback completes a lesson.
- Custom plan rejects cycles, unknown IDs, unknown resource URLs, and impossible workload.
- 320 px width and 200% text render without overflow.
- Reduced-motion mode suppresses particles and spatial path movement.

## 20. Manual acceptance script

1. Install fresh on Android at 390 × 844-equivalent size.
2. Reach the promise screen in under two seconds on a warm start.
3. Select Music, enter a concrete goal, choose motivation, proficiency, 10 minutes/day, and Find my level.
4. Complete baseline with one correct, one hinted, one skipped, and one incorrect item; leave and resume mid-session.
5. Confirm route explains its evidence and starts a lesson.
6. Complete a correct answer and observe Check -> feedback -> Continue.
7. Complete an incorrect answer and confirm supportive feedback plus later parallel retry.
8. Confirm points/streak/focus behavior and complete one daily quest.
9. Switch to Fashion and confirm isolated goal/progress.
10. Open Settings -> Offline AI models, download/resume/verify/select the small Qwen model, and run local inference.
11. Disable connectivity and repeat inference; confirm external resources indicate network need.
12. Return on Day 2 or use clearly labelled accelerated demo mode; complete new-example recall and inspect route change.
13. Enable reduced motion and 200% text; repeat one onboarding screen and one lesson.
14. Remove the model and confirm all learning progress remains.

## 21. Definition of done

The implementation is done only when:

- it is visibly and behaviorally a mobile app;
- a new user always understands the next action;
- onboarding, path, lessons, feedback, progress, and rewards share one coherent tactile system;
- Music and Fashion each work end to end with separate saved progress;
- a custom goal can produce a validated provisional path or a safe actionable error;
- model management exists under Settings and local inference is optional;
- authored learning works offline without a model;
- points/streaks never masquerade as mastery;
- all mascot artwork and Duolingo runtime assets are absent from the shipped application;
- small-screen, large-text, screen-reader, reduced-motion, failure, and persistence tests pass;
- the APK is built, installable, and accompanied by its version and SHA-256.

## 22. User decisions still required

The specification uses safe defaults for all undecided areas. The product owner should confirm these before account/social work begins:

1. Release identity: keep the product name “Sumi” and current app package identity, or rename it before public release.
2. Data model: remain fully local/guest-only for the first release, or add accounts and cloud sync.
3. General catalogue policy: allow any low-risk custom discipline immediately, or launch only with reviewed disciplines plus an application form for new tracks.
4. Sound default: sound effects on by default, or opt-in.
5. Social scope: omit leagues/friends entirely, or plan them after accounts exist.

Unless told otherwise, the coding agent must use: Sumi name, local/guest-only data, reviewed Music/Fashion plus clearly provisional low-risk custom goals, sound on with a visible toggle, and no social/leaderboard UI.

## 23. Local source map

- `research/duolingo-teardown.md`: observed flow and learning-system translation.
- `research/captures/01-landing.png` through `11-correct-feedback.png`: mobile visual evidence.
- `research/captures/*.txt`: accessibility structure and choice labels.
- `research/design-tokens.json`: earlier Sumi token proposal and contrast checks.
- `research/mvp-blueprint.md`: learner state, planning contract, resources, validation, and AI roles.
- `research/two-day-demo-plan.md`: current two-day product/usability evaluation.
- `research/animation-reference/README.md`: motion principles and production handoff.
- `research/animation-reference/animation-contract.json`: state/event metadata principles; mascot states are intentionally excluded here.
- `research/animation-reference/runtime-asset-inventory.md`: runtime evidence and strict no-redistribution boundary.
- `research/reusable/halflife-regression/`: historical MIT research reference; not production-validated for arbitrary disciplines.
- `app/assets/disciplines.json`: current reviewed Music and Fashion content.
- `app/assets/model_catalog.json`: current phone-model catalogue.
- `app/lib/on_device_native.dart`: current phone runtime and download flow.

