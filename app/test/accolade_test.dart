import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/learning_session/learning_session_state.dart';
import 'package:sumi/models.dart';
import 'package:sumi/session_result/accolade_resolver.dart';
import 'package:sumi/session_result/session_result.dart';

/// RES-02.
void main() {
  final select = ChallengeDefinition(id: 'a', kind: ChallengeKind.singleSelect, prompt: 'P', explanation: 'E', options: ['x', 'y'], answer: [0]);
  final repair = ChallengeDefinition(id: 'a~repair', kind: ChallengeKind.singleSelect, prompt: 'P', explanation: 'E', options: ['x', 'y'], answer: [0], content: {'repair_of': 'a'});
  final tap = ChallengeDefinition(id: 't', kind: ChallengeKind.musicImitate, prompt: 'Tap', explanation: 'E');
  final reflect = ChallengeDefinition(id: 'r', kind: ChallengeKind.typedReflection, prompt: 'R', explanation: 'E');

  GradedAttempt at(String id, FeedbackState o, [Json r = const {}]) => GradedAttempt(
    id: id, challengeId: id, response: r, outcome: o, reason: '', recordedAt: DateTime(2026),
  );
  LearningSessionState s(List<ChallengeDefinition> c, List<GradedAttempt> a) =>
      LearningSessionState(sessionId: 's', goalId: 'g', unitId: 'u', nodeId: 'n', challenges: c, attempts: a);

  test('rules in order', () {
    expect(
      resolveAccolade(session: s([select], [at('a', FeedbackState.correct)]), nodeType: NodeType.microLesson, assessedCount: 1, firstAttemptAccuracy: 1),
      SessionAccolade.accuracy,
    );
    expect(
      resolveAccolade(
        session: s([select, repair], [at('a', FeedbackState.incorrect), at('a~repair', FeedbackState.correct)]),
        nodeType: NodeType.microLesson, assessedCount: 1, firstAttemptAccuracy: 0),
      SessionAccolade.recovery,
    );
    expect(
      resolveAccolade(session: s([reflect], [at('r', FeedbackState.correct)]), nodeType: NodeType.projectStep, assessedCount: 0, firstAttemptAccuracy: 0),
      SessionAccolade.making,
    );
    expect(
      resolveAccolade(
        session: s([select, tap], [at('a', FeedbackState.nearCorrect), at('t', FeedbackState.correct, {'taps': [0, 1, 2, 3, 4]})]),
        nodeType: NodeType.microLesson, assessedCount: 2, firstAttemptAccuracy: .5),
      SessionAccolade.listening,
    );
    expect(
      resolveAccolade(session: s([reflect], [at('r', FeedbackState.correct)]), nodeType: NodeType.microLesson, assessedCount: 0, firstAttemptAccuracy: 0),
      SessionAccolade.reflection,
    );
    expect(
      resolveAccolade(session: s([select], [at('a', FeedbackState.nearCorrect)]), nodeType: NodeType.microLesson, assessedCount: 1, firstAttemptAccuracy: 0),
      SessionAccolade.consistency,
    );
  });
}
