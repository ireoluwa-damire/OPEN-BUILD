import 'dart:math' as math;
import 'models.dart';
import 'resource_system.dart';

enum AdaptationEventType {
  sessionStarted,
  sessionCompleted,
  sessionAbandoned,
  contentFormatPresented,
  resourceOpened,
  resourceReturned,
  questionResponse,
  explanationVariantShown,
  requestedFollowUp,
  recallResult,
  practicalEvidenceResult,
  learnerFeedback,
  explicitPreferenceChange,
}

class AdaptationEvent {
  final String id;
  final String goalId;
  final String disciplineId;
  final AdaptationEventType type;
  final DateTime timestamp;
  final String? format; // "video", "article", "interactive", etc.
  final bool? isCorrect;
  final bool? usedHint;
  final int? retriesCount;
  final double? activeSeconds;
  final String? capabilityId;
  final Json? metadata;

  AdaptationEvent({
    required this.id,
    required this.goalId,
    required this.disciplineId,
    required this.type,
    DateTime? timestamp,
    this.format,
    this.isCorrect,
    this.usedHint,
    this.retriesCount,
    this.activeSeconds,
    this.capabilityId,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AdaptationEvent.fromJson(Json j) => AdaptationEvent(
    id: j['id'] ?? '',
    goalId: j['goal_id'] ?? '',
    disciplineId: j['discipline_id'] ?? '',
    type: AdaptationEventType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => AdaptationEventType.sessionStarted,
    ),
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    format: j['format'],
    isCorrect: j['is_correct'],
    usedHint: j['used_hint'],
    retriesCount: j['retries_count'],
    activeSeconds: (j['active_seconds'] as num?)?.toDouble(),
    capabilityId: j['capability_id'],
    metadata: j['metadata'],
  );

  Json toJson() => {
    'id': id,
    'goal_id': goalId,
    'discipline_id': disciplineId,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'format': format,
    'is_correct': isCorrect,
    'used_hint': usedHint,
    'retries_count': retriesCount,
    'active_seconds': activeSeconds,
    'capability_id': capabilityId,
    'metadata': metadata,
  };
}

class InferredObservation {
  final String key;
  final String
  description; // e.g. "Short worked examples have helped on your last 4 checks"
  final String
  effectDescription; // e.g. "Suggests video format for new concepts"
  final int evidenceCount;
  final double confidence; // 0.0 to 1.0
  final List<String> sourceEventIds;
  final DateTime firstObservedAt;
  final DateTime lastUpdatedAt;

  InferredObservation({
    required this.key,
    required this.description,
    required this.effectDescription,
    required this.evidenceCount,
    required this.confidence,
    required this.sourceEventIds,
    required this.firstObservedAt,
    required this.lastUpdatedAt,
  });

  factory InferredObservation.fromJson(Json j) => InferredObservation(
    key: j['key'] ?? '',
    description: j['description'] ?? '',
    effectDescription: j['effect_description'] ?? '',
    evidenceCount: j['evidence_count'] ?? 0,
    confidence: (j['confidence'] as num? ?? 0.0).toDouble(),
    sourceEventIds: List<String>.from(j['source_event_ids'] ?? []),
    firstObservedAt:
        DateTime.tryParse(j['first_observed_at'] ?? '') ?? DateTime.now(),
    lastUpdatedAt:
        DateTime.tryParse(j['last_updated_at'] ?? '') ?? DateTime.now(),
  );

  Json toJson() => {
    'key': key,
    'description': description,
    'effect_description': effectDescription,
    'evidence_count': evidenceCount,
    'confidence': confidence,
    'source_event_ids': sourceEventIds,
    'first_observed_at': firstObservedAt.toIso8601String(),
    'last_updated_at': lastUpdatedAt.toIso8601String(),
  };
}

class LearnerAdaptationProfile {
  static const int schemaVersion = 1;
  final String goalId;
  final String disciplineId;

