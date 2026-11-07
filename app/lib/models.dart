import 'dart:math' as math;

import 'adaptation_system.dart';
import 'review/review_scheduler.dart';

typedef Json = Map<String, dynamic>;

enum EvidenceState {
  unseen,
  exposed,
  supported,
  independent,
  recalled,
  transferred,
  needsReview,
}

enum NodeType {
  microLesson,
  guidedPractice,
  recallReview,
  videoResource,
  projectStep,
  checkpoint,
  rewardUnlock,
}

enum NodeState {
  locked,
  available,
  current,
  inProgress,
  complete,
  mastered,
  needsReview,
}

enum ResourceType {
  video,
  article,
  interactive,
  audio,
  bookExcerpt,
  learnerSupplied,
}

enum ReviewedStatus {
  reviewed,
  externallyValidated,
  provisional,
  learnerSupplied,
}

enum ResourceEventType {
  impression,
  opened,
  returned,
  saved,
  learnerCompleted,
  postResourceCheckResult,
}

/// One immutable ledger entry (GAM-01, ARC-07). `source` is the stable
/// idempotency key `discipline:goal:node:session:challenge:rewardType`.
class RewardTransaction {
  final String id;
  final DateTime timestamp;
  final String source;
  final String rewardType;
  final int pointsDelta;
  final int sparksDelta;
  const RewardTransaction({
    required this.id,
    required this.timestamp,
    required this.source,
    this.rewardType = 'lesson',
    this.pointsDelta = 0,
    this.sparksDelta = 0,
  });
  factory RewardTransaction.fromJson(Json j) => RewardTransaction(
    id: j['id'] ?? '',
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    source: j['source'] ?? '',
    rewardType: j['reward_type'] ?? 'lesson',
    pointsDelta: j['points_delta'] ?? 0,
    sparksDelta: j['sparks_delta'] ?? 0,
  );
  Json toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'reward_type': rewardType,
    'points_delta': pointsDelta,
    'sparks_delta': sparksDelta,
  };
}

/// Injected clock so streak and week rules are testable (GAM-03).
typedef Clock = DateTime Function();

class ResourceUseEvent {
  final String id;
  final String resourceId;
  final ResourceEventType type;
  final DateTime timestamp;
  final Json? metadata;

