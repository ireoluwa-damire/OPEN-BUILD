# Third-party material excluded from the repository

Requirement: GOV-01 (owner decision E-01 default: exclude everything listed).

The following stay on the owner's machine as private research and are **not**
committed or redistributed. They are ignored in the root `.gitignore`, and
`scripts/check_repo_hygiene.ps1` / `scripts/check_repo_hygiene.sh` fail if any
of them becomes tracked.

| Path | What it is | Why it is excluded |
|---|---|---|
| `research/rea-duolingo-android-*/*.apk` | Third-party Android packages used for reverse-engineering notes | Copyrighted binaries; redistribution is not permitted |
| `research/rea-duolingo-android-*/rea-apk-inventory-evidence.json` | Inventory extracted from those packages | Derived from third-party binaries |
| `tools/jadx-headless-mcp*` | Decompiler tooling | Not part of Sumi; used only for private research |
| `research/captures/`, `research/live-reference-*/frames/`, `research/live-reference-*/*.png`, `research/session-reconstruction-*/*.png` | Screenshots and recording frames of a third-party app | Third-party trade dress and artwork |
| `research/animation-reference/{media,runtime,download-pack.zip,animated-contact-sheet.jpg}` | Public animation exports (Lottie/Rive/GIF) collected for reference | Third-party artwork |
| `research/duolingo-landing-*`, `research/rea-evidence-bundle.json` | Captured third-party web pages and evidence bundles | Third-party content |
| `research/brief-*.png`, `research/mascots/*.png`, `Mascot concepts` | Reference images and concept sheets | Unclear licence; not shipped |
| `OPEN-BUILD-reference-pack.zip`, `OPEN--BUILD-2026-Challenge-Brief.pdf` | Challenge organiser material | Organiser's documents; not ours to republish |
| `*.apk`, `*.aab`, `preview/`, `dist/*.apk` | Build outputs and recordings | Generated; large; may embed third-party frames |

The written specifications in `research/` (Markdown) describe observed
interaction grammar in our own words and are kept. No third-party asset is
referenced from `app/`.
