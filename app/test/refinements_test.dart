import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/phone_model_types.dart';
import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  setUpAll(() async {
    tracks =
        (jsonDecode(
                  await rootBundle.loadString('assets/disciplines.json'),
                )['tracks']
                as List)
            .map((j) => Catalog(Json.from(j)))
            .toList();
  });
  test(
    'only the selected disciplines are offered, with complete independent content',
    () {
      expect(tracks.map((c) => c.id).toSet(), {'music', 'fashion'});
      final allIds = <String>{};
      for (final c in tracks) {
        expect(c.questions, hasLength(6));
        expect(c.recallQuestions, hasLength(6));
        expect(c.calibration.map((d) => d['day']), [1, 2]);
        final before = <String>{};
        for (final m in c.milestones) {
          expect(before.containsAll(m.prerequisites), isTrue);
          // ARC-04: every node carries authored challenges; authored base
          // skills keep their concept lesson.
          expect(m.challenges, isNotEmpty);
          if (m.lesson != null) {
            expect(m.lesson!['options'], hasLength(4));
          }
          expect(c.resource(m.resourceId)!.url, startsWith('https://'));
          before.add(m.id);
        }
        for (final q in [...c.questions, ...c.recallQuestions]) {
          expect(allIds.add(q.id), isTrue);
          expect(q.correct, inInclusiveRange(0, q.options.length - 1));
          expect(c.milestones.any((m) => m.id == q.skill), isTrue);
        }
      }
    },
  );
  test('foreign answers cannot unlock another discipline baseline', () {
    final state = LearningState(
      trackId: 'music',
      attempts: tracks[1].questions
          .map((q) => Attempt(q.id, q.correct, false, 10))
          .toList(),
    );
    expect(state.baselineDone(tracks[0]), isFalse);
    expect(state.independent(tracks[0]), isEmpty);
  });
  test(
    'follow-up evidence changes effort without rewriting baseline evidence',
    () {
      final c = tracks.first;
      final state = LearningState(
        trackId: c.id,
        attempts: c.questions
            .map((q) => Attempt(q.id, q.correct, false, 10))
            .toList(),
      );
      final before = state.remaining(c);
      state.recallAttempts = c.recallQuestions
          .map((q) => Attempt(q.id, q.correct, true, 10))
          .toList();
      expect(state.recallDone(c), isTrue);
      expect(state.recallIndependent(c), isEmpty);
      expect(state.independent(c), hasLength(6));
      expect(state.remaining(c), greaterThan(before));
    },
  );
  test('early follow-up is identified using its actual timestamp', () {
    final start = DateTime.utc(2026, 10, 27, 12);
    final state = LearningState(
      startedAt: start,
      recallAttempts: [
        Attempt('test', 0, false, 2, recordedAt: start.add(Duration(hours: 1))),
      ],
    );
    expect(state.earlyRecall, isTrue);
    state.recallAttempts = [
      Attempt('test', 0, false, 2, recordedAt: start.add(Duration(hours: 24))),
    ];
    expect(state.earlyRecall, isFalse);
  });
  test(
    'subject progress is isolated and legacy progress is preserved',
    () async {
      final preferences = MemoryPreferences();
      preferences.values['sumi.learning.v1'] = 'legacy progress sentinel';
      final store = LocalStore(preferences: preferences);
      final music = LearningState(
        trackId: 'music',
        goal: 'Create a rhythm',
        attempts: [Attempt(tracks[0].questions.first.id, 0, false, 12)],
      );
      final fashion = LearningState(trackId: 'fashion', goal: 'Design a bag');
      await store.save(music);
      await store.save(fashion);
      expect((await store.load('music')).attempts, hasLength(1));
      expect((await store.load('fashion')).attempts, isEmpty);
      expect((await store.load('fashion')).goal, 'Design a bag');
      expect(
        preferences.values['sumi.learning.v1'],
        'legacy progress sentinel',
      );
      expect(LearningState().goal, isEmpty);
    },
  );
  test(
    'v2 to v3 migration handles legacy 30 min daily minutes and preserves data',
    () async {
      final preferences = MemoryPreferences();
      final v2Json = {
        'track_id': 'music',
        'goal': 'Master rhythm',
        'daily_minutes': 30,
        'attempts': [],
        'completed': ['music-pulse'],
      };
      preferences.values['sumi.learning.v2.music'] = jsonEncode(v2Json);
      final store = LocalStore(preferences: preferences);
      final loaded = await store.load('music');
      expect(loaded.dailyMinutes, 20); // legacy 30 mapped to 20
      expect(loaded.goal, 'Master rhythm');
      expect(loaded.completed, {'music-pulse'});
      expect(preferences.values['sumi.learning.v4.music'], isNotNull);
    },
  );
  test('model sources are pinned to revisions and SHA-256 digests', () async {
    final models =
        (jsonDecode(
                  await rootBundle.loadString('assets/model_catalog.json'),
                )['models']
                as List)
            .map((j) => PhoneModelChoice(Json.from(j)))
            .toList();
    expect(models, hasLength(3));
    for (final model in models) {
      expect(model.revision, matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(model.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(model.bytes, greaterThan(100000000));
    }
    expect(models.first.bytes, lessThan(models[1].bytes));
    expect(models.last.note, contains('not DeepSeek V4.1'));
  });
  test(
    'coach context contains the selected discipline and preserves grading boundaries',
    () {
      for (final c in tracks) {
        final prompt = buildCoachPrompt(
          c,
          LearningState(trackId: c.id, goal: 'My chosen goal'),
        );
        expect(prompt, contains(c.title));
        expect(prompt, contains('My chosen goal'));
        expect(prompt, contains('Do not assign a grade'));
        expect(prompt, isNot(contains('Python')));
      }
    },
  );
}
