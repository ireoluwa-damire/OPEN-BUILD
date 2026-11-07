# Duolingo teardown for an adaptive project-learning app

Investigation date: 27 October 2026, WAT. Intended use: product reference, interaction structure, and implementation planning.

## 1. What transfers best

Borrow the rhythm: a clear next action, a short attempt, useful feedback, a later recall check, and a visible piece of progress. For your app, progress should eventually mean a completed project or demonstrated capability.

Your differentiator is the connection between assessment and a practical outcome: the app explains why today's task exists, adjusts the route when evidence changes, and links the task to a real deliverable. A generic chatbot wrapped in a streak counter would make this value difficult to demonstrate.

## 2. What REA actually observed

REA launched installed Edge/Chromium in temporary profiles at a 390 x 844 viewport, English locale, Africa/Lagos timezone, light theme, and reduced motion. The inspected course was Spanish, using guest onboarding. The scenarios selected an education motivation, novice proficiency, ten minutes per day, and the beginner route as research inputs. These are synthetic research choices, not claims about your preferences.

| Stage | Observed structure | Lesson for your design |
| --- | --- | --- |
| Public landing | Logo, central character art, short promise, large primary entry action, secondary account action | Make the product promise understandable before explaining the models |
| Subject picker | A single question and a scrollable list; languages plus Math and Chess were visible | Support goal categories and free-text outcomes without overwhelming the first screen |
| Mascot introduction | Character speech, a progress indicator, and one Continue button | A companion can guide short transitions |
| Referral question | Single-choice radio list; Continue disabled until selection | Selection state and progression are explicit; referral collection is optional for your MVP |
| Motivation | Reasons such as education, career, travel, and connection; contextual reaction after a choice | Capture the learner's intended use, then acknowledge it briefly |
| Self-reported level | Five proficiency descriptions, from novice through detailed conversation | Use self-report to choose initial questions; verify it with work |
| Outcome preview | A short list of things the course helps the learner achieve | Show a concrete target project and its acceptance criteria |
| Daily commitment | 5, 10, 15, or 20 minutes per day; selection changes the supporting message | Ask about available time and make workload consequences clear |
| Starting point | Beginner route or a route-finding assessment | Offer a short baseline and an explicit beginner option |
| Transition into lesson | Brief motivation copy, then a lesson route | Keep your path into actual learning short |
| First lesson | Exit control, progress bar, a top-right count, prompt, three answer choices, disabled Check until selection | Reuse the single-task lesson shell with clear answer and feedback states |
| Correct-answer feedback | Choices become disabled, a result heading appears, difficulty feedback controls are available, and Continue replaces Check | Separate answer submission from moving on; let learners flag a mismatch |

Evidence anchors:

- Landing: ev_4dc26b6753f6f22df4bd2a307826ff269663773387963359cd12fa1f110ecf60.
- Subject picker: ev_ddfa510a04087119ff3c2160d3638a82007b9a68620b1e8e4ecd1ce24bc5be46.
- Mascot introduction/referral: ev_2c7cd0d394193077bdabbdebad526ed9b4c08e70fa9277772588b5229ad47cd5.
- Motivation: ev_f4da35ecf26f2113811b4d2bde91b5f891091d24328f065789b1b323189a7fda.
- Proficiency: ev_44b0b491749070a2d9ded69f6deccd4b7be703ebbec6bb0a6ac3ed8258c16ec4.
- Outcome preview: ev_89adc3d9deddb72f436117e9254a8fcbe4cd26ba60f83a670ce652274a367c6a.
- Daily time: ev_28e5b369c89d03a54b20eb54e7382114160de578dfbe41eff35e7a1bd583c1e1.
- Starting route: ev_8fd936d83eef2dec72804c03c1200d95e4f0fdba3bdc23a25f788b6dea5d652e.
- First exercise: ev_2926e216ffbd849c4b58b158667dd4468c6307f9e2d2ee44e0ddfc6f28416a44.
- Correct-answer feedback: ev_6bc5fb8c8e58990892e4988b43a6a2a6a4b03e22a7d204332b28c1149bdeb8af.

These IDs resolve inside the local evidence bundle. The capture index includes additional follow-up observations if present.

