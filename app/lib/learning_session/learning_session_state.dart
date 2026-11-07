import 'dart:convert';
import '../models.dart';
import 'challenge_definition.dart';

enum SubmissionState { idle, grading, persisted, failedToPersist }

enum ExplanationState { closed, authored, localAI, cloudAI }

enum SessionExitState { none, confirm, ending }

enum SessionLifecycleState { foreground, backgrounded, restoring }

dynamic _freeze(dynamic value) => value is Map
    ? Map<String, dynamic>.unmodifiable(
        value.map((k, v) => MapEntry(k as String, _freeze(v))),
      )
    : value is List
    ? List<dynamic>.unmodifiable(value.map(_freeze))
    : value;
Json immutableJson(Json value) =>
    _freeze(jsonDecode(jsonEncode(value))) as Json;

class GradedAttempt {
  final String id, challengeId, reason;
  final Json response;
  final FeedbackState outcome;
  final DateTime recordedAt;
  GradedAttempt({
    required this.id,
    required this.challengeId,
    required Json response,
    required this.outcome,
    required this.reason,
    required this.recordedAt,
  }) : response = immutableJson(response);
  Json toJson() => {
    'id': id,
    'challengeId': challengeId,
    'response': response,
    'outcome': outcome.name,
    'reason': reason,
    'recordedAt': recordedAt.toIso8601String(),
  };
  factory GradedAttempt.fromJson(Json j) => GradedAttempt(
    id: j['id'],
    challengeId: j['challengeId'],
    response: Json.from(j['response']),
    outcome: FeedbackState.values.byName(j['outcome']),
    reason: j['reason'],
    recordedAt: DateTime.parse(j['recordedAt']),
  );
}

class LearningSessionState {
  final String sessionId, goalId, unitId, nodeId;
  final List<ChallengeDefinition> challenges;
  final int currentChallengeIndex, focus, elapsedMilliseconds;
  final Json currentResponseDraft;
  final List<GradedAttempt> attempts;
  final SubmissionState submissionState;
  final FeedbackState feedbackState;
  final ExplanationState explanationState;
  final bool settingsOpen, resultAcknowledged;
  final SessionExitState exitState;
  final SessionLifecycleState lifecycleState;
  final Json? result;

  LearningSessionState({
    required this.sessionId,
    required this.goalId,
    required this.unitId,
    required this.nodeId,
    required List<ChallengeDefinition> challenges,
    this.currentChallengeIndex = 0,
    this.focus = 5,
    this.elapsedMilliseconds = 0,
    Json currentResponseDraft = const {},
    List<GradedAttempt> attempts = const [],
    this.submissionState = SubmissionState.idle,
    this.feedbackState = FeedbackState.hidden,
    this.explanationState = ExplanationState.closed,
    this.settingsOpen = false,
    this.exitState = SessionExitState.none,
    this.lifecycleState = SessionLifecycleState.foreground,
    this.resultAcknowledged = false,
    Json? result,
  }) : challenges = List.unmodifiable(challenges),
       attempts = List.unmodifiable(attempts),
       currentResponseDraft = immutableJson(currentResponseDraft),
       result = result == null ? null : immutableJson(result);

  List<String> get orderedChallengeIds =>
      challenges.map((c) => c.id).toList(growable: false);
  /// A requeued copy of an earlier challenge (LES-05). Never counted in progress.
  static bool isRepair(ChallengeDefinition c) => c.content['repair_of'] is String;

  /// Only the original challenges count toward lesson progress (LES-05).
  int get originalCount => challenges.where((c) => !isRepair(c)).length;

  /// Originals the learner has moved past, plus the current one once it can
  /// be continued. Persisted state only, so it never runs ahead of storage.
  int get persistedProgress {
    var passed = 0;
    for (var i = 0; i < challenges.length; i++) {
      if (isRepair(challenges[i])) continue;
      if (i < currentChallengeIndex || (i == currentChallengeIndex && canContinue)) {
        passed++;
      }
    }
    return passed;
  }

  ChallengeDefinition get challenge => challenges[currentChallengeIndex];
  GradedAttempt? get feedbackAttempt =>
      attempts.where((a) => a.challengeId == challenge.id).lastOrNull;
  List<GradedAttempt> attemptsFor(String challengeId) =>
      attempts.where((a) => a.challengeId == challengeId).toList();
  bool get canCheck =>
      submissionState != SubmissionState.grading &&
      feedbackState == FeedbackState.hidden &&
      challenge.valid(currentResponseDraft);

