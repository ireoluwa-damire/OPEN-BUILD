# Asset register (GOV-04)

Every asset that ships in the app has one row. Only original or openly licensed assets are allowed (DC §12). No Duolingo or other third-party artwork, animation or audio is included; the research material listed in `research/THIRD_PARTY_EXCLUDED.md` is git-ignored and never bundled.

| id | file | type | author | licence | editable_source | runtime_export | logical_size | semantic_label | reduced_motion_poster |
|---|---|---|---|---|---|---|---|---|---|
| font-nunito-500 | `fonts/Nunito-Medium.ttf` | ttf | Vernon Adams et al. (Nunito project) | SIL OFL 1.1 (`fonts/OFL.txt`) | upstream | as shipped | — | — | — |
| font-nunito-600 | `fonts/Nunito-SemiBold.ttf` | ttf | Nunito project | SIL OFL 1.1 | upstream | as shipped | — | — | — |
| font-nunito-700 | `fonts/Nunito-Bold.ttf` | ttf | Nunito project | SIL OFL 1.1 | upstream | as shipped | — | — | — |
| font-nunito-800 | `fonts/Nunito-ExtraBold.ttf` | ttf | Nunito project | SIL OFL 1.1 | upstream | as shipped | — | — | — |
| font-nunito-900 | `fonts/Nunito-Black.ttf` | ttf | Nunito project | SIL OFL 1.1 | upstream | as shipped | — | — | — |
| sound-tap | `sounds/tap.wav` | wav | Sumi (synthesised) | Project licence (LICENSE) | `scripts/make_sounds.py` | 44.1 kHz mono | < 1.5 s | — | silent when sound is off |
| sound-correct | `sounds/correct.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | < 1.5 s | — | silent when sound is off |
| sound-incorrect | `sounds/incorrect.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | < 1.5 s | — | silent when sound is off |
| sound-lesson-complete | `sounds/lesson_complete.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 1.6 s | — | silent when sound is off |
| sound-node-complete | `sounds/node_complete.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | < 1.5 s | — | silent when sound is off |
| sound-node-unlock | `sounds/node_unlock.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | < 1.5 s | — | silent when sound is off |
| sound-select | `sounds/select.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 0.07 s | — | silent when sound is off |
| sound-partial | `sounds/partial.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 0.45 s | — | silent when sound is off |
| sound-streak | `sounds/streak.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 0.9 s | — | silent when sound is off |
| sound-reward | `sounds/reward.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 0.8 s | — | silent when sound is off |
| sound-model-ready | `sounds/model_ready.wav` | wav | Sumi (synthesised) | Project licence | `scripts/make_sounds.py` | 44.1 kHz mono | 0.8 s | — | silent when sound is off |
| data-disciplines | `disciplines.json` | json | Sumi; lesson text AI-assisted, not expert-reviewed | Project licence; linked resources keep their publishers' licences | `scripts/build_disciplines.py`, `scripts/author_content.py` | as shipped | — | — | — |
| data-model-catalog | `model_catalog.json` | json | Sumi | Project licence; each model keeps its own licence | `scripts/resolve_phone_models.py` | as shipped | — | — | — |
| data-legacy-catalog | `catalog.json` | json | Sumi (v0.1) | Project licence | `scripts/sync_catalog.py` | not bundled (not in pubspec) | — | — | — |
| painter-mascot | `lib/mascot/sumi_rig.dart` | painter | Sumi (original code-drawn chameleon, owner-approved CF-01) | Project licence | Dart source; browser twin `research/mascot/sumi-rig.js` | runtime painter | 52 / 120 / 160 / 200 px | none (text carries meaning) | poster pose |
| painter-celebration | `lib/motion/celebration.dart` | painter | Sumi | Project licence | Dart source | runtime painter | full screen | none | not drawn |
| painter-wordmark | `lib/graphics/sumi_graphics.dart` (`SumiWordmark`) | painter | Sumi | Project licence | Dart source | runtime painter | 144 × 48; compact mark 48 | "Sumi" | static |
| painter-route-hero | `lib/graphics/sumi_graphics.dart` (`RouteHero`) | painter | Sumi | Project licence | Dart source | runtime painter | 340 × 232 | none (promise text carries meaning) | static |
| painter-discipline-scenes | `lib/graphics/sumi_graphics.dart` (`DisciplineScene`: music, fashion, custom) | painter | Sumi | Project licence | Dart source | runtime painter | 120 path · 72 card · 44 badge | none | static |
| painter-glyphs | `lib/graphics/sumi_graphics.dart` (`SumiGlyph`: 9 node, 5 reward, 8 exercise-format, 2 model glyphs) | painter | Sumi | Project licence | Dart source | runtime painter | 24 px grid | none unless a label is passed | static |
| painter-empty-states | `lib/graphics/sumi_graphics.dart` (`SumiEmptyIllustration`: caught up, nothing saved, no model, route complete) | painter | Sumi | Project licence | Dart source | runtime painter | 120 | none (heading carries meaning) | static |

## Still required before Phase 9 is done (DC §12)

Checkpoint scene (200) and guide heroes (160). The route-complete empty state is drawn but not yet placed (no route-complete screen exists). Interface chrome (back, close, chevrons, settings) still uses Material Symbols Rounded, which DC §5 allows as interim; the required families above are original.
