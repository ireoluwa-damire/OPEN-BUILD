# 04 — Design contract

Prepared: 31 October 2026 (WAT) · Applies to `app/` (Flutter)
Requirement IDs refer to `02-requirements-matrix.md`. Conflict IDs (`CF-nn`) are resolved there.
Status: specification only. **No application code was changed while preparing this document.**

This contract holds the exact visual and interaction values. When the matrix and this contract disagree on a visual value, this contract wins. When they disagree on behaviour, the matrix wins.

---

## 1. Fidelity rules

1. **Reproduce the grammar, not the property.** Sumi reproduces the observed Duolingo hierarchy, cadence, state transitions, tactile depth and feedback immediacy (S5 §14). It ships no Duolingo characters, artwork, sounds, wordmarks, course text, fonts or runtime files.
2. **Tokens only.** No colour, duration, radius or text-style literal may appear in widget code. Everything comes from `SumiColors`, `SumiType`, `SumiSpace`, `SumiRadius`, `SumiDepth` and `SumiMotion`.
3. **One implementation per component.** Height, radius, depth, pressed translation, disabled style, focus ring and semantics live in one class per component (S2 §6).
4. **Colour is never the only signal.** Every state uses icon + text + colour (A11Y-03).
5. **Reference viewport:** 390 × 844 logical pixels. **Supported widths:** 320–600 logical pixels. **Text:** 100–200 %.
6. **Labelled design decisions.** Values marked *(E)* are engineering defaults chosen under rule E, because no source specified them. They may be tuned without a contract change if they remain inside the range shown.

---

## 2. Colour

### 2.1 Core palette (S1 §6.1, reproduce exactly)

| Token | Hex | Use |
|---|---|---|
| `canvas` | `#FFFFFF` | Screen background |
| `surface` | `#FFFFFF` | Cards, sheets |
| `surfaceSoft` | `#F7F9FB` | Secondary panels; outside the 600 px column; hover fill |
| `ink` | `#3D4654` | Primary text; course strip |
| `muted` | `#737E8C` | Secondary text ≥ 16 px; unselected navigation; icons |
| `border` | `#E2E6EA` | Outlines, dividers, connectors |
| `borderShadow` | `#D4D9DE` | Bottom edge of white raised cards and choices |
| `primary` | `#50C86A` | Primary action, progress, success, available nodes |
| `primaryPressed` | `#3EA955` | Pressed primary fill |
| `primaryShadow` | `#319248` | Primary bottom edge |
| `primarySoft` | `#DDF7E4` | Correct panel; completed node fill |
| `sky` | `#2AA8E8` | Selection, information, project nodes, secondary buttons |
| `skyShadow` | `#1688C4` | Sky bottom edge |
| `violet` | `#A86BE8` | Review, practice header |
| `amber` | `#FFBE3F` | Streak, points, rewards, checkpoint |
| `coral` | `#FF6670` | Incorrect, destructive |
| `coralSoft` | `#FFE7EA` | Incorrect panel |
| `warning` | `#E99522` | Storage and thermal warnings |
| `disabled` | `#E5E8EB` | Disabled fill; locked node |
| `disabledText` | `#A7AFB8` | Disabled label and icon |
| `focusRing` | `#2A8FD4` | 3 px focus ring |

### 2.2 Added tokens (derived; not in S1)

These fill gaps that S1 leaves open. Each is derived from an existing token or from colours already in the code (rule C), or is a default (E).

| Token | Hex | Derivation | Use |
|---|---|---|---|
| `skySoft` | `#DDF2FC` | Sky tint, matching the `primarySoft` lightness *(E)* | Selected choice fill, nav tile, hint card, reference panels |
| `amberSoft` | `#FFF4D6` | Amber tint *(E)* | Near-correct panel |
| `violetSoft` | `#F1E7FC` | Violet tint *(E)* | Review chips, practice rows |
| `violetShadow` | `#7E50AE` | `violet` × 0.75 | Violet bottom edge |
| `amberShadow` | `#BF8E2F` | `amber` × 0.75 | Amber bottom edge |
| `coralShadow` | `#BF4C54` | `coral` × 0.75 | Coral bottom edge |
| `successInk` | `#217744` | Existing `feedbackColor` literal (C) | Text on `primarySoft` (4.89:1) |
| `errorInk` | `#B52D43` | Existing literal (C) | Text on `coralSoft` (5.22:1) |
| `warningInk` | `#98600A` | Existing literal (C) | Text on `amberSoft` (4.78:1) |
| `infoInk` | `#216998` | Existing literal (C) | Text on `skySoft` (5.14:1), selected nav label, hint link |
| `violetInk` | `#6B3AA8` | *(E)* | Text on `violetSoft` (6.29:1) |
| `mutedStrong` | `#5E6977` | *(E)* | Secondary text < 16 px (5.58:1 on white) |
| `scrim` | `ink` at 40 % | *(E)* | Dim behind sheets, popovers and the anchored card |
| `unitTeal` / `unitTealShadow` | `#246F89` / `#1B5367` | Existing `_palettes[0]` (C, CF-13) | Unit palette 0 |
| `unitPlum` / `unitPlumShadow` | `#87537D` / `#653E5E` | Existing `_palettes[1]` | Unit palette 1 |
| `unitOlive` / `unitOliveShadow` | `#58733C` / `#42562D` | Existing `_palettes[2]` | Unit palette 2 |

Shadow rule: `shadow = base × 0.75` per RGB channel. This is the same rule the current code uses (`Color.lerp(c, black, .25)`).

### 2.3 Semantic mapping

| Meaning | Fill | Edge | Text or icon on fill | Soft surface | Text on soft |
|---|---|---|---|---|---|
| Primary action, available, correct | `primary` | `primaryShadow` | white | `primarySoft` | `successInk` |
| Selection, information, project | `sky` | `skyShadow` | white | `skySoft` | `infoInk` |
| Review, practice | `violet` | `violetShadow` | white | `violetSoft` | `violetInk` |
| Reward, streak, checkpoint | `amber` | `amberShadow` | **`ink`** | `amberSoft` | `warningInk` |
| Incorrect, destructive | `coral` | `coralShadow` | white | `coralSoft` | `errorInk` |
| Disabled, locked | `disabled` | none | `disabledText` | — | — |

Blue (`sky`) is never used for the current learning action (S2 P1.1). The current node is `primary`.

### 2.4 Contrast and high-contrast mode (CF-25)

The default theme reproduces the palette exactly. Measured contrast:

| Pair | Ratio | Status |
|---|---|---|
| White on `primary` (button label) | 2.14 | Below AA. Accepted as visual identity in the default theme. |
| White on `sky` | 2.67 | Below AA, accepted the same way. |
| White on `coral` | 2.84 | Below AA, accepted the same way. |
| `ink` on `amber` | 5.76 | Passes |
| `ink` on white | 9.53 | Passes |
| `muted` on white | 4.12 | Fails for small text, hence the `mutedStrong` rule |
| Ink tokens on soft surfaces | 4.78–6.29 | Pass |

**Rules in every theme:**

- Body and secondary text must reach ≥ 4.5:1. `muted` may be used only at ≥ 16 px or for non-essential text; smaller secondary text uses `mutedStrong`.
- Feedback text always uses the `*Ink` tokens, never the saturated fill colour.
- Button labels are 15/20 weight 800 *(E; S1 says 14/18 weight 800)*. The 1 px increase improves legibility without changing the look.

**High-contrast theme** (Settings → Accessibility → High contrast) swaps only these values:

| Token | Default | High contrast | White label ratio |
|---|---|---|---|
| `primary` / `primaryShadow` | `#50C86A` / `#319248` | `#2B7D3E` / `#205E2E` | 5.11 |
| `sky` / `skyShadow` | `#2AA8E8` / `#1688C4` | `#137AB0` / `#0E5C84` | 4.73 |
| `coral` / `coralShadow` | `#FF6670` / `#BF4C54` | `#C8303F` / `#96242F` | 5.32 |
| `violet` / `violetShadow` | `#A86BE8` / `#7E50AE` | `#7E45C4` / `#5E3493` | 5.94 |
| `muted` | `#737E8C` | `#5B6573` | 5.91 |
| `border` | `#E2E6EA` | `#8A939E` | 3.11 vs white |
| `disabledText` | `#A7AFB8` | `#5B6573` | 4.8 on `disabled` |

In high contrast, every focus ring and selected outline is 3 px, not 2 px.

Dark theme is deferred (S1 §6.1). The app never auto-inverts.

---

## 3. Typography

### 3.1 Family (CF-26)

- **Nunito**, SIL Open Font License 1.1, bundled under `app/assets/fonts/` with `OFL.txt`.
- Weights: 500 Medium, 600 SemiBold, 700 Bold, 800 ExtraBold, 900 Black.
- Fallback: the platform sans.
- Golden tests load Nunito so results are stable.

### 3.2 Scale (S1 §6.2; reproduce exactly, except where marked)

| Style token | Size / line height | Weight | Use |
|---|---|---|---|
| `display` | 30 / 37 | 800 | Promise; result title. Centred; maximum three lines. |
| `heading` | 24 / 30 | 800 | Screen heading; lesson prompt |
| `section` | 20 / 26 | 800 | Unit title; feedback heading |
| `cardTitle` | 17 / 22 | 700 | Choice label; card title; node-card title (weight 800) |
| `body` | 16 / 24 | 500 | Instructions; explanations |
| `secondary` | 14 / 20 | 500 | Metadata; reasons |
| `button` | 15 / 20 | 800 | Buttons (uppercase for primary CTAs). S1 gives 14/18. |
| `caption` | 12 / 16 | 700 | Tags, stats, nav labels, section labels (uppercase, +0.6 letter spacing) |
| `statLarge` | 48 / 56 | 900 | Streak screen count. Tabular figures. *(E)* |
| `stat` | 16 / 20 | 800 | Counters in rows and pills. Tabular figures. |

### 3.3 Rules

- Rendered text never goes below 12 px.
- System text scaling is supported up to 2.0× without clipping. Text containers have no fixed heights.
- Body line length stays at 38–44 characters at 390 px. On wider columns, `maxWidth` is 560 px.
- All caps only for buttons, tags, eyebrows and section labels. Never for paragraphs.
- Hierarchy uses size and weight together, never weight alone (S2 P2.2). Lesson body text is weight 500, never bold.
- Counters use `FontFeature.tabularFigures()`.

---

## 4. Space, layout, radius and depth

### 4.1 Spacing scale

`SumiSpace` values: **4, 8, 12, 16, 20, 24, 32, 40, 48**. No other gaps are allowed (S1 §6.3).

### 4.2 Gutters and column

| Width | Horizontal gutter |
|---|---|
| 320–359 | 16 |
| 360–419 | 20 |
| ≥ 420 | 24 |

The column is at most 600 px wide and centred. Outside the column the background is `surfaceSoft`. Screens may never use a multi-column desktop layout.

### 4.3 Radius

| Token | Value | Use |
|---|---|---|
| `r8` | 8 | Index boxes; small badges |
| `r12` | 12 | Tokens, hint cards, nav tile, START bubble |
| `r16` | 16 | Buttons, choice rows, cards, unit header, node card |
| `r24` | 24 | Sheets; the path surface's top corners |
| `pill` | 999 | Progress bars, pills, tags |

### 4.4 Depth (crisp bottom edge, not blur)

| Element | Edge (rest) | Edge (pressed) | Pressed translation |
|---|---|---|---|
| Primary and coloured buttons | 4 px | 1 px | 3 px down |
| Choice rows, white cards | 3 px `borderShadow` | 1 px | 2 px |
| Path node | 6 px | 2 px | 4 px |
| Unit header, node card, section card | 4 px | 1 px (if tappable) | 3 px |
| Tokens and chips | 3 px | 1 px | 2 px |

- Implement the edge as a solid offset container. Do not use `BoxShadow` with blur.
- Ambient blur shadow is allowed only on modal sheets: `0 −2 16 ink@12%`.
- Disabled elements have no edge.

### 4.5 Touch targets

- Minimum 48 × 48. Visual elements smaller than that (a 40 px icon, for example) get padding to reach 48.
- Adjacent targets are at least 8 px apart.

---

## 5. Iconography and graphics

| Rule | Value |
|---|---|
| Style | Original filled and rounded icons; 24 px grid; strokes 2.25–2.75 px; rounded joins (S1 §7.2) |
| Format | SVG via `flutter_svg`, or `CustomPainter`. Every asset is registered in `app/assets/ASSETS.md`. |
| Interim | Material Symbols Rounded may stand in only until the original set lands (Phase 9). S6 rejects "Material-icon-only final graphic language". |
| Emoji | Never used as product icons. |
| Required families | S1 §7.1, items 1–9: wordmark; discipline tiles; onboarding hero; outcome icons; node set (lesson, review, project, story, checkpoint, chest, lock, check); exercise formats; rewards (flame, burst, spark, shield, quest target); model icons; empty states. |
| Discipline scenes | 120 × 120 (path), 160 (guide hero), 200 (checkpoint); 72 (discipline card) |
| Decorative graphics | Wrapped in `ExcludeSemantics` |

---

## 6. Motion

### 6.1 Tokens (`SumiMotion`)

| Token | ms | Curve | Use | Source |
|---|---:|---|---|---|
| `press` | 100 | easeOut | Button and node depth | S1 |
| `micro` | 160 | easeOut | Check draw, chip, selection, counter tick | S1 |
| `card` | 200 | easeOutCubic | Anchored node card, popover | CF-22 (S5: 160–240) |
| `screen` | 220 | easeInOut | Onboarding step forward and back | S1 |
| `sheet` | 240 | decelerate | Feedback panel; bottom sheets | S1 (S5: 180–320) |
| `slide` | 280 | easeOutCubic in, easeInCubic out | Guide, checkpoint, explain, streak (full-screen from the right) | CF-22 (S5: 220–320) |
| `pathReveal` | 420 | emphasizedDecelerate | Path reveal, connector fill, auto-scroll | S1 |
| `celebrationSmall` | ≤ 650 | spring then settle | Correct particles, quest tick | S1 |
| `nodeEvent` | 800 | Sequence (see PTH-06) | Node unlock and complete | Existing code; S2: 500–900 |
| `celebrationLarge` | ≤ 1,200 | staged | Result screen, checkpoint, chest | S1, CF-21 |
| `breath` | 1,600 loop | easeInOut | Current-node ring (guarded) | S1 |
| `tabSwitch` | 0–120 | linear crossfade | Root tabs | S2 §8 |
| `reducedFade` | ≤ 120 | linear | Reduced-motion replacement | S1 §8.3 |

### 6.2 Motion rules

- Motion never blocks input. Controls stay live during animation.
- Every celebration can be skipped with a tap.
- Loops run only when all of these hold: `SumiMotion.loopsEnabled`, reduced motion off, `TickerMode` enabled, and the app in the foreground. `loopsEnabled` is false in tests (MOT-04).
- An animation runs only after its triggering state has been persisted (S4).
- No percentage is shown unless it comes from real bytes or tokens.
- Under reduced motion: no particles, shake, travel or bounce. Use a `reducedFade` crossfade or an instant change, with the same final state and the same text.

### 6.3 Event contract (S1 §8.2, extended; MOT-02)