One earlier run stopped at a loading state after a short wait. A longer follow-up reached onboarding. A separate capture with network metadata reported incomplete event coverage and some 404 responses; this does not establish a broken user journey or the meaning of private endpoints. Later successful screen captures support the UI observations above. No network body or credential values were requested.

A final attempt to capture an incorrect-answer branch did not complete its action sequence. That branch is not claimed as observed; the original proposed retry states remain design recommendations. The failed scenario is retained as ev_126b4a0eaa1780440a7fd26907b59435560b5f94b07187a63e7f034ef0eb75c3.

## 3. Curriculum and learning structure

Duolingo's documented path arranges lessons into small units and interleaves new material with practice. Its 2022 redesign explanation also describes unit guidebooks and story activities embedded in the path. Treat this as a design explanation from that period, rather than proof that every current course has identical screens. [Home-screen redesign](https://blog.duolingo.com/new-duolingo-home-screen-design/).

For your app, use this proposed hierarchy:

    Goal -> capability -> milestone -> lesson -> challenge -> attempt

Example:

    Build a Python expense summarizer
      -> Process a structured file
        -> Read rows and convert amounts
          -> Read a CSV row
            -> Predict a conversion result
              -> Answer, feedback, and later recall

Keep the prerequisite graph in data. The visible path can show the recommended route through it. If a user already demonstrates a prerequisite, the planner should be able to skip its introductory lesson while retaining a later check.

Do not equate finishing a lesson with mastering a capability. Distinguish first exposure, supported success, independent success, delayed recall, and transfer to a different task. These are proposed states for your product.

## 4. Assessment, personalization, and review

