import 'models.dart';

abstract class RemoteResourceConnector {
  Future<List<Resource>> searchRemoteResources(String query, String discipline);
}

class DefaultRemoteResourceConnector implements RemoteResourceConnector {
  @override
  Future<List<Resource>> searchRemoteResources(
    String query,
    String discipline,
  ) async {
    // Contract: A model/connector must never invent unvalidated URLs.
    // If no provider-validated resources exist, returns an empty list.
    return [];
  }
}

class ResourceRepository {
  final List<Resource> _localCatalogue;
  final RemoteResourceConnector remoteConnector;

  ResourceRepository({
    List<Resource>? localCatalogue,
    RemoteResourceConnector? remoteConnector,
  }) : _localCatalogue = localCatalogue ?? [],
       remoteConnector = remoteConnector ?? DefaultRemoteResourceConnector();

  Resource? getResourceById(String id) {
    return _localCatalogue.where((r) => r.id == id).firstOrNull;
  }

  List<Resource> getAllResources({String? discipline}) {
    if (discipline == null || discipline.isEmpty) {
      return List.unmodifiable(_localCatalogue);
    }
    return _localCatalogue
        .where(
          (r) =>
              r.discipline == discipline ||
              r.capabilityTags.any((t) => t.startsWith(discipline)),
        )
        .toList();
  }

  Future<List<Resource>> searchResources(
    String query,
    String discipline,
  ) async {
    final localMatches = _localCatalogue
        .where(
          (r) =>
              r.title.toLowerCase().contains(query.toLowerCase()) ||
              r.description.toLowerCase().contains(query.toLowerCase()) ||
              r.capabilityTags.any(
                (t) => t.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();

    if (localMatches.isNotEmpty) return localMatches;

    final remoteCandidates = await remoteConnector.searchRemoteResources(
      query,
      discipline,
    );
    return remoteCandidates.map((r) {
      if (r.reviewedStatus == ReviewedStatus.reviewed) {
        return r;
      }
      return Resource(
        id: r.id,
        contentVersion: r.contentVersion,
        canonicalUrl: r.canonicalUrl,
        providerId: r.providerId,
        title: r.title,
        publisher: r.publisher,
        creator: r.creator,
        type: r.type,
        discipline: r.discipline,
        capabilityTags: r.capabilityTags,
        level: r.level,
        prerequisites: r.prerequisites,
        durationMinutes: r.durationMinutes,
        language: r.language,
        hasCaptions: r.hasCaptions,
        costType: r.costType,
        bandwidthType: r.bandwidthType,
        reviewedStatus: ReviewedStatus.provisional,
        reviewedAt: r.reviewedAt,
        provenance: 'External, not reviewed by Sumi',
        licenseNote: r.licenseNote,
        safetyFlags: r.safetyFlags,
        whyItHelps: r.whyItHelps,
        checkActivityId: r.checkActivityId,
        description: r.description,
      );
    }).toList();
  }

  bool isModelUrlValid(String url, String resourceId) {
    if (url.contains('example.com')) return false;
    final found = _localCatalogue
        .where((r) => r.id == resourceId || r.canonicalUrl == url)
        .firstOrNull;
    return found != null;
  }
}

class ResourceRecommendation {
  final Resource resource;
  final double score;
  final String reasoning;

  ResourceRecommendation({
    required this.resource,
    required this.score,
    required this.reasoning,
  });
}

class ResourceRanker {
  List<ResourceRecommendation> rank({
    required List<Resource> candidates,
    required LearningState state,
    required Catalog catalog,
    String? targetCapability,
    String learnerLanguage = 'en',
  }) {
    final results = <ResourceRecommendation>[];

    for (final r in candidates) {
      // 1. HARD FILTERS BEFORE RANKING
      if (r.safetyFlags.contains('unsafe') ||
          r.safetyFlags.contains('flagged')) {
        continue;
      }
      if (r.prerequisites.any((p) => !state.completed.contains(p))) {
        continue;
      }
      if (r.language != learnerLanguage) {
        continue;
      }
      if (state.dataSavingMode && r.bandwidthType == 'high') {
        continue;
      }

      // 2. SOFT RANKING SCORES
      double score = 50.0;
      final reasons = <String>[];

      final currentMilestone = state.current(catalog);
      final activeCapability = targetCapability ?? currentMilestone?.id ?? '';
      if (activeCapability.isNotEmpty &&
          (r.checkActivityId == activeCapability ||
              r.capabilityTags.contains(activeCapability))) {
        score += 30.0;
        reasons.add(
          'Directly matches your current project step (${currentMilestone?.title ?? activeCapability})',
        );
      }

      if (state.preferredFormatOverride != null) {
        if (r.type.name == state.preferredFormatOverride) {
          score += 25.0;
          reasons.add('Matches your preferred ${r.type.name} format override');
        }
      } else {
        final videoRecallCount = state.recallAttempts
            .where((a) => a.answerIndex != null && !a.usedHint)
            .length;
        if (r.type == ResourceType.video && videoRecallCount > 0) {
          score += 15.0;
          reasons.add(
            'Recommended video format based on your post-resource recall history',
          );
        }
      }

      if (r.durationMinutes <= state.dailyMinutes) {
        score += 10.0;
        reasons.add(
          'Fits within your ${state.dailyMinutes}-min daily commitment',
        );
      }

      // SET-05: "Prefer captioned videos" ranks captioned videos first.
      if (state.settings.captions &&
          r.type == ResourceType.video &&
          r.hasCaptions) {
        score += 12.0;
        reasons.add('Has captions');
      }

      if (r.reviewedStatus == ReviewedStatus.reviewed) {
        score += 10.0;
        reasons.add('Reviewed by Sumi educator');
      }

      final reasoningText = reasons.join(' · ');
      results.add(
        ResourceRecommendation(
          resource: r,
          score: score,
          reasoning: reasoningText,
        ),
      );
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
