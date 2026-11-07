import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/engagement/quests.dart';
import 'package:sumi/models.dart';

/// GAM-04: progress is derived from saved sessions; rewards pay once a day.
void main() {
  Map<String, dynamic> session(String id, DateTime at, List<Map<String, dynamic>> attempts, {bool done = true, int ms = 300000}) => {
    'sessionId': id,
    'nodeId': 'n',
    'elapsedMilliseconds': ms,
    'challenges': <Map<String, dynamic>>[],
    'result': done ? {'pointsAwarded': 0} : null,
    'attempts': [
      for (var i = 0; i < attempts.length; i++)
        {'recordedAt': at.toIso8601String(), ...attempts[i]},
    ],
  };
  Map<String, dynamic> a(String c, String outcome, [Map<String, dynamic> r = const {}]) =>
      {'challengeId': c, 'outcome': outcome, 'response': r};

  test('quests derive from today\'s sessions and refresh at midnight', () {
    final today = DateTime(2026, 11, 1, 10);
    final s = LearningState(trackId: 'music', dailyMinutes: 10);
    s.sessions['s1'] = session('s1', today, [
      a('x', 'correct'),
      a('y', 'correct', {'usedHint': true}),
      a('z', 'incorrect'),
      a('z', 'correct'),
      a('w', 'correct'),
      a('v', 'correct'),
    ], ms: 11 * 60000);
    final q = DailyQuests.of(s, today);
    expect(q.quests.map((x) => x.done), [true, true, true]);
    expect(q.allDone, isTrue);
    final tomorrow = DailyQuests.of(s, today.add(const Duration(days: 1)));
    expect(tomorrow.doneCount, 0);
  });

  test('rewards pay once per quest and the chest once per day', () {
    final today = DateTime(2026, 11, 1, 10);
    EngagementState.clock = () => today;
    addTearDown(() => EngagementState.clock = DateTime.now);
    final s = LearningState(trackId: 'music', dailyMinutes: 5);
    s.sessions['s1'] = session('s1', today, [a('x', 'correct'), a('y', 'correct'), a('z', 'correct')]);
    DailyQuests.award(s, today);
    DailyQuests.award(s, today);
    expect(s.engagement.pointsTotal, 30);
    expect(s.engagement.sparksBalance, 5);
    expect(s.demonstrated, isEmpty);
  });

  test('missing quests never block anything or change evidence', () {
    final s = LearningState(trackId: 'music');
    DailyQuests.award(s, DateTime(2026, 11, 1));
    expect(s.engagement.rewardTransactions, isEmpty);
    expect(s.completed, isEmpty);
  });
}
