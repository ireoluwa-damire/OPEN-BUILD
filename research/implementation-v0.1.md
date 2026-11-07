# Sumi

A little closer, every day. An Android and iOS mobile application.

Sumi is a Flutter learning companion that turns a project goal into small, useful steps. The first track helps learners build a Python expense summarizer. A short baseline produces a provisional route immediately; practice connects each capability to a real project task.

## What works in this prototype

- Goal and daily commitment intake.
- Six-question baseline with hints, skipped answers, explanations, and resumable progress.
- Adaptive task effort based on first-attempt, unhinted baseline answers.
- A prerequisite-ordered route, short lessons, parallel practice questions, and project tasks.
- A reviewed resource library with working publisher links.
- Local progress storage and a reset action.
- Optional real Qwen personalization through a local Ollama service.
- A separately labelled synthetic seven-day replay that leaves personal progress untouched.
- A mobile-first Flutter interface with bottom navigation, an original vector Sumi mascot, and reduced-motion support. The browser target is a phone-sized development preview.

The seven-day schedule is a product guide. This version implements the baseline and project-practice loop; a full daily recall scheduler and longitudinal learning validation are future work. Completion records self-reported project work and practice responses, not certified mastery.

## Stack

- Flutter / Dart: Android, iOS, and web client in app/.
- Python / FastAPI: stateless scoring and planning API in backend/.
- Ollama: local open-weight inference; defaults to qwen3:8b, already available on the development machine.
- Shared preferences: prototype progress stored on the device, without an account or sync.

The app's reviewed route works without the API. The explicit “Personalize with local AI” action calls the backend. A successful model result is labelled with its actual model name. Model failure leaves the reviewed route available and shows an explanation.

## Run locally

Prerequisites: Flutter stable with Dart >=3.8, Python >=3.10, and optionally Ollama with qwen3:8b.

The development workspace has a Flutter SDK in .tooling/flutter and a Python environment in .venv. These are ignored build tools, not part of the app source.

### API

From the project root:

~~~powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements-lock.txt
.\scripts\run-api.ps1
~~~

The API runs at http://127.0.0.1:8765. Interactive API documentation is at /docs.

If Python's bundled ensurepip fails in a managed runtime, use an existing pip to install into the environment:

~~~powershell
python -m pip --python .venv install -r backend\requirements-lock.txt
~~~

### Mobile app

~~~powershell
cd app
flutter pub get
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8765
~~~

Or from the root, use the workspace SDK helper:

~~~powershell
.\scripts\run-app.ps1
~~~

Start an Android emulator first. Replace emulator-5554 with the ID from flutter devices. The helper defaults to that Android emulator. The installable application uses Flutter's Android runtime.

For an Android emulator:

~~~powershell
.\scripts\run-app.ps1 -Device emulator-5554 -ApiUrl http://10.0.2.2:8765
~~~

Use flutter devices for the actual device ID. Physical phones need the API at a reachable LAN or HTTPS address; use API_BASE_URL to point the app at it. iOS builds require macOS and Xcode.

Build an Android package:

~~~powershell
.\scripts\flutter.ps1 build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8765
~~~

The debug APK is written to app/build/app/outputs/flutter-apk/app-debug.apk. This prototype pins Android NDK 29.0.14206865 and CMake 3.31.6 for native plugins. The default API address above reaches the computer from an Android emulator. On a physical phone, open Learning options > Connect local AI and enter the computer's reachable API address. The route and practice work without a connection.

### Optional phone preview in a browser

~~~powershell
.\scripts\run-app.ps1 -Device web-server
~~~

Open http://127.0.0.1:5173. This development preview is constrained to a phone interface, including when opened on a laptop.

## Model configuration

~~~powershell
ollama pull qwen3:8b
$env:SUMI_MODEL = 'qwen3:8b'
$env:SUMI_OLLAMA_URL = 'http://127.0.0.1:11434'
.\scripts\run-api.ps1
~~~

The API sends only the entered goal, daily time, supported track, and baseline readiness flags to local Ollama. It requests structured JSON, validates milestone IDs and text, and keeps scoring, timing, and prerequisites outside the model.

Optional environment variables:

| Variable | Default |
| --- | --- |
| SUMI_MODEL | qwen3:8b |
| SUMI_OLLAMA_URL | http://127.0.0.1:11434 |
| SUMI_CORS_ORIGINS | Local development origins on ports 5173 and 8080 |

The current hybrid is an open-weight language model plus transparent learner-state and scheduling rules. A second embedding model is not yet included: the small reviewed catalogue is matched by capability.

## Verify

~~~powershell
.\.venv\Scripts\python.exe -m unittest backend.test_planner -v
cd app
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8765
~~~

See VALIDATION.md for checks actually completed in this workspace. A check listed above is a reproducible command, not itself a claim that it has passed.

## Project map

~~~text
app/lib/
  main.dart        responsive learning space, route, library, replay
  assessment.dart  resumable baseline and feedback
  practice.dart    original mini lessons, practice, project tasks
  models.dart      learner evidence and local route calculations
  services.dart    local storage and API client
  mascot.dart      original vector Sumi, with reduced-motion behavior
backend/
  catalog.py       original reviewed content
  planner.py       deterministic grading, prerequisites, effort ranges
  model_service.py bounded, validated Ollama personalization
  main.py          API contracts
research/          source research and design explorations
~~~

Regenerate the client catalogue after editing backend/catalog.py:

~~~powershell
.\.venv\Scripts\python.exe scripts\sync_catalog.py
~~~

## Current boundaries

The prototype has one reviewed project track. It does not yet create validated courses for arbitrary disciplines, inspect submitted code, provide cloud accounts, or prove learning effectiveness. Daily time and completion estimates are prototype heuristics. Baseline answer keys are bundled in the client for offline practice; this is a low-stakes learning tool.

The local API is for development and has no authentication or server-side learner persistence. Configure authentication, restricted deployment origins, and durable storage before a public multiuser release.

## Attribution and openness

Original application source is MIT licensed; see LICENSE. The app uses original question text, lesson text, and vector artwork. Duolingo's public UX and research informed the design; no branded Duolingo assets or lesson content are used.

Qwen3 weights have their own Apache-2.0 terms; model weights are not included in this repository. Read the exact deployed model's licence. Flutter and each package retain their own licences. The historical HLR reference under research/reusable retains its supplied MIT notice and is not integrated into the current app.

The research, visual concepts, and implementation were substantially assisted by AI. Both teammates should review, understand, and test submitted work. Add names, contributions, measured evaluation results, and a working demonstration link before hackathon submission.
