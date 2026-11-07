import '../learning_session/challenge_definition.dart';
import '../learning_session/learning_session_state.dart';
import '../models.dart';
import 'session_result.dart';

/// RES-02: one accolade per finished session, first matching rule wins.
/// - `accuracy`: every assessed check right on the first try (no hint);
/// - `recovery`: at least one incorrect answer, and every requeued item was
///   then passed;
/// - `making`: a project node;
/// - `listening`: a rhythm tap graded correct from real screen taps;
/// - `reflection`: nothing in the session was assessed (reflection only);
/// - `consistency`: otherwise.
SessionAccolade resolveAccolade({
  required LearningSessionState session,
  required NodeType nodeType,
  required int assessedCount,
  required double firstAttemptAccuracy,
}) {
  if (assessedCount > 0 && firstAttemptAccuracy == 1) {
    return SessionAccolade.accuracy;
  }
  final hadIncorrect = session.attempts.any(
    (a) => a.outcome == FeedbackState.incorrect,
  );
  final repairs = session.challenges.where(LearningSessionState.isRepair);
  final repairsPassed = repairs.every(
    (c) => session.attempts.any(
      (a) => a.challengeId == c.id && a.outcome == FeedbackState.correct,
    ),
  );
  if (hadIncorrect && repairsPassed) return SessionAccolade.recovery;
  if (nodeType == NodeType.projectStep) return SessionAccolade.making;
  final tapped = session.challenges.any(
    (c) =>
        c.kind == ChallengeKind.musicImitate &&
        session.attempts.any(
          (a) =>
              a.challengeId == c.id &&
              a.outcome == FeedbackState.correct &&
              a.response['accessible'] != true &&
              a.response['taps'] is List,
        ),
  );
  if (tapped) return SessionAccolade.listening;
  if (assessedCount == 0) return SessionAccolade.reflection;
  return SessionAccolade.consistency;
}
