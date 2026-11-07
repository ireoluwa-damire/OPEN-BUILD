# Character actions and animation production brief

Research date: **27 October 2026 (Africa/Lagos)**. Intended use: private motion reference and planning for original artwork.

Start with [the playable reference catalogue](catalogue.html), [the animation contact sheet](animated-contact-sheet.jpg), and [the source/asset manifest](manifest.csv). GIFs play in the catalogue; each entry links back to its publisher. Exact files, byte sizes, frame counts, checksums, and source pages are in [manifest.json](manifest.json).

For a portable local copy, extract [the reference ZIP](download-pack.zip) and open `catalogue.html`. Downloaded third-party bytes and derived contact sheets are excluded by this folder's `.gitignore`; the source manifest and original planning documents can stay with the project.

Downloaded **71 distinct media files from 12 official articles**: **13 multiframe GIFs**, 57 static raster references, and one static SVG. Total: **52,479,025 bytes** (about 50 MiB). All 71 SHA-256 hashes were independently checked after downloading. This count includes concept art, UI captures and production studies; it is not 71 distinct character actions.

**Runtime follow-up:** [the separate guest-web asset inventory](runtime-asset-inventory.md) now adds **75 public animation exports** (59 Lottie JSON files and 16 Rive binaries), associated registries, and real lesson-state names. It includes exports associated with all ten supporting characters. These are additional static/acquisition findings, not visually verified playback or original editable projects; the editorial ZIP above remains its original 71-file snapshot.

## Scope and evidence

This is a bounded collection of **public first-party editorial references**, with primary-source documentation about additional behaviours. It is **not every Duo animation across every app version, experiment, language, season, platform, advertisement, or social account**. There is no public complete production master library verified here. A character pose, an outfit, a recolour, a rig control, and a distinct animation are different things.

The media are Duolingo's copyrighted character artwork. A downloadable public URL does not establish permission to redistribute it or ship it in Sumi. Keep these files in research; use the motion ideas to build your own character and keep its original source files. No Duolingo artwork was added to the app. No new mascot or variants were generated for this task.

