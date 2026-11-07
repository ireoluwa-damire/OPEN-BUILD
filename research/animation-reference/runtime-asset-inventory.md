# Public guest-web animation registry follow-up

27 October 2026, Africa/Lagos. This supplements the editorial reference collection; it does not replace its 71 files or alter the app.

## Result

A bounded pass over **three public guest-web JavaScript bundles** found an actual character/animation registry. The main bundle contains literal references to **75 animation-export URLs**, all of which were publicly downloadable from the same Duolingo CDN prefix:

| Export group in the acquired source | Files acquired | What was verified |
| --- | ---: | --- |
| `lottie/pathCharacters` | 42 | JSON with Lottie version, frame rate, time bounds and layer data; symbolic character/action mapping |
| `lottie/splash` | 12 | Same Lottie structural fields; directory name retained as a source label |
| `lottie/funboarding` | 4 | Same Lottie structural fields; exact screen/trigger not established |
| Other `lottie` | 1 | Same Lottie structural fields; exact screen/trigger not established |
| `rive/makerInLesson` | 10 | RIVE magic header; source registry associates one file with each world character |
| `rive/pathCharacters/math` | 6 | RIVE magic header and symbolic Math-path mapping |
| **Total** | **75** | **15,150,080 decoded bytes**, all SHA-256 hashes independently rechecked |

Start with [the asset index](runtime/asset-index.html), [asset manifest](runtime/asset-manifest.json), [registry and source locations](runtime/registry.json), and [source acquisition manifest](runtime/source-manifest.json). The index links to local exported files and their original public URLs. For a portable copy, extract [the separate runtime reference ZIP](runtime/runtime-reference-pack.zip) and open `runtime/asset-index.html`. A `.riv` runtime export is not an Adobe project or a verified editable source rig.

These downloads broaden the reference material substantially, but **do not establish every Duolingo animation, current native-app coverage, or what every animation looks like when played**. No downloaded JavaScript or animation was executed in this follow-up.

## Source and REA evidence

The earlier guest-web REA capture recorded the exact CDN bundle URLs. The retained first-lesson/onboarding observations are copied unchanged into the [prior guest-web evidence bundle](runtime/prior-guest-web-evidence.json). Acquisition fetched only these first-party files:

- `manifest-9f2aff54.js` — 14,364 decoded bytes.
- `features-91ec4487.js` — 3,151 decoded bytes.
- `app-c4519c5a.js` — 1,126,464 decoded bytes; SHA-256 `fd5c79437c965970c907a80c826eea49db9afcfe915a29ec87642d49de787456`.

The bootstrap manifest explicitly supplies the public prefix `https://d35aaqx5ub95lt.cloudfront.net/`. The application literals and that prefix determine the fetched asset URLs; filenames were not guessed. HTTP gzip responses were decoded before UTF-8 analysis. Encoded and decoded source hashes are recorded separately where applicable.

REA parent analysis: **`ev_42738d9b9f217bb573b6b0083402a51c40df59b0c22279291482dd988b84814d`**.

Summary receipt: `ev_8b294f4f100cb2f9cbb993bbcafb3cf5a216a65ebfac7538b504310d4b430496`. Module-reference projection: `ev_485e52577f215c56b8435a91f982b15fd7202a677467eadca77770c33ef39912`. [Retained evidence export](runtime/rea-evidence-bundle.json).

REA parsed **3/3 selected JavaScript files**, with **zero parse failures**, examining 1,143,979 source bytes and 296,241 AST nodes. Its application/semantic coverage is **partial**, and semantic retention is **truncated** at the explicitly selected limits: 512 MiB worker heap, 120-second per-source deadline, 6,000 total / 5,000 per-file semantic nodes and unknowns. It retained 5,464 semantic unknown records. Those limits mean the analysis cannot prove global absence, complete data flow or reachability. There was no need to repeat or enlarge the analysis to answer this bounded registry question.

The registry extraction is an additional source-text inspection with explicit character offsets and file hashes. It conservatively resolves literal object properties and exact in-scope constants. It does not use `eval`, execute the bundle bootstrap, recover private endpoints, or dispatch UI actions.

## World-character lesson rig configuration

The acquired literal registry associates a separate Rive URL with **Bea, Eddy, Falstaff, Junior, Lily, Lin, Lucy, Oscar, Vikram and Zari**. The exact character-to-file mapping, scale and offsets are in `runtime/registry.json`; all ten referenced files downloaded successfully.

The shared literal configuration is:

| Field | Source value | What this establishes |
| --- | --- | --- |
| Artboard | `character` | Name supplied by the shipped web configuration |
| State machine | `character_statemachine` | Configured state-machine identifier |
| Correct response | `correct_trig` | Configured success trigger name |
| Incorrect response | `incorrect_trig` | Configured retry/failure trigger name |
| Reset / unanswered | `reset_trig` | Configured reset trigger name |
| Dark appearance | `darkmode_bool` | Configured appearance boolean |
| Right-to-left layout | `rtl_bool` | Configured layout boolean |

These are **control names observed in code**, not a visual audit of each character's response. Binary header/string inspection corroborates that the acquired files are Rive candidates; a full Rive parser/runtime was not used to enumerate their internal artboards, timelines, transitions, constraints, events or external resources. Trigger type is suggested by the source field and suffix; runtime behaviour was not exercised.

## Path-character actions with direct exported-file associations

The registry maps 42 general path animations and six Math-path animations. The exact downloadable asset for every entry below is linked from the asset index and recorded with source ranges in the registry.

| Character | General path symbolic actions observed |
| --- | --- |
| **Duo** | `BALL`, `BOOKS`, `BUTTERFLY`, `CHEER`, `GEM`, `GLOBE`, `HEADPHONES`, `JUMPFLAP`, `POTION`, `SUNGLASSES`, `TWIRL`, `WHISTLING` |
| Bea | `SMORES`, `TENNIS` |
| Eddy | `BASKETBALL`, `JUMPROPE` |
| Falstaff | `EATING`, `FISHING`, `SNEEZING`, `SNOOZE` |
| Junior | `FROG`, `ICECREAM`, `POGO`, `SLEEP` |
| Lily | `DOOMSCROLL`, `RAINCLOUD`, `SHIRTS` |
| Lin | `BIKE`, `BIKEKISS` |
| Lucy | `CAT`, `WALKIETALKIE` |
| Oscar | `BONSAI`, `COMB`, `FLOWER`, `PAINTING` |
| Vikram | `GRILL`, `NOODLES`, `PANCAKES`, `PANSIES` |
| Zari | `GAMING`, `KICK`, `LOLLIPOP` |

Additional Math-path exports are **Duo `CLOCK` / `RULER`, Junior `CALCULATOR` / `GRID`, and Zari `HORSE` / `PROTRACTOR`**. These are exported symbolic labels; their names suggest intent without replacing a playback review.

One mapping, `DUO_BOOKS`, uses an exact bundled-module reference rather than an inline URL. The same acquired bundle contains that module's literal asset export, allowing the bounded pass to resolve it to `lottie/pathCharacters/dc7f54a73e6340a16176a91bf0d18b83.json`. Both source ranges are preserved. No dynamic module code was invoked.

The bundle contains **60 character/action symbols overall**, including 21 beginning with `DUO_`. Do **not** equate these with 60 playable clips: this broader set includes static-image chess entries and other references. For example, chess keys include Duo `BLACKBOARD`, `FLIPPING`, `LIFTING`, `PONDERING`, `SHOCKED` and Oscar `BLACKBOARD`, `COACHING`, `DEAD`, `PONDERING`, `QUEEN`, but this acquired chess registry provides image variants rather than a direct animation field. Dark/locked/guidebook image variants are not extra animation counts. This pass did not download that larger static-image library.

## How this changes the original production brief

The editorial-only table correctly recorded that it had no individual moving clip for several characters. This follow-up now supplies **downloaded runtime exports associated with all ten supporting characters**, including their shared correct/incorrect/reset control contract. It does not supply their original editable animation projects or establish the visual content of every internal state.

For your own original companion, the useful pattern is a small state machine: neutral/reset, success, retry, and appearance/layout variants, with optional separate path activities. Music and Fashion Design & Tailoring can use original beat, sketch, measuring and making props. There is no need to duplicate the full Duolingo cast or its 42 path activities for the two-day demonstration.

## Access, licensing and remaining boundary

All acquired URLs came from public first-party guest-web files. No login, private account, mobile package extraction, access-control bypass, guessed private path or authenticated request was used. The previous REA capture's observed third-party analytics URLs were not fetched for this follow-up.

The downloaded exports remain Duolingo/respective-owner material; public downloadability does not establish permission to ship or redistribute them. Keep them as private reference. The new source and export bytes, evidence bundle and ZIP are excluded from Git by this folder's `.gitignore`; nothing entered `app/assets` or application source.

Not established: every lazy chunk or embedded JSON module, every current web build, every native asset, seasonal/A-B variants, current live challenge coverage, visually verified playback, original authoring timelines, or complete Rive internals. Some symbolic actions may differ from their filenames or from later app releases. The 59 Lottie JSONs passed a structural check and report no non-embedded image-file references in their `assets` arrays; this is not a general guarantee about fonts, expressions, renderer support or all possible dependencies.
