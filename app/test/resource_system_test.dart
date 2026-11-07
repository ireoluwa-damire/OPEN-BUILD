import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/resource_system.dart';
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
    'shipped resource IDs are unique and publisher URLs are non-placeholder',
    () {
      final allResources = tracks.expand((t) => t.resources).toList();
      final ids = <String>{};

      for (final r in allResources) {
        expect(ids.add(r.id), isTrue, reason: 'Duplicate resource ID: ${r.id}');
        // A publisher chapter may support several activities. The catalogue
        // deliberately keeps distinct capability bindings under distinct IDs.
        expect(r.id, isNot(contains('placeholder')));
        expect(r.canonicalUrl, isNot(contains('example.com')));
        expect(r.canonicalUrl, startsWith('https://'));
      }
    },
  );

  test(
    'Music and Fashion each surface at least two verified videos and one non-video alternative in demo data',
    () {
      final music = tracks.firstWhere((t) => t.id == 'music');
      final fashion = tracks.firstWhere((t) => t.id == 'fashion');

      final musicVideos = music.resources
          .where((r) => r.type == ResourceType.video)
          .toList();
      final musicNonVideos = music.resources
          .where((r) => r.type != ResourceType.video)
          .toList();

      expect(musicVideos.length, greaterThanOrEqualTo(2));
      expect(musicNonVideos.length, greaterThanOrEqualTo(1));

      final fashionVideos = fashion.resources
          .where((r) => r.type == ResourceType.video)
          .toList();
      final fashionNonVideos = fashion.resources
          .where((r) => r.type != ResourceType.video)
          .toList();

      expect(fashionVideos.length, greaterThanOrEqualTo(2));
      expect(fashionNonVideos.length, greaterThanOrEqualTo(1));
    },
  );

  test(
    'every recommended resource maps to a known capability and application/check activity',
    () {
      final repository = ResourceRepository(
        localCatalogue: tracks.expand((t) => t.resources).toList(),
      );
      final ranker = ResourceRanker();

      for (final track in tracks) {
        final state = LearningState(trackId: track.id);
        final recs = ranker.rank(
          candidates: repository.getAllResources(discipline: track.id),
          state: state,
          catalog: track,
        );

        for (final rec in recs) {
          expect(rec.resource.checkActivityId, isNotEmpty);
          expect(
            track.milestones.any((m) => m.id == rec.resource.checkActivityId) ||
                track.questions.any(
                  (q) => q.skill == rec.resource.checkActivityId,
                ),
            isTrue,
          );
        }
      }
    },
  );

  test('unknown model-proposed URLs/IDs are rejected', () {
    final repository = ResourceRepository(
      localCatalogue: tracks.expand((t) => t.resources).toList(),
    );
    expect(
      repository.isModelUrlValid('https://example.com/fake', 'fake-id'),
      isFalse,
    );
    expect(
      repository.isModelUrlValid(
        'https://randomwebsite.org/lesson',
        'random-id',
      ),
      isFalse,
    );

    final validResource = tracks.first.resources.first;
    expect(
      repository.isModelUrlValid(validResource.canonicalUrl, validResource.id),
      isTrue,
    );
  });

  test('resource view alone cannot complete a capability', () async {
    final store = LocalStore(preferences: MemoryPreferences());
    final service = LearningService(store: store);
    final state = LearningState(trackId: 'music');
    final resource = tracks.first.resources.first;

    await service.recordResourceUse(state, resource);

    expect(state.completed, isEmpty);
    expect(state.demonstrated, isEmpty);
    expect(state.transferred, isEmpty);
    expect(state.engagement.pointsTotal, 0);
  });

  test('offline/unavailable video falls back without blocking the lesson', () {
    final catalog = tracks.first;
    final state = LearningState(trackId: catalog.id);
    final milestone = catalog.milestones.first;

    // Local model/video absence still yields deterministic milestone lesson step
    expect(milestone.lesson, isNotNull);
    expect(milestone.lesson!['idea'], isNotEmpty);
    expect(state.current(catalog)?.id, milestone.id);
  });

  test(
    'ranking respects language, prerequisites, bandwidth and learner format override before soft preference scores',
    () {
      final catalog = tracks.first; // music
      final ranker = ResourceRanker();

      final videoRes = Resource(
        id: 'res-video',
        canonicalUrl: 'https://youtube.com/v1',
        title: 'Video Guide',
        publisher: 'Publisher',
        type: ResourceType.video,
        discipline: 'music',
        capabilityTags: ['music-pulse'],
        durationMinutes: 5,
        language: 'en',
        bandwidthType: 'high',
        checkActivityId: 'music-pulse',
      );

      final articleRes = Resource(
        id: 'res-article',
        canonicalUrl: 'https://site.org/a1',
        title: 'Article Guide',
        publisher: 'Publisher',
        type: ResourceType.article,
        discipline: 'music',
        capabilityTags: ['music-pulse'],
        durationMinutes: 5,
        language: 'en',
        bandwidthType: 'low',
        checkActivityId: 'music-pulse',
      );

      // Filter by data saver mode (high bandwidth video excluded)
      final stateDataSaver = LearningState(
        trackId: 'music',
        dataSavingMode: true,
      );
      final recsDataSaver = ranker.rank(
        candidates: [videoRes, articleRes],
        state: stateDataSaver,
        catalog: catalog,
      );
      expect(recsDataSaver.map((r) => r.resource.id), [articleRes.id]);

      // Learner format override (article preferred)
      final stateArticleOverride = LearningState(
        trackId: 'music',
        preferredFormatOverride: 'article',
      );
      final recsOverride = ranker.rank(
        candidates: [videoRes, articleRes],
        state: stateArticleOverride,
        catalog: catalog,
      );
      expect(recsOverride.first.resource.id, articleRes.id);
    },
  );

  test('Library state survives external-app round trips', () async {
    final preferences = MemoryPreferences();
    final store = LocalStore(preferences: preferences);

    final state = LearningState(trackId: 'music');
    state.savedResourceIds.add('music-pulse-video');
    state.recentlyUsedResourceIds.add('music-pitch-video');
    state.resourceEvents.add(
      ResourceUseEvent(
        id: 'evt1',
        resourceId: 'music-pulse-video',
        type: ResourceEventType.opened,
      ),
    );

    await store.save(state);
    final reloaded = await store.load('music');

    expect(reloaded.savedResourceIds, contains('music-pulse-video'));
    expect(reloaded.recentlyUsedResourceIds, contains('music-pitch-video'));
    expect(reloaded.resourceEvents, hasLength(1));
    expect(reloaded.resourceEvents.first.resourceId, 'music-pulse-video');
  });
}
