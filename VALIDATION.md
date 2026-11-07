# Prototype validation — 27 October 2026

## Completed checks

| Area | Observed result |
| --- | --- |
| Dart static analysis | No issues found after the phone layout and code-example accessibility changes. |
| Flutter tests | Six passed: learner evidence, hints, timing, serialization, prerequisites, and a phone-sized assessment interaction. |
| Backend tests | Ten passed: scoring, skips, first attempts, prerequisite enforcement, effort estimates, and model-response validation. |
| Live HTTP API | Six checks passed; see backend/api-verification.json. |
| Local open model | Ollama qwen3:8b returned validated personalization in 68.2 seconds on this computer; see backend/live-model-verification.json. |
| Release web compilation | Completed successfully. Used only as a phone-sized development preview. |
| Android debug APK | Built successfully with Flutter 3.47.8 / Dart 3.13.7, Gradle 9.3.1, NDK 29.0.14206865, CMake 3.31.6. APK signature verified with Android apksigner (v2). |
| Android emulator | APK installed successfully on Pixel 9 / Android SDK 36; Sumi became the foreground activity and rendered the home screen with its mascot and bottom navigation. Native capture: preview/android-home.png. |
| Mobile interaction QA | At 390 × 844: baseline with independent, hinted, skipped, and incorrect answers; reload and resume; route prerequisite lock; resource filtering; first practice question and actual three-value Python project calculation; self-reported completion saved and the next lesson unlocked. |

The preview QA uses synthetic developer answers. It is not evidence about the user's proficiency or seven days of real learner activity. The synthetic replay in the app is labelled and separate from saved personal progress.

The emulator's cold boot produced Digital Wellbeing, System UI, and Pixel Launcher ANR dialogs. Increasing emulator resources and closing the unresponsive test-emulator background processes allowed a clean Sumi home-screen capture. Android's initial activity wait timed out during this slow startup. This is an installation/rendering smoke check, not a performance benchmark or a full native end-to-end test; the detailed interaction QA above used the phone-sized preview. The connected physical phone was not modified.

## Scope

The current application supports one original Python project track, local persistence, a baseline and practice loop, and optional real local-model personalization. The seven-day screen is a guide; longitudinal recall scheduling and arbitrary-discipline course generation remain future work. Practice completion combines a correct response and self-reported project work. It does not certify mastery.

iOS source is included. This Windows environment cannot compile or sign an iOS application; that requires macOS and Xcode.

## Android artifact

- File: app/build/app/outputs/flutter-apk/app-debug.apk
- Size: 155,376,548 bytes
- SHA-256: `4D5BC4BC3CD652E0FEB1954C27AD0EF3BCD9D44D862112DC61A371A417EC2E97`
- This is a debug-signed prototype for device testing.
- The optional workspace engine cache contains an official Flutter ARM64 runtime verified against Google Storage's published checksum over HTTPS. It is excluded from source control.