| Event | Visual | Haptic | Sound | Reduced motion |
|---|---|---|---|---|
| Choice selected | Border → `sky`, fill → `skySoft`, check slides in (`micro`), scale 1 → 1.015 → 1 | selectionClick | `select` | Instant fill and check |
| Primary pressed | 3 px translate, edge 4 → 1 (`press`) | lightImpact | `tap` (optional) | Same depth change |
| Correct | Choice turns green; check draws; panel rises (`sheet`); 6–10 particles ≤ 650 ms | success pattern (light, light) | `correct` | Panel instant; no particles |
| Near-correct | Amber outline; rubric chips reveal, staggered 40 ms | lightImpact | `partial` | Chips instant |
| Incorrect | Correct answer highlighted; selected card nudges ±4 px × 2 cycles in 240 ms | warning pattern (medium) | `incorrect` | No nudge; icon and text change only |
| Hint shown | Hint card unfolds (`micro`, height plus fade) | selectionClick | — | Instant |
| Node card | Scale 0.92 → 1 plus fade (`card`) | — | — | Instant |
| Lesson complete | Result sequence ≤ 1,200 ms: hero pop 0–300, title 240–600, tiles staggered 120 ms from 480, counters count up, confetti ends ≤ 1,200 | success | `lesson_complete` | Final frame |
| Node complete | `nodeEvent`: icon Y-flip, 8-ray burst, connector fills (`pathReveal`) | lightImpact | `node_complete` | Final state |
| Node unlock | `nodeEvent`: lock shake 0–32 %, colour flood, pop to 1.18 | lightImpact | `node_unlock` | Final state |
| Checkpoint | `nodeEvent` + amber flood + 12 rays + crown | mediumImpact | `reward` | Static crown |
| Path revised | Old nodes fade to 60 %; moved nodes slide; "Why this changed" card | — | — | Crossfade only |
| Streak maintained | Flame scales 1 → 1.08 → 1 once; count increments | lightImpact | `streak` | Count changes only |
| Reward chest | Lid opens; reward rises; SKIP available | mediumImpact | `reward` | Instant reward panel |
| Download | Bar follows real bytes | — | — | Same |
| Model verified | Check draws; offline badge appears | success | `model_ready` | Instant |
| Model error | Progress stops; warning card; Retry enabled | warning | — | Same |
| Tab switch | ≤ 120 ms crossfade, never via white | — | — | Instant |

Sound plays only when Settings → Sound effects is on. Haptics play only when Haptics is on. Audio is never the only feedback.

---

## 7. Components

Every component below has: one implementation; semantics; a 48 px minimum target; a focus ring; and every state that applies to it, from this list: **default, hover** (pointer devices only), **focused, pressed, selected, disabled, loading, success, empty, error**.

### 7.1 TactileButton

| Variant | Fill | Edge | Label | Use |
|---|---|---|---|---|
| `primary` | `primary` | `primaryShadow` | white | CHECK, CONTINUE (correct), START, GET STARTED |
| `secondary` | `sky` | `skyShadow` | white | CONTINUE LESSON, DONE, failure CONTINUE |
| `danger` | `coral` | `coralShadow` | white | Incorrect CONTINUE |
| `warning` | `amber` | `amberShadow` | `ink` | Near-correct TRY AGAIN |
| `outline` | white, 2 px `border` | 3 px `borderShadow` | `infoInk` (or `errorInk` in the incorrect context, with a `coral` border) | EXPLAIN MY MISTAKE, CONTINUE MY PROGRESS |
| `inset` | white | 3 px of the parent's shadow tone | parent colour (darkened `*Ink` for contrast) | Button inside the node card |
| `text` | none | none | `infoInk` / `mutedStrong` / `errorInk` | Secondary actions |

- **Size:** height 56 (plus the 4 px edge); full width by default; minimum width 120; horizontal padding 24; radius 16.
- **Label:** `button` style, uppercase for primary CTAs, maximum one line (ellipsis).
- **Leading icon:** optional, 20 px, 8 px gap.

| State | Specification |
|---|---|
| Default | As in the table above |
| Hover | Fill lerps 8 % toward white; cursor is a click pointer |
| Focused | 3 px `focusRing`, 2 px outside the bounds; layout unchanged |
| Pressed | Translate Y 3 px; edge to 1 px; fill to `*Pressed` (primary uses `primaryPressed`; others are base × 0.9); `press` 100 ms |
| Disabled | Fill `disabled`; no edge; label `disabledText`; `onTap` null; semantics `enabled: false` |
| Loading | Width fixed; a 18 px spinner replaces the leading icon; the verb stays readable ("SAVING…"); taps ignored |
| Success | A check icon shows for ≤ 350 ms, then the action continues |

Semantics: `button: true`, a label equal to the visible label, and `enabled`.

### 7.2 ChoiceRow

- **Size:** minimum height 64; padding 16; radius 16; 2 px `border` outline; 3 px `borderShadow` edge.
- **Leading content:** optional 32 × 32 index box (2 px `border`, radius 8, `caption` style, `mutedStrong`) or a 28–32 px icon (onboarding).
- **Label:** `cardTitle`, `ink`, wrapping.
- **Trailing content:** a check badge (24 px) in selected, correct and incorrect states.
- **Gap between rows:** 12.

| State | Outline / edge | Fill | Label | Trailing |
|---|---|---|---|---|
| Default | `border` / `borderShadow` | white | `ink` | — |
| Hover | Same | `surfaceSoft` | `ink` | — |
| Focused | + 3 px focus ring | — | — | — |
| Pressed | Translate 2 px; edge 1 | — | — | — |
| Selected | `sky` / `skyShadow` | `skySoft` | `infoInk` | `sky` check |
| Correct (graded) | `primary` / `primaryShadow` | `primarySoft` | `successInk` | Check circle |
| Incorrect (graded) | `coral` / `coralShadow` | `coralSoft` | `errorInk` | X circle |
| The right answer after an incorrect one | `primary`, dashed 2 px | white | `successInk` | Check plus "Correct answer" |
| Disabled or read-only | Unchanged, 100 % opacity, no tap | — | — | — |

Semantics: "Option {i} of {n}, {label}", plus `selected` and `inMutuallyExclusiveGroup`.

### 7.3 ProgressBar

- Height 10 (lesson) or 8 (cards); radius `pill`.
- Track `disabled`; fill `primary` (or the context colour).
- A highlight stripe: 3 px tall, inset 4 px from the top-left, white at 35 %, 60 % of the fill width.
- Value changes animate with `micro`.
- The indeterminate variant is a 30 %-wide segment sweeping at 1.2 s per pass. It is guarded like a loop; under reduced motion it is a static 30 % segment with a "Loading" label.
- Semantics: "{label}, {value} of {max}".

### 7.4 Tag and Pill

- **Tag:** height 24; horizontal padding 10; radius `pill`; `caption` style uppercase; soft fill with ink text (for example `primarySoft` with `successInk`).
- **Pill (stat):** height 36, inside a 48 target; 16 px icon; `stat` text; 8 px gap.

### 7.5 Card (Surface)

- White; radius 16; 2 px `border`; 3 px `borderShadow` edge when tappable (none when static).
- Padding 16 (compact) or 20.
- The existing `Surface` widget (radius 24, 1 px border) is replaced by this card.

### 7.6 TextField

- Fill `surfaceSoft`; radius 16; 2 px `border`; padding 16; text style `body`.
- Focus: 3 px `focusRing` border.
- Error: 2 px `coral` border plus a helper line in `errorInk`, 14/20.
- Counter at bottom right in `caption` `mutedStrong`.
- The label sits above the field (`cardTitle`), never placeholder-only.
- The field scrolls into view above the keyboard and the sticky action.

### 7.7 Chip (selectable)

- Height 40, inside a 48 target; padding 14; radius `pill`; 2 px `border`; `secondary` text at weight 700.
- Selected: `skySoft` fill, `sky` border, `infoInk` text, a 16 px check.
- Prompt chips (outcome) use the outline style with a 16 px "+" icon.

### 7.8 IconButton

- A 48 × 48 hit area; icon 24 (or 28 for the X in the lesson header); colour `muted`.
- Pressed: a `surfaceSoft` circle.
- A tooltip equal to the semantics label.

