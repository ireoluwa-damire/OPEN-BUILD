import '../adaptation_system.dart';
import '../engagement/points_policy.dart';
import '../engagement/quests.dart';
import '../learning_session/challenge_definition.dart';
import '../learning_session/learning_session_state.dart';
import '../models.dart';
import '../review/review_scheduler.dart';
import '../services.dart';
import '../session_result/session_result_assembler.dart';

/// ARC-01 / ARC-02: screens change learner data only through these use cases.
/// Each `call` wraps exactly one [LocalStore.transaction] (clone → mutate →
/// write → apply), so a failed write never changes the live state.
abstract class UseCase {
  final LocalStore store;
  const UseCase(this.store);
}

/// ONB-11: saves one onboarding answer as soon as it is valid.
class SaveOnboardingAnswer extends UseCase {
  const SaveOnboardingAnswer(super.store);
  Future<void> call(
    LearningState learning,
    void Function(OnboardingState onboarding) change,
  ) => store.transaction(learning, (s) async => change(s.onboarding));
}

/// ONB-10: writes the goal record and finishes onboarding in one transaction.
/// [trackId] must equal the active catalogue's ID (ONB-12).
class FinishOnboarding extends UseCase {
  const FinishOnboarding(super.store);
  Future<void> call(LearningState learning, {required String trackId}) =>
      store.transaction(learning, (s) async {
        final o = s.onboarding;
        if (s.trackId != trackId) {
          throw StateError('Onboarding track does not match the catalogue.');
        }
        final minutes = o.dailyMinutes ?? 10;
        s.goal = o.outcome.trim();
        s.dailyMinutes = minutes;
        s.goalRecord = GoalModel(
          id: s.goalRecord?.id ??
              'goal_${trackId}_${EngagementState.clock().microsecondsSinceEpoch}',
          disciplineId: trackId,
          outcome: o.outcome.trim(),
          deadline: o.deadline ?? 'None',
          constraints: List.of(o.constraints),
          proficiency: o.proficiency ?? '',
          motivation: o.motivation ?? '',
          dailyMinutes: minutes,
          startingRoute: o.startingRoute ?? 'basics',
        );
        o.completionState = true;
        o.stepIndex = 10;
      });
}

/// Baseline answers (ONB-09). Records the attempt and its adaptation event.
class RecordAttempt extends UseCase {
  const RecordAttempt(super.store);
  Future<void> call(LearningState learning, Catalog catalog, Attempt attempt) =>
      store.transaction(learning, (s) async {
        s.attempts.add(attempt);
        final q = catalog.questions
            .where((q) => q.id == attempt.questionId)
            .firstOrNull;
        s.adaptationEvents.add(
          AdaptationEvent(
            id: 'evt_${attempt.recordedAt.microsecondsSinceEpoch}_${s.adaptationEvents.length}',
            goalId: s.adaptationProfile.goalId,
            disciplineId: s.trackId,
            type: AdaptationEventType.questionResponse,
            isCorrect: q != null && attempt.answerIndex == q.correct,
            usedHint: attempt.usedHint,
            capabilityId: q?.skill,
          ),
        );
        AdaptationEngine().processEvents(
          profile: s.adaptationProfile,
          events: s.adaptationEvents,
        );
      });
}

/// The delayed follow-up check (demo window). Answers go to the recall
/// record; the first answer per question is permanent, as in the baseline.
class RecordRecallAttempt extends UseCase {
  const RecordRecallAttempt(super.store);
  Future<void> call(LearningState learning, Attempt attempt) =>
      store.transaction(learning, (s) async {
        if (s.recallAttempts.any((a) => a.questionId == attempt.questionId)) {
          return;
        }
        s.recallAttempts.add(attempt);
      });
}

