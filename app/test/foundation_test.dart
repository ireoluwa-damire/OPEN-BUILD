import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/on_device.dart';
import 'package:sumi/phone_model_types.dart';
import 'support/memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completing two different lessons within one minute awards both', () {
    final state = LearningState(trackId: 'music');
    state.engagement.addReward('music:goal:lesson1:complete:reward', 20, 5);
    state.engagement.addReward('music:goal:lesson2:complete:reward', 20, 5);
    expect(state.engagement.pointsTotal, 40);
    expect(state.engagement.rewardTransactions, hasLength(2));
  });

  test(
    'reopening/replaying one completed lesson never duplicates its reward',
    () {
      final state = LearningState(trackId: 'music');
      final eventId = 'music:goal:lesson1:complete:reward';
      state.engagement.addReward(eventId, 20, 5);
      state.engagement.addReward(eventId, 20, 5); // duplicate replay
      expect(state.engagement.pointsTotal, 20);
      expect(state.engagement.rewardTransactions, hasLength(1));
    },
  );

  test(
    'a viewed resource does not grant capability evidence or streak credit',
    () async {
      final state = LearningState(trackId: 'music');
      final service = LearningService(
        store: LocalStore(preferences: MemoryPreferences()),
      );
      final resource = Resource.fromJson({
        'id': 'r1',
        'title': 'Res',
        'publisher': 'Pub',
        'url': 'https://sumi.local',
        'skill': 'm1',
        'format': 'Article',
        'description': 'desc',
        'level': 'Beginner',
        'minutes': 10,
      });
      await service.recordResourceUse(state, resource);
      expect(state.completed, isEmpty);
      expect(state.engagement.pointsTotal, 0);
      expect(state.engagement.streakDays, 0);
    },
  );

  test('Music and Fashion progress remain isolated', () async {
    final store = LocalStore(preferences: MemoryPreferences());
    final music = LearningState(trackId: 'music', goal: 'Learn Rhythm');
    music.completed.add('music-pulse');
    await store.save(music);

    final fashion = LearningState(trackId: 'fashion', goal: 'Sew Jacket');
    await store.save(fashion);

    final loadedMusic = await store.load('music');
    final loadedFashion = await store.load('fashion');

    expect(loadedMusic.completed, {'music-pulse'});
    expect(loadedFashion.completed, isEmpty);
    expect(loadedMusic.goal, 'Learn Rhythm');
    expect(loadedFashion.goal, 'Sew Jacket');
  });

  test(
    'onboarding outcome and daily commitment are exactly values supplied to tutor/session assembler',
    () {
      final onboarding = OnboardingState(
        outcome: 'Master acoustic guitar',
        dailyMinutes: 20,
        selectedDiscipline: 'music',
      );
      final catalog = Catalog({
        'id': 'music',
        'title': 'Music',
        'description': '',
        'questions': [],
        'resources': [],
        'skills': [],
        'calibration': [],
      });
      final state = LearningState(
        trackId: 'music',
        goal: onboarding.outcome,
        dailyMinutes: onboarding.dailyMinutes!,
      );
      final prompt = buildCoachPrompt(catalog, state);
      expect(prompt, contains('Master acoustic guitar'));
      expect(prompt, contains('20 minutes/day'));
    },
  );

  test(
    'two custom goals receive different stable IDs and never share progress',
    () {
      final onboarding1 = OnboardingState(outcome: 'Custom Goal A');
      final catalog1 = Catalog.custom(onboarding1);
      final state1 = LearningState(
        trackId: catalog1.id,
        goal: onboarding1.outcome,
      );
      // CUS-01: no invented steps exist before a validated plan.
      expect(catalog1.milestones, isEmpty);
      expect(catalog1.questions, isEmpty);
      state1.completed.add('${catalog1.id}:step-1');

      final onboarding2 = OnboardingState(outcome: 'Custom Goal B');
      final catalog2 = Catalog.custom(onboarding2);
      final state2 = LearningState(
        trackId: catalog2.id,
        goal: onboarding2.outcome,
      );

      expect(catalog1.id, isNot(equals(catalog2.id)));
      expect(state1.completed, hasLength(1));
      expect(state2.completed, isEmpty);
    },
  );

  test(
    'ordinary milestone completion does not automatically produce transferred evidence',
    () {
      final catalog = Catalog({
        'id': 'music',
        'title': 'Music',
        'description': '',
        'questions': [],
        'resources': [],
        'skills': [
          {
            'id': 'm1',
            'title': 'M1',
            'subtitle': 'S',
            'prerequisites': <String>[],
            'minutes': 10,
            'resource_id': 'r1',
            'deliverable': 'd',
          },
        ],
        'calibration': [],
      });
      final state = LearningState(trackId: 'music');
      state.completed.add('m1');
      expect(
        state.getEvidenceState(catalog.milestones.first, catalog),
        isNot(equals(EvidenceState.transferred)),
      );
    },
  );

  test(
    'local model absence still allows complete deterministic learning loop',
    () async {
      final state = LearningState(trackId: 'music', goal: 'Learn rhythm');
      final catalog = Catalog({
        'id': 'music',
        'title': 'Music',
        'description': '',
        'questions': [],
        'resources': [],
        'skills': [],
        'calibration': [],
      });
      final service = LearningService(
        store: LocalStore(preferences: MemoryPreferences()),
      );
      final response = await service.askTutor(
        catalog,
        state,
        PhoneModelController(),
        'How do I start?',
      );
      expect(response, isNotEmpty);
      expect(response, contains('Learn rhythm'));
    },
  );

  test('no custom resource uses example.com', () {
    final onboarding = OnboardingState(outcome: 'Pottery');
    final catalog = Catalog.custom(onboarding);
    for (final r in catalog.resources) {
      expect(r.url, isNot(contains('example.com')));
    }
  });

  test('migration preserves an existing v3 learner record', () async {
    final preferences = MemoryPreferences();
    final v3State = LearningState(trackId: 'music', goal: 'Preserved v3 goal');
    v3State.completed.add('m1');
    preferences.values['sumi.learning.v3.music'] = jsonEncode(v3State.toJson());

    final store = LocalStore(preferences: preferences);
    final loaded = await store.load('music');
    expect(loaded.goal, 'Preserved v3 goal');
    expect(loaded.completed, {'m1'});
  });
}