  ResourceUseEvent({
    required this.id,
    required this.resourceId,
    required this.type,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ResourceUseEvent.fromJson(Json j) => ResourceUseEvent(
    id: j['id'] ?? '',
    resourceId: j['resource_id'] ?? '',
    type: ResourceEventType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => ResourceEventType.impression,
    ),
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    metadata: j['metadata'],
  );

  Json toJson() => {
    'id': id,
    'resource_id': resourceId,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

class EngagementState {
  /// Tests replace this to cross midnight or week boundaries.
  static Clock clock = DateTime.now;

  int streakDays;
  DateTime? lastStreakDate;
  int recoveryTokens;
  int focusBuffer; // Legacy field; Focus is session state only (LES-11).
  Set<String> completedQuestIds;
  Set<String> rewardedEventIds;
  List<RewardTransaction> rewardTransactions;

  /// Local calendar days (yyyy-mm-dd) with a qualifying event and its kind.
  Map<String, String> qualifyingDays;

  /// Sparks spent on cosmetics or tokens (GAM-05). Balance = earned - spent.
  int sparksSpent;

  EngagementState({
    this.streakDays = 0,
    this.lastStreakDate,
    this.recoveryTokens = 0,
    this.focusBuffer = 5,
    this.sparksSpent = 0,
    Set<String>? completedQuestIds,
    Set<String>? rewardedEventIds,
    List<RewardTransaction>? rewardTransactions,
    Map<String, String>? qualifyingDays,
  }) : completedQuestIds = completedQuestIds ?? {},
       rewardedEventIds = rewardedEventIds ?? {},
       rewardTransactions = rewardTransactions ?? [],
       qualifyingDays = qualifyingDays ?? {};

  /// ARC-07: totals are derived from the ledger, never stored separately.
  int get pointsTotal => rewardTransactions.fold(0, (n, t) => n + t.pointsDelta);

  /// Week starts Monday 00:00 local time.
  int get pointsWeek {
    final now = clock();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return rewardTransactions
        .where((t) => !t.timestamp.toLocal().isBefore(monday))
        .fold(0, (n, t) => n + t.pointsDelta);
  }

  int get sparksBalance =>
      rewardTransactions.fold(0, (n, t) => n + t.sparksDelta) - sparksSpent;

  factory EngagementState.fromJson(Json j) {
    final ledger = ((j['reward_transactions'] ?? []) as List)
        .map((t) => RewardTransaction.fromJson(Json.from(t)))
        .toList();
    final state = EngagementState(
      streakDays: j['streak_days'] ?? 0,
      lastStreakDate: DateTime.tryParse(j['last_streak_date'] ?? ''),
      recoveryTokens: j['recovery_tokens'] ?? 0,
      focusBuffer: j['focus_buffer'] ?? 5,
      sparksSpent: j['sparks_spent'] ?? 0,
      completedQuestIds: Set<String>.from(j['completed_quest_ids'] ?? []),
      rewardedEventIds: Set<String>.from(j['rewarded_event_ids'] ?? []),
      rewardTransactions: ledger,
      qualifyingDays: Map<String, String>.from(j['qualifying_days'] ?? {}),
    );
    // ARC-03: older records stored totals beside the ledger. Never recompute
    // past points: add one adjustment entry so derived totals stay identical.
    final storedPoints = j['points_total'];
    if (storedPoints is int && storedPoints != state.pointsTotal) {
      state.rewardTransactions.add(
        RewardTransaction(
          id: 'tx_migration_points',
          timestamp: DateTime.tryParse(j['last_streak_date'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          source: 'migration:v3:points',
          rewardType: 'migration',
          pointsDelta: storedPoints - state.pointsTotal,
        ),
      );
    }
    final storedSparks = j['sparks_balance'];
    if (storedSparks is int &&
        j['sparks_spent'] == null &&
        storedSparks != state.sparksBalance) {
      state.rewardTransactions.add(
        RewardTransaction(
          id: 'tx_migration_sparks',
          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
          source: 'migration:v3:sparks',
          rewardType: 'migration',
          sparksDelta: storedSparks - state.sparksBalance,
        ),
      );
    }
    return state;
  }

  Json toJson() => {
    'points_total': pointsTotal,
    'points_week': pointsWeek,
    'streak_days': streakDays,
    'last_streak_date': lastStreakDate?.toIso8601String(),
    'recovery_tokens': recoveryTokens,
    'sparks_balance': sparksBalance,
    'sparks_spent': sparksSpent,
    'focus_buffer': focusBuffer,
    'completed_quest_ids': completedQuestIds.toList(),
    'rewarded_event_ids': rewardedEventIds.toList(),
    'reward_transactions': rewardTransactions.map((t) => t.toJson()).toList(),
    'qualifying_days': qualifyingDays,
  };

  /// Adds one ledger entry unless [eventId] was already rewarded (GAM-02).
  /// Returns whether anything was added.
  bool addReward(
    String eventId,
    int pointsDelta,
    int sparksDelta, {
    String rewardType = 'lesson',
  }) {
    if (rewardedEventIds.contains(eventId)) {
      return false; // Reject exact duplicates forever
    }
    rewardedEventIds.add(eventId);
    final now = clock();
    rewardTransactions.add(
      RewardTransaction(
        id: 'tx_${now.microsecondsSinceEpoch}_${rewardTransactions.length}',
        timestamp: now,
        source: eventId,
        rewardType: rewardType,
        pointsDelta: pointsDelta,
        sparksDelta: sparksDelta,
      ),
    );
    return true;
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// GAM-03: only a completed lesson, due review or project step qualifies.
  /// One recovery token is earned at each 7-day multiple (max 2 stored) and
  /// covers exactly one missed day, applied automatically.
  void qualifyDailyStreak([String reason = 'lesson']) {
    final now = clock();
    final today = DateTime(now.year, now.month, now.day);
    if (lastStreakDate != null) {
      final last = lastStreakDate!.toLocal();
      final lastDay = DateTime(last.year, last.month, last.day);
      // Calendar-day difference, robust to daylight-saving changes.
      final diff = DateTime.utc(today.year, today.month, today.day)
          .difference(DateTime.utc(lastDay.year, lastDay.month, lastDay.day))
          .inDays;
      if (diff <= 0) {
        qualifyingDays.putIfAbsent(dayKey(today), () => reason);
        return; // Idempotent within same day
      } else if (diff == 1) {
        streakDays++;
      } else if (diff == 2 && recoveryTokens > 0) {
        recoveryTokens--;
        final missed = today.subtract(const Duration(days: 1));
        qualifyingDays[dayKey(missed)] = 'recovery_token';
        streakDays += 2;
      } else {
        streakDays = 1;
      }
    } else {
      streakDays = 1;
    }
    if (streakDays > 0 && streakDays % 7 == 0 && recoveryTokens < 2) {
      recoveryTokens++;
    }
    qualifyingDays[dayKey(today)] = reason;
    lastStreakDate = now;
  }

  /// Whether today already has a qualifying event.
  bool get qualifiedToday => qualifyingDays.containsKey(dayKey(clock()));
}

class GoalModel {
  final String id;
  final String disciplineId;
  final String outcome;
  final String deadline;
  final List<String> constraints;
  final String status;
  final String proficiency;
  final String motivation;
  final int dailyMinutes;
  final String startingRoute;
  GoalModel({
    required this.id,
    required this.disciplineId,
    required this.outcome,
    this.deadline = '',
    List<String>? constraints,
    this.status = 'active',
    this.proficiency = 'Completely new',
    this.motivation = 'Finish a real project',
    this.dailyMinutes = 15,
    this.startingRoute = 'basics',
  }) : constraints = constraints ?? [];

  factory GoalModel.fromJson(Json j) => GoalModel(
    id: j['id'] ?? '',
    disciplineId: j['discipline_id'] ?? '',
    outcome: j['outcome'] ?? '',
    deadline: j['deadline'] ?? '',
    constraints: List<String>.from(j['constraints'] ?? []),
    status: j['status'] ?? 'active',
    proficiency: j['proficiency'] ?? 'Completely new',
    motivation: j['motivation'] ?? 'Finish a real project',
    dailyMinutes: j['daily_minutes'] ?? 15,
    startingRoute: j['starting_route'] ?? 'basics',
  );

  Json toJson() => {
    'id': id,
    'discipline_id': disciplineId,
    'outcome': outcome,
    'deadline': deadline,
    'constraints': constraints,
    'status': status,
    'proficiency': proficiency,
    'motivation': motivation,
    'daily_minutes': dailyMinutes,
    'starting_route': startingRoute,
  };
}

/// Onboarding answers (ONB-11, CF-18). Every answer is null until the learner
/// chooses it: there are no defaults, so CONTINUE stays disabled until a
/// valid answer exists.
class OnboardingState {
  static const minuteOptions = [5, 10, 15, 20];

  int stepIndex;
  bool completionState;
  String? selectedDiscipline;
  String outcome;
  String? deadline;
  List<String> constraints;
  String? motivation;
  String? proficiency;
  int? dailyMinutes;
  String? startingRoute;
  OnboardingState({
    this.stepIndex = 0,
    this.completionState = false,
    this.selectedDiscipline,
    this.outcome = '',
    this.deadline,
    List<String>? constraints,
    this.motivation,
    this.proficiency,
    this.dailyMinutes,
    this.startingRoute,
  }) : constraints = constraints ?? [];

  static int? _minutes(dynamic raw) {
    if (raw is! int) return null;
    if (raw == 30) return 20;
    return minuteOptions.contains(raw) ? raw : null;
  }

  factory OnboardingState.fromJson(Json j) => OnboardingState(
    stepIndex: j['step_index'] ?? (j['completion_state'] == true ? 9 : 0),
    completionState: j['completion_state'] ?? false,
    selectedDiscipline: j['selected_discipline'],
    outcome: j['outcome'] ?? '',
    deadline: j['deadline'],
    constraints: List<String>.from(j['constraints'] ?? [])
      ..remove(LearnerSettings.legacyConsentFlag),
    motivation: j['motivation'],
    proficiency: j['proficiency'],
    dailyMinutes: _minutes(j['daily_minutes']),
    startingRoute: j['starting_route'],
  );

  /// ARC-03: v3 stored a default for every answer. For a learner who had not
  /// finished onboarding, only answers on steps already passed were confirmed;
  /// later "answers" were defaults and are cleared.
  factory OnboardingState.fromV3(Json j) {
    final o = OnboardingState.fromJson(j);
    if (o.completionState) return o;
    final step = o.stepIndex;
    if (step <= 1) o.selectedDiscipline = null;
    if (step <= 2) {
      o.outcome = '';
      o.deadline = null;
      o.constraints = [];
    }
    if (step <= 3) o.motivation = null;
    if (step <= 4) o.proficiency = null;
    if (step <= 6) o.dailyMinutes = null;
    if (step <= 7) o.startingRoute = null;
    return o;
  }

  Json toJson() => {
    'step_index': stepIndex,
    'completion_state': completionState,
    'selected_discipline': selectedDiscipline,
    'outcome': outcome,
    'deadline': deadline,
    'constraints': constraints,
    'motivation': motivation,
    'proficiency': proficiency,
    'daily_minutes': dailyMinutes,
    'starting_route': startingRoute,
  };
}

/// Learner settings (ARC-03, SET-03, SET-05). Separate from onboarding and
/// goal data; every Settings subtitle is derived from these values (SET-02).
class LearnerSettings {
  /// v3 stored cloud consent as a constraint string on onboarding.
  static const legacyConsentFlag = 'cloud_consent_given';
  static const textModes = ['system', 'large', 'larger'];

  bool soundEffects;
  bool haptics;
  bool reducedMotion;
  bool highContrast;

  /// `system` follows the device text size; `large` and `larger` add 15 % and
  /// 30 % on top of it (A11Y-04).
  String textMode;

  /// `local` (on-device model or authored text only) or `cloud` (only when a
  /// provider is configured and consent was given, TUT-02).
  String aiMode;
  bool cloudConsent;

  /// `short` or `detailed` explanations from the tutor.
  String explanationLength;
  bool captions;

  /// `balanced`, `practice` or `reading` (exercise mix, SET-03).
  String exerciseMix;

  LearnerSettings({
    this.soundEffects = true,
    this.haptics = true,
    this.reducedMotion = false,
    this.highContrast = false,
    this.textMode = 'system',
    this.aiMode = 'local',
    this.cloudConsent = false,
    this.explanationLength = 'short',
    this.captions = true,
    this.exerciseMix = 'balanced',
  });

  double get textScale => switch (textMode) {
    'large' => 1.15,
    'larger' => 1.3,
    _ => 1.0,
  };

  factory LearnerSettings.fromJson(Json j) => LearnerSettings(
    soundEffects: j['sound_effects'] ?? true,
    haptics: j['haptics'] ?? true,
    reducedMotion: j['reduced_motion'] ?? false,
    highContrast: j['high_contrast'] ?? false,
    textMode: textModes.contains(j['text_mode']) ? j['text_mode'] : 'system',
    aiMode: j['ai_mode'] == 'cloud' ? 'cloud' : 'local',
    cloudConsent: j['cloud_consent'] ?? false,
    explanationLength: j['explanation_length'] == 'detailed'
        ? 'detailed'
        : 'short',
    captions: j['captions'] ?? true,
    exerciseMix: const ['practice', 'reading'].contains(j['exercise_mix'])
        ? j['exercise_mix']
        : 'balanced',
  );

  /// ARC-03: build v4 settings from a v3 record's flat fields and move cloud
  /// consent out of the onboarding constraints.
  factory LearnerSettings.fromV3(Json j) {
    final constraints = List<String>.from(
      (j['onboarding'] as Map?)?['constraints'] ?? const [],
    );
    return LearnerSettings(
      soundEffects: j['sound_effects_enabled'] ?? true,
      haptics: j['haptics_enabled'] ?? true,
      reducedMotion: j['reduced_motion'] ?? false,
      cloudConsent: constraints.contains(legacyConsentFlag),
    );
  }

  Json toJson() => {
    'sound_effects': soundEffects,
    'haptics': haptics,
    'reduced_motion': reducedMotion,
    'high_contrast': highContrast,
    'text_mode': textMode,
    'ai_mode': aiMode,
    'cloud_consent': cloudConsent,
    'explanation_length': explanationLength,
    'captions': captions,
    'exercise_mix': exerciseMix,
  };
}

class Question {
  final String id, skill, label, prompt, hint, explanation, resourceId;
  final String? code;
  final List<String> options;
  final int correct;
  Question(Json j)
    : id = j['id'],
      skill = j['skill'],
      label = j['label'],
      prompt = j['prompt'],
      hint = j['hint'],
      explanation = j['explanation'],
      resourceId = j['resource_id'],
      code = j['code'],
      options = List<String>.from(j['options']),
      correct = j['correct'];
}

class Attempt {
  final String questionId;
  final int? answerIndex;
  final bool usedHint;
  final double activeSeconds;
  final DateTime recordedAt;
  Attempt(
    this.questionId,
    this.answerIndex,
    this.usedHint,
    this.activeSeconds, {
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();
  Attempt.fromJson(Json j)
    : questionId = j['question_id'],
      answerIndex = j['answer_index'],
      usedHint = j['used_hint'] ?? false,
      activeSeconds = (j['active_seconds'] as num? ?? 0).toDouble(),
      recordedAt = DateTime.tryParse(j['recorded_at'] ?? '') ?? DateTime.now();
  Json toJson() => {
    'question_id': questionId,
    'answer_index': answerIndex,
    'used_hint': usedHint,
    'active_seconds': activeSeconds,
    'recorded_at': recordedAt.toIso8601String(),
  };
  Json toApi() => Map.of(toJson())..remove('recorded_at');
}

class Resource {
  final String id;
  final int contentVersion;
  final String canonicalUrl;
  final String providerId;
  final String title;
  final String publisher;
  final String creator;
  final ResourceType type;
  final String discipline;
  final List<String> capabilityTags;
  final String level;
  final List<String> prerequisites;
  final int durationMinutes;
  final String language;
  final bool hasCaptions;
  final String costType;
  final String bandwidthType;
  final ReviewedStatus reviewedStatus;
  final String reviewedAt;
  final String provenance;
  final String licenseNote;
  final List<String> safetyFlags;
  final String whyItHelps;
  final String checkActivityId;
  final String description;

  const Resource({
    required this.id,
    this.contentVersion = 1,
    required this.canonicalUrl,
    this.providerId = 'general',
    required this.title,
    required this.publisher,
    this.creator = 'Unknown Creator',
    this.type = ResourceType.article,
    this.discipline = 'general',
    this.capabilityTags = const [],
    this.level = 'Foundations',
    this.prerequisites = const [],
    this.durationMinutes = 10,
    this.language = 'en',
    this.hasCaptions = false,
    this.costType = 'free',
    this.bandwidthType = 'low',
    this.reviewedStatus = ReviewedStatus.reviewed,
    this.reviewedAt = '2026-10-28T00:00:00Z',
    this.provenance = 'Sumi Reviewed Catalogue',
    this.licenseNote = 'Open Educational Use',
    this.safetyFlags = const [],
    this.whyItHelps = 'Provides foundational context for this learning step.',
    this.checkActivityId = '',
    this.description = '',
  });

  String get url => canonicalUrl;
  String get skill =>
      capabilityTags.isNotEmpty ? capabilityTags.first : checkActivityId;
  String get format => type.name;
  int get minutes => durationMinutes;

  factory Resource.fromJson(Json j) {
    ResourceType parseType(String? t) {
      switch (t?.toLowerCase()) {
        case 'video':
          return ResourceType.video;
        case 'interactive':
          return ResourceType.interactive;
        case 'audio':
          return ResourceType.audio;
        case 'bookexcerpt':
        case 'book_excerpt':
          return ResourceType.bookExcerpt;
        case 'learnersupplied':
        case 'learner_supplied':
          return ResourceType.learnerSupplied;
        case 'article':
        default:
          return ResourceType.article;
      }
    }

    ReviewedStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'externallyvalidated':
        case 'externally_validated':
          return ReviewedStatus.externallyValidated;
        case 'provisional':
          return ReviewedStatus.provisional;
        case 'learnersupplied':
        case 'learner_supplied':
          return ReviewedStatus.learnerSupplied;
        case 'reviewed':
        default:
          return ReviewedStatus.reviewed;
      }
    }

    final rawType = j['type'] ?? j['format'];
    final urlStr = j['canonical_url'] ?? j['url'] ?? '';

    return Resource(
      id: j['id'] ?? '',
      contentVersion: j['content_version'] ?? 1,
      canonicalUrl: urlStr,
      providerId:
          j['provider_id'] ??
          (urlStr.contains('youtube.com') || urlStr.contains('youtu.be')
              ? 'youtube'
              : 'web'),
      title: j['title'] ?? '',
      publisher: j['publisher'] ?? 'Sumi Knowledge Base',
      creator: j['creator'] ?? j['publisher'] ?? 'Sumi Educator',
      type: parseType(rawType),
      discipline: j['discipline'] ?? '',
      capabilityTags: List<String>.from(
        j['capability_tags'] ?? (j['skill'] != null ? [j['skill']] : []),
      ),
      level: j['level'] ?? 'Foundations',
      prerequisites: List<String>.from(j['prerequisites'] ?? []),
      durationMinutes: j['duration_minutes'] ?? j['minutes'] ?? 10,
      language: j['language'] ?? 'en',
      hasCaptions: j['has_captions'] ?? false,
      costType: j['cost_type'] ?? 'free',
      bandwidthType:
          j['bandwidth_type'] ??
          (parseType(rawType) == ResourceType.video ? 'high' : 'low'),
      reviewedStatus: parseStatus(j['reviewed_status']),
      reviewedAt: j['reviewed_at'] ?? '2026-10-28T00:00:00Z',
      provenance: j['provenance'] ?? 'Sumi Catalogue',
      licenseNote: j['license_note'] ?? 'Open Educational Use',
      safetyFlags: List<String>.from(j['safety_flags'] ?? []),
      whyItHelps:
          j['why_it_helps'] ??
          j['description'] ??
          'Helps reinforce core concepts.',
      checkActivityId: j['check_activity_id'] ?? j['skill'] ?? '',
      description: j['description'] ?? '',
    );
  }

  Json toJson() => {
    'id': id,
    'content_version': contentVersion,
    'canonical_url': canonicalUrl,
    'provider_id': providerId,
    'title': title,
    'publisher': publisher,
    'creator': creator,
    'type': type.name,
    'discipline': discipline,
    'capability_tags': capabilityTags,
    'level': level,
    'prerequisites': prerequisites,
    'duration_minutes': durationMinutes,
    'language': language,
    'has_captions': hasCaptions,
    'cost_type': costType,
    'bandwidth_type': bandwidthType,
    'reviewed_status': reviewedStatus.name,
    'reviewed_at': reviewedAt,
    'provenance': provenance,
    'license_note': licenseNote,
    'safety_flags': safetyFlags,
    'why_it_helps': whyItHelps,
    'check_activity_id': checkActivityId,
    'description': description,
  };
}

class Milestone {
  final String id, title, subtitle, resourceId, deliverable;
  final List<String> prerequisites;
  final int minutes;
  final Json? lesson;
  final NodeType type;

  /// ARC-04: the unit this node belongs to, from `skills[].unit_id`.
  final String? unitId;

  /// ARC-04 / LES-15: authored per-node challenges, from `skills[].challenges`.
  final List<Json> challenges;

  Milestone(Json j)
    : id = j['id'],
      title = j['title'] ?? '',
      subtitle = j['subtitle'] ?? '',
      resourceId = j['resource_id'] ?? '',
      deliverable = j['deliverable'] ?? '',
      prerequisites = List<String>.from(j['prerequisites'] ?? const []),
      lesson = j['lesson'] == null ? null : Json.from(j['lesson']),
      minutes = j['minutes'] ?? 10,
      unitId = j['unit_id'],
      challenges = ((j['challenges'] ?? const []) as List)
          .map((c) => Json.from(c))
          .toList(growable: false),
      type = _parseNodeType(j['id'], j['type']);

  static NodeType _parseNodeType(String id, String? type) {
    if (type != null) {
      switch (type) {
        case 'micro_lesson':
          return NodeType.microLesson;
        case 'guided_practice':
          return NodeType.guidedPractice;
        case 'recall_review':
          return NodeType.recallReview;
        case 'video_resource':
          return NodeType.videoResource;
        case 'project_step':
          return NodeType.projectStep;
        case 'checkpoint':
          return NodeType.checkpoint;
        case 'reward_unlock':
          return NodeType.rewardUnlock;
      }
    }
    if (id.contains('create') || id.contains('brief') || id.contains('seam')) {
      return NodeType.projectStep;
    }
    if (id.contains('practice')) return NodeType.guidedPractice;
    if (id.contains('recall')) return NodeType.recallReview;
    if (id.contains('video')) return NodeType.videoResource;
    return NodeType.microLesson;
  }
}

class Catalog {
  final String id, title, description, goalHint, project;
  // ARC-05 track-level presentation data (no discipline branches in code).
  final List<String> evidenceCategories;
  final String celebration, defaultAccolade, scene;
  final List<String> previewCapabilities;
  final List<String> outcomeChips;
  final List<Json> units;
  final List<Question> questions;
  final List<Resource> resources;
  final List<Milestone> milestones;
  final List<Json> calibration;
  final List<Question> recallQuestions;
  Catalog(Json j)
    : id = j['id'] ?? 'python-demo',
      title = j['title'] ?? 'Legacy Python demo',
      description = j['description'] ?? '',
      goalHint = j['goal_hint'] ?? 'What would you like to do?',
      project = j['project'] ?? '',
      evidenceCategories = List<String>.from(
        j['evidence_categories'] ??
            const ['concept', 'application observation', 'reflection'],
      ),
      celebration = j['celebration'] ?? 'discovery',
      defaultAccolade = j['default_accolade'] ?? 'reflection',
      scene = j['scene'] ?? 'generic',
      previewCapabilities = List<String>.from(j['preview_capabilities'] ?? []),
      outcomeChips = List<String>.from(j['outcome_chips'] ?? []),
      units = ((j['units'] ?? []) as List).map((u) => Json.from(u)).toList(),
      recallQuestions = ((j['recall_questions'] ?? []) as List)
          .map((q) => Question(q))
          .toList(),
      questions = ((j['questions'] ?? const []) as List)
          .map((q) => Question(q))
          .toList(),
      resources = ((j['resources'] ?? const []) as List)
          .map((r) => Resource.fromJson(r))
          .toList(),
      milestones = ((j['skills'] ?? const []) as List)
          .map((s) => Milestone(s))
          .toList(),
      calibration = ((j['calibration'] ?? const []) as List)
          .map((d) => Json.from(d))
          .toList();

  /// Whether this track is authored, reviewed content (as opposed to a
  /// learner's custom goal without a validated plan, CUS-01).
  bool get isCustom => id.startsWith('custom_');

  /// CUS-01: an honest, provisional catalogue for "Something else". It has a
  /// unique ID and no invented lessons, answer keys or links. A validated
  /// plan (CUS-02) is the only way nodes are added.
  ///
  /// [skills] are the nodes of a confirmed, validated plan (CUS-02).
  factory Catalog.custom(
    OnboardingState onboarding, {
    String? id,
    List<Json> skills = const [],
  }) {
    final outcome = onboarding.outcome.trim();
    return Catalog({
      'id': id ?? newCustomId(),
      'title': outcome.isNotEmpty ? outcome : 'Your own goal',
      'description': 'Provisional goal. Sumi needs a validated plan first.',
      'goal_hint': outcome,
      'project': '',
      'scene': 'custom',
      'questions': <Json>[],
      'recall_questions': <Json>[],
      'resources': <Json>[],
      'skills': skills,
      'units': [
        if (skills.isNotEmpty)
          {
            'id': 'custom-unit-1',
            'title': outcome.isNotEmpty ? outcome : 'Your own goal',
            'outcome': 'A provisional plan drafted on this device and checked by Sumi.',
            'palette': 0,
          },
      ],
      'calibration': <Json>[],
    });
  }

  static int _customSeq = 0;
  static String newCustomId() =>
      'custom_${DateTime.now().microsecondsSinceEpoch}_${_customSeq++}';

  Catalog forRecall() => Catalog({
    'id': id,
    'title': title,
    'description': description,
    'project': project,
    'questions': recallQuestions
        .map(
          (q) => {
            'id': q.id,
            'skill': q.skill,
            'label': q.label,
            'prompt': q.prompt,
            'hint': q.hint,
            'explanation': q.explanation,
            'resource_id': q.resourceId,
            'code': q.code,
            'options': q.options,
            'correct': q.correct,
          },
        )
        .toList(),
    'resources': <Json>[],
    'skills': <Json>[],
    'calibration': <Json>[],
  });
  /// The catalogue resource with [id], or null. Never invents a resource or
  /// a link (G10: no fabricated or dead resource).
  Resource? resource(String id) =>
      resources.where((r) => r.id == id).firstOrNull;
}

class LearningState {
  static const int schemaVersion = 4;
  String trackId;
  String goal;
  int dailyMinutes;
  List<Attempt> attempts;
  List<Attempt> recallAttempts;
  Json? demoFeedback;
  Set<String> completed;
  Set<String> demonstrated;
  Set<String> transferred;
  Set<String> savedResourceIds;
  List<String> recentlyUsedResourceIds;
  List<ResourceUseEvent> resourceEvents;
  String? preferredFormatOverride;
  bool dataSavingMode;

  /// ARC-03: settings live in their own record (schema v4).
  LearnerSettings settings;
  bool get soundEffectsEnabled => settings.soundEffects;
  set soundEffectsEnabled(bool v) => settings.soundEffects = v;
  bool get hapticsEnabled => settings.haptics;
  set hapticsEnabled(bool v) => settings.haptics = v;
  bool get reducedMotion => settings.reducedMotion;
  set reducedMotion(bool v) => settings.reducedMotion = v;

  /// EVD-03: review schedule per node.
  Map<String, ReviewItem> reviewSchedule;
  GoalModel? goalRecord;
  LearnerAdaptationProfile? _adaptationProfile;
  LearnerAdaptationProfile get adaptationProfile =>
      _adaptationProfile ??= LearnerAdaptationProfile(
        goalId: goalRecord?.id ?? 'goal_$trackId',
        disciplineId: trackId,
      );
  List<AdaptationEvent> adaptationEvents;
  int completedCheckIns;
  DateTime startedAt;
  DateTime? lastCheckInAt;
  Json? aiPlan;
  OnboardingState onboarding;
  EngagementState engagement;
  // Additive v3 fields. A session, its evidence, and path events share one record.
  Json sessions;
  Json pathContext;
  List<Json> pathEvents;

  LearningState({
    this.trackId = '',
    this.goal = '',
    this.dailyMinutes = 15,
    List<Attempt>? attempts,
    List<Attempt>? recallAttempts,
    this.demoFeedback,
    Set<String>? completed,
    Set<String>? demonstrated,
    Set<String>? transferred,
    Set<String>? savedResourceIds,
    List<String>? recentlyUsedResourceIds,
    List<ResourceUseEvent>? resourceEvents,
    this.preferredFormatOverride,
    this.dataSavingMode = false,
    bool reducedMotion = false,
    LearnerSettings? settings,
    Map<String, ReviewItem>? reviewSchedule,
    this.goalRecord,
    LearnerAdaptationProfile? adaptationProfile,
    List<AdaptationEvent>? adaptationEvents,
    this.completedCheckIns = 0,
    DateTime? startedAt,
    this.lastCheckInAt,
    this.aiPlan,
    OnboardingState? onboarding,
    EngagementState? engagement,
    Json? sessions,
    Json? pathContext,
    List<Json>? pathEvents,
  }) : attempts = attempts ?? [],
       recallAttempts = recallAttempts ?? [],
       completed = completed ?? {},
       demonstrated = demonstrated ?? {},
       transferred = transferred ?? {},
       savedResourceIds = savedResourceIds ?? {},
       recentlyUsedResourceIds = recentlyUsedResourceIds ?? [],
       resourceEvents = resourceEvents ?? [],
       settings = settings ?? LearnerSettings(reducedMotion: reducedMotion),
       reviewSchedule = reviewSchedule ?? {},
       _adaptationProfile = adaptationProfile,
       adaptationEvents = adaptationEvents ?? [],
       startedAt = startedAt ?? DateTime.now(),
       onboarding = onboarding ?? OnboardingState(),
       engagement = engagement ?? EngagementState(),
       sessions = sessions ?? {},
       pathContext = pathContext ?? {},
       pathEvents = pathEvents ?? [];

  /// Reads a v4 record, or upgrades a v3 record in memory (ARC-03).
  factory LearningState.fromJson(Json j) {
    final version = j['schema_version'] is int ? j['schema_version'] as int : 3;
    final v4 = version >= 4;
    var rawMinutes = j['daily_minutes'] ?? 15;
    if (rawMinutes == 30) rawMinutes = 20;
    if (![5, 10, 15, 20].contains(rawMinutes)) rawMinutes = 15;
    return LearningState(
      trackId: j['track_id'] ?? 'python-demo',
      sessions: Json.from(j['sessions'] ?? {}),
      pathContext: Json.from(j['path_context'] ?? {}),
      pathEvents: (j['path_events'] as List? ?? [])
          .map((e) => Json.from(e))
          .toList(),
      goal: j['goal'] ?? '',
      recallAttempts: ((j['recall_attempts'] ?? []) as List)
          .map((a) => Attempt.fromJson(Json.from(a)))
          .toList(),
      demoFeedback: j['demo_feedback'] == null
          ? null
          : Json.from(j['demo_feedback']),
      dailyMinutes: rawMinutes,
      attempts: ((j['attempts'] ?? []) as List)
          .map((a) => Attempt.fromJson(Json.from(a)))
          .toList(),
      completed: Set<String>.from(j['completed'] ?? []),
      demonstrated: Set<String>.from(j['demonstrated'] ?? []),
      transferred: Set<String>.from(j['transferred'] ?? []),
      savedResourceIds: Set<String>.from(j['saved_resource_ids'] ?? []),
      recentlyUsedResourceIds: List<String>.from(
        j['recently_used_resource_ids'] ?? [],
      ),
      resourceEvents: ((j['resource_events'] ?? []) as List)
          .map((e) => ResourceUseEvent.fromJson(Json.from(e)))
          .toList(),
      preferredFormatOverride: j['preferred_format_override'],
      dataSavingMode: j['data_saving_mode'] ?? false,
      settings: v4 && j['settings'] is Map
          ? LearnerSettings.fromJson(Json.from(j['settings']))
          : LearnerSettings.fromV3(j),
      reviewSchedule: {
        for (final e in Json.from(j['review_schedule'] ?? {}).entries)
          if (e.value is Map)
            e.key: ReviewItem.fromJson(Json.from(e.value as Map)),
      },
      goalRecord: j['goal_record'] == null
          ? null
          : GoalModel.fromJson(Json.from(j['goal_record'])),
      adaptationProfile: j['adaptation_profile'] == null
          ? null
          : LearnerAdaptationProfile.fromJson(
              Json.from(j['adaptation_profile']),
            ),
      adaptationEvents: ((j['adaptation_events'] ?? []) as List)
          .map((e) => AdaptationEvent.fromJson(Json.from(e)))
          .toList(),
      completedCheckIns: j['completed_check_ins'] ?? 0,
      startedAt: DateTime.tryParse(j['started_at'] ?? '') ?? DateTime.now(),
      lastCheckInAt: DateTime.tryParse(j['last_check_in_at'] ?? ''),
      aiPlan: j['ai_plan'],
      onboarding: j['onboarding'] == null
          ? OnboardingState()
          : v4
          ? OnboardingState.fromJson(Json.from(j['onboarding']))
          : OnboardingState.fromV3(Json.from(j['onboarding'])),
      engagement: j['engagement'] == null
          ? EngagementState()
          : EngagementState.fromJson(Json.from(j['engagement'])),
    );
  }

  factory LearningState.fromV2(Json j, String trackId) {
    var rawMinutes = j['daily_minutes'] ?? 15;
    if (rawMinutes == 30) rawMinutes = 20;
    if (![5, 10, 15, 20].contains(rawMinutes)) rawMinutes = 15;
    return LearningState(
      trackId: j['track_id'] ?? trackId,
      goal: j['goal'] ?? '',
      dailyMinutes: rawMinutes,
      attempts: ((j['attempts'] ?? []) as List)
          .map((a) => Attempt.fromJson(Json.from(a)))
          .toList(),
      recallAttempts: ((j['recall_attempts'] ?? []) as List)
          .map((a) => Attempt.fromJson(Json.from(a)))
          .toList(),
      demoFeedback: j['demo_feedback'] == null
          ? null
          : Json.from(j['demo_feedback']),
      completed: Set<String>.from(j['completed'] ?? []),
      demonstrated: Set<String>.from(j['demonstrated'] ?? []),
      transferred: Set<String>.from(j['transferred'] ?? []),
      goalRecord: GoalModel(
        id: 'goal_${trackId}_${DateTime.now().millisecondsSinceEpoch}',
        disciplineId: trackId,
        outcome: j['goal'] ?? '',
        dailyMinutes: rawMinutes,
      ),
      completedCheckIns: j['completed_check_ins'] ?? 0,
      startedAt: DateTime.tryParse(j['started_at'] ?? '') ?? DateTime.now(),
      lastCheckInAt: DateTime.tryParse(j['last_check_in_at'] ?? ''),
      aiPlan: j['ai_plan'],
      onboarding: OnboardingState(
        selectedDiscipline: j['track_id'] ?? trackId,
        outcome: j['goal'] ?? '',
        dailyMinutes: rawMinutes,
        completionState: true,
        stepIndex: 9,
      ),
      engagement: EngagementState(),
    );
  }

  Json toJson() => {
    'schema_version': schemaVersion,
    'sessions': sessions,
    'path_context': pathContext,
    'path_events': pathEvents,
    'track_id': trackId,
    'goal': goal,
    'daily_minutes': dailyMinutes,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'recall_attempts': recallAttempts.map((a) => a.toJson()).toList(),
    'demo_feedback': demoFeedback,
    'completed': completed.toList(),
    'demonstrated': demonstrated.toList(),
    'transferred': transferred.toList(),
    'saved_resource_ids': savedResourceIds.toList(),
    'recently_used_resource_ids': recentlyUsedResourceIds,
    'resource_events': resourceEvents.map((e) => e.toJson()).toList(),
    'preferred_format_override': preferredFormatOverride,
    'data_saving_mode': dataSavingMode,
    'settings': settings.toJson(),
    'review_schedule': {
      for (final e in reviewSchedule.entries) e.key: e.value.toJson(),
    },
    'goal_record': goalRecord?.toJson(),
    'adaptation_profile': adaptationProfile.toJson(),
    'adaptation_events': adaptationEvents.map((e) => e.toJson()).toList(),
    'completed_check_ins': completedCheckIns,
    'started_at': startedAt.toIso8601String(),
    'last_check_in_at': lastCheckInAt?.toIso8601String(),
    'ai_plan': aiPlan,
    'onboarding': onboarding.toJson(),
    'engagement': engagement.toJson(),
  };

  /// Publish a saved snapshot only after the storage operation succeeds.
  void applySnapshot(LearningState s) {
    trackId = s.trackId;
    goal = s.goal;
    dailyMinutes = s.dailyMinutes;
    attempts = s.attempts;
    recallAttempts = s.recallAttempts;
    demoFeedback = s.demoFeedback;
    completed = s.completed;
    demonstrated = s.demonstrated;
    transferred = s.transferred;
    savedResourceIds = s.savedResourceIds;
    recentlyUsedResourceIds = s.recentlyUsedResourceIds;
    resourceEvents = s.resourceEvents;
    preferredFormatOverride = s.preferredFormatOverride;
    dataSavingMode = s.dataSavingMode;
    settings = s.settings;
    reviewSchedule = s.reviewSchedule;
    goalRecord = s.goalRecord;
    _adaptationProfile = s._adaptationProfile;
    adaptationEvents = s.adaptationEvents;
    completedCheckIns = s.completedCheckIns;
    startedAt = s.startedAt;
    lastCheckInAt = s.lastCheckInAt;
    aiPlan = s.aiPlan;
    onboarding = s.onboarding;
    engagement = s.engagement;
    sessions = s.sessions;
    pathContext = s.pathContext;
    pathEvents = s.pathEvents;
  }

  bool get started => attempts.isNotEmpty;
  bool baselineDone(Catalog c) =>
      c.questions.isNotEmpty &&
      c.questions.every((q) => attempts.any((a) => a.questionId == q.id));
  bool recallDone(Catalog c) =>
      c.recallQuestions.isNotEmpty &&
      c.recallQuestions.every(
        (q) => recallAttempts.any((a) => a.questionId == q.id),
      );
  Set<String> recallIndependent(Catalog c) {
    final seen = <String>{}, ready = <String>{};
    for (final a in recallAttempts) {
      if (!seen.add(a.questionId)) continue;
      final q = c.recallQuestions
          .where((q) => q.id == a.questionId)
          .firstOrNull;
      if (q != null && a.answerIndex == q.correct && !a.usedHint) {
        ready.add(q.skill);
      }
    }
    return ready;
  }

  bool get earlyRecall =>
      recallAttempts.isNotEmpty &&
      recallAttempts.first.recordedAt.difference(startedAt) <
          const Duration(hours: 24);
  Set<String> latestEvidence(Catalog c) =>
      recallDone(c) ? recallIndependent(c) : independent(c);
  Set<String> independent(Catalog c) {
    final seen = <String>{}, ready = <String>{};
    for (final a in attempts) {
      if (!seen.add(a.questionId)) continue;
      final q = c.questions.where((q) => q.id == a.questionId).firstOrNull;
      if (q != null && a.answerIndex == q.correct && !a.usedHint) {
        ready.add(q.skill);
      }
    }
    return ready;
  }

  /// EVD-01 / EVD-02 promotion, strongest first:
  /// - `transferred` only from a first-try pass on a `context: transfer`
  ///   challenge (recorded in [transferred]); never from completion alone;
  /// - `needsReview` when a scheduled review is due or a new example failed;
  /// - `recalled` from independent success on the delayed follow-up;
  /// - `independent` from a first-try, no-hint pass ([demonstrated] or the
  ///   baseline);
  /// - `supported` after a hint or a correction;
  /// - `exposed` after any attempt.
  EvidenceState getEvidenceState(Milestone m, Catalog c) {
    if (transferred.contains(m.id)) return EvidenceState.transferred;
    final review = reviewSchedule[m.id];
    if (review != null && review.due(EngagementState.clock())) {
      return EvidenceState.needsReview;
    }
    if (recallDone(c) && recallIndependent(c).contains(m.id)) {
      return EvidenceState.recalled;
    }
    if (demonstrated.contains(m.id) || independent(c).contains(m.id)) {
      return EvidenceState.independent;
    }
    if (completed.contains(m.id)) return EvidenceState.supported;
    final milestoneAttempts = attempts.where(
      (a) => c.questions.any((q) => q.id == a.questionId && q.skill == m.id),
    );
    if (milestoneAttempts.isNotEmpty) {
      final usedHint = milestoneAttempts.any((a) => a.usedHint);
      return usedHint ? EvidenceState.supported : EvidenceState.exposed;
    }
    final started = sessions.values.any(
      (j) => j is Map && j['nodeId'] == m.id && (j['attempts'] as List? ?? []).isNotEmpty,
    );
    return started ? EvidenceState.exposed : EvidenceState.unseen;
  }

  NodeState getNodeState(Milestone m, Catalog c) {
    if (completed.contains(m.id)) return NodeState.complete;
    final curr = current(c);
    if (curr?.id == m.id) return NodeState.current;
    if (m.prerequisites.every(completed.contains)) return NodeState.available;
    return NodeState.locked;
  }

  int effort(Milestone m, Catalog c) => math.max(
    10,
    (m.minutes * (latestEvidence(c).contains(m.id) ? .5 : 1)).round(),
  );
  int remaining(Catalog c) => c.milestones
      .where((m) => !completed.contains(m.id))
      .fold(0, (n, m) => n + effort(m, c));
  int days(Catalog c) => math.max(1, (remaining(c) / dailyMinutes).ceil());
  Milestone? current(Catalog c) =>
      c.milestones.where((m) => !completed.contains(m.id)).firstOrNull;
  String reason(Milestone m, Catalog c) {
    final reasons = aiPlan?['milestones'] as List?;
    final match = reasons?.where((r) => r['id'] == m.id).firstOrNull;
    if (match != null && match['reason'] is String) return match['reason'];
    if (recallDone(c)) {
      return latestEvidence(c).contains(m.id)
          ? 'You connected this idea in the follow-up. Try applying it in your project.'
          : 'Your follow-up suggests this idea needs another small practice step.';
    }
    return independent(c).contains(m.id)
        ? 'You showed a starting understanding. Let’s apply it to a new example.'
        : 'A little focused practice here will support the next part of your project.';
  }
}