### 7.9 Sheets, popovers and scrim

- **Bottom sheet:**
  - Radius 24 on the top corners; white; a grabber (36 × 4, `border`, 8 px from the top).
  - Padding: the gutter at the sides, 24 at the top, 16 + safe area at the bottom.
  - Scrim behind it; enters with `sheet`.
  - Drag to dismiss, unless there are unsaved edits.
  - Esc and Android back close it.
- **Full-height sheet** (section overview): the same, plus a 56 px header with X at left and a centred title.
- **Popover:**
  - White card; radius 16; 2 px `border`; 16 px padding; maximum width 280.
  - An 8 px pointer toward the anchor.
  - Scrim behind it; enters with `card`.

### 7.10 SumiBottomNav (SHL-02, CF-14)

- Bar: 64 + safe area; white; 2 px `border` top line; four equal slots.
- Slot: icon 24 over label (`caption` style, not uppercase), with 4 px between.
- Selected: a 56 × 32 tile behind the icon (`skySoft` fill, 2 px `sky` outline, radius 12); icon and label `infoInk`.
- Unselected: `muted`. Hover: tile `surfaceSoft`. Focus: ring on the slot.
- Labels: "Learn", "Practice", "Library", "Profile".
- Semantics: "{label}, tab, {i} of 4" plus `selected`.

### 7.11 GoalCourseStrip and path surface (PTH-01)

- **Strip:** `ink` background; height 48 below the status-bar inset; horizontal scroll; item padding 16.
- **Items:** `button` style uppercase.
  - Selected: white, with a 3 × 24 px white underline (radius 2) 6 px below the text.
  - Unselected: white at 60 % opacity (4.63:1 on `ink`).
  - "+ ADD" is the last item, with a 16 px plus icon.
- **Truncation:** at 160 px with an ellipsis.
- **Path surface:** white; top corners r24; overlaps the strip by 24 px (the strip extends behind it); the status bar uses light icons.

### 7.12 PathNode (PTH-05)

**Geometry**

- Disc 72 × 72 (checkpoint 82 × 82), plus a 6 px edge below it.
- Hit area 88 × 96.
- Top highlight: 34 × 9 capsule, white at 28 %, centred 10 px from the disc top (omitted when locked).
- Icon 32 (checkpoint 36).

**Type fills** (when available or current)

| Type | Fill / edge | Icon (rounded set) | Icon colour |
|---|---|---|---|
| microLesson | `primary` / `primaryShadow` | star | white |
| guidedPractice | `primary` / `primaryShadow` | dumbbell / bolt | white |
| videoResource | `primary` / `primaryShadow` | play | white |
| recallReview | `violet` / `violetShadow` | rewind | white |
| projectStep | `sky` / `skyShadow` | tool (needle + ruler) | white |
| checkpoint | `amber` / `amberShadow` | flag | `ink` |
| rewardUnlock | `amber` / `amberShadow` | chest | `ink` |

**State overrides**

| State | Fill | Edge | Icon | Extra |
|---|---|---|---|---|
| locked | `disabled` | **none** | lock, `disabledText` | Semantics "locked" |
| available | Type fill | Type edge | Type icon | — |
| current | Type fill | Type edge | Type icon | START bubble + breathing ring (7.16) |
| inProgress | Type fill | Type edge | Type icon | 5 px progress ring at radius 46: track `disabled`, value in type fill; bubble reads "CONTINUE" |
| complete | `primarySoft` | `primaryShadow` at 40 % | check, `primary` | 3 px `primary` outline. Checkpoint: amber fill, crown icon. |
| mastered | As complete | As complete | As complete | 20 px amber star badge at top right |
| needsReview | `violet` | `violetShadow` | rewind | "REVIEW" bubble in place of START |

- **Interaction:** pressed = the disc translates 4 px and the edge goes to 2 px (`press`); hover = fill lightens 6 %; focus = a 3 px ring at radius 44.
- **Semantics:** button, label "{title}, {type label}, {state}", hint "Double tap to see details".

### 7.13 PathStatusRow (PTH-02)

