import '../models.dart';
import '../learning_session/learning_session_state.dart';
import '../learning_session/challenge_definition.dart';
import 'accolade_resolver.dart';
import 'session_result.dart';

SessionResult assembleSessionResult(
  LearningSessionState session,
  Catalog catalog, {
  required int points,
  String? unlockedNode,
}) {
  if (session.persistedProgress != session.originalCount) {
    throw StateError('Incomplete sessions cannot produce completion results.');
  }
  int count(FeedbackState value) =>
      session.attempts.where((a) => a.outcome == value).length;
  final assessed = session.challenges
      .where(
        (c) =>
            !LearningSessionState.isRepair(c) &&
            c.kind != ChallengeKind.typedReflection &&
            c.kind != ChallengeKind.projectReflection &&
            c.kind != ChallengeKind.drawing &&
            c.kind != ChallengeKind.mediaObservation &&
            (c.kind != ChallengeKind.musicImitate ||
                session.attempts.any(
                  (a) =>
                      a.challengeId == c.id &&
                      a.response['accessible'] != true &&
                      a.response['taps'] is List,
                )),
      )
      .toList();
  final firstCorrect = assessed
      .where(
        (c) {
          final first = session.attempts.firstWhere(
            (a) => a.challengeId == c.id,
          );
          return first.outcome == FeedbackState.correct &&
              first.response['usedHint'] != true;
        },
      )
      .length;
  final accuracy = assessed.isEmpty ? 0.0 : firstCorrect / assessed.length;
  final evidence = <String, dynamic>{
    'source': 'authored activities and learner reports',
    'independentlyAssessedPracticalSkill': false,
    'attempts': session.attempts.map((a) => a.toJson()).toList(),
    'assessedChallengeCount': assessed.length,
  };
  // ARC-05: discipline nouns, categories and celebration come from data.
  final discipline = catalog.id;
  evidence['categories'] = catalog.evidenceCategories;
  return SessionResult(
    sessionId: session.sessionId,
    duration: Duration(milliseconds: session.elapsedMilliseconds),
    correctCount: count(FeedbackState.correct),
    incorrectCount: count(FeedbackState.incorrect),
    nearCorrectCount: count(FeedbackState.nearCorrect),
    retryCount: count(FeedbackState.retry),
    firstAttemptAccuracy: accuracy,
    pointsAwarded: points,
    completedNode: session.nodeId,
    unlockedNode: unlockedNode,
    accolade: resolveAccolade(
      session: session,
      nodeType: catalog.milestones
              .where((m) => m.id == session.nodeId)
              .firstOrNull
              ?.type ??
          NodeType.microLesson,
      assessedCount: assessed.length,
      firstAttemptAccuracy: accuracy,
    ),
    celebrationType: catalog.celebration,
    evidencePayload: {discipline: evidence},
  );
}
