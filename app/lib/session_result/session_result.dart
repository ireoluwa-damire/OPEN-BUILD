import '../models.dart' show Json;

enum SessionAccolade {
  consistency,
  accuracy,
  recovery,
  listening,
  making,
  reflection,
}

class SessionResult {
  final String sessionId, completedNode, celebrationType;
  final String? unlockedNode;
  final Duration duration;
  final int correctCount,
      incorrectCount,
      nearCorrectCount,
      retryCount,
      pointsAwarded;
  final double firstAttemptAccuracy;
  final SessionAccolade accolade;
  final Json evidencePayload;

  /// RES-01 "Today" row and Next card, captured at completion so the screen
  /// reads only this result. Null for results saved before schema v4.
  final int? streakDays, minutesToday, dailyGoal;
  final bool streakExtended;
  final String? nextNodeId, nextNodeTitle;
  SessionResult({
    required this.sessionId,
    required this.duration,
    required this.correctCount,
    required this.incorrectCount,
    required this.nearCorrectCount,
    required this.retryCount,
    required this.firstAttemptAccuracy,
    required this.pointsAwarded,
    required this.completedNode,
    this.unlockedNode,
    required this.accolade,
    required this.celebrationType,
    required this.evidencePayload,
    this.streakDays,
    this.minutesToday,
    this.dailyGoal,
    this.streakExtended = false,
    this.nextNodeId,
    this.nextNodeTitle,
  });

  SessionResult withToday({
    required int streakDays,
    required int minutesToday,
    required int dailyGoal,
    required bool streakExtended,
    String? nextNodeId,
    String? nextNodeTitle,
  }) => SessionResult(
    sessionId: sessionId,
    duration: duration,
    correctCount: correctCount,
    incorrectCount: incorrectCount,
    nearCorrectCount: nearCorrectCount,
    retryCount: retryCount,
    firstAttemptAccuracy: firstAttemptAccuracy,
    pointsAwarded: pointsAwarded,
    completedNode: completedNode,
    unlockedNode: unlockedNode,
    accolade: accolade,
    celebrationType: celebrationType,
    evidencePayload: evidencePayload,
    streakDays: streakDays,
    minutesToday: minutesToday,
    dailyGoal: dailyGoal,
    streakExtended: streakExtended,
    nextNodeId: nextNodeId,
    nextNodeTitle: nextNodeTitle,
  );
  Json toJson() => {
    'sessionId': sessionId,
    'duration': duration.inMilliseconds,
    'correctCount': correctCount,
    'incorrectCount': incorrectCount,
    'nearCorrectCount': nearCorrectCount,
    'retryCount': retryCount,
    'firstAttemptAccuracy': firstAttemptAccuracy,
    'pointsAwarded': pointsAwarded,
    'completedNode': completedNode,
    'unlockedNode': unlockedNode,
    'accolade': accolade.name,
    'celebrationType': celebrationType,
    'evidencePayload': evidencePayload,
    'streakDays': streakDays,
    'minutesToday': minutesToday,
    'dailyGoal': dailyGoal,
    'streakExtended': streakExtended,
    'nextNodeId': nextNodeId,
    'nextNodeTitle': nextNodeTitle,
  };
  factory SessionResult.fromJson(Json j) => SessionResult(
    sessionId: j['sessionId'],
    duration: Duration(milliseconds: j['duration']),
    correctCount: j['correctCount'],
    incorrectCount: j['incorrectCount'],
    nearCorrectCount: j['nearCorrectCount'],
    retryCount: j['retryCount'],
    firstAttemptAccuracy: (j['firstAttemptAccuracy'] as num).toDouble(),
    pointsAwarded: j['pointsAwarded'],
    completedNode: j['completedNode'],
    unlockedNode: j['unlockedNode'],
    accolade: SessionAccolade.values.byName(j['accolade']),
    celebrationType: j['celebrationType'],
    evidencePayload: Json.from(j['evidencePayload']),
    streakDays: j['streakDays'],
    minutesToday: j['minutesToday'],
    dailyGoal: j['dailyGoal'],
    streakExtended: j['streakExtended'] ?? false,
    nextNodeId: j['nextNodeId'],
    nextNodeTitle: j['nextNodeTitle'],
  );
}
