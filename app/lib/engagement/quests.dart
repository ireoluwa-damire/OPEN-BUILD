import '../models.dart';

/// One daily quest's progress (GAM-04).
class QuestProgress {
  final String id, title;
  final int value, target;
  const QuestProgress(this.id, this.title, this.value, this.target);
  bool get done => value >= target;
}

/// GAM-04: three daily quests derived from saved sessions only (never widget
/// counters). They refresh at local midnight. Each is worth +10 points and
/// all three open a chest of +5 sparks (AMB-03, no randomness). Missing a
/// quest never touches evidence.
class DailyQuests {
  static const questPoints = 10;
  static const chestSparks = 5;

  final String day;
  final List<QuestProgress> quests;
  const DailyQuests(this.day, this.quests);

  bool get allDone => quests.every((q) => q.done);
  int get doneCount => quests.where((q) => q.done).length;

  static String rewardKey(String day, String questId) => 'quest:$day:$questId';

  factory DailyQuests.of(LearningState s, DateTime now) {
    final day = EngagementState.dayKey(now);
    var lessons = 0, firstTry = 0, ms = 0;
    var project = false;
    for (final raw in s.sessions.values) {
      if (raw is! Map) continue;
      final attempts = (raw['attempts'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final todays = attempts.where((a) {
        final at = DateTime.tryParse(a['recordedAt'] as String? ?? '');
        return at != null && EngagementState.dayKey(at.toLocal()) == day;
      }).toList();
      if (todays.isEmpty) continue;
      ms += raw['elapsedMilliseconds'] as int? ?? 0;
      if (raw['result'] != null) {
        lessons++;
        final node = s.completed.contains(raw['nodeId'])
            ? raw['nodeId'] as String?
            : null;
        if (node != null &&
            ((raw['challenges'] as List? ?? const []).any(
              (c) => c is Map && c['kind'] == 'projectReflection',
            ))) {
          project = true;
        }
      }
      final seen = <String>{};
      for (final a in todays) {
        final id = a['challengeId'] as String? ?? '';
        if (id.contains('~repair') || !seen.add(id)) continue;
        final firstEver = attempts.firstWhere((x) => x['challengeId'] == id);
        if (!identical(firstEver, a)) continue;
        final response = a['response'] as Map? ?? const {};
        if (a['outcome'] == 'correct' &&
            response['usedHint'] != true &&
            response['skipped'] != true) {
          firstTry++;
        }
      }
    }
    final minutes = (ms / 60000).floor();
    final goal = s.dailyMinutes;
    return DailyQuests(day, [
      QuestProgress('lesson', 'Complete one lesson', lessons.clamp(0, 1), 1),
      QuestProgress(
        'first_try',
        'Answer three challenges without a hint on the first try',
        firstTry.clamp(0, 3),
        3,
      ),
      QuestProgress(
        'time',
        'Spend $goal minutes learning, or complete one project step',
        project ? goal : minutes.clamp(0, goal),
        goal,
      ),
    ]);
  }

  /// Adds the rewards earned so far today. Idempotent: each quest and the
  /// chest pay once per day. Called inside a transaction.
  static void award(LearningState s, DateTime now) {
    final q = DailyQuests.of(s, now);
    for (final quest in q.quests.where((x) => x.done)) {
      s.engagement.addReward(
        rewardKey(q.day, quest.id),
        questPoints,
        0,
        rewardType: 'quest',
      );
    }
    if (q.allDone) {
      s.engagement.addReward(
        rewardKey(q.day, 'chest'),
        0,
        chestSparks,
        rewardType: 'quest_chest',
      );
    }
  }
}
