import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/application/use_cases.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/learning_session/learning_session_state.dart';
import 'package:sumi/models.dart';
import 'package:sumi/review/review_scheduler.dart';

/// EVD-01 / EVD-02 / EVD-03.
void main() {
  final catalog = Catalog({
    'id': 'music',
    'title': 'Music',
    'skills': [
      {
        'id': 'n1',
        'title': 'N1',
        'type': 'micro_lesson',
        'challenges': [
          {
            'id': 'a',
            'kind': 'singleSelect',
            'prompt': 'P',
            'explanation': 'E',
            'options': ['x', 'y'],
            'answer': [0],
          },
          {
            'id': 't',
            'kind': 'singleSelect',
            'prompt': 'Transfer',
            'explanation': 'E',
            'options': ['x', 'y'],
            'answer': [1],
            'content': {'context': 'transfer'},
          },
        ],
      },
    ],
  });
  final node = catalog.milestones.single;
  final defs = [
    ChallengeDefinition(id: 'n1:a', kind: ChallengeKind.singleSelect, prompt: 'P', explanation: 'E', options: ['x', 'y'], answer: [0]),
    ChallengeDefinition(id: 'n1:t', kind: ChallengeKind.singleSelect, prompt: 'T', explanation: 'E', options: ['x', 'y'], answer: [1], content: {'context': 'transfer'}),
  ];

  LearningSessionState session(List<(String, FeedbackState, Json)> attempts) =>
      LearningSessionState(
        sessionId: 's1',
        goalId: 'g',
        unitId: 'u',
        nodeId: 'n1',
        challenges: defs,
        currentChallengeIndex: defs.length - 1,
        submissionState: SubmissionState.persisted,
        feedbackState: FeedbackState.correct,
        attempts: [
          for (var i = 0; i < attempts.length; i++)
            GradedAttempt(
              id: 's1:$i',
              challengeId: attempts[i].$1,
              response: attempts[i].$3,
              outcome: attempts[i].$2,
              reason: '',
              recordedAt: DateTime(2026, 11, 1, 9),
            ),
        ],
      );

  setUp(() => EngagementState.clock = () => DateTime(2026, 11, 1, 10));
  tearDown(() => EngagementState.clock = DateTime.now);

  test('first-try, no-hint completion is independent, not transferred', () {
    final s = LearningState(trackId: 'music');
    final saved = session([
      ('n1:a', FeedbackState.correct, {'choice': 0}),
      ('n1:t', FeedbackState.incorrect, {'choice': 0}),
      ('n1:t', FeedbackState.correct, {'choice': 1}),
    ]);
    const CompleteActivity().apply(profile: s, catalog: catalog, saved: saved);
    expect(s.completed, {'n1'});
    expect(s.transferred, isEmpty);
    expect(s.getEvidenceState(node, catalog), isNot(EvidenceState.transferred));
    // A first-try mistake means support, and a next-day review (EVD-03).
    expect(s.getEvidenceState(node, catalog), EvidenceState.supported);
    expect(s.reviewSchedule['n1']!.outcome, 'incorrect');
    expect(s.reviewSchedule['n1']!.dueAt, DateTime(2026, 11, 2));
  });

  test('a hint never counts as independent', () {
    final s = LearningState(trackId: 'music');
    final saved = session([
      ('n1:a', FeedbackState.correct, {'choice': 0, 'usedHint': true}),
      ('n1:t', FeedbackState.correct, {'choice': 1, 'usedHint': true}),
    ]);
    const CompleteActivity().apply(profile: s, catalog: catalog, saved: saved);
    expect(s.demonstrated, isEmpty);
    expect(s.getEvidenceState(node, catalog), EvidenceState.supported);
    expect(s.reviewSchedule['n1']!.outcome, 'hinted');
  });

  test('a first-try pass on a transfer challenge is transferred', () {
    final s = LearningState(trackId: 'music');
    final saved = session([
      ('n1:a', FeedbackState.correct, {'choice': 0}),
      ('n1:t', FeedbackState.correct, {'choice': 1}),
    ]);
    const CompleteActivity().apply(profile: s, catalog: catalog, saved: saved);
    expect(s.demonstrated, {'n1'});
    expect(s.transferred, {'n1'});
    expect(s.getEvidenceState(node, catalog), EvidenceState.transferred);
    expect(s.reviewSchedule['n1']!.dueAt, DateTime(2026, 11, 11));
  });

  test('a due review shows needsReview without erasing evidence', () {
    final s = LearningState(trackId: 'music');
    s.completed.add('n1');
    s.demonstrated.add('n1');
    s.reviewSchedule['n1'] = ReviewScheduler.schedule(
      nodeId: 'n1',
      outcome: 'independent',
      now: DateTime(2026, 10, 28),
    );
    expect(s.getEvidenceState(node, catalog), EvidenceState.needsReview);
    expect(s.demonstrated, {'n1'});
  });

  test('scheduler intervals and pull-forward', () {
    final now = DateTime(2026, 11, 1, 15);
    for (final e in {'incorrect': 1, 'hinted': 1, 'independent': 2, 'recalled': 5, 'transferred': 10}.entries) {
      final r = ReviewScheduler.schedule(nodeId: 'n', outcome: e.key, now: now);
      expect(r.dueAt, DateTime(2026, 11, 1 + e.value), reason: e.key);
      expect(r.reason, isNotEmpty);
    }
    final earlier = ReviewScheduler.schedule(nodeId: 'n', outcome: 'incorrect', now: DateTime(2026, 10, 30));
    final after = ReviewScheduler.schedule(nodeId: 'n', outcome: 'incorrect', now: now, previous: earlier);
    expect(after.dueAt, earlier.dueAt);
    expect(ReviewScheduler.dueItems({'n': earlier}, now), hasLength(1));
  });
}
