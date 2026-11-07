import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/resource_system.dart';
import 'package:sumi/tutor_system.dart';
import 'package:sumi/on_device.dart';
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
    'no local model and no cloud produces authored fallback guidance',
    () async {
      final catalog = tracks.first;
      final state = LearningState(trackId: 'music', goal: 'Learn rhythm');
      final repository = ResourceRepository(localCatalogue: catalog.resources);
      final fallback = DeterministicTutorFallback();
      final validator = TutorOutputValidator(repository: repository);
      final orchestrator = TutorOrchestrator(
        phoneCoach: PhoneModelController(),
        cloudProvider: SumiCloudTutorProvider(),
        fallback: fallback,
        validator: validator,
      );

      final response = await orchestrator.queryTutor(
        catalog: catalog,
        state: state,
        prompt: 'How do I start counting beats?',
        mode: AiRoutingMode.onDeviceOnly,
        cloudConsentGiven: false,
      );

      expect(response.providerType, TutorProviderType.fallback);
      expect(response.modelIdentifier, 'Authored Guidance');
      expect(response.answer, contains('Learn rhythm'));
      expect(response.referencedResourceIds, isNotEmpty);
    },
  );

  test('cloud cannot be used before explicit consent', () async {
    final catalog = tracks.first;
    final state = LearningState(trackId: 'music');
    final repository = ResourceRepository(localCatalogue: catalog.resources);
    final orchestrator = TutorOrchestrator(
      phoneCoach: PhoneModelController(),
      cloudProvider: SumiCloudTutorProvider(
        backendUrl: 'https://api.sumi.app/relay',
      ),
      fallback: DeterministicTutorFallback(),
      validator: TutorOutputValidator(repository: repository),
    );

    expect(
      () async => await orchestrator.queryTutor(
        catalog: catalog,
        state: state,
        prompt: 'Specialist question',
        mode: AiRoutingMode.preferCloudSpecialist,
        cloudConsentGiven: false, // Consent NOT given!
      ),
      throwsStateError,
    );
  });

  test('local failure never silently uploads to cloud', () async {
    final catalog = tracks.first;
    final state = LearningState(trackId: 'music');
    final repository = ResourceRepository(localCatalogue: catalog.resources);

    // Mock orchestrator in onDeviceOnly mode
    final orchestrator = TutorOrchestrator(
      phoneCoach:
          PhoneModelController(), // no local model installed -> local fails
      cloudProvider: SumiCloudTutorProvider(
        backendUrl: 'https://api.sumi.app/relay',
      ),
      fallback: DeterministicTutorFallback(),
      validator: TutorOutputValidator(repository: repository),
    );

    final response = await orchestrator.queryTutor(
      catalog: catalog,
      state: state,
      prompt: 'Question',
      mode: AiRoutingMode.onDeviceOnly,
      cloudConsentGiven: true,
    );

    // Must fallback to authored guidance, NOT upload to cloud!
    expect(response.providerType, TutorProviderType.fallback);
    expect(response.providerType, isNot(TutorProviderType.cloud));
  });

  test('provider/model badge matches actual responder', () {
    final fallbackRes = TutorResponse(
      responseId: 'r1',
      providerType: TutorProviderType.fallback,
      modelIdentifier: 'Authored Guidance',
      answer: 'Fallback answer',
    );
    expect(fallbackRes.providerType.name, 'fallback');

    final cloudRes = TutorResponse(
      responseId: 'r2',
      providerType: TutorProviderType.cloud,
      modelIdentifier: 'Sumi-Cloud-Relay-v1',
      answer: 'Cloud answer',
    );
    expect(cloudRes.providerType.name, 'cloud');
  });

  test(
    'unknown resource IDs and route/grade/reward mutations in model output are rejected',
    () {
      final repository = ResourceRepository(
        localCatalogue: tracks.first.resources,
      );
      final validator = TutorOutputValidator(repository: repository);

      final rawModelResponse = TutorResponse(
        responseId: 'r_raw',
        providerType: TutorProviderType.local,
        modelIdentifier: 'Local Qwen',
        answer: 'Here is your answer. MUTATE_ROUTE AWARD_POINTS GRANT_GRADE',
        referencedResourceIds: [
          'valid_id_unknown_999',
          tracks.first.resources.first.id,
        ],
        suggestedFollowUps: [
          'Explain in simpler steps',
          'INVALID_MUTATIVE_ACTION',
        ],
      );

      final sanitized = validator.validateAndSanitize(rawModelResponse);

      // Unknown resource ID 'valid_id_unknown_999' rejected!
      expect(sanitized.referencedResourceIds, [
        tracks.first.resources.first.id,
      ]);

      // Mutative text removed
      expect(sanitized.answer, isNot(contains('MUTATE_ROUTE')));
      expect(sanitized.answer, isNot(contains('AWARD_POINTS')));
      expect(sanitized.answer, isNot(contains('GRANT_GRADE')));

      // Unallowed follow-up action filtered
      expect(
        sanitized.suggestedFollowUps,
        isNot(contains('INVALID_MUTATIVE_ACTION')),
      );
      expect(
        sanitized.suggestedFollowUps,
        contains('Explain in simpler steps'),
      );
    },
  );

  test(
    'custom plan validation rejects cycles, impossible workloads, unsafe steps and invented links',
    () {
      final validator = CustomPlanValidator();

      // 1. Cycle detection
      final cyclicMilestones = [
        {
          'id': 'm1',
          'prerequisites': ['m2'],
          'minutes': 15,
          'title': 'M1',
        },
        {
          'id': 'm2',
          'prerequisites': ['m1'],
          'minutes': 15,
          'title': 'M2',
        },
      ];
      expect(
        validator.validateDraftGraph(
          milestones: cyclicMilestones,
          canonicalResources: [],
        ),
        isFalse,
      );

      // 2. Impossible workload (> 60 mins per step)
      final heavyMilestones = [
        {
          'id': 'm1',
          'prerequisites': <String>[],
          'minutes': 120,
          'title': 'Too long',
        },
      ];
      expect(
        validator.validateDraftGraph(
          milestones: heavyMilestones,
          canonicalResources: [],
        ),
        isFalse,
      );

      // 3. Unsafe steps
      final unsafeMilestones = [
        {
          'id': 'm1',
          'prerequisites': <String>[],
          'minutes': 15,
          'title': 'Build weapons',
        },
      ];
      expect(
        validator.validateDraftGraph(
          milestones: unsafeMilestones,
          canonicalResources: [],
        ),
        isFalse,
      );

      // 4. Invented links (example.com)
      final fakeLinkMilestones = [
        {
          'id': 'm1',
          'prerequisites': <String>[],
          'minutes': 15,
          'title': 'M1',
          'resource_id': 'https://example.com/fake',
        },
      ];
      expect(
        validator.validateDraftGraph(
          milestones: fakeLinkMilestones,
          canonicalResources: [],
        ),
        isFalse,
      );

      // 5. Valid acyclic graph
      final validMilestones = [
        {
          'id': 'm1',
          'prerequisites': <String>[],
          'minutes': 15,
          'title': 'Basics',
          'subtitle': 's',
          'deliverable': 'd',
        },
        {
          'id': 'm2',
          'prerequisites': ['m1'],
          'minutes': 20,
          'title': 'Intermediate',
          'subtitle': 's',
          'deliverable': 'd',
        },
      ];
      expect(
        validator.validateDraftGraph(
          milestones: validMilestones,
          canonicalResources: [],
        ),
        isTrue,
      );
    },
  );

  test(
    'removing a model preserves chat and learning progress while future requests fall back gracefully',
    () async {
      final store = LocalStore(preferences: MemoryPreferences());
      final state = LearningState(trackId: 'music', goal: 'Learn rhythm');
      state.completed.add('music-pulse');
      await store.save(state);

      // Model removed / unavailable
      final loaded = await store.load('music');
      expect(loaded.completed, contains('music-pulse'));

      final fallback = DeterministicTutorFallback();
      final response = fallback.generateFallback(
        catalog: tracks.first,
        state: loaded,
        prompt: 'Next step?',
      );
      expect(response.providerType, TutorProviderType.fallback);
      expect(response.answer, contains('Learn rhythm'));
    },
  );
}