**REA observation:** a temporary, headless Edge session opened the public [streak animation article](https://blog.duolingo.com/streak-milestone-design-animation/) and captured its DOM, accessibility tree, screenshot, and network metadata. Evidence `ev_8707b868793d0447a1caea4bf0e83cdffa2da37c14645006cdd440bb824e680c` has complete requested capture coverage and reports that its owned browser process was terminated. The network record includes the published `04_AnimationPasses.gif`. Bodies were not requested; the later downloads are separately hashed acquisition records. See [the evidence bundle](rea-evidence-bundle.json), [captured page](rea-streak-article.png), and [captured DOM](rea-streak-dom.html).

The existing app-flow research also observed onboarding and first-lesson feedback through REA; those records remain in [the earlier teardown](../duolingo-teardown.md). They establish that sampled guest mobile-web flow, not the complete native animation catalogue.

## Duo actions and variants

“Downloaded” below means a reference file exists locally, not that a reusable production rig was recovered. “Documented” means a first-party publication describes it. “Proposed” means an original animation we recommend making.

| Family | Reference and action | Evidence available | What to study for your character |
| --- | --- | --- | --- |
| Ordinary Duo | Basic silhouette and shared construction rules | Downloaded `ref-004`, `ref-025`; [shape-language article](https://blog.duolingo.com/shape-language-duolingos-art-style/) | Readable outline, simple masses, expressions at small sizes |
| Welcoming / instruction | Companion introduces the experience and uses text | Earlier REA welcome capture, historical [Duo writing guidance](https://design.duolingo.com/writing/duo) | A brief greeting and a clear next action; no lip-sync needed for a text-only companion |
| Correct answer | Character-specific success reactions | Downloaded Junior example `ref-007`; [Building character](https://blog.duolingo.com/building-character/) | A short reaction after feedback, with personality rather than just particles |
| Mid-lesson / completion | Duo and Lily cross the scene together | Downloaded `ref-008` | Setup, movement, payoff, and return to the next task |
| Streak, older variant | Duo holds milestone-number balloons | Downloaded still `ref-012`; [streak design](https://blog.duolingo.com/streak-milestone-design-animation/) | Number overlays can be separate from the character rig |
| Streak, phoenix variant | Transformation into a flaming bird | Downloaded process animation `ref-013`, concepts `ref-010–011`, share-card `ref-014` | Anticipation, escalating energy, readable final pose; use a project milestone rather than a fake two-day “mastery” reward |
| Junior skate / playful movement | Junior's stylised skating sequence | Downloaded multiframe `ref-040`; identity visually checked on sampled frames | A personality flourish can reuse the same base design |
| Art-style exploration | Picasso-like Duo and alternate shape treatments | Downloaded still `ref-039`, shape studies `ref-026–036` | Maintain recognisability across deliberate style experiments |
| Super Duo | Iridescent premium identity, glow and strength motif | Downloaded stills `ref-047–049`; [Super launch](https://blog.duolingo.com/super-duolingo-launch/) | A skin/theme is not a new rig; keep effects and colours separable |
| Max Duo | Dark, reflective premium identity | Downloaded `ref-052`; [Max overview](https://blog.duolingo.com/duolingo-max/) | Theme variation through materials/colour; not essential for the demo |
| Path / lesson UI | Skill-icon changes and path progression | Downloaded multiframe `ref-037–038`, path stills `ref-041–046` | Keep non-character progress effects separate from the mascot |
| App-icon and social campaigns | Seasonal, promotional, “sick,” melting, and other campaign looks | Not exhaustively collected or authenticated here | These need their own campaign/archive investigation; do not treat app-icon images as in-app animation states |

The historical writing page is not a current animation specification: the later phoenix and skating work shows why older “Duo stays still” guidance cannot describe every subsequent production. Record a reference's date and context.

## Supporting cast and distinct performance

The cast should be studied as actors with different performances, rather than recoloured copies. “No individual clip” means this collection did not establish one; it does not mean Duolingo lacks that animation.

| Character | Verified reference coverage | Relevant acting/variant studies |
| --- | --- | --- |
| Junior | Downloaded correct-answer GIF `ref-007`, skating GIF `ref-040`, shared-shape study `ref-004`; [Building character](https://blog.duolingo.com/building-character/) | Compact success, energetic movement and visual family resemblance |
| Lily | Downloaded Duo/Lily interstitial `ref-008`, cast stills `ref-023–024`; [Rive case study](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life) | Restrained expressions, listening, pondering, confusion, approval, greeting and sign-off |
| Zari | Downloaded model turntables `ref-017`, `ref-019`, rig demo `ref-020`, production-process GIF `ref-022`, expression board `ref-018` | 2D-to-3D consistency, facial controls, acting reference, animation blocking and polish |
| Bea | Downloaded female-cast stills `ref-023–024`, Duo/Bea pose `ref-062`; [character origin article](https://blog.duolingo.com/duolingo-female-character-origin-stories/) | Distinct posture and motivation; no individual moving lesson reaction verified here |
| Lin | Downloaded cast stills, solo pose `ref-061`, Adventures GIF `ref-057`; [Adventures](https://blog.duolingo.com/adventures/) | Environmental interaction and a less energetic performance |
| Lucy | Downloaded female-cast stills; [origin article](https://blog.duolingo.com/duolingo-female-character-origin-stories/) | Readable age/posture differences; no individual moving reaction verified here |
| Eddy | Downloaded group pose `ref-059`, Adventures UI `ref-056`; [Apple's design interview](https://developer.apple.com/news/?id=jhkvppla) | Physical enthusiasm and environmental character interaction; no exact moving-reaction inventory established |
| Oscar | Downloaded wine pose `ref-063`, chess poses `ref-067–071`; [official chess review](https://blog.duolingo.com/chess-game-review/) | Approval and explanation poses in coaching; complete chess-animation set remains unknown |
| Vikram | Portrait included in downloaded Zari-production cover `ref-015`; broader world-cast artwork | No verified standalone animated clip recovered in this collection; do not invent a pose-by-pose inventory |
| Falstaff | Downloaded call stills `ref-050–051`; [official guided-call description](https://blog.duolingo.com/beginner-video-call-with-falstaff/) | A supportive coaching persona; public screenshots do not expose a production talking rig |

**Useful production lesson from Lily:** Rive reports eight head and eight body animation components producing 64-plus neutral combinations, with facial, mouth and camera states. It also describes modular transitions for greeting, listening, waiting, confusion, approval and ending a call, and reports a final file below one megabyte. This is a published case study, not an independent performance measurement or an inventory of downloadable Lily source files. [Rive case study](https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life).

## Original mascot: two-day demo production list

The character is **your choice**. Keep the existing Sumi drawing as a placeholder until you choose an original design; this brief does not make the mascot decision for you. These state IDs can drive any character. Start with one rig, modular face/body/prop layers, and a static fallback for every state.

The durations below are suggested production targets, not Duolingo timings.

| Priority | Asset/state ID | Trigger in this app | Suggested performance | Reduced-motion fallback |
| --- | --- | --- | --- | --- |
| P0 | `idle` | Home, route and instruction screens | Small blink/breath loop, 2–4 seconds, quiet enough for reading | Neutral attentive pose |
| P0 | `greet` | First open or return | A single wave/nod, under 1 second | Friendly open pose |
| P0 | `point` | Goal choice, next action, model-download entry | Brief directional gesture; do not cover text | Directional pose beside the control |
| P0 | `think` | Model loading or generating on the phone | A gentle gaze change; no fake progress indication | Thinking pose plus real text status |
| P0 | `correct` | First independently correct response | One nod or small celebratory gesture, about 0.5–0.9 seconds | Pleased expression |
| P0 | `retry` | Incorrect response | Curious/supportive gesture, not anger or shaming | Encouraging expression |
| P0 | `hint` | Learner asks for help | An explanatory gesture with a separate hint panel | Helpful pointing pose |
| P0 | `complete` | A real practice/project step is recorded | A short celebration, about 1–1.5 seconds; next action stays available | Completed pose and a text confirmation |
| P0 | `local_ready` | Model download verifies and local inference is ready | Small affirmative response; pair with the actual readiness result | Ready badge and neutral pose |
| P0 | `recover` | Download interruption, inference failure, low memory | Reassuring gesture; retry/cancel controls remain immediate | Calm pose and actionable status text |
| P1 | `listen` | Future spoken/music input | Attentive loop separated from `think` | Attentive pose |
| P1 | `compare` | Day-2 check compared with Day-1 evidence | Look between two result cards; do not imply proven mastery | A neutral comparison pose |
| P1 | `music_count` | Music practice cue | Beat-related gesture driven by an actual timing source, not a decorative free-running loop | Visible beat count; audio/accessibility handled separately |
| P1 | `design_make` | Fashion design/tailoring task | Sketch/fabric/tool prop using a separate layer; same base character | Making pose with a simple prop |
| P2 | `milestone_big` | Later meaningful project completion | A larger optional sequence; skippable | Single achievement pose |
| P2 | Skins, seasonal looks, supporting cast, turnarounds | After the demo's core interaction works | Reuse the rig and selectively add original performers | Matching static artwork |

Make the **P0 states first**. Music and Fashion Design & Tailoring can share the same companion, with a metronome/notebook/fabric prop layer when appropriate. Do not produce a full secondary cast, premium skins, or seven-day streak movie for the two-day demo.

## Authoring tool and app handoff

| Option | Best use | Deliverable for Flutter | Limits to plan for |
| --- | --- | --- | --- |
| **After Effects + Lottie exporter** | Short, preplanned feedback reactions using vector shape layers | Original `.aep`, an exported Lottie `.json` or compatible `.lottie`, and a PNG poster pose | Exporter/player feature support differs; test masks, effects, expressions and text on Android before animating the whole set. An AE project does not run directly in Flutter. [LottieFiles exporter](https://help.lottiefiles.com/hc/en-us/articles/4439877810841-Getting-Started), [supported features](https://lottiefiles.com/supported-features) |
| **Adobe Animate** | Frame-by-frame character work, symbol rigs, drawn poses | Original `.fla`; PNG sequence/sprite atlas or a carefully selected video/GIF delivery route | HTML5 Canvas export is browser output; it is not automatically a native Flutter rig. Prefer a tested raster export for an early demo. Adobe currently keeps Animate available in maintenance mode with fixes but no planned new features. [Adobe status](https://helpx.adobe.com/sg/animate/desktop/kb/maintenance-mode.html), [exports](https://helpx.adobe.com/it/animate/desktop/exporting-and-publishing/exporting.html) |
| **Rive** | Interactive mascot with reusable face/body layers and smooth state changes | Original editable Rive project plus exported `.riv` and a state/input map | Validate the chosen Flutter runtime's supported features and renderer on the actual phone. A production `.riv` is not the same as a project source file. [Flutter runtime](https://rive.app/docs/runtimes/flutter/flutter) |
| **Transparent PNG sequence** | Reliable fallback when a rig/exporter is not ready | Numbered PNGs, frame timing metadata, and a poster image | More raster memory/storage than a small vector rig; size it for the intended phone display. [Adobe image sequences](https://helpx.adobe.com/after-effects/desktop/render-and-export/render-and-export-images/rendering-exporting-still-images-still.html) |

**Recommendation:** if you already know After Effects, make the first short reactions there and export/test one of them before committing the remaining set. If you want the companion to blend expressions and respond to model state throughout the product, choose Rive as the delivery rig. Adobe Animate remains an option for drawn animation; its current maintenance status is relevant before paying specifically to learn it for this project.

Suggested handoff convention:

- One consistent transparent artboard (for example 512 × 512 logical design units), shared ground line and neutral pose; test the real display size rather than shipping oversized frames.
- Name layers semantically: `body`, `head`, `eyes`, `lids`, `brows`, `mouth`, `appendages`, `prop`, `shadow`. Keep optional scene effects separate.
- Specify which states loop, which return to idle, and which can be interrupted. Export the same character position in every state.
- For each export, include state ID, source filename, runtime filename, duration/frame rate, loop rule, entry/exit rule, poster pose, and licence/author.
- Use application events to drive animation. `downloadComplete` fires only after file verification; `modelReady` only after the engine loads; `answerCorrect` only after grading. Model-generated text must not fire a mastery or completion event.
- Keep controls responsive while animation plays. Respect reduced motion, pause loops when the app is backgrounded, and do not make sound the only feedback.

## Two-day usability checks for motion

Day 1: Can a new learner tell where to begin, what the companion is signalling, and whether a model is downloading or actually generating? Can they skip animation, ask for help, and recover from a cancelled download? Does the same screen make sense with motion disabled?

Day 2: Can they return to saved work, complete an independent recheck, understand the change from their Day-1 evidence, and distinguish a supported answer from an independent one? Test a Music task and a Fashion Design & Tailoring task. Check repeated loops, battery/heat, visual distraction, slow-phone frame drops, and whether celebrations feel proportional to the work.

This is a **48-hour product/usability demonstration**, not evidence of a learner's long-term mastery or a validated learning-speed model.

## Remaining gaps

- Complete current native/mobile animation inventories, seasonal A/B variants, and every supporting-character clip are not established.
- Original Duolingo authoring projects and unpublished source rigs were not obtained. Downloadable serialized runtime exports are documented in the separate follow-up; public editorial GIFs are presentation references.
- A lesson's wrong-answer response is a proposed original state here, not a claimed observation of every Duolingo character's failure animation.
- The reference collection mixes publication periods; historical UI and artwork do not prove current rollout.
- The files were validated as downloadable media with hashes and, for GIFs, multiframe metadata. The contact sheet samples frames; it is not a frame-by-frame audit of every animation.
