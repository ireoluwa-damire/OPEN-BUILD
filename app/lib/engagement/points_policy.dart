import '../learning_session/challenge_definition.dart';
import '../learning_session/learning_session_state.dart';
import '../models.dart';

/// One ledger award with a stable idempotency key (GAM-01, GAM-02).
class PointsAward {
  final String sourceId, rewardType;
  final int points, sparks;
  const PointsAward(this.sourceId, this.rewardType, this.points, [this.sparks = 0]);
}

/// S1 §11.1 points table, plus CF-09 (checkpoint). Prototype values: points
/// measure practice, not mastery.
abstract final class PointsPolicy {
  static const checked = 10;
  static const firstTry = 5;
  static const noHint = 5;
  static const lesson = 20;
  static const review = 15;
  static const project = 25;
  static const checkpoint = 25;
  static const quest = 10;
  static const perfect = 20;
  static const completionSparks = 5;

  /// Completion bonus for a node type (review/project/checkpoint substitute
  /// for the lesson bonus).
  static (String, int) completionFor(NodeType type) => switch (type) {
    NodeType.recallReview => ('review', review),
    NodeType.projectStep => ('project', project),
    NodeType.checkpoint => ('checkpoint', checkpoint),
    _ => ('lesson', lesson),
  };

  /// AMB-02: the base reward shown on the node card, guaranteed on first
  /// completion: 10 per challenge plus the completion bonus.
  static int baseReward(Milestone node, int challengeCount) =>
      checked * challengeCount + completionFor(node.type).$2;

  /// The legacy completion key is kept so v3 rewards stay idempotent.
  static String completionSource(String discipline, String goal, String node) =>
      '$discipline:$goal:$node:complete:reward';

  /// Awards for a finished session. Nothing is awarded when the node was
  /// already completed before (replays and re-entry, LES-20).
  static List<PointsAward> forSession({
    required LearningSessionState session,
    required String discipline,
    required Milestone node,
    required bool newlyCompleted,
  }) {
    if (!newlyCompleted) return const [];
    final prefix = '$discipline:${session.goalId}:${node.id}:${session.sessionId}';
    final awards = <PointsAward>[];
    var allFirstTryNoHint = true;
    for (final c in session.challenges) {
      if (LearningSessionState.isRepair(c)) continue;
      final attempts = session.attemptsFor(c.id);
      if (attempts.isEmpty) continue;
      final first = attempts.first;
      final skipped = first.response['skipped'] == true;
      final hinted = attempts.any((a) => a.response['usedHint'] == true);
      awards.add(PointsAward('$prefix:${c.id}:checked', 'checked', checked));
      final firstCorrect = !skipped && first.outcome == FeedbackState.correct;
      if (firstCorrect) {
        awards.add(PointsAward('$prefix:${c.id}:first_try', 'first_try', firstTry));
        if (!hinted) {
          awards.add(PointsAward('$prefix:${c.id}:no_hint', 'no_hint', noHint));
        }
      }
      if (!firstCorrect || hinted) allFirstTryNoHint = false;
    }
    final (type, bonus) = completionFor(node.type);
    awards.add(
      PointsAward(
        completionSource(discipline, session.goalId, node.id),
        type,
        bonus,
        completionSparks,
      ),
    );
    if (session.focus == 5 && allFirstTryNoHint) {
      awards.add(PointsAward('$prefix:perfect', 'perfect', perfect));
    }
    return awards;
  }

  static int total(Iterable<PointsAward> awards) =>
      awards.fold(0, (n, a) => n + a.points);
}
