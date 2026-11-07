/// GOV-03: build identity shown in About. `test/build_info_test.dart` checks
/// these against `pubspec.yaml`, so the screen can never drift from the real
/// version.
abstract final class BuildInfo {
  static const version = '0.2.0';
  static const build = '2';
  static const applicationId = 'com.example.sumi';
}
