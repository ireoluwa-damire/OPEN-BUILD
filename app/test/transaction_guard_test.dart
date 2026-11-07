import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/application/use_cases.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/learning_session/learning_session_controller.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';

import 'support/memory_preferences.dart';

// ignore: must_be_immutable
class FailingPreferences extends MemoryPreferences {
  bool fail = false;
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('simulated full disk');
    await super.setString(key, value);
  }
}

/// ARC-01: a failed write leaves the live state exactly as it was.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  late FailingPreferences prefs;
  late LocalStore store;
  late LearningState learning;

  setUpAll(() async {
    tracks = (jsonDecode(await rootBundle.loadString('assets/disciplines.json'))['tracks'] as List)
        .map((j) => Catalog(Json.from(j)))
        .toList();
  });
  setUp(() {
    prefs = FailingPreferences();
    store = LocalStore(preferences: prefs);
    learning = LearningState(trackId: 'music');
  });

  String snapshot() => jsonEncode(learning.toJson());

  Future<void> expectUnchanged(Future<void> Function() action) async {
    final before = snapshot();
    prefs.fail = true;
    await expectLater(action(), throwsA(isA<StateError>()));
    expect(snapshot(), before);
    prefs.fail = false;
  }

  test('onboarding answer', () async {
    await expectUnchanged(
      () => SaveOnboardingAnswer(store)(learning, (o) => o.motivation = 'Just for fun.'),
    );
    expect(learning.onboarding.motivation, isNull);
  });

  test('resource save and resource events', () async {
    final r = tracks.first.resources.first;
    await expectUnchanged(() => ToggleSaveResource(store)(learning, r));
    await expectUnchanged(
      () => RecordResourceUse(store)(learning, r, ResourceEventType.opened),
    );
    expect(learning.savedResourceIds, isEmpty);
    expect(learning.resourceEvents, isEmpty);
  });

  test('baseline attempt', () async {
    final q = tracks.first.questions.first;
    await expectUnchanged(
      () => RecordAttempt(store)(learning, tracks.first, Attempt(q.id, q.correct, false, 3)),
    );
    expect(learning.attempts, isEmpty);
  });

  test('setting change', () async {
    await expectUnchanged(
      () => UpdateSetting(store)(learning, (s) => s.settings.highContrast = true),
    );
    expect(learning.settings.highContrast, isFalse);
  });

  test('lesson completion', () async {
    final c = await LearningSessionController.open(
      store: store,
      learning: learning,
      catalog: tracks.first,
      node: tracks.first.milestones.first,
      unitId: 'u',
    );
    addTearDown(c.dispose);
    Json correct(ChallengeDefinition d) => switch (d.kind) {
      ChallengeKind.singleSelect => {'choice': d.answer.single},
      ChallengeKind.sequenceTokens || ChallengeKind.fashionProcedure => {'order': d.answer},
      ChallengeKind.matchPairs => {'pairs': d.answer},
      ChallengeKind.musicImitate => {'taps': [0, 600, 1200, 1800, 2400]},
      ChallengeKind.drawing => {
        'points': [[.1, .1], [.5, .5], [.9, .9]],
        'text': 'Inspect the seam',
      },
      ChallengeKind.projectReflection => {
        'made': 'A short rhythm on paper',
        'happened': 'One bar had an extra beat',
        'change': 'Count aloud before writing',
      },
      _ => {'text': 'A long enough reflection text.', 'observed': true},
    };
    for (var i = 0; i < c.state.challenges.length; i++) {
      c.updateDraft(correct(c.state.challenge));
      expect(await c.submit(), isTrue);
      if (i + 1 < c.state.challenges.length) expect(await c.advance(), isTrue);
    }
    final before = snapshot();
    prefs.fail = true;
    expect(await c.advance(), isFalse);
    expect(snapshot(), before);
    expect(learning.completed, isEmpty);
    expect(learning.engagement.rewardTransactions, isEmpty);
  });

  test('screens never call store.save outside LocalStore', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('services.dart'))
        .where((f) => RegExp(r'store\.save\(').hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