/// EVD-04: the learner removes one self-reported project entry. The attempt
/// stays in the history (so the session still adds up) but its text is
/// deleted and it is marked as removed.
class RemoveSelfReportedEvidence extends UseCase {
  const RemoveSelfReportedEvidence(super.store);
  Future<void> call(
    LearningState learning,
    String sessionId,
    String attemptId,
  ) => store.transaction(learning, (s) async {
    final raw = s.sessions[sessionId];
    if (raw is! Map) return;
    final session = LearningSessionState.fromJson(Json.from(raw));
    final attempts = [
      for (final a in session.attempts)
        if (a.id == attemptId &&
            session.challenges
                .where((c) => c.id == a.challengeId)
                .any((c) => c.kind == ChallengeKind.projectReflection))
          GradedAttempt(
            id: a.id,
            challengeId: a.challengeId,
            response: const {'removed': true},
            outcome: a.outcome,
            reason: 'Removed by the learner.',
            recordedAt: a.recordedAt,
          )
        else
          a,
    ];
    s.sessions[sessionId] = session.copyWith(attempts: attempts).toJson();
  });
}

/// GAM-05: sparks buy cosmetic items or a streak recovery token only; they
/// never gate content, retries, explanations, accessibility or inference.
class BuyRecoveryToken extends UseCase {
  static const price = 30;
  const BuyRecoveryToken(super.store);

  static bool canBuy(EngagementState e) =>
      e.sparksBalance >= price && e.recoveryTokens < 2;

  Future<void> call(LearningState learning) =>
      store.transaction(learning, (s) async {
        if (!canBuy(s.engagement)) {
          throw StateError('Not enough sparks or token slots.');
        }
        s.engagement.sparksSpent += price;
        s.engagement.recoveryTokens++;
      });
}

/// LIB-04: resource impressions, opens, returns and saves are events only.
/// They never add evidence, points or streak credit.
class RecordResourceUse extends UseCase {
  const RecordResourceUse(super.store);
  Future<void> call(
    LearningState learning,
    Resource resource,
    ResourceEventType type, {
    Json? metadata,
  }) => store.transaction(learning, (s) async {
    final now = EngagementState.clock();
    s.resourceEvents.add(
      ResourceUseEvent(
        id: 'evt_${now.microsecondsSinceEpoch}_${s.resourceEvents.length}',
        resourceId: resource.id,
        type: type,
        timestamp: now,
        metadata: metadata,
      ),
    );
    if (type == ResourceEventType.opened) {
      s.recentlyUsedResourceIds
        ..remove(resource.id)
        ..insert(0, resource.id);
      if (s.recentlyUsedResourceIds.length > 20) {
        s.recentlyUsedResourceIds.removeRange(20, s.recentlyUsedResourceIds.length);
      }
      s.adaptationEvents.add(
        AdaptationEvent(
          id: 'evt_${now.microsecondsSinceEpoch}_${s.adaptationEvents.length}',
          goalId: s.adaptationProfile.goalId,
          disciplineId: s.trackId,
          type: AdaptationEventType.resourceOpened,
          format: resource.type.name,
          capabilityId: resource.checkActivityId,
        ),
      );
      AdaptationEngine().processEvents(
        profile: s.adaptationProfile,
        events: s.adaptationEvents,
      );
    }
  });
}

/// LIB-03: save or unsave a resource, recorded as an event.
class ToggleSaveResource extends UseCase {
  const ToggleSaveResource(super.store);
  Future<void> call(LearningState learning, Resource resource) =>
      store.transaction(learning, (s) async {
        final saving = !s.savedResourceIds.contains(resource.id);
        if (saving) {
          s.savedResourceIds.add(resource.id);
        } else {
          s.savedResourceIds.remove(resource.id);
        }
        final now = EngagementState.clock();
        s.resourceEvents.add(
          ResourceUseEvent(
            id: 'evt_${now.microsecondsSinceEpoch}_${s.resourceEvents.length}',
            resourceId: resource.id,
            type: ResourceEventType.saved,
            timestamp: now,
            metadata: {'action': saving ? 'saved' : 'unsaved'},
          ),
        );
      });
}

/// SET-03 / SET-05 / library preferences: one setting change per call.
class UpdateSetting extends UseCase {
  const UpdateSetting(super.store);
  Future<void> call(
    LearningState learning,
    void Function(LearningState s) change,
  ) => store.transaction(learning, (s) async => change(s));
}

