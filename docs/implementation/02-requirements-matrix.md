# 02 — Requirements traceability matrix

Repository: `OPEN-BUILD/` · App: `app/` (Flutter package `sumi` 0.2.0+2)
Prepared: 31 October 2026 (WAT) · Follows: `01-repository-assessment.md`
Companion documents: `03-implementation-plan.md` (sequence, gates, DONE) and `04-design-contract.md` (exact visual and interaction values).
Status: specification only. **No application code was changed while preparing this document.**

---

## 0. How to use this document

1. Every requirement has a stable ID (`AREA-NN`). Code, tests, commits and PRs must cite it, for example `feat(path): anchored node card [PTH-08]`.
2. Each requirement has a **tier** and a **priority**.
3. Visual values (colours, sizes, timings, copy) are defined once in `04-design-contract.md` and referenced here as `DC §x`. When this matrix and the contract disagree, the contract wins for visual values and this matrix wins for behaviour.
4. "Current state" tags follow the assessment: **[V]** verified in source, **[R]** recorded in logs, **[I]** inferred and still to be confirmed by running the code.

### 0.1 Tiers

| Tier | Meaning | What an implementer may change |
|---|---|---|
| **X — Reproduce exactly** | Visual identity, interaction grammar, copy or state behaviour that the breakdown states explicitly. | Nothing user-visible. Internals may be written any way. |
| **F — Implement functionally** | The outcome is specified, not the exact form. | Layout details inside the design contract's limits; internal design. |
| **I — May improve** | A stated behaviour that may be implemented better, provided the user-facing behaviour stays the same. | Performance, structure, error handling, reuse, accessibility above the minimum. |
| **O — Optional** | Useful but not required for DONE. | Build only after every X/F requirement in the same phase passes. |

### 0.2 Priorities

| Priority | Meaning |
|---|---|
| **P0** | Blocks a truthful, working demo, risks data integrity, or creates legal exposure. |
| **P1** | Core experience: the Duolingo-grade learning loop. |
| **P2** | Fidelity and comprehension: the loop feels right. |
| **P3** | Polish and release hygiene. |

### 0.3 Source documents (the "breakdown")

No separate breakdown file was attached for this phase. The breakdown is therefore taken to be the set of agent-authored specifications already in the repository, which the assessment (§10) identified as the breakdowns:

| Key | Document | Date | Role |
|---|---|---|---|
| **S1** | `research/SUMI_EXPERIENCE_AGENT_BLUEPRINT.md` (+ `sumi-experience-agent-schema.json`) | 28 Oct | Base product, visual and data contract |
| **S2** | `research/SUMI_RECORDING_CORRECTION_SPEC_2026-10-28.md` | 28 Oct | Screen-level acceptance contract from a recording of the app |
| **S3** | `research/SUMI_NEXT_CORRECTION_AGENT_PROMPTS_2026-10-29.md` | 29 Oct | Overrides S1 on cloud AI, resources and adaptation |
| **S4** | `research/rea-duolingo-android-2026-10-29/REA_CODE_LEVEL_RECONSTRUCTION_SPEC.md` | 29 Oct | State-ownership and transition contract |
| **S5** | `research/live-reference-2026-10-29/DUOLINGO_LIVE_REFERENCE_RECONSTRUCTION_SPEC.md` | 29 Oct | Observed interaction grammar (reference recordings) |
| **S6** | `research/live-reference-2026-10-29/SUMI_FORENSIC_UI_RECONSTRUCTION_PROMPT.md` | 29 Oct | Strict UI reconstruction brief, component list, release blockers |
| **S7** | `docs/implementation/01-repository-assessment.md` | 31 Oct | Current code reality; records the owner's mascot decision |
| **S8** | `research/challenge-brief-extracted.txt` | 26 Oct | OPEN//BUILD rules (open-weight model, GitHub, no fabricated results) |

If the owner sends a different breakdown, re-run reconciliation against it. IDs in this document stay stable; new or changed requirements get new IDs.

### 0.4 Ambiguity resolution order

Applied in this order, as instructed:

- **A.** Explicit instructions in the breakdown (S1–S6). When two explicit sources disagree, the later, more specific, evidence-based source wins **only** where it states it overrides; otherwise the conflict is listed in §1 and resolved there.
- **B.** Screenshots, designs and reference materials (S5's frames and contact sheets, `research/captures/`).
- **C.** Existing application behaviour and established patterns (S7, `app/lib`).
- **D.** Existing architecture and conventions.
- **E.** Reasonable engineering and UX defaults.

Two sources sit above this order because the breakdown itself puts them there. S1 §0 says research "cannot override … the product owner's requests". S6 lists "the product owner's latest request" as evidence priority 1. So **a recorded owner decision outranks A**.

---

## 1. Conflict and ambiguity register

Each entry is resolved. None was dropped for being inconvenient. "Rule" is the resolution step from §0.4 that decided it.

| ID | Topic | Sources in tension | Resolution | Rule |
|---|---|---|---|---|
| **CF-01** | Mascot | S1 §0, §7, §8.3; S2 P2.1; S3 P5.7; S6 all say **no mascot**. S7 §10 records that the owner approved the Sumi chameleon on 31 Oct, and it is already built (`lib/mascot/`). | **Keep the original code-drawn Sumi mascot.** It must be original, never block input, show a still pose under reduced motion, use one-shot animations in tests, and carry no Duolingo slot names in shipped UI (GOV-05). Every mascot use also carries the same meaning in text and icon (A11Y-03). | Owner decision |
| **CF-02** | Node tap surface | S1 §9.11, S2 §4.1 and S3 P5.1 say bottom sheet. S4 §7 P0.1 and §10, and S5 §5.3, say an **anchored card**, never a bottom sheet. | **Anchored card** (already in code). It carries the union of fields from all sources: title, activity type, duration, reward, reason or due reason, state, Start/Review. | A (S4 and S5 are later, evidence-based and explicit: "never opens a bottom sheet"), then C |
| **CF-03** | Network and cloud AI | S1 §3: network only for downloads and links. S3 §0: cloud allowed with explicit consent. | **S3 wins** (it states it supersedes S1). No provider is configured, so the UI says "Cloud AI not configured". The canned `SumiCloudTutorProvider.queryCloud` string must never reach a learner. | A (explicit override) |
| **CF-04** | Current-node indicator | S1 §9.11: looping 2 px breathing ring. S7 risk 6: loops hang `pumpAndSettle` tests. The code shows a static START bubble. | **Reproduce both**: the START bubble and the breathing ring. The ring loops only when `SumiMotion.loopsEnabled` is true (false in tests), reduced motion is off, and `TickerMode` is enabled. | A, with an engineering guard (I) |
| **CF-05** | Incorrect answer flow | S1 §10.5: Continue moves on and requeues a parallel item. S5 §6.4: incorrect panel with "GOT IT", plus Explain. S4 §5.4: Continue, Retry or Explain "as dictated by grading". Code: an incorrect answer forces RETRY on the same item, with no Continue. | **Incorrect → coral CONTINUE advances**. The challenge, or its authored parallel variant, is requeued before the lesson ends. "EXPLAIN MY MISTAKE" is the outlined secondary action. Label is "CONTINUE" (S1 is explicit), not "GOT IT". | A (S1 explicit), B confirms the grammar |
| **CF-06** | Feedback headings | S1: "Correct!" / "Nice work.", "Not quite yet.", "Almost—one part needs work." S5 lists Duolingo's rotating praise strings. Code: "Well connected", "Let's repair this". | **S1 copy** (DC §11). Correct headings rotate between S1's two strings only. Duolingo's own rotating strings are not copied. Tests asserting the old copy are updated on purpose (plan §13). | A |
| **CF-07** | When Focus drops | S1 §11.3: first-try incorrect only. S4 §5.5: only after a persisted incorrect attempt. Code: every incorrect attempt. | Drop **once per challenge, on the first persisted attempt, only when that attempt is `incorrect`**. Near-correct and retry never drop Focus. | A |
| **CF-08** | Points values | S1 §11.1: an itemised table. S2 P1.3: "such as 10/15/20/30" bands, given as an example. Code: flat 20. | **S1 §11.1 table** (GAM-01). S2 offered an example, not a rule. | A (specific beats example) |
| **CF-09** | Checkpoint points | S1 §11.1 has no checkpoint row. S2 suggests 30. | Checkpoint pass is +25, the same as a project step, plus 5 sparks. Checkpoint challenges still earn per-challenge points. Labelled a prototype rule. | E |
| **CF-10** | Path connectors | S1 §9.11 (6–8 px soft grey, primary when complete) and S2 P1.1 ("visible connectors") require them. S4 P1.3: "validate against recording before retaining". | **Draw connectors** as specified in S1. S4 asked for validation, not removal. | A |
| **CF-11** | Titles under nodes | S2: every node needs an accessible title. S4 P1.2: nodes rely on icons, and detail lives in the card. | **No visible title under nodes.** The title is in the semantics label and the anchored card. | A (both satisfied) |
| **CF-12** | Node fill colour | S1/schema: available = primary fill, completed = primary-soft with primary outline. S5 and the code: node colour follows the unit palette. | **S1 semantic colours for nodes** (DC §7.12). The unit palette is used only by the unit header and the section cards. | A over B and C |
| **CF-13** | Unit header colour | S1: "full-width coloured unit header", no token given. S5: saturated card with a darker edge. Code: literal `#246F89`, `#87537D`, `#58733C`. | **Promote the three existing hues to tokens** (`unitTeal`, `unitPlum`, `unitOlive`, plus shadows). White text on them passes 5.3–5.9:1, while white on `primary` is 2.14:1. | C (A silent) |
| **CF-14** | Bottom navigation | S1: four labelled destinations, muted unselected items. S5: six icon-only, colourful unselected. | **Four labelled destinations with muted unselected items** (S1), using S5's selected-tile treatment (tinted rounded square plus outline). | A, then B for treatment |
| **CF-15** | Focus in the path stats row | S1 §9.11 puts it in the top stats row. S2 P1.3: keep Focus in the lesson, not beside lifetime stats. S5 maps energy to "focus only where pedagogically justified". | **Focus appears only in the lesson header.** It resets every lesson, so a path-level value would always read 5 and would mislead. The path status row shows the discipline badge, streak and points. | A (S2 later, with a reason), with E |
| **CF-16** | Goal/course strip | S5 §4.1 and S6 require a persistent top course strip. S1 has a discipline-switcher icon only. | **Implement the strip** on the Learn tab: an ink-coloured band with uppercase discipline tabs and `+ ADD`. It replaces the AppBar there. | A (S6 explicit) |
| **CF-17** | Discipline card: auto-advance or Continue | S1 §9.2: "advances immediately". S1 §4 principle 3: "never combine selection and navigation". S5 §7.6: selection enables Continue. | **Select, then Continue.** S1 contradicts itself; the global principle and the observed reference agree. | A (general rule) and B |
| **CF-18** | Onboarding defaults | S1 §9.4–9.7: Continue disabled until selection, "Default: none". Code: `OnboardingState` pre-fills every answer [V], so Continue is always enabled. | **No defaults.** Migration keeps the stored answers of learners who already finished onboarding (ARC-03). | A |
| **CF-19** | Route reveal | S1 §9.10 requires it. Code: `nextStep()` at step 8 sets `completionState = true` and calls `onFinished`, so step 9 is skipped [I]. | **Show the route reveal.** Fixing the skip is P0. | A |
| **CF-20** | Basics route | S1 §9.8: Basics gets three light checks inside the first lesson. Code: both routes go to the six-question baseline [V]. | **Branch the routes** (ONB-08). | A |
| **CF-21** | Lesson-complete timing | S1 §8.1: `celebrationSmall` 650 ms covers "correct/lesson complete"; `celebrationLarge` 1,200 ms covers milestones. S2 §4.1: celebration within 1.2 s. Code: 1,400 ms intro and 1,900 ms confetti. | The in-lesson correct micro-celebration is ≤ 650 ms. The **result screen sequence is ≤ 1,200 ms** and confetti ends by 1,200 ms. Both can be skipped. | A |
| **CF-22** | Anchored-card and slide timings | S5 gives ranges (card 160–240 ms, slides 220–320 ms) but S1 has no tokens. | New tokens: `card` 200 ms; `slide` 280 ms. S1's `screen` 220 ms remains for onboarding steps (DC §6). | B, then E |
| **CF-23** | Neutral lesson footer | S1 §10.1: white sticky area with a top divider; the feedback sheet replaces it. Code: a 218 px tinted panel that is always shown, with idle copy. | **White footer holding only CHECK** (plus a skip action where one applies). The feedback panel rises in its place. | A |
| **CF-24** | Selected choice colour | The S1 palette has `sky` for "informational choices" but no soft sky tint. | Selected = `sky` border plus a new `skySoft #DDF2FC` fill (DC §2.2). | A, then E |
| **CF-25** | Primary label contrast | S1 palette: white on `primary` is 2.14:1, white on `sky` 2.67:1 (fail WCAG AA). S1 §15 and S2 require high contrast and accessibility. | **Default theme keeps the S1 palette exactly** (it is the visual identity). A **High-contrast mode** (SET-05) swaps the fills to the shadow tones (3.9:1) and the text to ink. All body text pairs must pass 4.5:1 in both modes; `muted` body text below 16 px uses `mutedStrong`. See DC §2.4. | A, with an accessibility improvement (I) |
| **CF-26** | Font | S1: original, redistributable rounded sans. Code: `fontFamily: 'Arial'`, which is not shipped on Android, so it silently falls back to Roboto. | **Bundle Nunito** (SIL OFL 1.1) at weights 500–900. | A, then E |
| **CF-27** | Section overview presentation | S5: a tall white surface over the path with a close control. Code: a pushed page titled "Sections & units". | **Full-height modal sheet** (radius 24, X at left, discipline title centred). "Sections & units" stays as its semantic label. | B |
| **CF-28** | Result-screen primary action | S2 §4.3: one clear next action plus a secondary Return to path. S4: Continue returns to the exact path position. Code and tests: `RETURN TO PATH` only. | Primary **CONTINUE** returns to the path, plays the completion and unlock events, then opens the anchored card on the new current node. Secondary text button **RETURN TO PATH** returns without opening the card. | A |
| **CF-29** | Lesson exit confirmation | S1 §10.2: "Keep progress and leave?" with KEEP LEARNING / SAVE & EXIT. S5: lesson settings sheet with END SESSION. Code: AlertDialog "Pause this lesson?". | **Rounded-top confirm sheet** with S1 copy. END SESSION in the settings sheet opens the same confirmation. | A copy, B grammar |
| **CF-30** | Reminders | S2 P0.2: either implement them or label them honestly. Code: the toggle can show "enabled" with no schedule [V]. | **Label "Not set up yet" and disable the toggle** (SET-04). A real schedule is optional (SET-04-O). | A |
| **CF-31** | Brand proximity | S1 mandates `#50C86A`/`#2AA8E8`. S7 risk 11: close to Duolingo's palette. | **Keep S1** (A). Raised to the owner as non-blocking escalation E-03. | A |
| **CF-32** | Content beyond the authored set | S6 requires, per discipline, a video activity plus an application question, ordering/matching, choice, reflection, correct, incorrect and near-correct. Today only the first question varies per node (S7 §6.1). | **Author per-node challenge lists in data** (ARC-04, LES-15). New wording is AI-assisted original content, labelled as such in the README, and listed for owner review. | A |

### 1.1 Ambiguities resolved with defaults (not conflicts)

| ID | Question | Default chosen |
|---|---|---|
| AMB-01 | Which variant does "project: amber or sky fill" mean? | **Sky** for project. Amber is reserved for checkpoint and reward ("checkpoint stars"). |
| AMB-02 | Base reward shown on the node card | `10 × challenges + completion bonus` (+20 lesson, +15 review, +25 project or checkpoint). That amount is guaranteed on completion. Bonuses appear on the result screen. |
| AMB-03 | Daily-quest chest contents | +5 sparks, shown openly. No randomness. |
| AMB-04 | What counts as an "early follow-up" | A Day-2 check made < 24 h after the baseline's first attempt is labelled "Early follow-up". |
| AMB-05 | Where the lesson settings control sits | A 40 px icon button at the far right of the lesson header, after Focus. |
| AMB-06 | Keyboard shortcuts (web preview, hardware keyboard) | Enter = active primary action; Esc = close the card, sheet or explanation. Number keys for choices are optional (A11Y-08-O). |
| AMB-07 | Units per track | Two units per reviewed track (three skills each), plus a video node, a checkpoint and a reward node per unit (ARC-04). |
| AMB-08 | Mascot in the anchored card or path | Not used there. The mascot appears only in feedback (52 px), on the result screen, and on empty states (DC §7.33). |

### 1.2 Escalations to the owner

Only items that could cause irreversible change, a security or legal problem, or fundamentally different product behaviour. The implementation can start without them: each has a safe default that is applied until the owner decides.

| ID | Decision needed | Why it matters | Default until decided |
|---|---|---|---|
| **E-01** | Before the **first commit or push**, confirm the exclusion list (GOV-01): Duolingo APKs, the decompiler, Duolingo screenshots, recordings, frames, runtime animation packs, `OPEN-BUILD-reference-pack.zip`, and the root file `Mascot concepts`. | Publishing copyrighted binaries or assets cannot be undone, and the brief requires a public GitHub repository. | Exclude all of them. Nothing is pushed until G0 passes. |
| **E-02** | Confirm the owner's approval of the Sumi mascot (CF-01) still stands, since five of the six breakdown documents forbid a mascot. | Fundamentally different visual identity. | Keep the mascot as built, with the constraints in CF-01. |
| **E-03** | Keep the S1 green/blue palette or move toward the emerald mascot (`#22C08B`)? (CF-31) | Trade-dress risk versus the explicit contract. | Keep S1 exactly. |
| **E-04** | Cloud AI provider, relay and retention policy (S3 open decisions). | Security and privacy. Learner text would leave the device. | Cloud stays "not configured". No requests are sent. |
| **E-05** | Change `applicationId` from `com.example.sumi` (GOV-03). | The change is effectively irreversible after a store or sideload release, because existing installs cannot upgrade in place. | Keep it for the demo build; change it before any public release. |

---

## 2. Tier summary

**X — Reproduce exactly (64):** SHL-01–04, ONB-01–08, ONB-10, ONB-11, PTH-01–12, PTH-14, LES-01–06, LES-08–11, LES-13, LES-14, LES-17, LES-18, RES-01, RES-03, RES-04, GAM-01–04, GAM-08, EVD-01, EVD-02, PRA-01, SET-01, SET-02, MOT-01–03, A11Y-01–05, GOV-04, GOV-05.

**F — Implement functionally (47):** GOV-01, GOV-02, ARC-01–05, ARC-07, SHL-05, ONB-09, ONB-12, PTH-13, LES-07, LES-12, LES-15, LES-16, LES-19–21, RES-02, GAM-05, GAM-06, EVD-03, EVD-04, PRA-02, LIB-01–04, PRO-01, PRO-02, SET-03–07, AIM-01, TUT-01–03, CUS-01, CUS-02, SND-01, SND-02, TYP-01, QA-01, QA-02.

**I — May improve (6):** ARC-06, GOV-03, A11Y-06, A11Y-07, MOT-04, QA-03.

**O — Optional (5):** GAM-07, SET-04-O, A11Y-08-O, CUS-03-O, LIB-05-O.

---

## 3. Summary index

| ID | Name | Tier | Pri | Current state | Phase (03) |
|---|---|---|---|---|---|
| GOV-01 | Repository hygiene and third-party exclusion | F | P0 | Git initialised with no commits; `.gitignore` misses the APKs [V] | 0 |
| GOV-02 | Compile and test baseline for today's uncompiled changes | F | P0 | Not analysed or tested [R] | 0 |
| GOV-03 | Build identity and version metadata | I | P3 | Hard-coded "v0.2.0 (Build 2)" [V] | 10 |
| GOV-04 | Original-asset rule and asset register | X | P0 | No register [V] | 0 / 9 |
| GOV-05 | No Duolingo references in shipped strings | X | P0 | `SumiAnim` labels such as `DUO_CHEER` appear in the Settings gallery [V] | 0 |
| ARC-01 | Single authoritative state; all mutations transactional | F | P0 | Onboarding and resource events bypass the transaction [V] | 1 |
| ARC-02 | Use-case layer | F | P1 | Partial; some methods unused [V] | 1 |
| ARC-03 | Schema v4 migration | F | P0 | v3 [V] | 1 |
| ARC-04 | Data-driven content: types, units, per-node challenges, checkpoints | F | P0 | Types inferred from IDs; challenges hard-coded [V] | 1 |
| ARC-05 | Remove discipline branching from code | F | P1 | `challengesFor`, assembler [V] | 1 |
| ARC-06 | Bound profile growth | I | P3 | Unbounded [V] | 10 |
| ARC-07 | Ledger invariants | F | P1 | Totals stored, not reconciled [V] | 1 |
| SHL-01 | Mobile column and gutters | X | P1 | ≤ 600 px column exists; gutters fixed at 20 [V] | 2 |
| SHL-02 | Four-tab bottom navigation | X | P1 | Material `NavigationBar` defaults [V] | 2 |
| SHL-03 | Tab state retention, no blank body | X | P0 | `IndexedStack` [V]; blank frames not re-verified | 2 |
| SHL-04 | Hide navigation in focused flows | X | P1 | Pushed routes cover it [V] | 2 |
| SHL-05 | Boot, loading and recovery states | F | P1 | Spinner plus retry [V] | 2 |
| ONB-01 | Promise screen | X | P1 | Text only; no wordmark or hero; "Continue" [V] | 3 |
| ONB-02 | Choose a discipline | X | P0 | Rows, not a grid; custom flow broken [V] | 3 |
| ONB-03 | Define the outcome | X | P1 | ≥ 3 chars; no constraint or prompt chips [V] | 3 |
| ONB-04 | Motivation | X | P1 | Different list and heading [V] | 3 |
| ONB-05 | Starting level | X | P1 | Different list and heading [V] | 3 |
| ONB-06 | Outcome preview | X | P1 | Shows the raw ID "Discipline: music" [V] | 3 |
| ONB-07 | Daily goal | X | P1 | No labels or workload sentence; default 15 [V] | 3 |
| ONB-08 | Starting route and branching | X | P0 | Both routes take the baseline [V] | 3 |
| ONB-09 | Baseline scoring rules | F | P1 | Working [V][R] | 3 |
| ONB-10 | Route reveal | X | P0 | Skipped [I] | 3 |
| ONB-11 | Onboarding chrome, persistence and resume | X | P0 | Continue is never disabled [V] | 3 |
| ONB-12 | Selected discipline equals active catalogue | F | P0 | Baseline uses `widget.catalog` [I] | 3 |
| PTH-01 | Goal/course strip | X | P1 | Missing [V] | 4 |
| PTH-02 | Path status row | X | P1 | AppBar shows "N pts" text [V] | 4 |
| PTH-03 | Unit header card | X | P1 | Exists; no depth edge; literal colours [V] | 4 |
| PTH-04 | Serpentine layout and connectors | X | P1 | No connectors; mirrored order [V] | 4 |
| PTH-05 | Node families and states | X | P1 | Unit-palette fills; locked nodes have depth [V] | 4 |
| PTH-06 | Node animation triggers and ordering | X | P1 | Implemented, uncompiled [V] | 4 |
| PTH-07 | Current-node indicator | X | P2 | START bubble only [V] | 4 |
| PTH-08 | Anchored node action card | X | P1 | White card with blur shadow, fixed 220 px [V] | 4 |
| PTH-09 | Locked node explanation | X | P1 | Generic text [V] | 4 |
| PTH-10 | Section overview | X | P2 | Pushed list page [V] | 4 |
| PTH-11 | Unit guide | X | P1 | Exists; no hero or slide grammar [V] | 4 |
| PTH-12 | Checkpoint (star) detail | X | P2 | Missing; no checkpoint data [V] | 4 |
| PTH-13 | Discipline scenes | F | P2 | One faint 100 px painter [V] | 9 |
| PTH-14 | Scroll restore and one auto-scroll | X | P1 | Restore exists; no auto-scroll to current [V] | 4 |
| LES-01 | Lesson header | X | P1 | AppBar with text "Focus N" [V] | 5 |
| LES-02 | Lesson state machine | X | P0 | Mostly present [V] | 5 |
| LES-03 | Sticky CHECK footer | X | P1 | 218 px tinted panel [V] | 5 |
| LES-04 | Correct feedback panel | X | P1 | Generic tint and copy [V] | 5 |
| LES-05 | Incorrect panel, Continue and requeue | X | P0 | Forced retry [V] | 5 |
| LES-06 | Near-correct panel | X | P1 | Forced retry [V] | 5 |
| LES-07 | Ungraded retry state | F | P1 | Exists [V] | 5 |
| LES-08 | Explain My Mistake screen | X | P1 | "Understand this response" page [V] | 5 |
| LES-09 | Lesson settings sheet | X | P2 | Plain sheet [V] | 5 |
| LES-10 | Exit confirmation | X | P1 | AlertDialog [V] | 5 |
| LES-11 | Focus buffer rules | X | P0 | Decrements on every incorrect [V] | 1 / 5 |
| LES-12 | Eight renderers with every state | F | P1 | Present [V] | 5 |
| LES-13 | Choice row component | X | P1 | Flat outline [V] | 2 / 5 |
| LES-14 | Token bank with stable placeholders | X | P2 | Partial [V] | 5 |
| LES-15 | Per-node content mix | F | P0 | Fixed per discipline [V] | 1 / 5 |
| LES-16 | Hints and "I don't know yet" | F | P1 | Baseline only [V] | 5 |
| LES-17 | Lesson loading screen | X | P2 | None (opens directly) [V] | 5 |
| LES-18 | Persist before feedback, points or animation | X | P0 | Implemented [V][R] | 5 |
| LES-19 | Lifecycle restore | F | P1 | Implemented [V][R] | 5 |
| LES-20 | Re-entering a completed node | F | P2 | Opens a new session [V] | 5 |
| LES-21 | Project evidence: structured reflection | F | P1 | Single free-text reflection [V] | 5 |
| RES-01 | Result screen contents | X | P1 | Points, accuracy and time only [V] | 6 |
| RES-02 | Accolade resolver and discipline payloads | F | P2 | Inline in the assembler [V] | 6 |
| RES-03 | Checkpoint failure result | X | P2 | Missing [V] | 6 |
| RES-04 | Continue → path → events → next card | X | P1 | Returns to path [V] | 6 |
| GAM-01 | Points formula | X | P1 | Flat 20 [V] | 1 / 6 |
| GAM-02 | Reward idempotency | X | P0 | Stable event IDs [V] | 1 |
| GAM-03 | Streak and recovery tokens | X | P1 | Streak works; no tokens [V] | 6 |
| GAM-04 | Daily quests | X | P2 | Missing [V] | 6 |
| GAM-05 | Sparks (cosmetic only) | F | P3 | Balance accrues; never spent [V] | 6 |
| GAM-06 | Streak screen (personal) | F | P2 | Missing [V] | 6 |
| GAM-07 | Weekly achievements | O | P3 | Missing | 6 |
| GAM-08 | No leaderboard or social UI | X | P1 | None [V] | — |
| EVD-01 | Seven evidence states and promotion | X | P0 | Implemented; `demonstrated` added on accuracy 1 [V] | 1 |
| EVD-02 | Transfer only from a different context or a project | X | P0 | To verify [I] | 1 |
| EVD-03 | Review scheduler | F | P1 | Missing [V] | 7 |
| EVD-04 | "Why Sumi believes this" | F | P2 | Missing [V] | 7 |
| PRA-01 | Practice sections and copy | X | P1 | Generic list [V] | 7 |
| PRA-02 | Practice runs through the same transaction | F | P1 | Opens milestones [V] | 7 |
| LIB-01 | Library groups | F | P1 | Ranked list [V] | 7 |
| LIB-02 | Resource card fields | F | P1 | Partial [V] | 7 |
| LIB-03 | Detail sheet, return-safe | F | P1 | Exists [V] | 7 |
| LIB-04 | Resource events; no evidence from views | F | P0 | Events exist; mutated outside the transaction [V] | 1 / 7 |
| LIB-05-O | Embedded official video player | O | P3 | External launch [V] | — |
| PRO-01 | Engagement and evidence panels separated | F | P1 | Partly [V] | 7 |
| PRO-02 | AI mode and privacy shown in Profile | F | P2 | Missing [V] | 7 |
| SET-01 | Settings section order | X | P1 | Flat list [V] | 7 |
| SET-02 | Every status truthful | X | P0 | Reminders and cloud rows misleading [V] | 7 |
| SET-03 | Learning preferences | F | P2 | Minutes only [V] | 7 |
| SET-04 | Reminders labelled honestly | F | P0 | Can claim enabled [V] | 7 |
| SET-04-O | Real reminder schedule | O | P3 | — | — |
| SET-05 | Accessibility sub-screen | F | P1 | Reduced motion only [V] | 7 |
| SET-06 | Storage and privacy scoped actions | F | P2 | Reset dialogs [V] | 7 |
| SET-07 | About and licences | F | P3 | Static copy [V] | 7 |
| AIM-01 | Offline AI models | F | P1 | Working [R] | — (regress only) |
| TUT-01 | Tutor entry points and context | F | P1 | Path AppBar icon; explain button [V] | 8 |
| TUT-02 | Provider badge and consent | F | P0 | Consent stored in `constraints` [V] | 8 |
| TUT-03 | Cloud honesty | F | P0 | Canned stub [V] | 8 |
| CUS-01 | Honest custom-discipline state | F | P0 | Broken [I] | 3 / 8 |
| CUS-02 | Validated provisional plan | F | P2 | Validator unused [V] | 8 |
| CUS-03-O | Cloud-drafted plan | O | P3 | — | — |
| MOT-01 | Motion tokens | X | P1 | Ad hoc durations [V] | 2 |
| MOT-02 | Event-to-animation contract | X | P1 | Partial [V] | 5 / 6 / 9 |
| MOT-03 | Reduced motion | X | P0 | Partial [V] | 2 |
| MOT-04 | Loop guard and backgrounding | I | P1 | Ad hoc [V] | 2 |
| SND-01 | Sound effects | F | P2 | WAVs not registered [V] | 9 |
| SND-02 | Haptics toggle | F | P2 | Unconditional haptics [V] | 9 |
| TYP-01 | Bundled rounded font and tabular numbers | F | P1 | Arial [V] | 2 |
| A11Y-01 | Semantics for every control | X | P0 | Partial [V] | 2–7 |
| A11Y-02 | 48 × 48 targets | X | P1 | Mostly [V] | 2 |
| A11Y-03 | Icon + text + colour for state | X | P0 | Partial [V] | 2–5 |
| A11Y-04 | 200 % text without clipping | X | P1 | Partial; fixed heights [V] | 2–7 |
| A11Y-05 | Announcements | X | P1 | Feedback title is a live region [V] | 5 |
| A11Y-06 | Contrast above the minimum | I | P1 | Fails for primary labels [V] | 2 |
| A11Y-07 | Focus ring and order | I | P2 | Inputs only [V] | 2 |
| A11Y-08-O | Number-key choice shortcuts | O | P3 | — | — |
| QA-01 | Golden and viewport suite | F | P1 | None [V] | 10 |
| QA-02 | Device script and contact sheet | F | P1 | Previous recordings [R] | 10 |
| QA-03 | Content lint | I | P2 | None [V] | 1 |

---

## 4. Requirement cards

Card fields: **Function** · **Visual** · **Interaction and states** · **Files** (existing) · **Change** · **Depends on** · **Accept** (acceptance criteria) · **Verify** · **Tier / Priority / Sources**.

### 4.1 Governance

#### GOV-01 — Repository hygiene and third-party exclusion

- **Function:** The public repository contains only Sumi-owned or properly licensed material.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `.gitignore`, `research/rea-duolingo-android-2026-10-29/*.apk`, `rea-apk-inventory-evidence.json`, `tools/jadx-headless-mcp*`, `research/captures/*.png`, `research/live-reference-2026-10-29/{frames,*.png}`, `research/animation-reference/{media,runtime,download-pack.zip}`, `OPEN-BUILD-reference-pack.zip`, `Mascot concepts`, `research/duolingo-landing-*`, `research/rea-evidence-bundle.json`.
- **Change:** Extend `.gitignore` with each path above. Add `research/THIRD_PARTY_EXCLUDED.md`, which explains what was excluded and why. Run `git status --ignored` and `git check-ignore -v` for every listed path.
- **Depends on:** E-01.
- **Accept:** `git ls-files` lists none of the paths. The README states that the reference material is private and not redistributed.
- **Verify:** A script, `scripts/check_repo_hygiene.ps1`, fails if any `*.apk`, `*.riv`, Lottie JSON, Duolingo-named file or capture PNG is tracked.
- **Tier / Priority / Sources:** F · P0 · S7 §7.2, S1 §0, S8 §6.

#### GOV-02 — Compile and test baseline

- **Function:** Today's uncompiled changes compile, and the existing suite is green before feature work starts.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** All files listed in S7 §8; `test/session_recording_test.dart`.
- **Change:** Run `.\scripts\flutter.ps1 analyze` and `.\scripts\test-ui.ps1`. Fix analyzer errors. Fix the harness bug "a painting debug variable was changed" by resetting `debugPaint*` flags in `tearDown`. Re-check the stale "Key ideas" failure.
- **Depends on:** —
- **Accept:** Zero analyzer issues. All tests pass, with the count recorded (≥ 68).
- **Verify:** Logs saved to `.tooling/phase0-analyze.log` and `.tooling/phase0-test.log`.
- **Tier / Priority / Sources:** F · P0 · S7 §5.1, §11.

#### GOV-03 — Build identity and version metadata

- **Function:** About shows the real version and build.
- **Visual:** A plain list row (DC §7.30).
- **Interaction and states:** None.
- **Files:** `main.dart` (Settings), `pubspec.yaml`, `android/app/build.gradle*`.
- **Change:** Add `package_info_plus`. Read version and build at runtime. Replace the hard-coded string. Change `applicationId` only after E-05 is decided.
- **Depends on:** E-05.
- **Accept:** About shows `Sumi <version> (<build>)` matching `pubspec.yaml`.
- **Verify:** A widget test with a mocked `PackageInfo`.
- **Tier / Priority / Sources:** I · P3 · S2 P3.1.

#### GOV-04 — Original-asset rule and asset register

- **Function:** Every shipped icon, illustration, sound, font and animation is original or licensed, and is recorded.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `app/assets/**`, `lib/mascot/`, `lib/motion/`, `scripts/make_sounds.py`.
- **Change:** Create `app/assets/ASSETS.md`. Each entry has the ID, file, author, licence, editable source, runtime export, logical size, semantic label, and reduced-motion poster where one applies (S1 §7.2).
- **Depends on:** —
- **Accept:** Every file under `app/assets/` has an entry. No research asset is referenced from `app/`.
- **Verify:** A test compares `ASSETS.md` against `pubspec.yaml` assets and the files on disk.
- **Tier / Priority / Sources:** X · P0 · S1 §7, S5 header, S6.

#### GOV-05 — No Duolingo references in shipped strings

- **Function:** No user-visible text names Duolingo assets, slots or characters.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `lib/mascot/sumi_rig.dart` (`SumiAnim` labels `DUO_*`, "Streak phoenix transformation"), the Settings "Sumi animation library" row in `main.dart`.
- **Change:** Move the reference-slot labels to a debug-only map, compiled out of release builds with `kReleaseMode`. Show the gallery only in debug builds, under About.
- **Depends on:** —
- **Accept:** `strings` or a grep of the release APK's Dart snapshot finds no `DUO_` and no "Duolingo".
- **Verify:** A content-lint test (QA-03) that scans `lib/**` string literals outside `kDebugMode` blocks.
- **Tier / Priority / Sources:** X · P0 · S1 §7, CF-01.

### 4.2 Architecture and data

#### ARC-01 — Single authoritative state; all mutations transactional

- **Function:** Every write to learner data goes through `LocalStore.transaction` (clone → mutate → write → apply).
- **Visual:** None.
- **Interaction and states:** On failure, the screen keeps its current state and shows a retryable inline error (DC §7.36).
- **Files:** `services.dart`, `main.dart` (`persist()`, `openResourceDetail`, `toggleSaveResource`, `OnboardingFlow.nextStep`, the baseline `onAttempt` that calls `learning.attempts.add`), `lesson_shell.dart` (the reduced-motion toggle already uses a transaction).
- **Change:** Delete `LearningHome.persist()` as a mutation path. Every call site goes through a use case (ARC-02). Add an assertion in debug builds: `LearningState` setters throw when called outside a transaction (a guard flag).
- **Depends on:** ARC-02.
- **Accept:** A grep finds no `store.save(` outside `LocalStore`. Fault-injection tests (a store that throws on write) leave the in-memory state unchanged for onboarding, resource save, attempt and completion.
- **Verify:** New `test/transaction_guard_test.dart`.
- **Tier / Priority / Sources:** F · P0 · S3 P1.4, S2 §5, S7 risk 8.

#### ARC-02 — Use-case layer

- **Function:** Screens call use cases, never mutate state directly.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `services.dart` (`LearningService`); new `lib/application/use_cases.dart`.
- **Change:** Define `CompleteActivity`, `RecordAttempt`, `RecordResourceUse`, `QualifyDailyGoal`, `GetNextLearningSession`, `AskTutor`, `SaveOnboardingAnswer`, `FinishOnboarding`, `UpdateSetting`. Each is one class with a `call()` that wraps exactly one transaction. Reuse and remove the unused `LearningService` methods (S7 §6.4).
- **Depends on:** —
- **Accept:** Widgets import `application/use_cases.dart` and not `services.dart` (except the composition root).
- **Verify:** An import-lint test that greps imports under `lib/**/` screens.
- **Tier / Priority / Sources:** F · P1 · S3 P1.

#### ARC-03 — Schema v4 migration

- **Function:** Version 4 of the learner record supports: nullable onboarding answers; separate `settings` (sound, haptics, reduced motion, high contrast, text mode, AI mode, cloud consent); a reward ledger with source IDs and reward types; per-challenge first-attempt flags; review due dates; a quest state; streak recovery tokens.
- **Visual:** None.
- **Interaction and states:** A failed migration shows the recovery screen (SHL-05). It never silently resets.
- **Files:** `models.dart` (`LearningState.fromJson`, `fromV2`), `services.dart` (keys `sumi.learning.v3.<track>`).
- **Change:** Add `LearningState.fromV3`, which writes to `sumi.learning.v4.<track>` and keeps the v3 key untouched until the v4 write succeeds. Rules:
  - Move `onboarding.constraints['cloud_consent_given']` to `settings.cloudConsent`.
  - Keep completed onboarding answers. Clear default answers for *incomplete* onboarding at step ≤ 3.
  - Back-fill reward-ledger entries from `rewardedEventIds`, keeping existing totals; never recompute old points.
- **Depends on:** —
- **Accept:** A v3 fixture taken from a real device export loads with identical points, streak, completed nodes and evidence. The v3 key still exists after migration.
- **Verify:** `test/migration_v4_test.dart` with three fixtures: fresh, mid-onboarding, and completed with progress.
- **Tier / Priority / Sources:** F · P0 · S1 §0, §14; S3 P1.10.

#### ARC-04 — Data-driven content

- **Function:** The path structure and challenges come from data.
- **Visual:** Drives PTH-05 node families.
- **Interaction and states:** None.
- **Files:** `assets/disciplines.json`, `scripts/build_disciplines.py`, `models.dart` (`Milestone`, `_parseNodeType`), `learning_path_state.dart` (`LearningUnit.forCatalog`), `challenge_definition.dart` (`challengesFor`).
- **Change:** Extend the schema with:
  - `units[] {id, title, outcome, palette, guide{key_ideas[], watch[], reference[], try}}`;
  - `skills[].type` (`micro_lesson | guided_practice | recall_review | video_resource | project_step | checkpoint | reward_unlock`);
  - `skills[].unit_id`;
  - `skills[].challenges[] {id, kind, prompt, explanation, options, answer, content, parallel_of?, hint?}`.

  Add per unit one `video_resource` node bound to the existing video resource, one `checkpoint` and one `reward_unlock`. `challengesFor` becomes a pure loader that returns `skills[].challenges`, falling back to today's sequence when the list is absent. `_parseNodeType` keeps the ID heuristic only as a fallback for old data.
- **Depends on:** LES-15 (content authoring).
- **Accept:** No `catalog.id == 'music'` or `'fashion'` branches in `challenge_definition.dart` or `session_result_assembler.dart`. Each track exposes all seven node types.
- **Verify:** `test/content_schema_test.dart` validates every track: IDs unique, prerequisites acyclic, every challenge valid and gradeable, every `video_resource` linked to an existing resource.
- **Tier / Priority / Sources:** F · P0 · S7 §6.1, §6.5, §9.1, §9.3; S4 §5.3; S2 P1.5.

#### ARC-05 — Discipline branching removed from code

- **Function:** Adding a discipline needs data only.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `challenge_definition.dart`, `session_result_assembler.dart`, `main.dart`, `path_screen.dart` (`_DisciplineScene`), `session_result_screen.dart` (`celebrationType`).
- **Change:** Evidence categories, celebration type, scene ID and copy nouns move into track data (`evidence_categories[]`, `celebration`, `scene`).
- **Depends on:** ARC-04.
- **Accept:** A grep finds no `'music'` or `'fashion'` literals in `lib/` outside tests and fixtures.
- **Verify:** QA-03 lint.
- **Tier / Priority / Sources:** F · P1 · S7 risk 9, S2 P1.5.

#### ARC-06 — Bound profile growth

- **Function:** Old sessions and events are compacted.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `models.dart`, `services.dart`.
- **Change:**
  - Keep the full detail of the last 50 sessions per track and roll older ones up to `{sessionId, nodeId, result}`.
  - Cap `resourceEvents` and `adaptationEvents` at 2,000 each, after folding them into aggregates.
  - Never drop anything referenced by an evidence explanation (EVD-04).
- **Depends on:** EVD-04.
- **Accept:** A synthetic profile with 1,000 sessions saves in < 150 ms on the test device. Explanations still resolve.
- **Verify:** A unit test plus a timing log.
- **Tier / Priority / Sources:** I · P3 · S7 risk 7.

#### ARC-07 — Ledger invariants

- **Function:** Displayed totals equal the sum of the ledger.
- **Visual:** None.
- **Interaction and states:** None.
- **Files:** `models.dart` (`EngagementState`).
- **Change:**
  - `pointsTotal` and `pointsWeek` become derived getters over `rewardTransactions`.
  - The week starts Monday 00:00 local time.
  - Every completed assessed node has ≥ 1 attempt.
  - A streak day has ≥ 1 qualifying event that day.
- **Depends on:** ARC-03.
- **Accept:** The six invariants in S2 §5 hold for every fixture.
- **Verify:** `test/invariants_test.dart`, property-style, over random action sequences.
- **Tier / Priority / Sources:** F · P1 · S2 §5.

### 4.3 Shell

#### SHL-01 — Mobile column and gutters

- **Function:** One phone column on every screen.
- **Visual:** Maximum width 600, centred. Horizontal gutters of 16 / 20 / 24 at widths 320–359 / 360–419 / ≥ 420 (DC §4.2). Canvas `#FFFFFF`. Outside the column, `surfaceSoft`.
- **Interaction and states:** None.
- **Files:** `main.dart` (`SumiApp.builder`), all screens using hard-coded `EdgeInsets.all(20/24)`.
- **Change:** Add `SumiLayout.gutter(context)` and use it everywhere. No literal horizontal padding.
- **Depends on:** —
- **Accept:** Screenshots at 320, 360, 390, 430 and 600 px show the gutter rule.
- **Verify:** Golden tests (QA-01).
- **Tier / Priority / Sources:** X · P1 · S1 §3, §6.3.

#### SHL-02 — Four-tab bottom navigation

- **Function:** Learn, Practice, Library, Profile, in that order.
- **Visual:**
  - Bar height 64 plus the safe-area inset, white, with a 2 px `border` top line.
  - Original filled icons at 24 px; labels 12/16 weight 700.
  - Selected: a 56 × 32 tile filled `skySoft` with a 2 px `sky` outline, radius 12; icon and label `infoInk`.
  - Unselected: `muted`.

  (DC §7.10)
- **Interaction and states:**
  - Tap switches instantly. No transition through white; a crossfade of ≤ 120 ms is allowed.
  - Re-tapping the active tab scrolls it to the top.
  - Focus shows the 3 px ring.
- **Files:** `main.dart` (`NavigationBar`), `theme.dart` (`navigationBarTheme`).
- **Change:** Replace the Material `NavigationBar` with `SumiBottomNav` (custom) for the exact tile treatment.
- **Depends on:** MOT-01, TYP-01.
- **Accept:** Goldens match DC §7.10. Semantics announce "Learn, tab, 1 of 4, selected".
- **Verify:** Golden and semantics tests.
- **Tier / Priority / Sources:** X · P1 · S1 §5.2, S5 §4.4, CF-14.

#### SHL-03 — Tab state retention, no blank body

- **Function:** Switching tabs never shows an empty body. Each tab keeps its scroll position and selection.
- **Visual:** Cached content on the first frame. A destination-shaped skeleton only for genuine async work, and only after 150 ms (DC §7.35).
- **Interaction and states:** Five rapid tab changes show no spinner, blank page or lost state.
- **Files:** `main.dart` (`IndexedStack` exists).
- **Change:** Keep the `IndexedStack`. Ensure no tab returns an empty `Container`/`SizedBox` while loading. Add pointer-up → first-meaningful-paint timing in debug builds.
- **Depends on:** —
- **Accept:** Tab change paints meaningful content in ≤ 100 ms on the device. No frame in a 60 fps recording has a blank body.
- **Verify:** `test/tab_retention_test.dart` with slow fake repositories; QA-02 contact sheet.
- **Tier / Priority / Sources:** X · P0 · S2 P0.1, S3 P1.1.

#### SHL-04 — Hide navigation in focused flows

- **Function:** No bottom bar during onboarding, lessons, baseline, explain, checkpoint detail, guide, model import or modal project submission.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `main.dart`, routes.
- **Change:** These flows push routes on the root navigator, not inside a tab.
- **Depends on:** —
- **Accept:** No `NavigationBar` or `SumiBottomNav` widget is present in those routes.
- **Verify:** A widget test per route.
- **Tier / Priority / Sources:** X · P1 · S1 §5.2.

#### SHL-05 — Boot, loading and recovery states

- **Function:** The boot screen shows the Sumi wordmark and a progress indicator. A failed migration opens a recovery screen: "We couldn't open your progress." It offers Try again, Export recovery file and Start a fresh profile (with confirmation; the original data is kept).
- **Visual:** DC §8.1.
- **Interaction and states:** loading → ready | error → retry.
- **Files:** `main.dart` (`boot`).
- **Change:** Replace the generic copy. Add the recovery route (S1 §5.1, `RecoveryScreen`).
- **Depends on:** ARC-03.
- **Accept:** An injected migration error never deletes the old keys.
- **Verify:** Unit and widget tests.
- **Tier / Priority / Sources:** F · P1 · S1 §5.1, §16.

### 4.4 Onboarding

All onboarding screens share ONB-11. All copy is exact (DC §11.1).

#### ONB-01 — Promise screen

- **Function:** Explains the product before the technology.
- **Visual:** From top to bottom:
  - safe area;
  - centred Sumi wordmark, 144 px wide;
  - flexible space;
  - 232 px original hero (knowledge tiles flowing along a curved route to a project object);
  - promise text at 30/37 weight 800, centred, maximum three lines;
  - support line at 16/24 `muted`;
  - flexible space;
  - full-width primary "GET STARTED";
  - outlined "CONTINUE MY PROGRESS", only when recoverable progress exists;
  - 20 px bottom spacing.

  No progress bar or back button on this screen (DC §8.2).
- **Interaction and states:** GET STARTED → discipline step. The mascot may greet (one-shot `greet`, poster frame under reduced motion), placed above the hero or replacing it per CF-01. No carousel, no permissions.
- **Files:** `main.dart` `buildScreenContent` case 0.
- **Change:** Rebuild per the layout above. Extract the flow to `lib/onboarding/`.
- **Depends on:** TYP-01, the tactile button, GOV-04 hero asset.
- **Accept:** Golden matches. The primary action is visible without scrolling at 320 × 640 at 100 % text.
- **Verify:** Golden and widget tests.
- **Tier / Priority / Sources:** X · P1 · S1 §9.1.

#### ONB-02 — Choose a discipline

- **Function:** Pick Music, Fashion Design & Tailoring, or Something else.
- **Visual:**
  - Heading "What do you want to learn?" (24/30, weight 800).
  - Two-column grid of `DisciplineCard`s, minimum 156 × 180, radius 16, 2 px `border`, 3 px `borderShadow` bottom edge. Each has a 72 px original graphic, title 17/22 weight 700, and subtitle 14/20.
  - "Something else" spans both columns.
  - Selected card: `skySoft` fill, `sky` border and edge, check badge (DC §7.27).
- **Interaction and states:**
  - Select, then CONTINUE (CF-17). Selecting Something else opens a rounded-top sheet with a text field ("Describe the skill or project you want to learn") and CONTINUE. It then follows CUS-01.
  - Selecting a reviewed discipline calls `SelectDiscipline` (ONB-12).
- **Files:** `main.dart` case 1.
- **Change:** Grid, graphics, sheet; remove the immediate state change in `onTap` that bypasses the transaction.
- **Depends on:** ONB-12, CUS-01, GOV-04.
- **Accept:** CONTINUE is disabled with no selection. A 320 px width keeps two columns, with cards ≥ 140 wide; the card minimum flexes there (DC §9).
- **Verify:** Widget and golden tests.
- **Tier / Priority / Sources:** X · P0 · S1 §9.2, CF-17.

#### ONB-03 — Define the outcome

- **Function:** Capture the outcome (20–200 characters), an optional deadline and optional constraints.
- **Visual:**
  - Heading "What would you like to be able to do?"
  - A multiline field with a live character count (`12/200`, turning `coral` above 200).
  - Two to four track prompt chips above the field (DC §11.1).
  - Deadline chips: None, 2 weeks, 1 month, 3 months, Custom date (date picker).
  - Constraint chips: Phone only, Low bandwidth, No equipment, Beginner materials, Accessibility need, Other.
- **Interaction and states:**
  - A prompt chip fills the field (editable).
  - CONTINUE is enabled only when the trimmed length is 20–200.
  - The keyboard never covers the field or CONTINUE (inset-aware scroll).
  - Nothing is generated per keystroke.
- **Files:** `main.dart` case 2.
- **Change:** As specified.
- **Depends on:** —
- **Accept:** 19 characters disables CONTINUE; 20 enables it; 201 disables it.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.3.

#### ONB-04 — Motivation

- **Function:** Single choice from S1's eight motivations, in order.
- **Visual:**
  - Heading "Why does this goal matter to you?"
  - `ChoiceRow`s with a 28 px original icon (DC §7.2).
  - Below the list, one support line that changes with the selection (DC §11.1).
- **Interaction and states:** Select, then CONTINUE. No default.
- **Files:** `main.dart` case 3.
- **Change:** Replace the list and heading.
- **Depends on:** LES-13 component.
- **Accept:** Exact strings; CONTINUE is disabled until a selection.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.4.

#### ONB-05 — Starting level

- **Function:** Self-report on S1's five levels. It sets the baseline's first difficulty only.
- **Visual:** Heading "How much experience do you have with this?" Choice rows with level-bar icons.
- **Interaction and states:** Select, then CONTINUE.
- **Files:** `main.dart` case 4.
- **Change:** Replace the list and heading.
- **Depends on:** —
- **Accept:** No evidence state changes from this answer.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.5.

#### ONB-06 — Outcome preview

- **Function:** Reassurance screen. No input.
- **Visual:**
  - Heading "Here's what your route will help you do."
  - Exactly three rows with 48 px icons. Track-specific text comes from data (`preview_capabilities[3]`).
  - Custom goals show a `PROVISIONAL` tag.
- **Interaction and states:** CONTINUE is always enabled.
- **Files:** `main.dart` case 5.
- **Change:** Remove "Discipline: $selectedDisciplineId".
- **Depends on:** ARC-04 data.
- **Accept:** No raw IDs on screen.
- **Verify:** Golden test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.6.

#### ONB-07 — Daily goal

- **Function:** Choose 5, 10, 15 or 20 min/day.
- **Visual:**
  - Heading "What's your daily learning goal?"
  - Rows read "5 min/day" on the left and "Casual" (`muted`) on the right; likewise Regular, Serious, Intense.
  - After a selection, a workload sentence: "At {m} minutes a day, the first project is roughly {a}–{b} sessions." with a `PROVISIONAL` tag.
- **Interaction and states:**
  - No default.
  - The range is computed from the route: total node minutes to the first project node ÷ m, then ±25 %, with floor and ceiling.
- **Files:** `main.dart` case 6.
- **Change:** As specified.
- **Depends on:** ARC-04.
- **Accept:** The sentence always shows a range, never a single number.
- **Verify:** Unit test of the estimator.
- **Tier / Priority / Sources:** X · P1 · S1 §9.7.

#### ONB-08 — Starting route and branching

- **Function:** "Start from the basics" or "Find my level".
- **Visual:** Heading "Let's find the best place to start." Two large choice cards, each with an icon, title and S1 subtitle.
- **Interaction and states:**
  - **Basics:** skip the six-question baseline. Mark the goal `startingRoute=basics`. The first lesson then includes three lower-difficulty check challenges, tagged `CHECK` and drawn from the baseline pool.
  - **Find my level:** run the baseline (ONB-09).
  - Both routes end at the route reveal (ONB-10).
- **Files:** `main.dart` cases 7–8, `assessment.dart`, `challenge_definition.dart`.
- **Change:** As specified. `GetNextLearningSession` injects the basics checks.
- **Depends on:** ARC-02, ARC-04.
- **Accept:** The two routes produce different first sessions (S1 §19 test).
- **Verify:** `test/onboarding_routes_test.dart`.
- **Tier / Priority / Sources:** X · P0 · S1 §9.8, CF-20.

#### ONB-09 — Baseline scoring rules

- **Function:**
  - The first response is permanent.
  - Correct without a hint = independent; correct after a hint = supported; incorrect then corrected = repair.
  - Skip = no evidence.
  - Active time excludes waiting and background time.
  - No percentage shown.
- **Visual:** Uses the lesson shell (LES-01 to 06). "I DON'T KNOW YET" is a secondary action in the footer. "Show hint" is a text button under the prompt, at most once per item.
- **Interaction and states:** Leaving and resuming mid-baseline restores the exact item and draft.
- **Files:** `assessment.dart`.
- **Change:** Re-skin to the lesson shell components. The logic is already correct [V][R].
- **Depends on:** LES-01, LES-03.
- **Accept:** Existing assessment tests are green; a new test covers resume.
- **Verify:** Tests.
- **Tier / Priority / Sources:** F · P1 · S1 §9.9.

#### ONB-10 — Route reveal

- **Function:** Shows that the route is ready and why.
- **Visual:**
  - Heading "Your first route is ready."
  - Goal summary card.
  - "Based on {n} starting checks" (or "Based on your starting choice" for Basics).
  - A mini path preview with 3–6 nodes, using the same node component at 0.66 scale.
  - First deliverable; the session range; a confidence tag (`EARLY` / `GROWING` / `SUPPORTED`).
  - An expandable "Why this route?" card listing the observed evidence and the assumptions.
  - Primary "START FIRST LESSON".
- **Interaction and states:**
  - The path-reveal animation (`pathReveal` 420 ms: nodes fade and rise, staggered by 60 ms; reduced motion = instant).
  - A model is mentioned only if one contributed.
  - START FIRST LESSON finishes onboarding (one transaction), shows the path, and opens the first lesson directly.
- **Files:** `main.dart` case 9, `nextStep`.
- **Change:** Fix the step-8 completion skip (CF-19).
- **Depends on:** ONB-08, PTH-05.
- **Accept:** A fresh install always shows this screen before the path.
- **Verify:** `test/onboarding_flow_test.dart`.
- **Tier / Priority / Sources:** X · P0 · S1 §9.10.

#### ONB-11 — Onboarding chrome, persistence and resume

- **Function:**
  - Back control (from step 1 on).
  - A 10 px top progress bar using the `ProgressBar` component, filling (step + 1) / total.
  - One decision per screen.
  - A sticky primary action that is disabled until valid.
  - Every valid answer is persisted immediately (`SaveOnboardingAnswer`).
  - Reopening returns to the same step with the same selection.
- **Visual:** DC §8.2.
- **Interaction and states:**
  - Forward and back use a horizontal slide (`screen` 220 ms; crossfade under reduced motion).
  - Android back = the Back control.
- **Files:** `main.dart` (`OnboardingFlow`).
- **Change:** Remove the defaults (CF-18). Add per-step validity.
- **Depends on:** ARC-02, ARC-03.
- **Accept:** S1 §19: "Continue disabled until valid selection"; "Back and resume preserve each selection".
- **Verify:** Widget tests, including a kill-and-restore simulation using `MemoryPreferences`.
- **Tier / Priority / Sources:** X · P0 · S1 §4, §5.1, §9.

#### ONB-12 — Selected discipline equals the active catalogue

- **Function:** The baseline, outcome chips and preview always use the catalogue the learner selected.
- **Visual:** —
- **Interaction and states:** Changing the discipline mid-onboarding keeps the other discipline's progress untouched.
- **Files:** `main.dart` (`OnboardingFlow` gets `widget.catalog`; `selectDiscipline`).
- **Change:** `OnboardingFlow` is keyed by the selected track. `SelectDiscipline` calls `setActiveTrack` before the baseline.
- **Depends on:** ARC-02.
- **Accept:** Selecting Fashion while Music is active runs Fashion baseline questions.
- **Verify:** `test/discipline_flow_test.dart` extension.
- **Tier / Priority / Sources:** F · P0 · S7 §6.2, S3 P1.8.

### 4.5 Learn path

#### PTH-01 — Goal/course strip

- **Function:** Shows the active disciplines and goals, and switches between them while keeping each path's position.
- **Visual:**
  - A full-width `ink` band, 48 px tall, under the status-bar inset.
  - Horizontally scrollable uppercase tab labels at 14/18 weight 800: selected = white with a 3 px × 24 px white underline; unselected = white at 60 % opacity.
  - The last item is "+ ADD".
  - Below it, the path surface: white, with top corners of radius 24 overlapping the band by 24 px (DC §7.11).
- **Interaction and states:**
  - Tap → `SelectDiscipline` (switch in ≤ 100 ms using cached state; skeleton otherwise).
  - "+ ADD" opens the discipline chooser (ONB-02 grammar, full-screen, Continue disabled until valid).
  - Long names truncate with an ellipsis at 160 px.
- **Files:** `path_screen.dart` (`AppBar`), `main.dart`.
- **Change:** New `goal_course_strip.dart`. Remove the path AppBar.
- **Depends on:** ONB-12.
- **Accept:** Switching Music → Fashion → Music restores the Music scroll offset exactly.
- **Verify:** Widget and golden tests.
- **Tier / Priority / Sources:** X · P1 · S5 §4.1–4.2, S6, CF-16.

#### PTH-02 — Path status row

- **Function:** Compact stats for the active goal.
- **Visual:**
  - A 44 px row inside the surface. Left: a 32 px discipline badge.
  - Right: streak (flame icon + tabular count, `amber` when today qualified, `disabledText` when not) and points (burst icon + tabular count, `amber`).
  - Each is a 48 px-tall tappable pill (DC §7.13).
  - No Focus here (CF-15).
- **Interaction and states:**
  - Tapping streak opens the streak screen (GAM-06).
  - Tapping points opens an anchored popover over a dimmed path: "Points this week: N · Points measure practice, not mastery." It closes on an outside tap or Esc.
  - When values change, the counter increments (`micro` 160 ms).
- **Files:** `path_screen.dart`.
- **Change:** New `path_status_row.dart`.
- **Depends on:** GAM-01, GAM-03.
- **Accept:** Semantic labels such as "Streak, 3 days, today completed" and "Points, 140".
- **Verify:** Semantics test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S2 P2.3, S5 §4.3.

#### PTH-03 — Unit header card

- **Function:** Anchors the unit: eyebrow, outcome title, progress, guide action, and access to sections.
- **Visual:**
  - Full content width, radius 16, unit palette fill, 4 px bottom edge in the unit shadow colour.
  - Left area: eyebrow "UNIT {n} · {done}/{total} STEPS" at 12/16 weight 800 in white at 80 %; title at 20/26 weight 800 white, maximum two lines.
  - Right segment: 64 px wide, divided by a 2 px line at white 25 %, with a 28 px guidebook icon and the label "GUIDE".
  - No in-card progress bar (the eyebrow carries progress).

  (DC §7.14)
- **Interaction and states:**
  - The card body opens the section overview.
  - The guide segment opens the unit guide (PTH-11).
  - Pressed: translate 3 px and collapse the edge (as a button).
- **Files:** `path_screen.dart` (`UnitHeaderCard`, `_palettes`).
- **Change:** Use tokens, the depth edge and the two tap zones.
- **Depends on:** CF-13 tokens.
- **Accept:** At 200 % text the title wraps to at most three lines with no overflow.
- **Verify:** Golden test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S5 §5.1, S4 P1.5.

#### PTH-04 — Serpentine layout and connectors

- **Function:** Lays out the unit's nodes vertically.
- **Visual:**
  - Node pitch 104 px.
  - Horizontal offsets follow the sequence 0, −A, 0, +A, … with A = min(76, (contentWidth − 72) / 2 − 16).
  - Connectors: an 8 px-wide rounded quadratic curve between node centres, under the nodes, coloured `border`; segments between two completed nodes are `primary`.
  - Discipline scene slots sit on the opposite side of the offset at nodes 2 and 5 of each unit (PTH-13).
  - The first node is 24 px below the header.
  - 96 px of bottom padding.
- **Interaction and states:** Connector colour animates when a completion event plays (`pathReveal` 420 ms; instant under reduced motion).
- **Files:** `path_screen.dart` (`SerpentinePath`).
- **Change:** Invert the offset order (centre, left, centre, right). Add `PathConnectorPainter`.
- **Depends on:** —
- **Accept:** Goldens at 320 and 430 px show no node clipped and no connector crossing a node.
- **Verify:** Golden test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S2 P1.1, CF-10.

#### PTH-05 — Node families and states

- **Function:** Each node shows its type and its state.
- **Visual (DC §7.12):**
  - Main disc 72 × 72 with a 6 px bottom edge; checkpoint discs are 82.
  - Inner top highlight (34 × 9 at white 28 %).
  - Icon 32 px.
  - Type → fill when available: micro-lesson, guided practice and video = `primary`; recall review = `violet`; project = `sky`; checkpoint and reward = `amber` (with an `ink` icon).
  - State overrides:
    - locked = `disabled` fill, lock icon in `disabledText`, **no** edge;
    - completed = `primarySoft` fill, 3 px `primary` outline, `primary` check icon (checkpoint completed = amber with a crown);
    - mastered = completed plus a small amber star badge;
    - needsReview = `violet` with a rewind icon;
    - inProgress = available plus a progress ring (5 px, value = share of challenges correct).
- **Interaction and states:**
  - Pressed: the disc translates 4 px into its edge (`press` 100 ms).
  - Focus: a 3 px `focusRing` ring.
  - Hover (pointer devices): the fill lightens 6 %.
- **Files:** `path_screen.dart` (`PathNodeWidget`), `learning_path_controller.dart` (`presentation`).
- **Change:** Apply the semantic colours (CF-12). Remove the depth on locked nodes.
- **Depends on:** ARC-04 (types), EVD-03 (needsReview).
- **Accept:** All 7 types × 7 states are distinguishable in greyscale (shape and icon), shown in one golden sheet.
- **Verify:** `test/goldens/path_nodes_matrix.png`.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S2 §4.1, S4 §4.2, S5 §5.2.

#### PTH-06 — Node animation triggers and ordering

- **Function:**
  - Unlock: persist, then recompute, look locked, fire `unlock` once, then show active.
  - Complete: persist evidence and points, fire `completeNode` once, update the ring; for a checkpoint, then fire `completeCheckpoint`.
- **Visual:**
  - Unlock 800 ms: the lock shakes (0–32 %), the colour floods in, the node pops to 1.18 and settles.
  - Complete 800 ms: a Y-flip icon swap and a burst of 8 rays (12 for a checkpoint).
  - Connector fill as in PTH-04.
- **Interaction and states:**
  - Events are claimed from `pathEvents` before playing. They never replay on rebuild.
  - Taps stay live during an animation.
  - Reduced motion jumps to the final frame.
- **Files:** `learning_path_controller.dart`, `path_screen.dart` (implemented, uncompiled).
- **Change:** Verify the existing code (GOV-02). Add a haptic call through the effects service (SND-02).
- **Depends on:** GOV-02.
- **Accept:** S4 §10: triggers fire once after persistence, never on rebuild.
- **Verify:** Existing tests plus a rebuild test.
- **Tier / Priority / Sources:** X · P1 · S4 §4.4.

#### PTH-07 — Current-node indicator

- **Function:** "You are here".
- **Visual:**
  - A START bubble 30 px above the node (white, 2 px `border`, tail, label 13 px weight 800 in the node colour; "CONTINUE" when in progress).
  - Plus a breathing ring: 2 px `primary` at 40 %, radius 44 → 48, 1,600 ms ease-in-out, repeating.
- **Interaction and states:** The ring runs only when `SumiMotion.loopsEnabled`, reduced motion is off and `TickerMode` is enabled. It stops when the app is backgrounded (CF-04).
- **Files:** `path_screen.dart` (`_StartBubble`).
- **Change:** Add the ring behind the guard.
- **Depends on:** MOT-04.
- **Accept:** Tests using `pumpAndSettle` complete. Reduced motion shows a static ring.
- **Verify:** Widget test with `loopsEnabled` true, pumping a fixed number of frames.
- **Tier / Priority / Sources:** X · P2 · S1 §9.11.

#### PTH-08 — Anchored node action card

- **Function:** A node tap shows an action card anchored to the node. It does not navigate.
- **Visual (DC §7.15):**
  - Width min(340, contentWidth); height fits the content (no fixed 220).
  - Radius 16, filled with the node's type colour (completed nodes: `primary`; locked: `disabled` with `ink` text), with a 4 px edge in the shadow tone.
  - A 16 px pointer triangle toward the node.
  - Content:
    - eyebrow: type label + "· {m} MIN" (12/16 weight 800, white 85 %);
    - title: 17/22 weight 800 white;
    - reason line: 14/20 white 90 %, maximum two lines (due reason for reviews; "Video · {duration} · Needs connection" for video nodes);
    - full-width **white inset** button with the node-colour label: "START +{base} POINTS" | "CONTINUE" | "REVIEW" | "PRACTISE AGAIN" (completed).
  - Placed below the node unless there is no room, in which case above.
- **Interaction and states:**
  - Appears in ≤ 250 ms (`card` 200 ms scale 0.92 → 1 plus fade; reduced motion = instant).
  - Selecting another node replaces the card; never stacks.
  - Outside tap, scroll or Esc dismisses.
  - START persists the path context, then pushes the lesson (`LES-17` loading if > 150 ms).
  - Busy: the button shows a spinner and keeps its width.
- **Files:** `path_screen.dart` (`NodeActionOverlay`).
- **Change:** Re-skin from the white blur card to the S5 grammar.
- **Depends on:** PTH-05, GAM-01 (base reward).
- **Accept:** S4 §10 and S5 §12 path criteria.
- **Verify:** Widget tests for show, replace, dismiss and timing; goldens.
- **Tier / Priority / Sources:** X · P1 · S4 §7 P0.1, S5 §5.3, CF-02.

#### PTH-09 — Locked node explanation

- **Function:** Tapping a locked node explains which prerequisite is missing.
- **Visual:** The same card in the locked variant: eyebrow "LOCKED", title = node title, body "Finish “{prerequisite title}” to unlock this step.", and an outlined button "GO TO {PREREQUISITE}" that scrolls to and selects that node.
- **Interaction and states:** —
- **Files:** `path_screen.dart`.
- **Change:** Name the specific prerequisite.
- **Depends on:** PTH-08.
- **Accept:** S1 §19: locked nodes provide a prerequisite explanation.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S2 P1.1.

#### PTH-10 — Section overview

- **Function:** Lists every unit for the goal, with progress and jump-to.
- **Visual:**
  - Full-height modal sheet (radius 24 at top, white, dimmed path behind at `ink` 40 %).
  - Header: X at left, discipline title centred (17/22 weight 800).
  - Unit cards: radius 16, unit palette, 4 px edge. Each has the eyebrow "UNIT n", the title, the capability range "Steps {a}–{b}", and a progress bar (8 px, white on white 30 %).
  - Current unit: "CONTINUE". Future unit: "JUMP HERE" (opens the checkpoint detail; a placement check is required).
  - Provisional units carry a `PROVISIONAL` tag.
- **Interaction and states:** Opens with `sheet` 240 ms. Picking a unit sets the selected unit and scrolls to its first node.
- **Files:** `path_screen.dart` (`SectionOverviewScreen`).
- **Change:** Convert to a sheet with tokens.
- **Depends on:** PTH-12 (jump).
- **Accept:** Jumping never completes nodes without a checkpoint pass.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P2 · S5 §5.4, CF-27.

#### PTH-11 — Unit guide

- **Function:** Reference material for the unit: KEY IDEAS, WATCH, REFERENCE, TRY.
- **Visual:**
  - Full-screen white page that slides in from the right (`slide` 280 ms).
  - Header: X at left, centred "Unit {n} guide".
  - A 160 px original hero scene.
  - Section labels at 12/16 weight 800 `muted`, uppercase.
  - KEY IDEAS: rounded 16 cards, 2 px `border`.
  - WATCH: video cards (thumbnail placeholder, title, channel, duration, "Opens outside Sumi").
  - REFERENCE: `skySoft` teaching panels.
  - TRY: a primary button "PRACTISE THIS UNIT".
- **Interaction and states:**
  - Opening a resource goes through the resource detail sheet (LIB-03).
  - The tutor entry is here (TUT-01).
  - Available after completion.
- **Files:** `unit_guide_screen.dart`.
- **Change:** Re-skin. Content comes from `units[].guide` (ARC-04).
- **Depends on:** ARC-04, LIB-03.
- **Accept:** Section order is exact. The guide never awards evidence.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S4 §7 P0.2, S5 §5.6.

#### PTH-12 — Checkpoint (star) detail

- **Function:** Explains the acceptance rule for the checkpoint before it starts.
- **Visual:**
  - Full-screen slide from the right.
  - X at left; centred unit name.
  - Three star silhouettes, 48 px, filled `amber` for the levels earned.
  - A 200 px original scene.
  - Body: "Answer every check correctly to earn a star. Use what you practised in this unit — the examples are new."
  - Two info tiles: "LEVEL {n}/3" and "UP TO +{x} POINTS".
  - Primary "START CHECKPOINT". No currency price.
- **Interaction and states:** Back reverses the slide. Failing shows RES-03.
- **Files:** New `checkpoint_detail_screen.dart`.
- **Change:** New.
- **Depends on:** ARC-04 (checkpoint data).
- **Accept:** The checkpoint uses examples different from the instruction (S1 §12.3).
- **Verify:** Content-schema test.
- **Tier / Priority / Sources:** X · P2 · S5 §5.5.

#### PTH-13 — Discipline scenes

- **Function:** Original discipline objects beside the nodes give orientation and emotion.
- **Visual:**
  - 120 × 120 vector scenes:
    - Music: pulse grid, note and metronome;
    - Fashion: swatch, measuring tape and pattern piece;
    - Custom: modular blocks.
  - Opacity 100 % (not today's faint 25 %). Colours from tokens.
  - An optional one-shot idle motion on unit entry, ≤ 1,200 ms.
- **Interaction and states:** Decorative; excluded from semantics.
- **Files:** `path_screen.dart` (`_DisciplineScene`).
- **Change:** New painters, or SVG via `flutter_svg`, registered in `ASSETS.md`.
- **Depends on:** GOV-04.
- **Accept:** No Material icon is used as the final scene.
- **Verify:** Golden test.
- **Tier / Priority / Sources:** F · P2 · S5 §5.2, S6 #8, S2 P2.1.

#### PTH-14 — Scroll restore and one auto-scroll

- **Function:**
  - Returning from a lesson, guide or settings, or after backgrounding, restores the exact offset.
  - On the first visit of a session, auto-scroll once to centre the current node, only if it is outside the comfortable viewport (the middle 60 %).
- **Visual:** The scroll animates (`pathReveal` 420 ms; reduced motion = jump).
- **Interaction and states:** —
- **Files:** `learning_path_controller.dart` (`pathContext`).
- **Change:** Add the auto-scroll flag per app session.
- **Depends on:** —
- **Accept:** S4 §10: the exact scroll position survives.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §9.11, S4 §4.4.

### 4.6 Lesson

#### LES-01 — Lesson header

- **Function:** Exit, progress, Focus and settings.
- **Visual:**
  - Height 56 below the safe area.
  - Left: a 48 px X button (`muted`).
  - Centre: the `ProgressBar` (10 px, radius 999, `disabled` track, `primary` fill with a 3 px white-35 % highlight stripe), filling the remaining width.
  - Right: the Focus pill (heart-shield icon 22 px in `coral`, plus the count at 16 px weight 800, tabular figures; when 0, the icon is `disabledText` and a "PRACTICE MODE" tag appears under the bar).
  - Far right: a 40 px tune icon (AMB-05).
- **Interaction and states:** Progress animates by `micro` 160 ms when a challenge is first passed.
- **Files:** `lesson_shell.dart` (AppBar).
- **Change:** New `lesson_progress_header.dart`.
- **Depends on:** TYP-01.
- **Accept:** Semantics: "Lesson progress, 2 of 5" and "Focus 4 of 5".
- **Verify:** Semantics test. Update the test that asserts the old "Focus 4" text.
- **Tier / Priority / Sources:** X · P1 · S1 §10.1, S5 §6.1.

#### LES-02 — Lesson state machine

- **Function:** `loading → unanswered → selected → submitting → correct | partial(nearCorrect) | incorrect | retry | error → continuing → next | completed` (S1 §10.2), mapped onto `SubmissionState` × `FeedbackState`.
- **Visual:** —
- **Interaction and states:**
  - `submitting` locks the inputs.
  - `error` keeps the response and shows RETRY SAVE.
  - `completed` commits the summary transactionally before any celebration.
- **Files:** `learning_session_state.dart`, `learning_session_controller.dart`.
- **Change:** Add an `incorrect → continuing` path (LES-05) and the requeue queue.
- **Depends on:** LES-05.
- **Accept:** All transitions are covered by `session_contract_test.dart` additions.
- **Verify:** Unit tests.
- **Tier / Priority / Sources:** X · P0 · S1 §10.2, S4 §5.2.

#### LES-03 — Sticky CHECK footer

- **Function:** The primary action is pinned above the safe area and the keyboard.
- **Visual:**
  - White background with a 2 px `border` top line; padding 16 on top, the gutter at the sides, and 16 + safe area at the bottom.
  - A full-width tactile primary button "CHECK": `disabled` style until the response is valid, then `primary`.
  - Optional secondary text action on the left of the row when the challenge allows it: "I DON'T KNOW YET" (baseline, checks) or "CAN'T DO THIS NOW" (music tap, media). Both are 14 px weight 800 `muted`.
- **Interaction and states:** Enter key = CHECK when enabled.
- **Files:** `feedback_panel.dart`.
- **Change:** Split into `sticky_lesson_action.dart` (neutral) and `feedback_panel.dart` (graded).
- **Depends on:** Tactile button.
- **Accept:** In the neutral state the footer is ≤ 108 px + safe area at 100 % text. The prompt and response are visible in the first viewport at 390 × 844 for every renderer.
- **Verify:** Goldens per renderer.
- **Tier / Priority / Sources:** X · P1 · S1 §10.1, S2 P1.2, S5 §6.1, CF-23.

#### LES-04 — Correct feedback panel

- **Function:** States what was correct, connects it to the capability, shows the points, and continues.
- **Visual (DC §7.21):**
  - Panel `primarySoft`, rising from the bottom, replacing the footer.
  - Status row: a 32 px white circle with a check in `primary`, the heading "Correct!" or "Nice work." (20/26 weight 800 `successInk`), and on the right a points chip "+{n}" (amber), tappable to show the breakdown.
  - Explanation: 16/24 `successInk`, ≤ 240 characters before "More".
  - Calibration row: text buttons "Too easy" · "Too hard" · "Report issue" (12/16 weight 700 `successInk`).
  - Mascot reaction: 52 px at the right of the heading.
  - Full-width primary "CONTINUE".
- **Interaction and states:**
  - The panel rises with `sheet` 240 ms.
  - The selected answer turns green and the check draws (`micro` 160 ms).
  - 6–10 particles (≤ 650 ms).
  - Sound "correct"; haptic "success".
  - Reduced motion: no particles, instant panel.
  - The panel appears only after the attempt is persisted.
- **Files:** `feedback_panel.dart`, the renderers.
- **Change:** Copy, layout and particles.
- **Depends on:** LES-18, SND-01.
- **Accept:** Semantics announce "Correct. {explanation}" once.
- **Verify:** Golden and semantics tests.
- **Tier / Priority / Sources:** X · P1 · S1 §10.4, §8.2; S5 §6.4.

#### LES-05 — Incorrect panel, Continue and requeue

- **Function:** Shows the correct principle, preserves the answer, moves on, and brings the item back later.
- **Visual:**
  - Panel `coralSoft`. Status: a 32 px white circle with a coral X; heading "Not quite yet." (`errorInk`).
  - "Correct answer:" label, then the correct option text in weight 700. Then one specific explanation.
  - Outlined secondary "EXPLAIN MY MISTAKE" (2 px `coral` border, `errorInk` label), full width, above a coral primary "CONTINUE".
  - The selected option shows a coral outline and an X; the correct option shows a green outline.
- **Interaction and states:**
  - The selected card makes a 4 px, two-cycle horizontal nudge within 240 ms.
  - Sound "incorrect" (soft); haptic "warning".
  - Focus drops on the first try only (LES-11).
  - CONTINUE advances and appends the challenge's `parallel_of` variant to the end of the queue (or the same challenge, if none is authored), tagged `REPAIR`. Lesson progress counts only the original challenges.
  - No shame language and no forced wait.
- **Files:** `learning_session_controller.dart` (`advance`, `canContinue`, `retry`), `learning_session_state.dart`.
- **Change:** Implement `canContinue` for incorrect, the requeue list and progress accounting (CF-05).
- **Depends on:** ARC-04 (`parallel_of`).
- **Accept:** S1 §19: "Wrong item is requeued as a different challenge" (where a variant exists).
- **Verify:** Unit and widget tests.
- **Tier / Priority / Sources:** X · P0 · S1 §10.5, S5 §6.4, S4 §5.4.

#### LES-06 — Near-correct panel

- **Function:** Partly right.
- **Visual:**
  - Panel `amberSoft` (#FFF4D6). Status icon: an amber "≈" in a white circle.
  - Heading "Almost—one part needs work." (`warningInk`).
  - Rubric rows (passed ✓ / missing ✕ / uncertain ?) for multi-part answers, for example "Steps 1–2 in order ✓ · Step 3 ✕".
  - Primary amber "TRY AGAIN" (ink label); secondary text "CONTINUE" (`warningInk`).
- **Interaction and states:**
  - One revision allowed. Both attempts are preserved.
  - A second near-correct or a Continue requeues the item, as in LES-05.
  - Never independent evidence.
- **Files:** `challenge_definition.dart` (grade), `feedback_panel.dart`.
- **Change:** Add rubric results to `Grade`.
- **Depends on:** LES-02.
- **Accept:** A revision after near-correct records `supported`, never `independent`.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** X · P1 · S1 §10.6, S5 §6.4.

#### LES-07 — Ungraded retry state

- **Function:** For input that could not be judged (fewer than 5 taps, or timing out of range) or a learner retry.
- **Visual:** Panel `skySoft`. Heading "Let's try that again." Explanation of what is needed. Primary sky "TRY AGAIN". "CAN'T DO THIS NOW" alternative where one applies.
- **Interaction and states:** No Focus loss. Not recorded as incorrect.
- **Files:** `challenge_definition.dart`.
- **Change:** Copy and visual only.
- **Depends on:** —
- **Accept:** —
- **Verify:** Widget test.
- **Tier / Priority / Sources:** F · P1 · S5 §6.4 (speaking retry), S4 §5.4.

#### LES-08 — Explain My Mistake screen

- **Function:** A dedicated explanation that returns to the same session state.
- **Visual:**
  - Full-screen slide from the right.
  - Back arrow; title "Explain my mistake" (17/22 weight 800).
  - "Your answer" chips (coral outline).
  - A large explanation card (radius 16, 2 px `border`) showing the authored explanation with the key term highlighted in `skySoft`, plus one example.
  - Helpfulness: "Was this helpful?" with thumbs up and down (48 px).
  - Optional "EXPLAIN IT ANOTHER WAY" outlined button for the local or cloud tutor, with a provider badge (TUT-02).
  - Primary sky "CONTINUE LESSON".
- **Interaction and states:**
  - Opening and closing never changes the grade or the draft.
  - A failed AI call shows "Couldn't reach the tutor. The explanation above still applies." with Retry.
  - Feedback is recorded as an adaptation event.
- **Files:** `lesson_shell.dart` (`explain`).
- **Change:** New `explain_mistake_screen.dart`. Update the tests that look for "Return to my response" or "Understand this response".
- **Depends on:** TUT-01, TUT-02.
- **Accept:** S4 §10: Explain returns to the same session state.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S5 §6.5, S6.

#### LES-09 — Lesson settings sheet

- **Function:** Sound, haptics, reduced motion, captions/transcripts, explanation length (Short / Detailed), Refill Focus, END SESSION.
- **Visual:**
  - A rounded-top sheet (radius 24) over the lesson dimmed at `ink` 40 %, with a grabber.
  - Title "Lesson settings".
  - Switch rows (DC §7.30).
  - "Refill Focus" outlined button with the line "Focus never blocks learning or explanations."
  - Primary sky "DONE".
  - Text button "END SESSION" in `errorInk`.
- **Interaction and states:**
  - Changes persist immediately through `UpdateSetting`.
  - The draft is preserved.
  - END SESSION opens LES-10.
- **Files:** `lesson_shell.dart` (`settings`).
- **Change:** New `lesson_settings_sheet.dart`. Keep the "Back to lesson" test, or update it on purpose (plan §13).
- **Depends on:** SET-05, SND-02.
- **Accept:** —
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P2 · S5 §6.6.

#### LES-10 — Exit confirmation

- **Function:** Leaving with work in progress asks for confirmation. With nothing in progress, exit is immediate.
- **Visual:** A rounded-top sheet titled "Keep progress and leave?" with the body "Your checked answers and current draft are saved on this device." Primary "KEEP LEARNING"; text button "SAVE & EXIT" (`muted`).
- **Interaction and states:** Android back = X. Completed checked items are never discarded.
- **Files:** `lesson_shell.dart` (`leave`).
- **Change:** Copy and grammar (CF-29).
- **Depends on:** —
- **Accept:** No draft → no confirmation.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §10.2.

#### LES-11 — Focus buffer rules

- **Function:**
  - Starts each lesson at 5.
  - −1 on the first persisted incorrect attempt of a challenge.
  - Hints cost nothing but cancel the perfect bonus.
  - At 0, show "PRACTICE MODE" and keep going.
  - Resets at the next lesson.
  - Refill is available in settings.
- **Visual:** LES-01.
- **Interaction and states:** Focus never locks content, explanations, retries or AI.
- **Files:** `learning_session_controller.dart` (`submit`).
- **Change:** Change the decrement condition (CF-07). Stop writing `engagement.focusBuffer` as a lifetime stat; it becomes session state only.
- **Depends on:** —
- **Accept:** S1 §19: "Focus reaches zero without locking the lesson".
- **Verify:** Unit test.
- **Tier / Priority / Sources:** X · P0 · S1 §11.3, S4 §5.5.

#### LES-12 — Eight renderers, every state

- **Function:** Each renderer supports untouched, check-ready, grading, correct, incorrect, near-correct, restored and read-only.
- **Visual:** Uses LES-13 and LES-14 components and DC §7.17–7.20.
- **Interaction and states:** Renderers emit intents only.
- **Files:** `challenge_renderer_registry.dart`.
- **Change:** Re-skin to the components. Replace the literal `feedbackColor` values with tokens (`successInk`, `errorInk`, `warningInk`, `infoInk`).
- **Depends on:** LES-13, LES-14.
- **Accept:** An 8 × 8 golden grid.
- **Verify:** `test/goldens/renderers_*.png`.
- **Tier / Priority / Sources:** F · P1 · S4 §5.3.

#### LES-13 — Choice row component

- **Function:** A selectable answer row.
- **Visual:**
  - Minimum height 64; radius 16; 2 px `border` outline; 3 px `borderShadow` bottom edge.
  - Padding 16. Optional 32 px leading index box ("1", "2", …) with a 2 px border, radius 8, 14 px weight 800 `muted`.
  - Label 17/22 weight 700 `ink`.
  - Selected: `sky` outline and edge (`skyShadow`), `skySoft` fill, label `infoInk`, 1.015 scale settle (`micro`).
  - Correct: `primary` outline, `primarySoft` fill.
  - Incorrect: `coral` outline, `coralSoft` fill.
  - Disabled: 50 % opacity.
- **Interaction and states:**
  - Pressed: translate 2 px into the edge.
  - Hover: `surfaceSoft` fill.
  - Focus ring.
  - Semantics: "Option 2 of 4, {label}, selected".
- **Files:** `challenge_renderer_registry.dart` (`SingleSelectChallengeRenderer`), onboarding rows.
- **Change:** New `design_system/choice_row.dart`, used by onboarding and lessons.
- **Depends on:** MOT-01.
- **Accept:** One implementation for all choice UIs (S2 §6).
- **Verify:** Golden test.
- **Tier / Priority / Sources:** X · P1 · S1 §6.3, §8.2.

#### LES-14 — Token bank with stable placeholders

- **Function:** Ordering and sequencing.
- **Visual:**
  - Tokens are white chips (radius 12, 2 px `border`, 3 px edge, 15/20 weight 700), minimum 48 tall.
  - The answer area shows two to three 2 px `border` guide lines.
  - A used token leaves a `disabled` placeholder of the same size.
- **Interaction and states:**
  - Tapping a bank token moves it to the answer; tapping an answer token returns it.
  - Move animation `micro` 160 ms; reduced motion = instant.
  - Correct tokens turn green and wrong ones red after grading.
- **Files:** `challenge_renderer_registry.dart` (`SequenceTokens`, `FashionProcedure`).
- **Change:** As specified.
- **Depends on:** —
- **Accept:** No layout jump: the bank keeps its size.
- **Verify:** Golden before and after a tap.
- **Tier / Priority / Sources:** X · P2 · S5 §6.3.

#### LES-15 — Per-node content mix

- **Function:** Each reviewed node has its own challenges.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `assets/disciplines.json`, `scripts/build_disciplines.py`.
- **Change:** Author 4–6 challenges per node (≥ 2 kinds per node). Across each track, include:
  - a video node followed by an application question;
  - ordering or matching;
  - choice;
  - a structured reflection;
  - at least one near-correct-capable item;
  - parallel variants for every gradeable item.

  Keep the existing honest disclosures (no audio grading, no garment inspection). New text is labelled AI-assisted in the README.
- **Depends on:** ARC-04.
- **Accept:** No two nodes share an identical challenge list. QA-03 passes (no coding residue).
- **Verify:** Content-schema test.
- **Tier / Priority / Sources:** F · P0 · S6 required demonstration, S7 §6.1, CF-32.

#### LES-16 — Hints and "I don't know yet"

- **Function:** At most one hint per item. "I don't know yet" records a skip (no evidence) and moves on.
- **Visual:** "Show hint" text button (14 px weight 800 `infoInk`) under the prompt. The hint card unfolds below the prompt (`micro` 160 ms; `skySoft`, radius 12).
- **Interaction and states:** A hint removes independence credit and the perfect bonus.
- **Files:** `assessment.dart`, renderers.
- **Change:** Extend to lessons wherever `hint` exists in the data.
- **Depends on:** ARC-04.
- **Accept:** S1 §19: hint success is not independent success.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P1 · S1 §9.9, §11.3.

#### LES-17 — Lesson loading screen

- **Function:** Shown only when opening a session takes > 150 ms.
- **Visual:** A white full screen; a centred 120 px original illustration (or a mascot `think` poster); "Getting your step ready…" at 16/24 `muted`; and an indeterminate `ProgressBar` with no fake percentage.
- **Interaction and states:** Never a blank body.
- **Files:** `main.dart` (`openMilestone`).
- **Change:** New `lesson_loading_screen.dart`.
- **Depends on:** —
- **Accept:** A 300 ms fake store shows the loading screen, not blank frames.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P2 · S5 §8 #8, §12.

#### LES-18 — Persist before feedback, points or animation

- **Function:** Each attempt is persisted before its feedback shows. Completion persists evidence, points and streak before celebrating.
- **Visual:** While saving, the primary button shows a spinner with "SAVING…" and keeps its width.
- **Interaction and states:** A persistence failure shows "Not saved yet", keeps the response, and offers RETRY SAVE.
- **Files:** `learning_session_controller.dart` (implemented).
- **Change:** Regression only.
- **Depends on:** —
- **Accept:** Existing contract tests.
- **Verify:** `session_contract_test.dart`.
- **Tier / Priority / Sources:** X · P0 · S4 §5.4, §9.

#### LES-19 — Lifecycle restore

- **Function:** Backgrounding or killing the app restores the exact challenge, draft and feedback.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `learning_session_controller.dart` (implemented).
- **Change:** Regression only.
- **Depends on:** —
- **Accept:** —
- **Verify:** Existing tests.
- **Tier / Priority / Sources:** F · P1 · S4 §5.2.

#### LES-20 — Re-entering a completed node

- **Function:** Opening a completed node shows a compact review (the result summary and "Review saved responses"), not a pre-completed active lesson. "PRACTISE AGAIN" starts a new practice session with no completion bonus. The per-challenge points use new event IDs only when the challenge is due (EVD-03).
- **Visual:** The result layout in a "review" variant, without confetti.
- **Interaction and states:** —
- **Files:** `main.dart` (`openMilestone`), `learning_session_controller.dart` (`open`).
- **Change:** As specified.
- **Depends on:** GAM-02.
- **Accept:** Reopening never duplicates a reward (S3 P1).
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P2 · S2 P1.2.

#### LES-21 — Project evidence: structured reflection

- **Function:** Project nodes require three short fields: what I made or tried; one observation or result; one change for next time (each ≥ 12 characters). An optional photo or audio note is not part of this phase. The result is labelled self-reported.
- **Visual:** Three stacked fields with labels (DC §7.29). The footer CHECK becomes "SAVE EVIDENCE". An evidence-strength tag "SELF-REPORTED" appears on the result.
- **Interaction and states:** The domain rubric from data (for example, Fashion: brief clarity, measurement method, material rationale, construction accuracy, reflection) is shown as self-check chips.
- **Files:** `challenge_renderer_registry.dart` (`TypedReflection`), `challenge_definition.dart`.
- **Change:** A new kind, `projectReflection`, or a multi-field `typedReflection`.
- **Depends on:** ARC-04.
- **Accept:** A checkbox alone cannot complete a project node. Self-reported evidence never reaches `independent`.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P1 · S2 P1.4.

### 4.7 Result

#### RES-01 — Result screen contents

- **Function:** Shows the outcome of the session.
- **Visual (DC §8.9):**
  - Hero: 200 px (mascot `complete`, or `inkBloom` for perfect) over rays.
  - Title "Step complete!" or "Perfect step!" (30/37 weight 800). Accolade line.
  - Three stat tiles: POINTS (amber, with a tappable breakdown), ACCURACY (first-attempt %; or REFLECTION "Saved" for unassessed sessions), TIME (active time m:ss).
  - A "Daily goal & streak" row: a ring for today's minutes and the streak count, with "+1 day" when this session qualified.
  - Evidence card: categories and counts, plus the self-reported note.
  - "Next: {node title}" card.
  - Primary "CONTINUE"; text button "RETURN TO PATH"; text button "Review saved responses".
- **Interaction and states:**
  - Sequence ≤ 1,200 ms total (CF-21), skippable by tap.
  - Count-ups use tabular figures.
  - Sound "lesson_complete"; haptic "success".
  - Reduced motion = final frame.
- **Files:** `session_result_screen.dart`.
- **Change:** Add the streak/goal row and the next card. Retime the sequence.
- **Depends on:** GAM-01, GAM-03.
- **Accept:** Reads only `SessionResult`.
- **Verify:** Golden and widget tests.
- **Tier / Priority / Sources:** X · P1 · S2 §4.3, S4 §6, S1 §8.2.

#### RES-02 — Accolade resolver and discipline payloads

- **Function:** Rules:
  - `accuracy` when first-attempt accuracy is 1;
  - `recovery` when there was ≥ 1 incorrect answer and every requeued item was then passed;
  - `making` for project nodes;
  - `reflection` for reflection-only sessions;
  - `listening` for music tap with spread ≤ 0.18;
  - `consistency` otherwise.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `session_result_assembler.dart`.
- **Change:** New `accolade_resolver.dart`. Evidence categories come from data (ARC-05).
- **Depends on:** ARC-05.
- **Accept:** Music and Fashion produce different payloads in the same shell.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P2 · S4 §6.

#### RES-03 — Checkpoint failure result

- **Function:** When a checkpoint fails (more than two incorrect first attempts, or an unpassed requeued item at the end), it is not passed.
- **Visual:** A centred white screen with an original illustration, the heading "Not unlocked yet", the body "You've kept every answer. Practise “{repair node}” and try the checkpoint again." and a primary sky "CONTINUE".
- **Interaction and states:**
  - Attempts are preserved.
  - Repair review is scheduled (EVD-03).
  - Returns to the path at the checkpoint.
  - The node is not completed.
- **Files:** New `checkpoint_fail_screen.dart`.
- **Change:** New.
- **Depends on:** PTH-12, EVD-03.
- **Accept:** S4 §10: failure does not mark the node complete.
- **Verify:** Unit and widget tests.
- **Tier / Priority / Sources:** X · P2 · S5 §6.7.

#### RES-04 — Continue → path → events → next card

- **Function:** CONTINUE acknowledges the result, returns to the exact path position, plays `completeNode` (then `completeCheckpoint`, then `unlock`), and opens the anchored card on the new current node. RETURN TO PATH does the same without opening the card.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `lesson_shell.dart` (`finish`), `path_screen.dart` (`start`).
- **Change:** Add an `openCardAfterEvents` flag.
- **Depends on:** PTH-06, PTH-08.
- **Accept:** —
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S4 §9, CF-28.

### 4.8 Gamification

#### GAM-01 — Points formula

- **Function:** S1 §11.1 values:

  | Event | Points |
  |---|---|
  | Checked challenge | +10 |
  | First-try correct | +5 |
  | Correct without a hint | +5 |
  | Completed lesson | +20 |
  | Completed due review | +15 (instead of +20) |
  | Completed project step | +25 (instead of +20) |
  | Checkpoint passed | +25 (CF-09) |
  | Daily quest | +10 each |
  | Perfect bonus (Focus 5, no hints) | +20 |

  Each entry is an immutable ledger transaction with `sourceId = discipline:goal:node:session:challenge:rewardType`.
- **Visual:** The points chip and the result breakdown (DC §7.21, §8.9).
- **Interaction and states:** —
- **Files:** `models.dart` (`EngagementState.addReward`), `learning_session_controller.dart`.
- **Change:** New `engagement/points_policy.dart`.
- **Depends on:** ARC-03, ARC-07.
- **Accept:** Fixture sessions produce the expected totals.
- **Verify:** Table-driven unit test.
- **Tier / Priority / Sources:** X · P1 · S1 §11.1, CF-08.

#### GAM-02 — Reward idempotency

- **Function:** No duplicate points from reopening, retrying or replaying. Two different lessons completed within one minute both reward.
- **Visual:** —
- **Interaction and states:** —
- **Files:** `models.dart`.
- **Change:** Keep stable IDs and extend them per GAM-01.
- **Depends on:** —
- **Accept:** S3 P1 tests.
- **Verify:** Existing and new tests.
- **Tier / Priority / Sources:** X · P0 · S3 P1.3.

#### GAM-03 — Streak and recovery tokens

- **Function:**
  - A streak day comes from a completed lesson, a completed due review, or a project step with reflection. Calendar days are learner-local.
  - Opening the app, viewing a resource, downloading a model or asking the AI never counts.
  - One recovery token is earned on reaching a 7-day streak (maximum 2 stored). A token covers exactly one missed day, and is applied automatically on the next qualifying day.
  - The UI says what maintained the streak.
- **Visual:**
  - The flame in the status row.
  - On a streak increment: one 8 % pulse plus the count increment.
  - Sound "streak"; haptic "light".
- **Interaction and states:** —
- **Files:** `models.dart` (`qualifyDailyStreak`).
- **Change:** Add tokens and the qualifying-event record.
- **Depends on:** ARC-03.
- **Accept:** S1 §19 streak tests; a time-zone test that crosses midnight.
- **Verify:** Unit tests with an injected clock.
- **Tier / Priority / Sources:** X · P1 · S1 §11.2.

#### GAM-04 — Daily quests

- **Function:** Three quests:
  - "Complete one lesson".
  - "Answer three challenges without a hint on the first try".
  - "Spend {daily minutes} minutes learning, or complete one project step".

  They refresh at local midnight. Each gives +10 points; all three give a chest of +5 sparks. Missing a quest never touches evidence.
- **Visual:**
  - A collapsible `QuestCard` above the unit header on Learn (collapsed after the first view each day).
  - Each row: a 32 px target icon, the title, and a progress bar (8 px, `amber`) with "1/3".
  - The chest icon unlocks when all three are done.
  - Purple header variant on the Practice tab (`violet`).
- **Interaction and states:** Completing a quest plays a small burst and a sound. The chest opens with the reward rising; Skip is available (S1 §8.2).
- **Files:** New `engagement/quests.dart`, `quest_card.dart`.
- **Change:** New.
- **Depends on:** GAM-01.
- **Accept:** Quest progress is derived from ledger and attempt events, not widget counters.
- **Verify:** Unit test with a clock.
- **Tier / Priority / Sources:** X · P2 · S1 §9.12, §11.5; S5 §7.3.

#### GAM-05 — Sparks (cosmetic only)

- **Function:** Earned from quests, checkpoints and projects. Spent only on a mascot skin (`SumiSkin`) or a recovery token (30 sparks). Never on content, retries, explanations, accessibility or inference.
- **Visual:** A sparks pill in Profile.
- **Interaction and states:** —
- **Files:** `models.dart`, `mascot/`.
- **Change:** Add a spend use case.
- **Depends on:** GAM-03.
- **Accept:** No code path gates learning on sparks.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P3 · S1 §11.4.

#### GAM-06 — Streak screen (personal)

- **Function:** Streak count, today's state, a month calendar of qualified days (tokens marked), what counts toward the streak, and tokens held. No Friends tab.
- **Visual:**
  - A full-screen overlay with X; header in `skySoft` with a large flame and the count (48/56 weight 900, tabular).
  - Calendar cells 40 px: qualified = `amber` fill; token = `sky` outline.
- **Interaction and states:** —
- **Files:** New `engagement/streak_screen.dart`.
- **Change:** New.
- **Depends on:** GAM-03.
- **Accept:** —
- **Verify:** Golden test.
- **Tier / Priority / Sources:** F · P2 · S5 §7.2.

#### GAM-07 — Weekly achievements (optional)

- **Function:** S1 §11.5 list, shown in Profile.
- **Tier / Priority / Sources:** O · P3 · S1 §11.5.

#### GAM-08 — No leaderboard or social UI

- **Function:** Hidden behind a compile-time flag that defaults to false.
- **Accept:** No friend or league widgets in the tree.
- **Tier / Priority / Sources:** X · P1 · S1 §11.5, S5 §7.

### 4.9 Evidence and review

#### EVD-01 — Seven evidence states and promotion

- **Function:**
  - `unseen → exposed` (first attempt or view of instruction);
  - `→ supported` (success with a hint, or after correction);
  - `→ independent` (first-try success with no hint on a reviewed item);
  - `→ recalled` (independent success on a new item after the delay; labelled "Early follow-up" if < 24 h);
  - `→ transferred` (see EVD-02);
  - `needsReview` when a new example fails or evidence decays.
- **Files:** `models.dart` (`EvidenceState`, `getEvidenceState`), `learning_session_controller.dart` (`profile.demonstrated.add` on accuracy 1).
- **Change:** `demonstrated` maps only to `independent`. Remove any implicit path to `transferred`.
- **Depends on:** —
- **Accept:** S3 P1.9 and S1 §19 evidence tests.
- **Verify:** `evidence_test.dart` additions.
- **Tier / Priority / Sources:** X · P0 · S1 §11.6.

#### EVD-02 — Transfer only from a different context or a project

- **Function:** `transferred` requires a pass on a challenge tagged `context: transfer` (authored as materially different) or an assessed project-node rubric. Self-report alone does not count.
- **Files:** `models.dart`.
- **Change:** Add a `context` tag to challenge data.
- **Depends on:** ARC-04.
- **Accept:** Ordinary milestone completion never yields `transferred`.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** X · P0 · S3 P1.9.

#### EVD-03 — Review scheduler

- **Function:** S1 §12.4 rules:

  | Outcome | Next review |
  |---|---|
  | Incorrect | Repair in-lesson, plus next day |
  | Hinted correct | +1 day |
  | Independent | +2 days |
  | Recalled | +5 days |
  | Transferred | +10 days |
  | New failure | Pull forward; keep earlier evidence |

  It feeds `needsReview` node states, `recall_review` nodes and the Practice tab, and always records a due reason.
- **Files:** New `review/review_scheduler.dart`. Retire `recallDone()`.
- **Change:** New.
- **Depends on:** ARC-03.
- **Accept:** Every due item has a human reason string.
- **Verify:** Unit tests with a clock.
- **Tier / Priority / Sources:** F · P1 · S1 §12.4, S2 §4.4.

#### EVD-04 — "Why Sumi believes this"

- **Function:** From any capability in Profile, a detail view lists the attempts, the task, the result, the evidence source, the hint use and the dates. The learner can remove self-reported project evidence.
- **Visual:** A full-screen slide. Rows show date · task · outcome icon + text. An evidence-strength tag.
- **Files:** `main.dart` (`ProfileTab`).
- **Change:** New `profile/evidence_detail_screen.dart`.
- **Depends on:** EVD-01.
- **Accept:** Every claim traces to an event ID (S3 P3).
- **Verify:** Widget test.
- **Tier / Priority / Sources:** F · P2 · S2 P2.4, S3 P5.5.

### 4.10 Practice

#### PRA-01 — Practice sections and copy

- **Function:** Sections, in order:
  1. Review due;
  2. Repair mistakes;
  3. Strengthen a capability;
  4. Rehearse the project;
  5. Early follow-up / Day 2 check (demo window only).

  Each item shows why it is due. The empty state reads "You're caught up" with the body "New reviews appear after you practise. Next one: {date}." and the optional button "PRACTISE ANYWAY".
- **Visual:**
  - A violet header card "Practice" with an original illustration.
  - Item rows: 48 px type icon, title, a reason line in `muted`, and a chevron.
  - Section labels at 12/16 weight 800 uppercase.
- **Interaction and states:** An item opens a lesson session built by `GetNextLearningSession` for that reason.
- **Files:** `main.dart` (`PracticeTab`), `practice.dart` (unused `PracticeScreen`).
- **Change:** Rebuild on top of EVD-03. Reuse `PracticeScreen` if it fits, otherwise delete it.
- **Depends on:** EVD-03.
- **Accept:** The tab never lists every milestone generically (S3 P5.3).
- **Verify:** Widget test with fixtures.
- **Tier / Priority / Sources:** X · P1 · S1 §9.13.

#### PRA-02 — Practice runs through the same transaction

- **Function:** Practice completion updates evidence and rewards through `CompleteActivity`.
- **Accept:** No separate reward path.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P1 · S2 §4.4.

### 4.11 Library

#### LIB-01 — Library groups

- **Function:** Groups: Recommended for you, Saved, Used recently, Browse by discipline. Group headers are 12/16 weight 800 uppercase; each group is a horizontal or vertical list.
- **Files:** `main.dart` (`LibraryTab`).
- **Change:** Extract to `tabs/library_tab.dart`.
- **Depends on:** —
- **Accept:** Saved and recent state survives an external-app round trip.
- **Verify:** Widget test using `didChangeAppLifecycleState`.
- **Tier / Priority / Sources:** F · P1 · S3 P2.4, S2 §4.5.

#### LIB-02 — Resource card fields

- **Function:** Each card shows:
  - title and publisher;
  - the matched capability;
  - format, level, time and access (icon + text);
  - review status;
  - why it is recommended (one line);
  - "Try a related task".
- **Visual:** A compact card (radius 16, 2 px `border`, 3 px edge), maximum height 168 at 100 % text, with progressive disclosure (DC §7.31).
- **Files:** `main.dart` (`_ResourceCard`).
- **Change:** Re-skin.
- **Depends on:** —
- **Accept:** No full-height generic text blocks.
- **Verify:** Golden test.
- **Tier / Priority / Sources:** F · P1 · S1 §9.14, S2 P1.6.

#### LIB-03 — Detail sheet before leaving the app, return-safe

- **Function:** An in-app detail sheet with OPEN RESOURCE, SAVE and MARK USED. On return, offer "Try the related check".
- **Visual:** Rounded-top sheet. Offline state: "Connection needed for this source."
- **Files:** `resource_detail_screen.dart`.
- **Change:** Re-skin, and make the offline copy exact.
- **Depends on:** —
- **Accept:** Opening a resource never marks a capability complete.
- **Verify:** Existing `resource_system_test.dart`.
- **Tier / Priority / Sources:** F · P1 · S1 §9.14, S3 P2.

#### LIB-04 — Resource events; no evidence from views

- **Function:** Records impression, opened, returned, saved, learner-completed and post-check result through `RecordResourceUse`, in a transaction.
- **Files:** `main.dart` (`openResourceDetail` mutates `learning.resourceEvents` directly).
- **Change:** Route through the use case.
- **Depends on:** ARC-02.
- **Accept:** A view creates no evidence or streak.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P0 · S3 P1.5.

#### LIB-05-O — Embedded official video player

- **Tier / Priority / Sources:** O · P3 · S3 P2.7. Requires a terms review.

### 4.12 Profile

#### PRO-01 — Engagement and evidence panels separated

- **Function:**
  - Header: discipline identity with an original badge and the goal outcome.
  - Engagement panel: streak, points this week, lessons completed, quests done.
  - Evidence panel: one capability card per node with state tag, last practised date, evidence count and an uncertainty word (Early / Growing / Supported).
  - "How Sumi is adapting" (existing `adaptation_screen.dart`).
  - The discipline switcher.
  - Settings in the AppBar (gear, 48 px).
- **Visual:** DC §8.12.
- **Files:** `main.dart` (`ProfileTab`).
- **Change:** Extract to `tabs/profile_tab.dart`.
- **Depends on:** EVD-04.
- **Accept:** Sentences follow the S1 §9.15 style ("You solved 3 …"); no labels such as "fast learner".
- **Verify:** Content-lint list of banned labels.
- **Tier / Priority / Sources:** F · P1 · S1 §9.15, S3 P3.

#### PRO-02 — AI mode and privacy shown in Profile

- **Function:** A row such as "AI: On-device (Qwen3 0.6B) · Cloud not configured", linking to Settings.
- **Accept:** Matches the actual state.
- **Tier / Priority / Sources:** F · P2 · S3 P5.5.

### 4.13 Settings

#### SET-01 — Section order

- **Function:** Sections, in order:
  1. Profile on this device;
  2. Learning preferences;
  3. Notifications and reminders;
  4. Accessibility;
  5. Offline AI models;
  6. Cloud AI;
  7. Storage and privacy;
  8. About and licences.
- **Visual:** A quiet grouped list. Section labels at 12/16 weight 800 `muted`. Rows 56 tall minimum, with chevrons (DC §7.30).
- **Files:** `main.dart` (`SettingsScreen`).
- **Change:** Extract to `settings/settings_screen.dart`.
- **Depends on:** —
- **Accept:** The order is exact.
- **Verify:** Widget test.
- **Tier / Priority / Sources:** X · P1 · S1 §5.3, S3 P5.6, S5 §7.5.

#### SET-02 — Every status truthful

- **Function:** Each subtitle is derived from state or a platform API:
  - storage: "Stored on this device (not encrypted)";
  - reminders: "Not set up yet";
  - cloud: "Not configured";
  - accessibility: the actual settings, for example "Reduced motion on · Text: system".
- **Files:** `main.dart`.
- **Change:** As specified.
- **Depends on:** SET-04, TUT-03.
- **Accept:** S2 P0.2: a test asserts each subtitle against state.
- **Verify:** `test/settings_truth_test.dart`.
- **Tier / Priority / Sources:** X · P0 · S2 P0.2, S3 P1.6.

#### SET-03 — Learning preferences

- **Function:** Daily minutes, current goal and deadline (editable), exercise mix (Balanced / More practice / More reading), sounds, haptics, and discipline management.
- **Tier / Priority / Sources:** F · P2 · S1 §9.16.

#### SET-04 — Reminders labelled honestly

- **Function:** The toggle is disabled and the subtitle reads "Not set up yet — Sumi can't send notifications in this build." Migration clears any stored `remindersEnabled = true` (CF-30).
- **Tier / Priority / Sources:** F · P0 · S2 P0.2.

#### SET-04-O — Real reminder schedule

- **Function:** `flutter_local_notifications`, the permission flow, time and days, and a test notification.
- **Tier / Priority / Sources:** O · P3.

#### SET-05 — Accessibility sub-screen

- **Function:**
  - Text size: System / Larger (×1.15 on top of system);
  - High contrast (CF-25);
  - Reduced motion;
  - Sound effects;
  - Haptics;
  - Always show captions and transcripts;
  - Colour-independent feedback (always on; shown as informational);
  - Screen-reader verbosity (Standard / Brief).

  Changes take effect immediately and persist.
- **Files:** New `settings/accessibility_settings_screen.dart`, `theme.dart` (high-contrast theme).
- **Change:** New.
- **Depends on:** A11Y-06.
- **Accept:** Toggling high contrast re-themes without a restart.
- **Verify:** Golden test in high contrast.
- **Tier / Priority / Sources:** F · P1 · S1 §9.16, S2 P2.5.

#### SET-06 — Storage and privacy scoped actions

- **Function:**
  - Storage summary (bytes per track; model bytes separate).
  - Export progress (JSON via `file_selector` save).
  - Import compatible progress (version check).
  - Clear one discipline.
  - Clear all progress.
  - Each with a scoped confirmation. Models are never removed unless also selected.
- **Tier / Priority / Sources:** F · P2 · S1 §9.16, §13.5.

#### SET-07 — About and licences

- **Function:** Build metadata (GOV-03); `showLicensePage` for packages; model licences; content and source acknowledgements; AI-assistance disclosure (S8 §8).
- **Tier / Priority / Sources:** F · P3 · S8.

### 4.14 AI

#### AIM-01 — Offline AI models

- **Function:** Keep the existing working manager: states, hash check and the "Ready only after load" rule.
- **Visual:** Re-skin the cards to the tokens only.
- **Files:** `phone_models_screen.dart`, `on_device_native.dart`.
- **Change:** No functional change. Regression only.
- **Accept:** S1 §19 model tests; the phone smoke test from S7 [R].
- **Verify:** `integration_test/on_device_test.dart`.
- **Tier / Priority / Sources:** F · P1 · S1 §13.

#### TUT-01 — Tutor entry points and context

- **Function:** Entry points: Explain My Mistake, the unit guide, resource detail, and the Profile AI row. **Remove the tutor icon from the path header** (S4 P0.3). The context envelope is as specified in S3 P4 (existing `TutorOrchestrator`).
- **Files:** `path_screen.dart`, `tutor_chat_screen.dart`, `tutor_system.dart`.
- **Change:** Move the entry points.
- **Accept:** No dominant tutor control on the path.
- **Tier / Priority / Sources:** F · P1 · S4 P0.3, S3 P4.

#### TUT-02 — Provider badge and consent

- **Function:**
  - Every AI response shows a badge: "Authored", "On-device · {model}" or "Cloud · {provider}".
  - Consent is stored in `settings.cloudConsent`, not in `constraints`.
  - Never silently fall back from local to cloud.
- **Visual:** Badge pill at 12/16 weight 800: `surfaceSoft` fill with an icon (chip / cloud / book).
- **Files:** `tutor_chat_screen.dart`, `tutor_system.dart`, `models.dart`.
- **Change:** Migrate consent (ARC-03).
- **Accept:** The badge matches the actual responder.
- **Verify:** `tutor_system_test.dart`.
- **Tier / Priority / Sources:** F · P0 · S3 P4.

#### TUT-03 — Cloud honesty

- **Function:** While E-04 is open, Cloud AI shows "Not configured" everywhere. `SumiCloudTutorProvider.queryCloud` throws `CloudNotConfigured`; it never returns canned text.
- **Accept:** No code path renders the stub string.
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P0 · S3 P4, S8 (no fabricated results).

#### CUS-01 — Honest custom-discipline state

- **Function:**
  - Choosing Something else creates a unique `Goal` with its own ID and an isolated record.
  - It shows the provisional-plan screen: "Sumi needs a plan for “{outcome}”."
  - If a local model is ready: "DRAFT A PLAN ON THIS DEVICE" → CUS-02.
  - Otherwise: "Download an offline model in Settings to draft a plan, or choose Music or Fashion for now."
  - No fake lessons and no `example.com` links.
  - The active track and `trackId` stay consistent.
- **Files:** `main.dart` (onboarding custom branch), `models.dart` (`Catalog.custom`).
- **Change:** As specified.
- **Depends on:** ARC-03.
- **Accept:** Two custom goals get different IDs and never share progress (S3 P1).
- **Verify:** Unit test.
- **Tier / Priority / Sources:** F · P0 · S3 P1.7–1.8, S7 §6.2.

#### CUS-02 — Validated provisional plan (local model)

- **Function:**
  - The local model drafts the S1 §12.3 contract.
  - `CustomPlanValidator` rejects cycles, unknown IDs, invented URLs, impossible workloads and unsafe steps; failure fails closed with a clear message.
  - The learner confirms or edits.
  - Generic authored formats (reflection, ordering of self-written steps) are used; there are no invented quiz answer keys.
  - High-risk topics are narrowed to theory.
- **Files:** `tutor_system.dart`, `models.dart`, `services.dart` (`CustomPlanValidator`).
- **Change:** Wire up the validator.
- **Depends on:** CUS-01, AIM-01.
- **Accept:** S1 §19 custom-plan tests.
- **Tier / Priority / Sources:** F · P2 · S1 §12.2–12.3.

#### CUS-03-O — Cloud-drafted plan

- **Function:** After E-04 is decided.
- **Tier / Priority / Sources:** O · P3.

### 4.15 Motion, sound and type

#### MOT-01 — Motion tokens

- **Function:** One `SumiMotion` class holding the S1 §8.1 tokens plus `card` 200 and `slide` 280 (CF-22). No literal durations in widgets.
- **Files:** New `design_system/motion.dart`.
- **Accept:** A grep for `Duration(milliseconds:` in `lib/**` UI code finds only `motion.dart`; data timers are exempt.
- **Tier / Priority / Sources:** X · P1 · S1 §8.1.

#### MOT-02 — Event-to-animation contract

- **Function:** S1 §8.2 table, rows 1–14, implemented (DC §6.3).
- **Accept:** Each row has a widget test for both normal and reduced motion.
- **Tier / Priority / Sources:** X · P1 · S1 §8.2.

#### MOT-03 — Reduced motion

- **Function:** `reduceMotion = settings.reducedMotion || MediaQuery.disableAnimations`. Spatial motion is replaced by crossfades of ≤ 120 ms or instant changes. Particles are suppressed.
- **Accept:** S1 §19: "Reduced-motion mode suppresses particles and spatial path movement."
- **Tier / Priority / Sources:** X · P0 · S1 §8.3.

#### MOT-04 — Loop guard and backgrounding

- **Function:** `SumiMotion.loopsEnabled` (false under `FLUTTER_TEST`). Every looping ticker sits under `TickerMode` and pauses on `AppLifecycleState.paused`.
- **Tier / Priority / Sources:** I · P1 · S7 risk 6, S1 §8.3.

#### SND-01 — Sound effects

- **Function:**
  - Add `audioplayers` (or `just_audio`). Register `assets/sounds/`.
  - Generate the missing sounds (select, partial, streak, reward, model_ready) with `scripts/make_sounds.py`. All are original and < 1.5 s.
  - Play them from controller and effects-service events, never from widgets.
  - On by default; obey the setting.
  - Never the only form of feedback.
- **Files:** `pubspec.yaml`, new `effects/effects_service.dart`.
- **Accept:** Sound off → no player calls (verified with a mock).
- **Tier / Priority / Sources:** F · P2 · S1 §8.4.

#### SND-02 — Haptics toggle

- **Function:** Every `HapticFeedback` call goes through the effects service, which honours `settings.hapticsEnabled`.
- **Accept:** A grep finds no direct `HapticFeedback.` outside the service.
- **Tier / Priority / Sources:** F · P2 · S1 §15.

#### TYP-01 — Bundled rounded font and tabular numbers

- **Function:** Bundle Nunito (OFL) at weights 500, 600, 700, 800 and 900. Use `FontFeature.tabularFigures()` for counters.
- **Files:** `theme.dart`, `pubspec.yaml` fonts, `assets/fonts/OFL.txt`.
- **Accept:** No `'Arial'` reference remains.
- **Tier / Priority / Sources:** F · P1 · S1 §6.2, CF-26.

### 4.16 Accessibility

#### A11Y-01 — Semantics for every control

- **Function:** Labels, roles, values and selected/disabled states on every interactive element. Decorative graphics are excluded.
- **Verify:** `meetsGuideline(textContrastGuideline)`, `androidTapTargetGuideline`, `labeledTapTargetGuideline` in widget tests for every screen.
- **Tier / Priority / Sources:** X · P0 · S1 §15.

#### A11Y-02 — 48 × 48 targets

- **Tier / Priority / Sources:** X · P1 · S1 §6.3, §15. (S3 P5 gives 44; the stricter 48 applies.)

#### A11Y-03 — Icon + text + colour for state

- **Function:** Correct, partial, incorrect, locked, selected and completed each use all three.
- **Tier / Priority / Sources:** X · P0 · S1 §4.11, §15.

#### A11Y-04 — 200 % text without clipping

- **Function:** No fixed heights on text containers (remove the `218`/`280` and `220`/`310` heuristics). Every essential flow is operable at 200 %.
- **Verify:** Goldens at textScaler 2.0.
- **Tier / Priority / Sources:** X · P1 · S1 §6.2, §15.

#### A11Y-05 — Announcements

- **Function:** One live-region announcement per feedback outcome, download state change and result. None per animation frame.
- **Tier / Priority / Sources:** X · P1 · S1 §15.

#### A11Y-06 — Contrast above the minimum

- **Function:** The high-contrast theme (CF-25), plus the `mutedStrong` rule for small text.
- **Tier / Priority / Sources:** I · P1 · S1 §15.

#### A11Y-07 — Focus ring and order

- **Function:** A 3 px `focusRing` outside the layout on every focusable control. Traversal order matches the visual order. Esc closes overlays. Enter activates the primary action.
- **Tier / Priority / Sources:** I · P2 · S1 §6.4.

#### A11Y-08-O — Number-key choice shortcuts

- **Tier / Priority / Sources:** O · P3.

### 4.17 Verification

#### QA-01 — Golden and viewport suite

- **Function:** Goldens for every screen and state at 320 × 700, 390 × 844, 430 × 932 and 600 × 960, plus 200 % text, high contrast and reduced motion. The font is loaded in tests so the goldens are stable.
- **Tier / Priority / Sources:** F · P1 · S2 §9, S3 P5, S6.

#### QA-02 — Device script and contact sheet

- **Function:** S1 §20, S2 §9 and S3 P6 scripts. A 60 fps recording; 2-second and quarter-second contact sheets.
- **Tier / Priority / Sources:** F · P1 · S3 P6, S6.

#### QA-03 — Content lint

- **Function:** A test that fails on `code|coding|program|python|repository|compiler|uploaded code` in Music/Fashion content and UI strings; on banned learner labels (`fast learner`, `slow learner`, `visual learner`, `IQ`, `talent`); on `example.com`; and on `DUO_` or `Duolingo` in shipped strings.
- **Tier / Priority / Sources:** I · P2 · S2 P1.5, S3 P1.

---

## 5. Requirements not carried forward, and why

None were dropped. These are **explicitly deferred** with an owner-visible flag:

| Item | Source | Status |
|---|---|---|
| Accounts, cloud sync, friends, leagues | S1 §3, §22 | Out of scope until accounts are approved (GAM-08). |
| Photo or audio project evidence | S2 P1.4 ("optionally") | Deferred: needs permissions and storage design. |
| Seven-day calibration | S1 §1 | The data model supports it. No UI this phase. |
| iOS build | S7 risk 5 | Needs macOS. Not verified. |
| Embedded video player | S3 P2.7 | LIB-05-O. |
