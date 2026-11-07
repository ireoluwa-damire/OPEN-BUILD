import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../design_system/app_settings.dart';

/// The eleven original UI sounds (DC §12, `assets/sounds/`).
enum SumiSound {
  tap('tap'),
  select('select'),
  correct('correct'),
  partial('partial'),
  incorrect('incorrect'),
  lessonComplete('lesson_complete'),
  nodeComplete('node_complete'),
  nodeUnlock('node_unlock'),
  streak('streak'),
  reward('reward'),
  modelReady('model_ready');

  final String file;
  const SumiSound(this.file);
}

enum SumiHaptic { selection, light, medium, success }

/// Plays sounds. Replaceable so tests can record calls without audio.
abstract class SoundBackend {
  Future<void> play(SumiSound sound);
}

class _AudioplayersBackend implements SoundBackend {
  final _players = <SumiSound, AudioPlayer>{};
  @override
  Future<void> play(SumiSound sound) async {
    final player = _players.putIfAbsent(sound, () {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.stop);
      return p;
    });
    await player.stop();
    await player.play(AssetSource('sounds/${sound.file}.wav'));
  }
}

class _SilentBackend implements SoundBackend {
  @override
  Future<void> play(SumiSound sound) async {}
}

/// SND-01 / SND-02: every sound and haptic goes through here, and both obey
/// the learner's settings. Controllers and event handlers call it; widgets do
/// not call `HapticFeedback` directly.
class EffectsService {
  EffectsService._();
  static final EffectsService instance = EffectsService._();

  /// No audio under `flutter test` or on the web preview.
  SoundBackend backend = _underTestOrWeb()
      ? _SilentBackend()
      : _AudioplayersBackend();

  /// Haptics sink; tests replace it to count calls.
  void Function(SumiHaptic kind) hapticSink = _platformHaptic;

  static bool _underTestOrWeb() {
    if (kIsWeb) return true;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return true;
    }
  }

  static void _platformHaptic(SumiHaptic kind) {
    switch (kind) {
      case SumiHaptic.selection:
        HapticFeedback.selectionClick();
      case SumiHaptic.light:
        HapticFeedback.lightImpact();
      case SumiHaptic.medium:
        HapticFeedback.mediumImpact();
      case SumiHaptic.success:
        HapticFeedback.heavyImpact();
    }
  }

  /// Plays [sound] when sound effects are on. Failures are silent: a sound
  /// never blocks learning.
  Future<void> sound(SumiSound sound) async {
    if (!appSettings.value.soundEffects) return;
    try {
      await backend.play(sound);
    } catch (_) {}
  }

  void haptic(SumiHaptic kind) {
    if (!appSettings.value.haptics) return;
    try {
      hapticSink(kind);
    } catch (_) {}
  }

  /// One feedback moment: a sound and a matching haptic.
  void feedback(SumiSound s, SumiHaptic h) {
    sound(s);
    haptic(h);
  }
}