/// GAM-03: marks today as qualified. Only a completed lesson, due review or
/// project step may call this (never app open, a resource view or a model
/// download).
class QualifyDailyGoal extends UseCase {
  const QualifyDailyGoal(super.store);
  Future<void> call(LearningState learning, String reason) =>
      store.transaction(learning, (s) async {
        s.engagement.qualifyDailyStreak(reason);
      });
}

/// Why the next session was chosen, always with a human reason.
class NextSession {
  final Milestone node;
  final String reason;

  /// ONB-08: the Basics route flags three light checks for the first lesson.
  final bool lightChecks;
  const NextSession(this.node, this.reason, {this.lightChecks = false});
}

/// The next learning session for the active route (EVD-03, ONB-08).
class GetNextLearningSession {
  const GetNextLearningSession();
  NextSession? call(LearningState learning, Catalog catalog) {
    final now = EngagementState.clock();
    final due = ReviewScheduler.dueItems(learning.reviewSchedule, now)
        .where((r) => catalog.milestones.any((m) => m.id == r.nodeId))
        .firstOrNull;
    if (due != null) {
      return NextSession(
        catalog.milestones.firstWhere((m) => m.id == due.nodeId),
        due.reason,
      );
    }
    final next = learning.current(catalog);
    if (next == null) return null;
    final basicsFirst =
        learning.completed.isEmpty &&
        learning.onboarding.startingRoute == 'basics';
    return NextSession(
      next,
      learning.reason(next, catalog),
      lightChecks: basicsFirst,
    );
  }
}

/// Everything a finished session changes, applied inside the session's own
/// completion transaction (LES-18, GAM-01/02, EVD-01/02/03, GAM-03).
class CompleteActivity {
  const CompleteActivity();