  // User-declared explicit preferences (kept SEPARATE from inferred observations)
  String? explicitFormatPreference; // "video", "article", null (auto)
  String? explicitExplanationStyle; // "concise", "detailed", "example_first"
  bool explicitDataSavingMode;
  bool explicitHighContrast;

  // Format performance counters
  Map<String, int> formatPresents;
  Map<String, int> formatSuccesses;
  Map<String, int> formatRecallSuccesses;

  // Scaffolding counters
  int totalHintsRequested;
  int totalRetries;
  int totalExplanationRequests;

  // Misconception tags
  Set<String> activeMisconceptionTags;

  // Inferred observations (built strictly by AdaptationEngine)
  Map<String, InferredObservation> inferredObservations;

  DateTime lastUpdated;

  LearnerAdaptationProfile({
    required this.goalId,
    required this.disciplineId,
    this.explicitFormatPreference,
    this.explicitExplanationStyle,
    this.explicitDataSavingMode = false,
    this.explicitHighContrast = false,
    Map<String, int>? formatPresents,
    Map<String, int>? formatSuccesses,
    Map<String, int>? formatRecallSuccesses,
    this.totalHintsRequested = 0,
    this.totalRetries = 0,
    this.totalExplanationRequests = 0,
    Set<String>? activeMisconceptionTags,
    Map<String, InferredObservation>? inferredObservations,
    DateTime? lastUpdated,
  }) : formatPresents = formatPresents ?? {},
       formatSuccesses = formatSuccesses ?? {},
       formatRecallSuccesses = formatRecallSuccesses ?? {},
       activeMisconceptionTags = activeMisconceptionTags ?? {},
       inferredObservations = inferredObservations ?? {},
       lastUpdated = lastUpdated ?? DateTime.now();