  /// Correct and incorrect continue (CF-05). Near-correct may continue at once
  /// (the item is requeued) or revise once. Ungraded retry must try again.
  bool get canContinue =>
      submissionState == SubmissionState.persisted &&
      (feedbackState == FeedbackState.correct ||
          feedbackState == FeedbackState.incorrect ||
          feedbackState == FeedbackState.nearCorrect);

  /// Near-correct allows exactly one revision (LES-06); retry always may.
  bool get canTryAgain =>
      submissionState == SubmissionState.persisted &&
      (feedbackState == FeedbackState.retry ||
          (feedbackState == FeedbackState.nearCorrect &&
              attemptsFor(challenge.id)
                      .where((a) => a.outcome == FeedbackState.nearCorrect)
                      .length <
                  2));

  LearningSessionState copyWith({
    List<ChallengeDefinition>? challenges,
    int? currentChallengeIndex,
    int? focus,
    int? elapsedMilliseconds,
    Json? currentResponseDraft,
    List<GradedAttempt>? attempts,
    SubmissionState? submissionState,
    FeedbackState? feedbackState,
    ExplanationState? explanationState,
    bool? settingsOpen,
    SessionExitState? exitState,
    SessionLifecycleState? lifecycleState,
    bool? resultAcknowledged,
    Json? result,
  }) => LearningSessionState(
    sessionId: sessionId,
    goalId: goalId,
    unitId: unitId,
    nodeId: nodeId,
    challenges: challenges ?? this.challenges,
    currentChallengeIndex: currentChallengeIndex ?? this.currentChallengeIndex,
    focus: focus ?? this.focus,
    elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
    currentResponseDraft: currentResponseDraft ?? this.currentResponseDraft,
    attempts: attempts ?? this.attempts,
    submissionState: submissionState ?? this.submissionState,
    feedbackState: feedbackState ?? this.feedbackState,
    explanationState: explanationState ?? this.explanationState,
    settingsOpen: settingsOpen ?? this.settingsOpen,
    exitState: exitState ?? this.exitState,
    lifecycleState: lifecycleState ?? this.lifecycleState,
    resultAcknowledged: resultAcknowledged ?? this.resultAcknowledged,
    result: result ?? this.result,
  );

  Json toJson() => {
    'sessionId': sessionId,
    'goalId': goalId,
    'unitId': unitId,
    'nodeId': nodeId,
    'challenges': challenges.map((c) => c.toJson()).toList(),
    'currentChallengeIndex': currentChallengeIndex,
    'focus': focus,
    'elapsedMilliseconds': elapsedMilliseconds,
    'draft': currentResponseDraft,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'submissionState': submissionState.name,
    'feedbackState': feedbackState.name,
    'explanationState': explanationState.name,
    'settingsOpen': settingsOpen,
    'exitState': exitState.name,
    'lifecycleState': lifecycleState.name,
    'resultAcknowledged': resultAcknowledged,
    'result': result,
  };

  factory LearningSessionState.fromJson(Json j) => LearningSessionState(
    sessionId: j['sessionId'],
    goalId: j['goalId'],
    unitId: j['unitId'],
    nodeId: j['nodeId'],
    challenges: (j['challenges'] as List)
        .map((c) => ChallengeDefinition.fromJson(Json.from(c)))
        .toList(),
    currentChallengeIndex: j['currentChallengeIndex'],
    focus: j['focus'],
    elapsedMilliseconds: j['elapsedMilliseconds'],
    currentResponseDraft: Json.from(j['draft']),
    attempts: (j['attempts'] as List)
        .map((a) => GradedAttempt.fromJson(Json.from(a)))
        .toList(),
    submissionState: SubmissionState.values.byName(j['submissionState']),
    feedbackState: FeedbackState.values.byName(j['feedbackState']),
    explanationState: ExplanationState.values.byName(j['explanationState']),
    settingsOpen: j['settingsOpen'],
    exitState: SessionExitState.values.byName(j['exitState']),
    lifecycleState: SessionLifecycleState.values.byName(j['lifecycleState']),
    resultAcknowledged: j['resultAcknowledged'] ?? false,
    result: j['result'] == null ? null : Json.from(j['result']),
  );
}