The published Birdbrain account describes a predictor that combines learner proficiency and exercise difficulty to estimate whether a learner will answer correctly. A session generator uses that estimate when assembling exercises. This is useful conceptual separation: measuring a learner, selecting an exercise, and composing an explanation are different jobs. The post does not supply the present production model or its weights. [Introducing Birdbrain](https://blog.duolingo.com/learning-how-to-help-you-learn-introducing-birdbrain/).

An earlier Duolingo placement-test article describes adaptive question selection and the limits of purely binary grading. Use it as historical assessment design context, not current implementation documentation. In your prototype, partial-credit rubrics should identify which subskill succeeded and which failed. [Placement-test improvements](https://blog.duolingo.com/partial-credit-improvements-to-duolingos-placement-test/).

Duolingo explains that its practice uses accuracy and spaced repetition, and that mistakes may return near the end of a lesson. For your product, separate immediate repair from delayed recall: successfully repeating the same answer seconds later is different evidence from solving a related question the next day. [Spaced repetition](https://blog.duolingo.com/spaced-repetition-for-learning/).

For implementable research, Half-Life Regression predicts recall as:

    p(recall) = 2 ^ (-elapsed_time / estimated_half_life)

The paper and released implementation concern language-learning traces. Reusing the form for programming concepts would be a new application requiring validation; its parameters cannot simply be assumed to transfer. Begin with a transparent review schedule and collect your own evidence before training anything. [Research paper](https://research.duolingo.com/papers/settles.acl16.pdf), [MIT implementation](https://github.com/duolingo/halflife-regression).

## 5. Lesson shell and exercise types

Recommended shell for your app:

1. Header: exit/back, lesson progress, optional remaining tasks.
2. Context: capability being practiced and a short prompt.
3. Work area: one response format.
4. Help: optional hint; mark hinted attempts.
5. Sticky primary action: Check, then Continue after feedback.
6. Feedback panel: result, a short explanation, and the next useful action.

Keep these states explicit: loading, unanswered, selected, submitting, correct, partly correct, retry, network failure, and completed. Preserve the learner's work when a request fails. Confirm before abandoning unsaved work.

Useful adaptations:

| Exercise | What it reveals | Best use |
| --- | --- | --- |
| Multiple choice | Recognition and common misconceptions | Early baseline and quick checks |
| Short explanation | Whether the learner can express a concept | Understanding and teach-back |
| Predict an output | Whether a rule can be applied mentally | Programming and quantitative topics |
| Order the steps | Whether a process makes sense | Procedures and project planning |
| Diagnose a small mistake | Whether the learner can distinguish causes | Debugging and conceptual errors |
| Apply to a new case | Whether knowledge transfers | Milestone acceptance |
| Submit a small artifact | Whether the learner can produce usable work | Project completion |

These exercise recommendations are our design proposal. Duolingo's older Session Generator article is a useful system breakdown of challenge pools and lesson assembly; its Scala architecture and performance figures describe that historical system. [Session Generator](https://blog.duolingo.com/rewriting-duolingos-engine-in-scala/).

## 6. Motivation and game systems

Duolingo's documented motivational mechanisms include daily streaks, weekly XP leaderboards, and cooperative Friends Quests. Its help page also describes reminder settings and streak protection. [Motivation overview](https://blog.duolingo.com/sticking-with-it-tips-for-staying-motivated/), [streak help](https://www.duolingo.com/help/what-is-a-streak).

Suggested priority:

| Mechanism | Your app's version | Priority |
| --- | --- | --- |
| Clear next action | Today's one useful task | Essential |
| Progress path | Milestones toward the learner's project | Essential |
| Small celebration | A capability or deliverable completed | Essential |
| Streak | Optional consistency indicator with forgiving recovery | Later |
| Quest | A short weekly project target | Later |
| Peer challenge | Two people completing a compatible goal | Later |
| XP, currencies, leagues | Additional reward systems | Defer |

Keep capability evidence separate from engagement rewards. A person can be diligent yet still need help, or have little time and demonstrate strong understanding.

Older breakdowns often assume Hearts are universal. Duolingo has published an Energy system that replaces mistake-based limits with a usage-based system and reward/refill mechanics. Availability is tested and varies; neither publication nor our web sample proves a universal native rollout. We do not recommend a lesson-limiting economy for this hackathon MVP. [Energy explanation](https://blog.duolingo.com/duolingo-energy/).

The saved first-lesson screenshot specifically shows a five-heart indicator in this guest mobile web sample. Keep that observed web state separate from published mobile Energy rollouts.

## 7. Visual language and motion

The observed mobile landing and onboarding use generous whitespace, large rounded interactive elements, strong selected states, character-led transitions, and a clear primary button.

Duolingo's art explanation emphasizes simple readable shapes, small-screen clarity, expressive poses, and motion that directs attention. Its core-tab redesign describes a restrained type hierarchy, intentional spacing, and consistency balanced against each tab's purpose. Use those production principles to create an original system. [Shape language](https://blog.duolingo.com/shape-language-duolingos-art-style/), [core tabs](https://blog.duolingo.com/core-tabs-redesign/).

For your app, Sumi's indigo/teal/coral palette and tile-arranging motion can connect the mascot to planning. Use one short animation at the moment a path changes. Keep neutral, thinking, hint, retry, and celebration states. Static expressions should carry the same meaning when motion is reduced.

Rive's own site confirms interactive state-machine animation and its use by Duolingo. It is an optional production reference, not a requirement for your first build. A PNG plus a few original transitions is sufficient to prove the learning loop. [Rive](https://rive.app/).

Several old design.duolingo.com brand subpages redirected to the design blog hub during verification. Search snippets still expose older guideline text; do not treat those snippets as a current downloadable asset licence or a complete component library.

## 8. What you can actually reuse

- General interaction ideas: guided paths, short tasks, visible feedback, review queues, and supportive character reactions.
- The archived MIT HLR implementation, with its copyright and licence notice, subject to adaptation and testing.
- Your original mascot drafts, proposed tokens, and planning templates in this pack.
- Linked research as a design reference with attribution.

Screenshots and DOM captures are research records. A public asset URL does not establish a redistribution licence. Use original character art, sounds, wording, icons, and course items in the submitted app. A repository with an open-source clone UI also does not automatically license the branded artwork inside it.

## 9. Remaining unknowns and coverage

| Question | Status |
| --- | --- |
| Mobile web onboarding and first lesson anatomy | Observed through REA |
| Curriculum and review rationale | Supported by first-party publications; not independently audited |
| Birdbrain concept | Public description available; current production internals unknown |
| Current signed-in path, leaderboard, quest, shop, and profile behavior | Publication reference only |
| Native mobile app source/resources and platform-specific experiments | Not inspected; no APK/IPA supplied |
| Exact current ranking formula, reminder optimizer, mastery thresholds | Unknown |
| Whether language-learning results transfer to all disciplines | Requires your own evaluation |
| Exhaustive inventory of all public breakdowns | Not claimed; curated sources cover the requested product decisions |
