import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  setUpAll(() async {
    catalog = Catalog(
      jsonDecode(
        await rootBundle.loadString('assets/disciplines.json'),
      )['tracks'][0],
    );
  });
  test('hinted success stays separate from independent evidence', () {
    final q = catalog.questions.first;
    final state = LearningState(attempts: [Attempt(q.id, q.correct, true, 20)]);
    expect(state.independent(catalog), isEmpty);
  });
  test('a later correction never erases the first baseline attempt', () {
    final q = catalog.questions.first;
    final state = LearningState(
      attempts: [
        Attempt(q.id, (q.correct + 1) % q.options.length, false, 20),
        Attempt(q.id, q.correct, false, 20),
      ],
    );
    expect(state.independent(catalog), isEmpty);
  });
  test('local route decreases effort for demonstrated starting knowledge', () {
    final state = LearningState(
      attempts: catalog.questions
          .map((q) => Attempt(q.id, q.correct, false, 20))
          .toList(),
    );
    expect(
      state.remaining(catalog),
      lessThan(LearningState().remaining(catalog)),
    );
    expect(state.baselineDone(catalog), isTrue);
  });
  test('progress survives a JSON round trip', () {
    final state = LearningState(
      dailyMinutes: 20,
      completed: {catalog.milestones.first.id},
      attempts: [Attempt(catalog.questions.first.id, null, false, 12)],
    );
    final restored = LearningState.fromJson(
      jsonDecode(jsonEncode(state.toJson())),
    );
    expect(restored.completed, {catalog.milestones.first.id});
    expect(restored.attempts.single.answerIndex, isNull);
    expect(restored.dailyMinutes, 20);
    expect(restored.current(catalog)?.id, catalog.milestones[1].id);
  });
  test('every prerequisite precedes its dependent capability', () {
    final seen = <String>{};
    for (final milestone in catalog.milestones) {
      expect(seen.containsAll(milestone.prerequisites), isTrue);
      seen.add(milestone.id);
    }
  });
}
