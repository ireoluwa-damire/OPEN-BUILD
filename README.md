# Sumi — two-day mobile demo

A Flutter learning companion for **Music** and **Fashion Design & Tailoring**, selected by the project owner. The learner chooses a discipline and enters their own goal. Each discipline keeps separate progress.

## What is implemented

- Six original baseline questions per subject, with hints, skips, explanations, and resumable answers.
- Six original practice lessons and project tasks per subject. Physical work is self-reported.
- Day 2 uses six different questions. Baseline records remain unchanged; completed follow-up evidence can update practice effort.
- Early check-ins are labelled. Two days tests features and usability, not mastery or a validated learning-speed estimate.
- Local usability feedback: navigation, question clarity, optional coach usefulness, and notes.
- Model manager: download/resume, progress, publisher SHA-256 verification, selection, removal, and GGUF import.
- Native llama.cpp inference through pinned llamadart 0.16.5. The inference path accepts a local file only and has no server fallback. The model unloads after each reply to release memory.
- The current Sumi drawing remains a placeholder. No new mascot was selected or generated for this refinement.

Music exercises currently assess text/visual fundamentals of Western rhythm and notation; they do not listen to or grade audio. Fashion exercises cover a starter brief, material selection, measurement, patterns, samples, and quality review; the app does not inspect a sewn garment.

## Phone models

| Option | Download | Source |
| --- | --- | --- |
| Qwen3 0.6B Q8_0 | 639 MB | Official Qwen Hugging Face repository; first phone test target |
| Qwen3 1.7B Q8_0 | 1.83 GB | Official Qwen repository; larger optional model |
| DeepSeek R1 Distill Qwen 1.5B Q4_K_M | 1.12 GB | Community conversion by bartowski; distinct from DeepSeek V4.1 |

Sizes are decimal. RAM guidance in the app is an estimate, not a guarantee. The current context is 2,048 tokens with CPU inference; speed and memory use depend on the phone and other apps.

DeepSeek V4.1 is not a practical target on the connected 8 GB phone. The smaller distilled option is explicitly named separately. Ollama is not required on Android. Hugging Face supplies weight files; the inference path does not send it learner prompts.

Exact source revisions, sizes, and published hashes are in app/assets/model_catalog.json. Import supports compatible single-file GGUF files up to 4 GB in this demo. Unsupported architectures may fail to load. A local hash for an imported model does not verify its publisher.

Models live in the app's private support directory; learning profiles use local shared preferences. The old v0.1 Python profile is preserved and is not silently mixed into the new disciplines. Android automatic backup is disabled. Uninstalling or clearing app storage removes local progress and models.

## Android build

Use Flutter stable with Dart >=3.10.7. This workspace has Flutter 3.47.8 / Dart 3.13.7 under .tooling/flutter; the helper uses it when available. Native plugins use Android NDK 29.0.14206865 and CMake 3.31.6. This build targets 64-bit Android.

~~~powershell
.\scripts\flutter.ps1 pub get
.\scripts\flutter.ps1 devices
.\scripts\run-app.ps1 -Device <device-id>
.\scripts\flutter.ps1 build apk --debug --target-platform android-arm64,android-x64
~~~

APK output: app/build/app/outputs/flutter-apk/app-debug.apk. This is a debug-signed prototype. No API process is needed. The Python backend remains as historical v0.1 source and is not called by the refined app.

iOS on-device packaging requires macOS, Xcode, and the matching Apple runtime companion. It has not been validated here. The optional browser target remains a phone-sized UI preview; it does not claim to run the phone inference engine.

## Verification

~~~powershell
.\scripts\flutter.ps1 analyze
.\scripts\test-ui.ps1
.\scripts\test-phone.ps1 -Device <phone-id>
~~~

The UI-only adapter uses the workspace Flutter test runner without a desktop native-asset builder. It does not test inference. Standard flutter test also works once the package's desktop runtime has been downloaded.

The phone helper builds a separate test APK, installs it with adb install --no-streaming -r, and attaches the integration driver to the running app. It stops on an installation rejection and never uninstalls or clears storage. Approve Android's install prompts while it runs. After the suite it restores the regular APK from dist with another update installation. Flutter's default test installer is avoided because its failed-install fallback can uninstall the existing app.

The integration test downloads Qwen3 0.6B on the phone if absent, verifies its hash, and attempts inference with Dart HTTP requests forbidden during generation. It writes files/phone-models/on-device-smoke.json in the app; the helper copies a successful report to research/on-device-smoke.json. Its synthetic prompt does not change learner answers. A rejected install or a built test APK is not a successful inference result.

Commands describe reproduction, not observed success. See VALIDATION.md and the refinement validation report for completed outcomes.

## Two-day testing and mascot production

- research/two-day-demo-plan.md: functionality, usability, offline, and recovery checks.
- research/animation-reference/catalogue.html: playable reference catalogue.
- research/animation-reference/download-pack.zip: 71 public editorial media files, including 13 multiframe GIFs.
- research/animation-reference/runtime/runtime-reference-pack.zip: 75 additional public exports (59 Lottie JSON and 16 Rive files), with a registry and asset index.
- research/animation-reference/README.md: observed Duo/cast coverage, tool comparison, and original mascot production brief.
- research/animation-reference/animation-contract.json: state IDs and art handoff expectations.

The collection is bounded public research, not every animation from every app version or an editable production rig. Duolingo artwork remains in research and is not bundled in the app.

## Sources and licences

Original app code and lesson wording are MIT licensed. Publisher learning pages are linked, not copied. Qwen weights use Apache-2.0 terms. The distilled DeepSeek model and its upstream Qwen base have applicable MIT/Apache notices. Weight files are not bundled with source or the APK.

Implementation, research, and original lesson wording were AI-assisted. These starter materials have not been validated by a subject expert.

Primary sources: [llamadart](https://pub.dev/packages/llamadart), [llama.cpp Android](https://github.com/ggml-org/llama.cpp/blob/master/docs/android.md), [Qwen3 0.6B](https://huggingface.co/Qwen/Qwen3-0.6B-GGUF), [Qwen3 1.7B](https://huggingface.co/Qwen/Qwen3-1.7B-GGUF), [distilled DeepSeek GGUF](https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF), [DeepSeek V4.1](https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash).
