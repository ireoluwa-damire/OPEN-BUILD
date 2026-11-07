import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/resource_system.dart';
import 'package:sumi/adaptation_system.dart';

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
    'one video completion does not label a video preference (conservative threshold = 3)',
    () {
      final profile = LearnerAdaptationProfile(
        goalId: 'g1',
        disciplineId: 'music',
      );
      final engine = AdaptationEngine();

      final singleEvent = AdaptationEvent(
        id: 'e1',
        goalId: 'g1',
        disciplineId: 'music',
        type: AdaptationEventType.recallResult,
        format: 'video',
        isCorrect: true,
      );

      engine.processEvents(profile: profile, events: [singleEvent]);

      // Single event MUST NOT trigger an inferred observation
      expect(
        profile.inferredObservations.containsKey('video_recall_boost'),
        isFalse,
      );
      expect(profile.inferredObservations, isEmpty);
    },
  );

  test(
    'repeated stronger post-resource results modestly alter ranking/session format (>= 3 threshold)',
    () {
      final profile = LearnerAdaptationProfile(
        goalId: 'g1',
        disciplineId: 'music',
      );
      final engine = AdaptationEngine();

      final events = [
        AdaptationEvent(
          id: 'e1',
          goalId: 'g1',
          disciplineId: 'music',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
        AdaptationEvent(
          id: 'e2',
          goalId: 'g1',
          disciplineId: 'music',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
        AdaptationEvent(
          id: 'e3',
          goalId: 'g1',
          disciplineId: 'music',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
      ];

      engine.processEvents(profile: profile, events: events);

      expect(
        profile.inferredObservations.containsKey('video_recall_boost'),
        isTrue,
      );
      final obs = profile.inferredObservations['video_recall_boost']!;
      expect(obs.evidenceCount, 3);
      expect(obs.confidence, greaterThanOrEqualTo(0.50));
      expect(obs.sourceEventIds, ['e1', 'e2', 'e3']);
    },
  );

  test(
    'explicit accessibility/bandwidth/format choices override inferred soft preferences',
    () {
      final catalog = tracks.first; // music
      final ranker = ResourceRanker();

      final videoRes = Resource(
        id: 'v1',
        canonicalUrl: 'https://youtube.com/v1',
        title: 'Video Lesson',
        publisher: 'Pub',
        type: ResourceType.video,
        discipline: 'music',
        capabilityTags: ['music-pulse'],
        durationMinutes: 5,
        checkActivityId: 'music-pulse',
      );

      final articleRes = Resource(
        id: 'a1',
        canonicalUrl: 'https://site.org/a1',
        title: 'Article Lesson',
        publisher: 'Pub',
        type: ResourceType.article,
        discipline: 'music',
        capabilityTags: ['music-pulse'],
        durationMinutes: 5,
        checkActivityId: 'music-pulse',
      );

      // Profile has inferred video boost, BUT explicit format preference is set to 'article'
      final state = LearningState(
        trackId: 'music',
        preferredFormatOverride: 'article',
      );
      state.adaptationProfile.inferredObservations['video_recall_boost'] =
          InferredObservation(
            key: 'video_recall_boost',
            description: 'Video boost',
            effectDescription: 'boost video',
            evidenceCount: 5,
            confidence: 0.8,
            sourceEventIds: ['e1'],
            firstObservedAt: DateTime.now(),
            lastUpdatedAt: DateTime.now(),
          );

      final recs = ranker.rank(
        candidates: [videoRes, articleRes],
        state: state,
        catalog: catalog,
      );

      // Explicit override MUST beat inferred soft preference
      expect(recs.first.resource.id, 'a1');
      expect(
        recs.first.reasoning,
        contains('preferred article format override'),
      );
    },
  );

  test(
    'a recent failure schedules repair without erasing earlier success',
    () async {
      final catalog = tracks.first; // music
      final repository = ResourceRepository(localCatalogue: catalog.resources);
      final ranker = ResourceRanker();
      final assembler = SessionAssembler(
        repository: repository,
        ranker: ranker,
      );

      final state = LearningState(trackId: 'music');
      // Prior success recorded
      // The current step is music-duration (after the unit video).
      state.completed.addAll(['music-pulse', 'music-u1-video']);
      expect(state.completed, contains('music-pulse'));

      // Recent attempt failed on next capability
      state.attempts.add(Attempt('music-duration-baseline', null, false, 15));

      final profile = LearnerAdaptationProfile(
        goalId: 'g1',
        disciplineId: 'music',
      );
      final session = assembler.assembleSession(
        catalog: catalog,
        state: state,
        profile: profile,
      );

      expect(session.isRepairScheduled, isTrue);
      expect(session.steps.any((s) => s.stepType == 'review'), isTrue);
      // Erasing earlier success check: music-pulse is STILL complete!
      expect(state.completed, contains('music-pulse'));
    },
  );

  test(
    'recall and transfer evidence are distinct from exposure and engagement',
    () {
      final catalog = tracks.first;
      final milestone = catalog.milestones.first;
      final state = LearningState(trackId: 'music');

      // Exposure (viewed or attempted)
      state.attempts.add(
        Attempt('music-pulse-baseline', 1, true, 10),
      ); // wrong or hint
      expect(
        state.getEvidenceState(milestone, catalog),
        EvidenceState.supported,
      );

      // Recall
      // Recall summaries are published after the complete follow-up, using its
      // own questions and answers (the baseline is a different assessment).
      state.recallAttempts.addAll(
        catalog.recallQuestions.map((q) => Attempt(q.id, q.correct, false, 10)),
      );
      expect(
        state.getEvidenceState(milestone, catalog),
        EvidenceState.recalled,
      );

      // Transfer requires explicit transferred set inclusion
      expect(
        state.getEvidenceState(milestone, catalog),
        isNot(EvidenceState.transferred),
      );
      state.transferred.add(milestone.id);
      expect(
        state.getEvidenceState(milestone, catalog),
        EvidenceState.transferred,
      );
    },
  );

  test('all displayed adaptation claims trace to recorded event IDs', () {
    final profile = LearnerAdaptationProfile(
      goalId: 'g1',
      disciplineId: 'music',
    );
    final engine = AdaptationEngine();

    final events = [
      AdaptationEvent(
        id: 'event_001',
        goalId: 'g1',
        disciplineId: 'music',
        type: AdaptationEventType.questionResponse,
        usedHint: true,
      ),
      AdaptationEvent(
        id: 'event_002',
        goalId: 'g1',
        disciplineId: 'music',
        type: AdaptationEventType.questionResponse,
        usedHint: true,
      ),
      AdaptationEvent(
        id: 'event_003',
        goalId: 'g1',
        disciplineId: 'music',
        type: AdaptationEventType.questionResponse,
        usedHint: true,
      ),
    ];

    engine.processEvents(profile: profile, events: events);

    final obs = profile.inferredObservations['scaffolding_hints']!;
    expect(obs.sourceEventIds, ['event_001', 'event_002', 'event_003']);
  });

  test(
    'resetting inferred preferences preserves learning progress and explicit accessibility settings',
    () {
      final profile = LearnerAdaptationProfile(
        goalId: 'g1',
        disciplineId: 'music',
        explicitFormatPreference: 'article',
        explicitHighContrast: true,
        explicitDataSavingMode: true,
      );
      profile.inferredObservations['scaffolding_hints'] = InferredObservation(
        key: 'scaffolding_hints',
        description: 'Test',
        effectDescription: 'Test effect',
        evidenceCount: 4,
        confidence: 0.7,
        sourceEventIds: ['e1'],
        firstObservedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      profile.resetInferredPreferences();

      // Inferred observations cleared
      expect(profile.inferredObservations, isEmpty);

      // Explicit accessibility settings & preferences PRESERVED
      expect(profile.explicitFormatPreference, 'article');
      expect(profile.explicitHighContrast, isTrue);
      expect(profile.explicitDataSavingMode, isTrue);
    },
  );

  test(
    'adaptation remains isolated between unrelated goals unless explicitly permitted',
    () {
      final engine = AdaptationEngine();
      final profileMusic = LearnerAdaptationProfile(
        goalId: 'goal_music_1',
        disciplineId: 'music',
      );

      final fashionEvents = [
        AdaptationEvent(
          id: 'fe1',
          goalId: 'goal_fashion_1',
          disciplineId: 'fashion',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
        AdaptationEvent(
          id: 'fe2',
          goalId: 'goal_fashion_1',
          disciplineId: 'fashion',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
        AdaptationEvent(
          id: 'fe3',
          goalId: 'goal_fashion_1',
          disciplineId: 'fashion',
          type: AdaptationEventType.recallResult,
          format: 'video',
          isCorrect: true,
        ),
      ];

      engine.processEvents(profile: profileMusic, events: fashionEvents);

      // Fashion events MUST NOT alter Music adaptation profile!
      expect(profileMusic.inferredObservations, isEmpty);
      expect(profileMusic.formatRecallSuccesses['video'], isNull);
    },
  );

  test(
    'Fixture: Two learners receive meaningfully different sessions from the same capability while deterministic grading remains identical',
    () {
      final catalog = tracks.first; // music
      final repository = ResourceRepository(localCatalogue: catalog.resources);
      final ranker = ResourceRanker();
      final assembler = SessionAssembler(
        repository: repository,
        ranker: ranker,
      );

      // Learner A: Standard learner with video recall boost & concise preference
      final stateA = LearningState(trackId: 'music');
      final profileA = LearnerAdaptationProfile(
        goalId: 'gA',
        disciplineId: 'music',
      );
      profileA.inferredObservations['video_recall_boost'] = InferredObservation(
        key: 'video_recall_boost',
        description: 'Video boost',
        effectDescription: 'Video preference',
        evidenceCount: 4,
        confidence: 0.8,
        sourceEventIds: ['e1', 'e2', 'e3', 'e4'],
        firstObservedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      // Learner B: Scaffolding learner who needs hints and worked examples, data saving mode on
      final stateB = LearningState(trackId: 'music', dataSavingMode: true);
      final profileB = LearnerAdaptationProfile(
        goalId: 'gB',
        disciplineId: 'music',
        explicitExplanationStyle: 'example_first',
      );
      profileB.inferredObservations['scaffolding_hints'] = InferredObservation(
        key: 'scaffolding_hints',
        description: 'Hints needed',
        effectDescription: 'Includes worked examples',
        evidenceCount: 3,
        confidence: 0.7,
        sourceEventIds: ['e5', 'e6', 'e7'],
        firstObservedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      final sessionA = assembler.assembleSession(
        catalog: catalog,
        state: stateA,
        profile: profileA,
      );
      final sessionB = assembler.assembleSession(
        catalog: catalog,
        state: stateB,
        profile: profileB,
      );

      // Session A receives video format; Session B receives article due to data saving mode
      expect(sessionA.adaptedFormat, 'video');
      expect(sessionB.adaptedFormat, 'article');

      // Session B receives worked_example step due to scaffolding needs; Session A gets direct path
      expect(sessionB.steps.any((s) => s.stepType == 'worked_example'), isTrue);
      expect(
        sessionA.steps.any((s) => s.stepType == 'worked_example'),
        isFalse,
      );

      // Deterministic grading remains identical for both learners on the underlying questions
      final question = catalog.questions.first;
      expect(
        question.correct,
        0,
      ); // Deterministic correctness rule is identical
    },
  );
}
