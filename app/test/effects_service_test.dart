import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/design_system/app_settings.dart';
import 'package:sumi/effects/effects_service.dart';
import 'package:sumi/models.dart';

class RecordingBackend implements SoundBackend {
  final played = <SumiSound>[];
  @override
  Future<void> play(SumiSound sound) async => played.add(sound);
}

/// SND-01 / SND-02 / GOV-04.
void main() {
  late RecordingBackend backend;
  final haptics = <SumiHaptic>[];
  setUp(() {
    backend = RecordingBackend();
    haptics.clear();
    EffectsService.instance.backend = backend;
    EffectsService.instance.hapticSink = haptics.add;
  });
  tearDown(() => appSettings.value = LearnerSettings());

  test('sound and haptics play when enabled', () async {
    appSettings.value = LearnerSettings();
    EffectsService.instance.feedback(SumiSound.correct, SumiHaptic.light);
    await Future<void>.delayed(Duration.zero);
    expect(backend.played, [SumiSound.correct]);
    expect(haptics, [SumiHaptic.light]);
  });

  test('sound off is silent; haptics off never vibrates', () async {
    appSettings.value = LearnerSettings(soundEffects: false, haptics: false);
    EffectsService.instance.feedback(SumiSound.incorrect, SumiHaptic.medium);
    await EffectsService.instance.sound(SumiSound.reward);
    EffectsService.instance.haptic(SumiHaptic.success);
    expect(backend.played, isEmpty);
    expect(haptics, isEmpty);
  });

  test('every sound file exists, is short and is registered', () {
    final register = File('assets/ASSETS.md').readAsStringSync();
    for (final s in SumiSound.values) {
      final f = File('assets/sounds/${s.file}.wav');
      expect(f.existsSync(), isTrue, reason: s.file);
      // 44.1 kHz mono 16-bit: 88,200 bytes per second (plus a 44-byte header).
      expect(f.lengthSync(), lessThan(88200 * 1.7 + 44), reason: s.file);
      expect(register.contains('sounds/${s.file}.wav'), isTrue, reason: s.file);
    }
  });

  test('widgets do not call HapticFeedback directly', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('effects_service'))
        .where((f) => f.readAsStringSync().contains('HapticFeedback.'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
