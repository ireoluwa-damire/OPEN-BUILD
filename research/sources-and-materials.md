# Sources and reusable materials

Verified or inspected on 27 October 2026. References are prioritized for decisions you need to make. Links provide original context; the descriptions below are intentionally brief.

## Read first

| Reference | Use it for | Evidence type |
| --- | --- | --- |
| [Duolingo public app](https://www.duolingo.com/) | Landing, subject picker, onboarding, first exercise | Live controlled REA scenarios, saved locally |
| [How to use Duolingo](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/) | Broad user journey and feature overview | First-party product explanation |
| [Learning-path redesign](https://blog.duolingo.com/new-duolingo-home-screen-design/) | Guided sequence, review within the path | First-party historical design rationale |
| [Birdbrain](https://blog.duolingo.com/learning-how-to-help-you-learn-introducing-birdbrain/) | Separate learner state from exercise selection | First-party historical model explanation |
| [Spaced repetition](https://blog.duolingo.com/spaced-repetition-for-learning/) | Recall timing and review UX | First-party learning explanation |
| [Core tabs redesign](https://blog.duolingo.com/core-tabs-redesign/) | Consistency, hierarchy, and spacing | First-party design breakdown |

## Deeper breakdowns

| Reference | Useful material | Boundary |
| --- | --- | --- |
| [Session Generator](https://blog.duolingo.com/rewriting-duolingos-engine-in-scala/) | Exercise pools and lesson assembly | Historical architecture, not current backend proof |
| [Human expertise and AI](https://blog.duolingo.com/how-duolingo-experts-work-with-ai/) | Curriculum, content, and personalization roles | Published design, not source code |
| [LLMs for exercise creation](https://blog.duolingo.com/large-language-model-duolingo-lessons/) | Constrained generation and human editing | Keep human-reviewed correctness checks |
| [Placement partial credit](https://blog.duolingo.com/partial-credit-improvements-to-duolingos-placement-test/) | Adaptive assessment and grading limitations | Historical placement design |
| [Shape language](https://blog.duolingo.com/shape-language-duolingos-art-style/) | Simple silhouettes, readable imagery, expressive motion | Visual reference, not an asset licence |
| [Widget design](https://blog.duolingo.com/widget-feature/) | Character expression as a reminder mechanism | Optional motivation reference |
| [Streak help](https://www.duolingo.com/help/what-is-a-streak) | Streak behavior and reminders | Platform behavior may vary |
| [Motivational features](https://blog.duolingo.com/sticking-with-it-tips-for-staying-motivated/) | Streaks, leaderboards, cooperative quests | Later product scope |
| [Energy](https://blog.duolingo.com/duolingo-energy/) | Changes to legacy Hearts assumptions | Experiment/rollout scope is not universal |
| [Duolingo research index](https://research.duolingo.com/) | Papers and datasets, including HLR, SLAM, and notifications | Check each dataset's own terms and relevance |
| [HLR paper](https://research.duolingo.com/papers/settles.acl16.pdf) | Recall prediction formulation and evaluation | Language learning; transfer requires evidence |
| [Rive](https://rive.app/) | Optional interactive animation and state machines | Runtime/tool reference, not a licence to reuse Duo |

The old design.duolingo.com root and several brand-guideline paths redirected to the design blog hub. Use current blog breakdowns and saved runtime screenshots; do not depend on cached guideline snippets as downloadable materials.

## Materials included for direct reuse

The folder reusable/halflife-regression contains LICENSE.md, README.md, experiment.py, and evaluation.r fetched through the GitHub connector from commit 0041df0dcd436bf1b4aa7a17a020d9c670db70d8.

This repository's software is MIT licensed. Preserve its copyright and licence notice with substantial reused code. The README also requests citation of Settles and Meeder (2016). These are research scripts, not a ready-made app backend; the Python script includes legacy iteritems calls. The scripts were archived and inspected, not executed or ported.

The full dataset was not downloaded. Read its release terms separately before using it. You do not need a large language-learning dataset to demonstrate a transparent review scheduler for one reviewed discipline.

Original materials in this pack that your team can adapt:

- The MVP flow, planning contract, and prompts.
- The proposed design-token JSON.
- Six mascot concepts and a four-character visual exploration.

The concept sheet is raster concept art, not a production vector or animation rig. Final mascot production still needs a consistent model sheet, scalable source artwork, and small-screen checks.

## Candidate models

| Official source | Proposed role | Terms shown by the model card |
| --- | --- | --- |
| [Qwen3-4B](https://huggingface.co/Qwen/Qwen3-4B) | Explanation, exercise drafts, plan drafts | Apache-2.0 |
| [Qwen3-Embedding-0.6B](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B) | Catalogue and passage retrieval | Apache-2.0 |

No model weights were downloaded or benchmarked. Select and pin actual revisions during implementation. Open-weight availability and software openness are separate questions, as the challenge brief notes.

## Starter content for the example discipline

- [Python tutorial](https://docs.python.org/3/tutorial/): for people with some programming background.
- [Python CSV reference](https://docs.python.org/3/library/csv.html): project-specific file handling.
- [Python licence](https://docs.python.org/3/license.html): documentation and code-example terms.

Link to these exact sources in the reviewed resource catalogue. Add original novice-friendly bridges if the baseline shows that the prerequisites are missing.

## Copying checklist grounded in the brief

Use the linked publications to understand mechanisms. Use explicitly licensed code with its notices. Make your mascot, lesson content, sounds, and branding original. Keep research screenshots separate from app assets. Record significant reused work and AI assistance in the submitted project's acknowledgements.

The challenge brief asks for licence compliance, acknowledgement, and an explanation of your implementation. It does not authorize copying proprietary Duolingo assets or claiming others' work as your own.
