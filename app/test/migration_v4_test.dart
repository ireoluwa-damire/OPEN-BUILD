import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';

import 'support/memory_preferences.dart';

/// ARC-03: v3 records upgrade to v4 with identical totals, the v3 key kept.
void main() {
  String fixture(String name) =>
      File('test/fixtures/$name.json').readAsStringSync();

  Future<(LearningState, MemoryPreferences)> load(String name) async {
    final prefs = MemoryPreferences();
    prefs.values['sumi.learning.v3.music'] = fixture(name);
    final store = LocalStore(preferences: prefs);
    return (await store.load('music'), prefs);
  }

  test('fresh v3 record migrates; v3 key is kept and v4 is written', () async {
    final (state, prefs) = await load('v3_fresh');
    expect(state.trackId, 'music');
    expect(prefs.values['sumi.learning.v3.music'], fixture('v3_fresh'));
    final v4 = jsonDecode(prefs.values['sumi.learning.v4.music']!);
    expect(v4['schema_version'], 4);
    expect(v4['settings'], isA<Map>());
    // CF-18: unconfirmed defaults are cleared for incomplete onboarding.
    expect(state.onboarding.selectedDiscipline, isNull);
    expect(state.onboarding.motivation, isNull);
    expect(state.onboarding.dailyMinutes, isNull);
    expect(state.onboarding.startingRoute, isNull);
  });

  test('mid-onboarding at step 3 keeps confirmed answers only', () async {
    final (state, _) = await load('v3_mid_onboarding');
    expect(state.onboarding.stepIndex, 3);
    expect(state.onboarding.selectedDiscipline, 'music');
    expect(state.onboarding.outcome, 'Keep a steady rhythm for a whole song');
    expect(state.onboarding.deadline, '2 weeks');
    expect(state.onboarding.constraints, ['Phone only']);
    expect(state.onboarding.motivation, isNull);
    expect(state.onboarding.proficiency, isNull);
  });

  test('completed record keeps points, streak, nodes, evidence and answers', () async {
    final raw = jsonDecode(fixture('v3_completed'));
    final (state, prefs) = await load('v3_completed');
    expect(state.engagement.pointsTotal, raw['engagement']['points_total']);
    expect(state.engagement.sparksBalance, raw['engagement']['sparks_balance']);
    expect(state.engagement.streakDays, raw['engagement']['streak_days']);
    expect(state.completed, Set<String>.from(raw['completed']));
    expect(state.demonstrated, Set<String>.from(raw['demonstrated']));
    expect(state.attempts, hasLength(1));
    expect(state.onboarding.completionState, isTrue);
    expect(state.onboarding.motivation, 'Finish a real project');
    // Settings moved out of the flat fields; consent out of constraints.
    expect(state.settings.reducedMotion, isTrue);
    expect(state.settings.soundEffects, isFalse);
    expect(state.settings.cloudConsent, isTrue);
    expect(state.onboarding.constraints, ['Low bandwidth']);
    // A v4 round trip is stable.
    final again = LearningState.fromJson(
      jsonDecode(prefs.values['sumi.learning.v4.music']!),
    );
    expect(again.engagement.pointsTotal, state.engagement.pointsTotal);
    expect(again.settings.toJson(), state.settings.toJson());
    expect(again.onboarding.toJson(), state.onboarding.toJson());
  });

  test('a v3 total that disagrees with its ledger is preserved by an adjustment', () {
    final raw = jsonDecode(fixture('v3_completed'));
    raw['engagement']['points_total'] = 55; // e.g. an older award formula
    final state = LearningState.fromJson(raw);
    expect(state.engagement.pointsTotal, 55);
    expect(
      state.engagement.rewardTransactions.last.rewardType,
      'migration',
    );
  });

  test('an unreadable record raises a recoverable error, never a reset', () async {
    final prefs = MemoryPreferences();
    prefs.values['sumi.learning.v3.music'] = '{not json';
    final store = LocalStore(preferences: prefs);
    await expectLater(store.load('music'), throwsA(isA<MigrationException>()));
    expect(prefs.values['sumi.learning.v3.music'], '{not json');
  });
}