  factory LearnerAdaptationProfile.fromJson(Json j) {
    return LearnerAdaptationProfile(
      goalId: j['goal_id'] ?? '',
      disciplineId: j['discipline_id'] ?? '',
      explicitFormatPreference: j['explicit_format_preference'],
      explicitExplanationStyle: j['explicit_explanation_style'],
      explicitDataSavingMode: j['explicit_data_saving_mode'] ?? false,
      explicitHighContrast: j['explicit_high_contrast'] ?? false,
      formatPresents: Map<String, int>.from(j['format_presents'] ?? {}),
      formatSuccesses: Map<String, int>.from(j['format_successes'] ?? {}),
      formatRecallSuccesses: Map<String, int>.from(
        j['format_recall_successes'] ?? {},
      ),
      totalHintsRequested: j['total_hints_requested'] ?? 0,
      totalRetries: j['total_retries'] ?? 0,
      totalExplanationRequests: j['total_explanation_requests'] ?? 0,
      activeMisconceptionTags: Set<String>.from(
        j['active_misconception_tags'] ?? [],
      ),
      inferredObservations:
          (j['inferred_observations'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, InferredObservation.fromJson(Json.from(v))),
          ) ??
          {},
      lastUpdated: DateTime.tryParse(j['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Json toJson() => {
    'schema_version': schemaVersion,
    'goal_id': goalId,
    'discipline_id': disciplineId,
    'explicit_format_preference': explicitFormatPreference,
    'explicit_explanation_style': explicitExplanationStyle,
    'explicit_data_saving_mode': explicitDataSavingMode,
    'explicit_high_contrast': explicitHighContrast,
    'format_presents': formatPresents,
    'format_successes': formatSuccesses,
    'format_recall_successes': formatRecallSuccesses,
    'total_hints_requested': totalHintsRequested,
    'total_retries': totalRetries,
    'total_explanation_requests': totalExplanationRequests,
    'active_misconception_tags': activeMisconceptionTags.toList(),
    'inferred_observations': inferredObservations.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'last_updated': lastUpdated.toIso8601String(),
  };

  void resetInferredPreferences() {
    inferredObservations.clear();
    formatPresents.clear();
    formatSuccesses.clear();
    formatRecallSuccesses.clear();
    totalHintsRequested = 0;
    totalRetries = 0;
    totalExplanationRequests = 0;
    activeMisconceptionTags.clear();
    lastUpdated = DateTime.now();
  }
}

class AdaptationEngine {
  static const int minEvidenceThreshold = 3;

  LearnerAdaptationProfile processEvents({
    required LearnerAdaptationProfile profile,
    required List<AdaptationEvent> events,
  }) {
    // Filter events belonging specifically to this profile's goal and discipline
    final goalEvents = events
        .where(
          (e) =>
              e.goalId == profile.goalId &&
              e.disciplineId == profile.disciplineId,
        )
        .toList();

    for (final e in goalEvents) {
      if (e.format != null) {
        final fmt = e.format!;
        if (e.type == AdaptationEventType.contentFormatPresented ||
            e.type == AdaptationEventType.resourceOpened) {
          profile.formatPresents[fmt] = (profile.formatPresents[fmt] ?? 0) + 1;
        }
        if (e.isCorrect == true) {
          if (e.type == AdaptationEventType.questionResponse ||
              e.type == AdaptationEventType.practicalEvidenceResult) {
            profile.formatSuccesses[fmt] =
                (profile.formatSuccesses[fmt] ?? 0) + 1;
          }
          if (e.type == AdaptationEventType.recallResult) {
            profile.formatRecallSuccesses[fmt] =
                (profile.formatRecallSuccesses[fmt] ?? 0) + 1;
          }
        }
      }

      if (e.usedHint == true) {
        profile.totalHintsRequested++;
      }
      if (e.retriesCount != null && e.retriesCount! > 0) {
        profile.totalRetries += e.retriesCount!;
      }
    }

    // Evaluate Rules with conservative minimum evidence thresholds
    // Rule 1: Video recall preference inference
    final videoRecallCount = profile.formatRecallSuccesses['video'] ?? 0;
    final videoEvents = goalEvents
        .where((e) => e.format == 'video')
        .map((e) => e.id)
        .toList();

    if (videoRecallCount >= minEvidenceThreshold) {
      final confidence = math.min(0.85, 0.50 + (videoRecallCount * 0.10));
      profile.inferredObservations['video_recall_boost'] = InferredObservation(
        key: 'video_recall_boost',
        description:
            'Video resources have led to stronger recall on your last $videoRecallCount checks.',
        effectDescription:
            'Modestly prioritizes video resource recommendations for new concepts.',
        evidenceCount: videoRecallCount,
        confidence: confidence,
        sourceEventIds: videoEvents,
        firstObservedAt: goalEvents.first.timestamp,
        lastUpdatedAt: DateTime.now(),
      );
    } else {
      profile.inferredObservations.remove('video_recall_boost');
    }

    // Rule 2: Step-by-step worked example scaffolding inference
    if (profile.totalHintsRequested >= minEvidenceThreshold) {
      final hintEvents = goalEvents
          .where((e) => e.usedHint == true)
          .map((e) => e.id)
          .toList();
      profile.inferredObservations['scaffolding_hints'] = InferredObservation(
        key: 'scaffolding_hints',
        description:
            'Short worked examples and hints have helped on your last ${profile.totalHintsRequested} checks.',
        effectDescription:
            'Includes step-by-step worked examples prior to practical exercises.',
        evidenceCount: profile.totalHintsRequested,
        confidence: 0.70,
        sourceEventIds: hintEvents,
        firstObservedAt: goalEvents.first.timestamp,
        lastUpdatedAt: DateTime.now(),
      );
    } else {
      profile.inferredObservations.remove('scaffolding_hints');
    }

    profile.lastUpdated = DateTime.now();
    return profile;
  }
}

class SessionStep {
  final String title;
  final String subtitle;
  final String
  stepType; // "review", "learn_concept", "worked_example", "practice_task"
  final String? milestoneId;
  final Resource? recommendedResource;
  final String? reasoning;

  SessionStep({
    required this.title,
    required this.subtitle,
    required this.stepType,
    this.milestoneId,
    this.recommendedResource,
    this.reasoning,
  });
}

class LearningSession {
  final String goalId;
  final String disciplineId;
  final Milestone currentMilestone;
  final List<SessionStep> steps;
  final String adaptedFormat; // "video", "article", etc.
  final bool isRepairScheduled;

  LearningSession({
    required this.goalId,
    required this.disciplineId,
    required this.currentMilestone,
    required this.steps,
    required this.adaptedFormat,
    this.isRepairScheduled = false,
  });
}

class SessionAssembler {
  final ResourceRepository repository;
  final ResourceRanker ranker;

  SessionAssembler({required this.repository, required this.ranker});

  LearningSession assembleSession({
    required Catalog catalog,
    required LearningState state,
    required LearnerAdaptationProfile profile,
    double explorationRate = 0.20, // 20% variety exploration to prevent lock-in
  }) {
    final milestone = state.current(catalog) ?? catalog.milestones.first;
    final candidates = repository.getAllResources(discipline: catalog.id);

    // Rank candidates using Adaptation Profile preferences
    final recommendations = ranker.rank(
      candidates: candidates,
      state: state,
      catalog: catalog,
      targetCapability: milestone.id,
    );

    final topRec =
        recommendations
            .where((r) => r.resource.id == milestone.resourceId)
            .firstOrNull ??
        recommendations.firstOrNull;

    // Check if recent failure requires a repair step
    final recentAttempt = state.attempts
        .where(
          (a) => catalog.questions.any(
            (q) => q.id == a.questionId && q.skill == milestone.id,
          ),
        )
        .lastOrNull;
    final isRepairNeeded =
        recentAttempt != null &&
        (recentAttempt.answerIndex == null || recentAttempt.usedHint);

    final steps = <SessionStep>[];

    // 1. Repair or Review step if needed
    if (isRepairNeeded) {
      steps.add(
        SessionStep(
          title: 'Targeted Review & Repair',
          subtitle:
              'Review the core concept before retrying the practical task.',
          stepType: 'review',
          milestoneId: milestone.id,
          reasoning:
              'A recent check needed hints or review. Let’s reinforce this concept.',
        ),
      );
    }

    // 2. Worked Example / Concept step if profile has scaffolding inference
    if (profile.inferredObservations.containsKey('scaffolding_hints') ||
        profile.explicitExplanationStyle == 'example_first') {
      steps.add(
        SessionStep(
          title: 'Short Worked Example',
          subtitle: 'Walk through a completed demonstration first.',
          stepType: 'worked_example',
          milestoneId: milestone.id,
          reasoning: 'Short worked examples have helped on your recent checks.',
        ),
      );
    }

    // 3. Learning Resource Step
    steps.add(
      SessionStep(
        title: milestone.title,
        subtitle: milestone.subtitle,
        stepType: 'learn_concept',
        milestoneId: milestone.id,
        recommendedResource:
            topRec?.resource ?? catalog.resource(milestone.resourceId),
        reasoning: topRec?.reasoning ?? 'Matches your active project step.',
      ),
    );

    // 4. Practical Project Task
    steps.add(
      SessionStep(
        title: 'Practical Project Task',
        subtitle: milestone.deliverable,
        stepType: 'practice_task',
        milestoneId: milestone.id,
        reasoning: 'Apply what you learned in your project.',
      ),
    );

    final chosenFormat =
        profile.explicitFormatPreference ??
        (profile.inferredObservations.containsKey('video_recall_boost')
            ? 'video'
            : 'article');

    return LearningSession(
      goalId: profile.goalId,
      disciplineId: catalog.id,
      currentMilestone: milestone,
      steps: steps,
      adaptedFormat: chosenFormat,
      isRepairScheduled: isRepairNeeded,
    );
  }
}