- Height 44; the gutter on both sides; 12 px below the surface's top edge.
- **Left:** the discipline badge (32 × 32, radius 8, the discipline's mini-graphic).
- **Right:** two pills, 16 px apart:
  - flame + streak count: `amber` when today qualified, otherwise `disabledText`, with semantics "not yet today";
  - burst + points: `amber`.
- Tapping a pill gives the pressed state (scale 0.96, `press`).

### 7.14 UnitHeaderCard (PTH-03)

- Full content width; radius 16; fill = the unit palette; 4 px edge in the unit shadow colour.
- Minimum height 88; padding 16 at the left, 0 at the right.
- **Left zone:**
  - eyebrow "UNIT {n} · {done}/{total} STEPS" (`caption`, white at 80 %);
  - 4 px gap;
  - title (`section`, white, maximum three lines at 200 %).
- **Right zone:** 72 px wide; a 2 px left divider in white at 25 %; a centred guidebook icon (28, white) over "GUIDE" (`caption`, white).
- **Two tap targets:** body → section overview; guide zone → unit guide. Each has its own pressed state.

### 7.15 NodeActionCard (PTH-08, PTH-09)

- Width `min(340, contentWidth)`; height fits the content.
- Radius 16; padding 16; 4 px edge in the shadow tone.
- **Fill:**
  - available or current: the node's type fill;
  - complete: `primary`;
  - needsReview: `violet`;
  - locked: white with a 2 px `border` and a `borderShadow` edge; text in `ink`/`mutedStrong`.
- **Pointer:** a 16 × 8 triangle toward the node's centre, clamped 16 px inside the card edges.
- **Layout:**
  1. eyebrow (`caption`, white at 85 %): "{TYPE} · {m} MIN", or "LOCKED";
  2. 4 px gap; title (`cardTitle` weight 800, white, maximum two lines);
  3. 4 px gap; reason line (`secondary`, white at 90 %, maximum two lines);
  4. 12 px gap; action.
- **Action:**
  - `inset` TactileButton, full width: "START +{base} POINTS", "CONTINUE", "REVIEW +15 POINTS", "PRACTISE AGAIN", or "START CHECKPOINT".
  - Locked: an `outline` button "GO TO {PREREQUISITE}".
- **Placement:** 12 px below the node. If the space below is < card height + 24, it goes 12 px above.
- **Motion:** appears with `card`; replaced by another card with a crossfade (`micro`).
- **Dismissal:** outside tap, scroll > 8 px, Esc or Android back.
- **Semantics:** a route-like container announced as "{title} details", with focus moved to the title.

### 7.16 Connector, START bubble and breathing ring

- **Connector:** an 8 px round-cap quadratic curve from the bottom centre of node *i* to the top centre of node *i+1*, with the control point at the vertical midpoint and the horizontal mean. Colour `border`; `primary` when both ends are complete. It is painted under the nodes.
- **START bubble:**
  - white; radius 12; 2 px `border`; padding 12 × 6;
  - label 13 px weight 800 in the node fill (the `infoInk` equivalent for contrast: on primary nodes use `successInk`);
  - a 14 × 7 tail;
  - the bubble's bottom sits 6 px above the disc top;
  - it is not affected by text scaling (it is decorative, and the label is duplicated in the node's semantics).
- **Breathing ring:** a 2 px stroke in the node fill at 40 %, radius animating 44 → 48 → 44 over `breath`, guarded (§6.2). Static at 46 when not animating.

### 7.17 Token chip and bank (LES-14)

- **Token:** minimum height 48; padding 14 × 10; radius 12; white; 2 px `border`; 3 px `borderShadow` edge; text 15/20 weight 700.
- **Placeholder:** the same size, `disabled` fill, no edge, no label.
- **Answer area:** minimum height 112; two to three guide lines (2 px `border`) 56 px apart; tokens wrap with 8 px gaps.
- **Graded:** answer tokens recolour as in ChoiceRow correct/incorrect, per position.

### 7.18 Match pairs

- Two columns with a 12 px gap; tiles are 64 tall and styled like ChoiceRow.
- Selecting a left tile gives the sky selection; then selecting a right tile forms a pair. Paired tiles show a shared index badge.
- After grading: correct pairs are green; wrong pairs are coral and show the correct partner.

### 7.19 Media, music and drawing renderers

- **Media observation:**
  - a reference card (`surfaceSoft`, radius 16): title, source, duration, "Opens outside Sumi" with a link icon, and an OPEN outline button;
  - a check row "I watched or read this" (ChoiceRow style, check variant);
  - an observation field (7.6).
- **Music tap:**
  - a 4-beat visual pulse row (4 circles, 24 px, `sky` when lit, `surfaceSoft` when not), lit by the real metronome tick;
  - a 120 px TAP disc (TactileButton-style circle, `primary`);
  - a tap counter "3/5";
  - a "CAN'T TAP NOW" alternative records the accessible count.
  - Copy discloses that taps, not audio, are measured.
- **Drawing:** a canvas 100 % × 180 (radius 12, `surfaceSoft`, 2 px `border`); a 4 px `ink` stroke; Undo and Clear as text buttons; a label field.

### 7.20 Reflection field

TextField (7.6), minimum three lines, with a prompt label above. The minimum length is shown as a helper: "At least 12 characters".

### 7.21 FeedbackPanel (LES-04 to LES-07)

- Replaces the sticky action.
- Full width; padding 16 at the top, the gutter at the sides, 16 + safe area at the bottom.
- Top corners square, matching the reference; no top border.
- Rises with `sheet`. Maximum height is 50 % of the viewport, with internal scrolling.

**Header row:**

- a 32 px white circle with a 20 px state icon;
- 12 px gap;
- heading (`section` style, ink token);
- trailing: a points chip (correct only; `amber` fill, `ink` text "+{n}", tappable for the breakdown) or the mascot reaction (52 px). If both apply, the mascot is placed left of the heading and the chip right.

**Body:** explanation in `body`, ink token, ≤ 240 characters, then "More" (`text` button).

**Actions:** 16 px below the body; full-width buttons with a 12 px gap.

| Variant | Panel | Icon | Heading | Body | Actions |
|---|---|---|---|---|---|
| correct | `primarySoft` | check, `primary` | "Correct!" or "Nice work." (alternating by attempt index) | Authored explanation | Calibration row (text: Too easy · Too hard · Report issue, `successInk` `caption`) · `primary` CONTINUE |
| incorrect | `coralSoft` | X, `coral` | "Not quite yet." | "Correct answer:" + the answer in weight 700, then the explanation | `outline` (coral) EXPLAIN MY MISTAKE · `danger` CONTINUE |
| nearCorrect | `amberSoft` | ≈, `amberShadow` | "Almost—one part needs work." | Rubric rows (✓ / ✕ / ? + text), then the explanation | `warning` TRY AGAIN · `text` CONTINUE (`warningInk`) · `text` EXPLAIN MY MISTAKE |
| retry | `skySoft` | refresh, `sky` | "Let's try that again." | What is needed | `secondary` TRY AGAIN · `text` CAN'T DO THIS NOW (where it applies) |
| saveError | `surfaceSoft` | warning, `warning` | "Not saved yet" | "Your answer is still here. Check storage and try again." | `primary` RETRY SAVE |

- **Semantics:** the panel is a live region and announces "{heading}. {first sentence of body}" once. Focus moves to the heading.

### 7.22 LessonProgressHeader (LES-01)

- Row height 56; gutter padding.
- Contents, left to right:
  - X (48);
  - 8 px gap;
  - ProgressBar (flexible);
  - 12 px gap;
  - Focus pill (heart-shield 22 px `coral` + `stat` count; 48 target);
  - tune IconButton (40 visual, 48 target).
- At 320 px the progress bar keeps at least 96 px.
- **Focus = 0:** the icon is `disabledText`, and a Tag "PRACTICE MODE" (`violetSoft` / `violetInk`) appears under the bar, centred.
- **Semantics:** "Lesson progress, {done} of {total}"; "Focus {n} of 5".

### 7.23 StickyLessonAction (LES-03)

- White; 2 px `border` top line; padding 16 / gutter / 16 + safe area.
- Contents: the primary button (CHECK, or SAVE EVIDENCE for project nodes).
- Optional leading `text` action, placed above the button in a 40 px row at 200 % text or < 360 px width; otherwise on the same row at 40 % width.
- It moves with the keyboard inset and is never covered.

### 7.24 ExplainMistakeScreen (LES-08)

- AppBar 56: back arrow (48), title "Explain my mistake" (`cardTitle` weight 800), no elevation, 2 px `border` bottom line.
- Body (gutter; 24 at the top), in order:
  1. "YOUR ANSWER" section label, then chips (Token style, coral outline);
  2. 24 px gap; explanation card (Card 7.5, padding 20). Key term highlighted in a `skySoft` span with `infoInk`; then the "Example" sub-label and the example text;
  3. 16 px gap; "Was this helpful?" (`secondary`) with two 48 px thumb IconButtons; the selected one is `skySoft` / `infoInk`;
  4. 24 px gap; optional `outline` "EXPLAIN IT ANOTHER WAY" with a provider badge (7.38) under it.
- Footer: sticky `secondary` "CONTINUE LESSON".
- AI states: loading = an indeterminate bar with "Asking {provider}…" and Stop (`text`); error = an inline error (7.36) with Retry; the response appears in a second card labelled with the provider badge.

### 7.25 LessonSettingsSheet and ExitConfirmSheet

- **LessonSettingsSheet (7.9 sheet):**
  - title "Lesson settings" (`section`);
  - switch rows (7.30) for Sound effects, Haptics, Reduced motion and Captions & transcripts;
  - segmented control for "Explanations: Short / Detailed" (two segments, 48 tall, radius 12, selected `skySoft`/`infoInk`);
  - a Focus row: "Focus never blocks learning or explanations." with an `outline` "REFILL FOCUS";
  - `secondary` DONE;
  - `text` END SESSION (`errorInk`).
- **ExitConfirmSheet:**
  - title "Keep progress and leave?" (`section`);
  - body "Your checked answers and current draft are saved on this device.";
  - `primary` KEEP LEARNING;
  - `text` SAVE & EXIT (`mutedStrong`).

### 7.26 Points popover

Popover (7.9) anchored to the points pill:

- "{n} points this week" (`cardTitle`);
- "Points measure practice, not mastery." (`secondary`);
- "See evidence in Profile →" (`text`).

### 7.27 DisciplineCard (ONB-02)

- Minimum 156 × 180, flexing to 140 at 320 px; radius 16; 2 px `border`; 3 px edge; padding 16.
- Layout: a 72 px graphic at top left; 12 px gap; title (`cardTitle`); 4 px gap; subtitle (`secondary`, maximum three lines).
- The "Something else" card spans two columns with a horizontal layout: graphic left, text right; minimum height 96.
- **Selected:** `skySoft` fill; `sky` border and edge; a 24 px check badge at top right.

### 7.28 QuestCard (GAM-04)

- Card (7.5).
- Header row: 32 px quest-target icon (`violet`); "Daily quests" (`cardTitle`); "{done}/3"; collapse chevron.
- Rows (56): icon, title (`secondary` weight 700), 8 px amber ProgressBar, "x/y" (`caption`).
- Footer: chest icon. Locked = `disabled`; open = `amber` with "+5 sparks".
- Collapsed height 56.

### 7.29 Project reflection form (LES-21)

- Three labelled fields (7.6): "What did you make or try?", "What happened? One observation", "What will you change next time?". The fields are 16 px apart.
- Rubric self-check chips (7.7) under the heading "Check your own work".
- A Tag "SELF-REPORTED" next to the heading.

### 7.30 Settings list and rows

- Section label: `caption` uppercase in `mutedStrong`; 24 px above and 8 px below.
- Row: minimum height 56; padding 16; title `body` weight 700; subtitle `secondary` `mutedStrong`, derived from state; trailing chevron or switch.
- Rows are separated by a 1 px `border` line, inset 16.
- Switch: Material switch themed with track `primary` (on) and `disabled` (off), and a white thumb.
- Disabled row: the title in `disabledText`, the subtitle explains why.
- Groups sit on white with no cards (quiet list, S5 §7.5).

### 7.31 ResourceCard (LIB-02)

- Card (7.5), padding 16, maximum height 168 at 100 % text.
- Row 1: format icon (24) + title (`cardTitle`, two lines).
- Row 2: publisher · duration · level (`secondary` `mutedStrong`).
- Row 3: tags for "MATCHES: {capability}", the review status, and "NEEDS CONNECTION" (if online-only).
- Row 4: "Why: {one line}" (`secondary`).
- Actions: `text` SAVE / SAVED and `text` "TRY A RELATED TASK".
- Tap opens the detail sheet.

### 7.32 StatTile (result)

- A coloured frame (radius 16, the label strip 28 px tall in the fill colour, `caption` white uppercase) around a white inner box (radius 14, padding 14 × 6) holding a 22 px icon and a 20/24 weight 900 tabular value in the frame colour.
- Three tiles with 8 px gaps.
- POINTS uses an `amber` frame with an `ink` label strip for contrast.

### 7.33 Mascot slot rules (CF-01)

- Allowed placements:
  - the feedback panel (52 px);
  - the result hero (200 px);
  - empty states (120 px);
  - the onboarding promise (one-shot `greet`, 160 px);
  - the lesson loading screen (`think` poster).
- **Not** allowed on the path, node cards, Settings (except the debug gallery), or as decoration on every screen.
- Always `ExcludeSemantics`, unless a `semanticLabel` adds meaning. Text carries the meaning.
- Reduced motion: the poster pose. Tests: `loopsEnabled = false`, so no infinite loops.

### 7.34 EmptyState

- A centred column: 120 px original illustration; 16 px gap; heading (`section`); 8 px gap; body (`body` `muted`, maximum three lines); 24 px gap; optional `outline` action.
- Required copy is in §11.6.

### 7.35 Skeleton and loading

- Only for genuine async work, and only after 150 ms.
- Destination-shaped blocks in `surfaceSoft`, radius matching the real component.
- A one-pass shimmer, never indefinite. After 2 s, show a static skeleton with the label "Still loading…".

### 7.36 Inline error and snackbar

- **Inline error:** a row in `coralSoft`, radius 12, padding 12: warning icon (20, `errorInk`) + message (`secondary` `errorInk`) + `text` RETRY.
- **Snackbar:** only for confirmations ("Saved"); `ink` background, white text, radius 12, floating 16 px above the navigation bar, 4 s.

### 7.37 Model card (re-skin only, AIM-01)

- Card (7.5) with: model name (`cardTitle`); quantization · size · RAM guidance (`secondary`); licence link; a status Tag; a primary action. A real-bytes ProgressBar while downloading.
- No change to the state logic.

### 7.38 Provider badge (TUT-02)

- A pill 24 tall: `surfaceSoft` fill; 1 px `border`; a 14 px icon (book / chip / cloud) + `caption` text: "AUTHORED", "ON-DEVICE · {MODEL}" or "CLOUD · {PROVIDER}".

---

## 8. Screen layouts at 390 × 844 (top to bottom)

### 8.1 Boot and recovery (SHL-05)

- **Boot:** white; a centred 144 px wordmark; 24 px gap; an indeterminate ProgressBar 120 px wide; no copy unless the boot takes > 1 s ("Opening your learning space…").
- **Recovery:** EmptyState with the heading "We couldn't open your progress", the body "Your saved data is untouched.", and actions TRY AGAIN (`primary`), EXPORT RECOVERY FILE (`outline`) and START A FRESH PROFILE (`text`, confirmation required).

### 8.2 Onboarding scaffold (ONB-11)

- Top row (56): back IconButton (hidden on the promise screen); 8 px gap; ProgressBar 10 px, flexible; 48 px right spacer for symmetry.
- Body: scrollable; gutter; 24 px top padding; the heading (`heading`) is the first element; content follows 20 px below.
- Footer: StickyLessonAction styling with one `primary` button (CONTINUE / START FIRST LESSON).
- Step transition: a horizontal slide (`screen`) — forward from the right, back from the left. Crossfade under reduced motion.

Step-specific layouts are in matrix ONB-01 to ONB-10. Copy is in §11.1.

### 8.3 Learn

1. GoalCourseStrip (48).
2. Path surface (r24 top) starting with PathStatusRow (44).
3. QuestCard (collapsed, 56), 12 px below.
4. UnitHeaderCard, 12 px below.
5. Serpentine path (pitch 104) with connectors and scenes.
6. The next unit's header, 32 px after the last node; then its nodes.
7. 96 px bottom padding.
8. SumiBottomNav.

The first viewport at 390 × 844 shows the strip, status row, unit header, the current node and at least one adjacent node (S2 §4.1).

### 8.4 Section overview (PTH-10)

A full-height sheet. A 56 px header (X / centred title). Then section cards, 12 px apart:

- unit palette fill; radius 16; 4 px edge; padding 16;
- a 64 px original graphic at the right;
- eyebrow, title, "Steps a–b", a ProgressBar 8 px (white on white at 30 %);
- a `inset` button CONTINUE or JUMP HERE.

### 8.5 Unit guide (PTH-11)

Slide in. Header 56 (X / "Unit {n} guide"). Then:

- a 160 px hero;
- KEY IDEAS cards;
- WATCH video cards;
- REFERENCE `skySoft` panels (radius 16, padding 16, `infoInk` headings);
- TRY with `primary` "PRACTISE THIS UNIT".

### 8.6 Checkpoint detail (PTH-12)

Slide in. Header 56. Then:

- three 48 px stars, 8 px apart, centred, 24 px below the header;
- a 200 px scene;
- the title "{Unit title} checkpoint" (`heading`, centred);
- the rule text (`body`, centred, max width 320);
- two info tiles side by side (Card, 50 % each);
- a sticky `primary` START CHECKPOINT.

### 8.7 Lesson (LES-01 to LES-03)

1. LessonProgressHeader (56).
2. Body (gutter; 24 px top):
   - optional category Tag (NEW IDEA / PRACTICE / REVIEW / PROJECT / CHECK / REPAIR);
   - 8 px gap; prompt (`heading`);
   - 8 px gap; optional context (`body` `muted`, ≤ 90 words; "Learn more" beyond 120);
   - 20 px gap; the renderer;
   - flexible space.
3. StickyLessonAction, or FeedbackPanel.

At 390 × 844 and 100 % text, the prompt and the whole response control are visible without scrolling for every authored challenge. At 200 % they stay reachable by scrolling, with no overlap.

### 8.8 Explain My Mistake

See 7.24.

### 8.9 Result (RES-01)

1. Hero (200; mascot over rays).
2. 8 px gap; title (`display`, centred, `successInk`, or `warningInk` for recovery).
3. Accolade line (`body`, centred).
4. 24 px gap; three StatTiles.
5. 16 px gap; a "Today" row (Card): a daily-goal ring (40 px, `primary`, "{m}/{goal} min") + streak flame + "{n}-day streak" + a "+1 day" Tag when this session qualified.
6. 16 px gap; evidence card.
7. 16 px gap; "Next: {title}" card with the node icon.
8. Sticky footer: `primary` CONTINUE; below it `text` RETURN TO PATH and `text` Review saved responses, side by side.

### 8.10 Checkpoint failure (RES-03)

A centred EmptyState layout, then a sticky `secondary` CONTINUE.

### 8.11 Practice (PRA-01)

1. AppBar 56: "Practice".
2. Violet header card (`violet` fill, `violetShadow` edge, white title "Practice" + "{n} items ready", 96 px graphic).
3. Section label and rows for each of the five sections, in order. Empty sections are hidden.
4. When everything is empty, the EmptyState "You're caught up".
5. Rows: 48 px type icon disc (node colours), title (`cardTitle`), reason (`secondary` `mutedStrong`), chevron. Height ≥ 72.

### 8.12 Profile (PRO-01)

1. AppBar: "Profile"; settings gear (48) at right.
2. Identity header (radius 16, unit-palette fill, white): discipline badge 56, the discipline title, and the goal outcome (two lines).
3. "THIS WEEK" engagement row: four mini stats (streak, points, lessons, quests) in a 2 × 2 grid of Cards.
4. "WHAT YOU'VE SHOWN" evidence list: capability cards with a state Tag, a "last practised" line, an evidence count and an uncertainty word, plus a chevron to EVD-04.
5. "HOW SUMI IS ADAPTING" card.
6. "AI" row (PRO-02).
7. "DISCIPLINES" switcher.

### 8.13 Library (LIB-01)

AppBar "Library". Groups in order — Recommended for you, Saved, Used recently, Browse by discipline — each with a section label and ResourceCards 12 px apart. Filter chips (7.7) at the top: Video / Reading / Offline-friendly / Free.

### 8.14 Settings (SET-01)

AppBar "Settings". The sections in the SET-01 order. Rows and subtitles are in §11.5.

### 8.15 Streak screen (GAM-06)

Slide in:

- X (48) at left;
- header area 240 tall in `skySoft`: a flame graphic 96 px, the count (`statLarge`), "day streak";
- a month calendar (7 columns, 40 px cells, 4 px gaps): qualified = an `amber` circle with an `ink` day number; token-covered = a `sky` outline; today = a 2 px `ink` outline;
- "What counts" card;
- "Recovery tokens: n/2" card.

### 8.16 Custom-goal plan screen (CUS-01)

A heading, the outcome card and a `PROVISIONAL` Tag. Then, depending on model state:

- **model ready:** `primary` "DRAFT A PLAN ON THIS DEVICE", followed by a progress view during generation and a validation result;
- **no model:** the EmptyState "Sumi needs a plan for this goal" with `outline` "SET UP AN OFFLINE MODEL" and `text` "CHOOSE MUSIC OR FASHION FOR NOW".

---

## 9. Responsive behaviour

| Width | Rules |
|---|---|
| 320–359 | Gutter 16. Serpentine amplitude 76 → clamp `(w − 2·16 − 72)/2 − 16` (= 92 at 320, clamped to 76). Discipline cards flex to 140 wide. The sticky leading text action moves above the button. The node card is `contentWidth` wide. |
| 360–419 | Gutter 20. Reference layout. |
| 420–600 | Gutter 24. Body text max width 560. The node card is capped at 340. Path amplitude stays 76; the extra width becomes margin. |
| > 600 | A centred 600 column on `surfaceSoft`. |
| Text 1.3–2.0× | No fixed-height text boxes. The node card, feedback panel and footers grow. The START bubble does not scale (its meaning is in semantics). Stat tiles scale their values down with FittedBox (min 12 px). The status row wraps the points pill under the streak pill when overflowing. The course strip keeps one line and scrolls. |
| Landscape (phones) | The same column. The lesson body scrolls. The footer stays sticky. No dedicated layout. |
| Keyboard open | `resizeToAvoidBottomInset` on. The active field and primary action remain visible (scroll-into-view with 16 px clearance). |

Golden viewports: 320 × 700, 390 × 844, 430 × 932, 600 × 960. Each also runs at 2.0× text, in high contrast, and with reduced motion (QA-01).

---

## 10. Accessibility and keyboard

### 10.1 Semantics

| Element | Role and label |
|---|---|
| TactileButton | `button`; the visible label; `enabled` |
| ChoiceRow | `button` + `selected` + `inMutuallyExclusiveGroup`; "Option i of n, {label}" |
| PathNode | `button`; "{title}, {type}, {state}"; hint "Shows details" |
| NodeActionCard | Container; focus moves to the title; the card is announced |
| ProgressBar | "Lesson progress, x of y" |
| Focus pill | "Focus x of 5" (+ ", practice mode") |
| Stat pills | "Streak, n days, {today done / not yet today}"; "Points, n" |
| FeedbackPanel | `liveRegion`; one announcement |
| Decorative art, mascot, scenes, connectors, confetti | `ExcludeSemantics` |
| External links | Hint "Opens outside Sumi. May need a connection." |
| Music tasks | Visible beat count and transcript text |
| Fashion diagrams | A concise description label |

### 10.2 Focus order

Visual order everywhere:

- **Lesson:** X → progress (read only) → Focus → settings → prompt → response controls → secondary action → primary action.
- **After grading:** focus moves to the feedback heading → actions.
- **On sheet and card open:** focus moves to the first element. On close: focus returns to the trigger.

### 10.3 Keyboard (hardware keyboard, web preview, ChromeOS)

| Key | Action |
|---|---|
| Tab / Shift+Tab | Move focus with the 3 px ring visible |
| Enter / Space | Activate the focused control |
| Enter (no focus inside a field) | The active primary action (CHECK / CONTINUE), when enabled |
| Esc | Close the node card, popover, sheet or explanation; in a lesson with no overlay, open the exit confirmation |
| 1–9 | *(optional, A11Y-08-O)* select choice *n* |

Hover states exist only on pointer devices (`MouseRegion`). They never carry information that is missing on touch.

### 10.4 Other requirements

- Minimum target 48 × 48.
- 200 % text: no clipping and no horizontal scroll.
- Reduced motion takes effect immediately and persists.
- Sound and haptics can be toggled independently.

---

## 11. Copy deck (exact strings)

Mixed case is as written. Buttons are uppercase where shown.

### 11.1 Onboarding (S1 §9)

| Key | Text |
|---|---|
| promise.title | Learn anything by doing it, one clear step at a time. |
| promise.support | A route that adapts to what you can show. |
| promise.cta | GET STARTED |
| promise.resume | CONTINUE MY PROGRESS |
| discipline.heading | What do you want to learn? |
| discipline.music | Music — Rhythm, pitch, practice, and creation. |
| discipline.fashion | Fashion Design & Tailoring — Design, measure, construct, and refine. |
| discipline.custom | Something else — Describe any skill or project. |
| custom.sheet.label | Describe the skill or project you want to learn |
| outcome.heading | What would you like to be able to do? |
| outcome.chips.music | Keep a steady rhythm · Write a four-bar pattern · Understand basic notation · Practise a song effectively |
| outcome.chips.fashion | Make a simple tote · Draft a basic pattern · Learn accurate measurements · Build clean seams |
| outcome.deadline | None · 2 weeks · 1 month · 3 months · Custom date |
| outcome.constraints | Phone only · Low bandwidth · No equipment · Beginner materials · Accessibility need · Other |
| outcome.helper | Describe one thing you want to be able to do (20–200 characters). |
| motivation.heading | Why does this goal matter to you? |
| motivation.options | Finish a real project. · Support my education. · Improve my career. · Spend time productively. · Express myself creatively. · Build a lasting habit. · Just for fun. · Something else. |
| motivation.support | Project → "We'll keep each task connected to your project." · Education → "We'll connect each step to what you're studying." · Career → "We'll favour skills you can show to others." · Productive → "Short, focused steps that fit your day." · Creative → "Every unit ends with something you make." · Habit → "Small daily steps, with reviews at the right time." · Fun → "We'll keep it light and hands-on." · Something else → "We'll adapt as we learn what helps you." *(E)* |
| level.heading | How much experience do you have with this? |
| level.options | I'm completely new. · I know a few terms or basic ideas. · I can complete simple tasks with guidance. · I can work independently on familiar tasks. · I can handle varied tasks and explain my choices. |
| preview.heading | Here's what your route will help you do. |
| preview.generic | Understand the essential ideas for {outcome}. · Complete a small project or performance you can show. · Build a repeatable practice and review habit. |
| goal.heading | What's your daily learning goal? |
| goal.options | 5 min/day · Casual — 10 min/day · Regular — 15 min/day · Serious — 20 min/day · Intense |
| goal.workload | At {m} minutes a day, the first project is roughly {a}–{b} sessions. |
| route.heading | Let's find the best place to start. |
| route.basics | Start from the basics — Begin with the first foundation and still answer a few light checks. |
| route.level | Find my level — Try a short baseline so Sumi can recommend a starting point. |
| reveal.heading | Your first route is ready. |
| reveal.evidence | Based on {n} starting checks · Based on your starting choice |
| reveal.why | Why this route? |
| reveal.cta | START FIRST LESSON |
| onboarding.cta | CONTINUE |

### 11.2 Path

| Key | Text |
|---|---|
| unit.eyebrow | UNIT {n} · {done}/{total} STEPS |
| unit.guide | GUIDE |
| node.start | START +{p} POINTS |
| node.continue | CONTINUE |
| node.review | REVIEW +15 POINTS |
| node.again | PRACTISE AGAIN |
| node.checkpoint | START CHECKPOINT |
| node.locked.title | LOCKED |
| node.locked.body | Finish “{prerequisite}” to unlock this step. |
| node.locked.cta | GO TO {PREREQUISITE} |
| node.types | LESSON · PRACTICE · VIDEO · REVIEW · PROJECT · CHECKPOINT · REWARD |
| bubble | START · CONTINUE · REVIEW |
| sections.title | {Discipline title} *(semantic label: "Sections & units")* |
| sections.jump | JUMP HERE |
| guide.title | Unit {n} guide |
| guide.sections | KEY IDEAS · WATCH · REFERENCE · TRY |
| guide.try | PRACTISE THIS UNIT |
| checkpoint.rule | Answer every check correctly to earn a star. Use what you practised in this unit — the examples are new. |
| points.popover | {n} points this week · Points measure practice, not mastery. |

### 11.3 Lesson

| Key | Text |
|---|---|
| check | CHECK |
| skip | I DON'T KNOW YET |
| cant | CAN'T DO THIS NOW |
| hint | Show hint |
| correct.heading | Correct! / Nice work. |
| correct.calibration | Too easy · Too hard · Report issue |
| incorrect.heading | Not quite yet. |
| incorrect.answer | Correct answer: |
| near.heading | Almost—one part needs work. |
| retry.heading | Let's try that again. |
| continue | CONTINUE |
| tryAgain | TRY AGAIN |
| explain | EXPLAIN MY MISTAKE |
| explain.title | Explain my mistake |
| explain.answer | YOUR ANSWER |
| explain.helpful | Was this helpful? |
| explain.another | EXPLAIN IT ANOTHER WAY |
| explain.back | CONTINUE LESSON |
| settings.title | Lesson settings |
| settings.focus | Focus never blocks learning or explanations. |
| settings.refill | REFILL FOCUS |
| settings.done | DONE |
| settings.end | END SESSION |
| exit.title | Keep progress and leave? |
| exit.body | Your checked answers and current draft are saved on this device. |
| exit.stay | KEEP LEARNING |
| exit.leave | SAVE & EXIT |
| saving | SAVING… |
| saveError.heading | Not saved yet |
| saveError.retry | RETRY SAVE |
| loading | Getting your step ready… |
| practiceMode | PRACTICE MODE |
| project.fields | What did you make or try? · What happened? One observation · What will you change next time? |
| project.cta | SAVE EVIDENCE |
| project.disclosure | This records your reflection and project evidence. Sumi does not independently verify the finished work in this demo. |

### 11.4 Result

| Key | Text |
|---|---|
| title | Step complete! / Perfect step! |
| accolades | accuracy "Every check right first time." · recovery "You worked through the tricky parts." · making "An idea made visible." · reflection "A thoughtful next step." · consistency "You showed up today." · listening "Great attention to rhythm." (existing) |
| tiles | POINTS · ACCURACY · REFLECTION · TIME |
| today | {m}/{goal} min today · {n}-day streak · +1 DAY |
| next | Next: {title} |
| cta | CONTINUE |
| secondary | RETURN TO PATH · Review saved responses |
| selfReport | Reflections and practical observations are self-reported. Completing this step does not certify mastery. |
| fail.heading | Not unlocked yet |
| fail.body | You've kept every answer. Practise “{repair}” and try the checkpoint again. |

### 11.5 Settings rows (titles and state-derived subtitles)

| Section | Row | Subtitle rule |
|---|---|---|
| Profile on this device | Guest profile | "Guest · progress stays on this device" |
| Learning preferences | Daily goal | "{m} min/day" |
| | Goal and deadline | "{outcome} · {deadline or "No deadline"}" |
| | Exercise mix | "Balanced" / "More practice" / "More reading" |
| | Disciplines | "{n} active" |
| Notifications and reminders | Practice reminders | "Not set up yet — Sumi can't send notifications in this build." (toggle disabled) |
| Accessibility | Accessibility | Summary of the actual values, for example "Reduced motion on · High contrast off · Text: system" |
| Offline AI models | Offline AI models | "{active model} ready" / "No model installed" / "Downloading {x}%" (real bytes) |
| Cloud AI | Cloud AI | "Not configured" |
| Storage and privacy | Storage and privacy | "Stored on this device (not encrypted) · {size}" |
| About and licences | About Sumi | "Sumi {version} ({build})" from PackageInfo |
| | Licences | "Open-source, model and content licences" |

### 11.6 Empty and error states

| Where | Heading | Body | Action |
|---|---|---|---|
| Practice | You're caught up | New reviews appear after you practise. Next one: {date}. | PRACTISE ANYWAY |
| Library: Saved | Nothing saved yet | Tap SAVE on any resource to keep it here. | — |
| Library: offline | Connection needed for this source | Sumi keeps the details here. Try again when you're online. | TRY AGAIN |
| No model (tutor) | No offline model yet | Lessons work without one. A model adds private explanations on this device. | SET UP AN OFFLINE MODEL |
| Path complete | Route complete | You've finished every step in this route. Review keeps it fresh. | GO TO PRACTICE |
| Custom, no model | Sumi needs a plan for this goal | Download an offline model in Settings to draft a plan, or choose Music or Fashion for now. | SET UP AN OFFLINE MODEL · CHOOSE MUSIC OR FASHION FOR NOW |

### 11.7 Banned copy (QA-03)

The content lint rejects these strings:

- "Encrypted local guest storage" (unless encryption is implemented);
- "Daily practice nudges enabled";
- any "fast/slow/visual learner", "IQ" or "talent" label;
- "uploaded code", "Python" or "repository" in Music/Fashion content;
- "Duolingo" or `DUO_` in shipped strings;
- "24-hour retention" for checks made in under 24 hours;
- any cloud reply text while cloud is not configured.

---

## 12. Asset register requirements (GOV-04)

`app/assets/ASSETS.md` has one row per asset with these columns: `id`, `file`, `type` (svg / painter / wav / ttf), `author`, `licence`, `editable_source`, `runtime_export`, `logical_size`, `semantic_label`, `reduced_motion_poster`.

Required before Phase 9's DONE:

- the wordmark and the compact mark;
- three discipline tiles;
- the onboarding hero;
- three outcome icons;
- the eight node icons;
- the eight exercise-format icons;
- the five reward icons;
- the eight model icons;
- four empty-state illustrations;
- three path scenes (Music, Fashion, Custom);
- the checkpoint scene and the guide heroes;
- the eleven sounds: `tap`, `select`, `correct`, `partial`, `incorrect`, `lesson_complete`, `node_complete`, `node_unlock`, `streak`, `reward`, `model_ready`;
- the Nunito font files and `OFL.txt`.