  /// Mutates [profile] (a transaction candidate) and returns the result JSON
  /// stored on the session.
  Json apply({
    required LearningState profile,
    required Catalog catalog,
    required LearningSessionState saved,
  }) {
    final newlyCompleted = !profile.completed.contains(saved.nodeId);
    final availableBefore = catalog.milestones
        .where((n) => n.prerequisites.every(profile.completed.contains))
        .map((n) => n.id)
        .toSet();
    final node = catalog.milestones.firstWhere((n) => n.id == saved.nodeId);
    final awards = PointsPolicy.forSession(
      session: saved,
      discipline: catalog.id,
      node: node,
      newlyCompleted: newlyCompleted,
    ).where((a) => !profile.engagement.rewardedEventIds.contains(a.sourceId))
        .toList();
    final points = PointsPolicy.total(awards);
    final projected = {...profile.completed, saved.nodeId};
    final unlocked = catalog.milestones
        .where(
          (n) =>
              !availableBefore.contains(n.id) &&
              !projected.contains(n.id) &&
              n.prerequisites.every(projected.contains),
        )
        .toList();
    final result = assembleSessionResult(
      saved,
      catalog,
      points: points,
      unlockedNode: unlocked.firstOrNull?.id,
    );
    profile.completed.add(saved.nodeId);

    // EVD-01: a first-try, no-hint pass on every assessed item is
    // `independent` evidence, never `transferred`.
    final independent = result.firstAttemptAccuracy == 1;
    if (independent) profile.demonstrated.add(saved.nodeId);

    // EVD-02: transfer only from a first-try pass on a challenge authored as
    // a different context. Self-report and ordinary completion never count.
    if (transferPassed(saved)) profile.transferred.add(saved.nodeId);

    for (final a in awards) {
      profile.engagement.addReward(
        a.sourceId,
        a.points,
        a.sparks,
        rewardType: a.rewardType,
      );
    }
    final qualifiedBefore = profile.engagement.qualifiedToday;
    profile.engagement.qualifyDailyStreak(
      node.type == NodeType.projectStep
          ? 'project'
          : node.type == NodeType.recallReview
          ? 'review'
          : 'lesson',
    );

    // EVD-03: schedule the next review from the evidence just shown.
    final now = EngagementState.clock();
    final outcome = profile.transferred.contains(saved.nodeId)
        ? 'transferred'
        : sessionHadMistake(saved)
        ? 'incorrect'
        : sessionUsedHint(saved)
        ? 'hinted'
        : node.type == NodeType.recallReview && independent
        ? 'recalled'
        : 'independent';
    profile.reviewSchedule[saved.nodeId] = ReviewScheduler.schedule(
      nodeId: saved.nodeId,
      outcome: outcome,
      now: now,
      previous: profile.reviewSchedule[saved.nodeId],
    );

    profile.adaptationEvents.add(
      AdaptationEvent(
        id: '${saved.sessionId}:complete',
        goalId: saved.goalId,
        disciplineId: catalog.id,
        capabilityId: saved.nodeId,
        type: AdaptationEventType.practicalEvidenceResult,
        isCorrect: independent,
      ),
    );
    AdaptationEngine().processEvents(
      profile: profile.adaptationProfile,
      events: profile.adaptationEvents,
    );
    // GAM-04: daily quests pay out in the same transaction (idempotent).
    profile.sessions[saved.sessionId] = saved.copyWith(result: result.toJson()).toJson();
    DailyQuests.award(profile, now);

    // RES-01: today's minutes include this session's active time.
    final today = EngagementState.dayKey(now);
    var msToday = saved.elapsedMilliseconds;
    for (final raw in profile.sessions.values) {
      if (raw is! Map || raw['sessionId'] == saved.sessionId || raw['result'] == null) {
        continue;
      }
      final attempts = raw['attempts'] as List? ?? const [];
      final last = attempts.isEmpty ? null : DateTime.tryParse(attempts.last['recordedAt'] ?? '');
      if (last != null && EngagementState.dayKey(last) == today) {
        msToday += (raw['elapsedMilliseconds'] as int? ?? 0);
      }
    }
    final next = profile.current(catalog);
    final resultJson = result
        .withToday(
          streakDays: profile.engagement.streakDays,
          minutesToday: (msToday / 60000).ceil(),
          dailyGoal: profile.dailyMinutes,
          streakExtended: !qualifiedBefore && profile.engagement.qualifiedToday,
          nextNodeId: next?.id,
          nextNodeTitle: next?.title,
        )
        .toJson();
    profile.sessions[saved.sessionId] = saved
        .copyWith(result: resultJson)
        .toJson();
    if (newlyCompleted) {
      profile.pathEvents.add({
        'id': '${saved.sessionId}:complete',
        'nodeId': saved.nodeId,
        'trigger': 'completeNode',
      });
      if (node.type == NodeType.checkpoint) {
        profile.pathEvents.add({
          'id': '${saved.sessionId}:checkpoint',
          'nodeId': saved.nodeId,
          'trigger': 'completeCheckpoint',
        });
      }
      for (final next in unlocked) {
        profile.pathEvents.add({
          'id': '${saved.sessionId}:unlock:${next.id}',
          'nodeId': next.id,
          'trigger': 'unlock',
        });
      }
    }
    return resultJson;
  }

  static GradedAttempt? _first(LearningSessionState s, String id) =>
      s.attempts.where((a) => a.challengeId == id).firstOrNull;

  /// EVD-02: a `context: transfer` challenge passed on the first attempt
  /// without a hint or a skip.
  static bool transferPassed(LearningSessionState s) => s.challenges.any((c) {
    if (LearningSessionState.isRepair(c) || c.content['context'] != 'transfer') {
      return false;
    }
    if (c.selfReported) return false;
    final first = _first(s, c.id);
    return first != null &&
        first.outcome == FeedbackState.correct &&
        first.response['usedHint'] != true &&
        first.response['skipped'] != true;
  });

  static bool sessionHadMistake(LearningSessionState s) => s.challenges.any((c) {
    if (LearningSessionState.isRepair(c)) return false;
    final first = _first(s, c.id);
    return first != null &&
        (first.outcome == FeedbackState.incorrect ||
            first.response['skipped'] == true);
  });

  static bool sessionUsedHint(LearningSessionState s) =>
      s.attempts.any((a) => a.response['usedHint'] == true);
}
