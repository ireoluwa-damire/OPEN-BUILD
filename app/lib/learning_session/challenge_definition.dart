import '../models.dart';

enum ChallengeKind {
  singleSelect,
  sequenceTokens,
  matchPairs,
  typedReflection,
  mediaObservation,
  musicImitate,
  fashionProcedure,
  drawing,
  projectReflection,
}

enum FeedbackState { hidden, correct, incorrect, nearCorrect, retry }

class Grade {
  final FeedbackState outcome;
  final String reason;
  const Grade(this.outcome, this.reason);
}

/// Content and grading live outside renderers. Definitions are saved with a
/// session so an interrupted lesson survives later catalogue changes.
class ChallengeDefinition {
  /// LES-21 project evidence fields, each at least 12 characters.
  static const projectFields = ['made', 'happened', 'change'];
  static const projectLabels = [
    'What did you make or try?',
    'What happened? One observation',
    'What will you change next time?',
  ];

  final String id, prompt, explanation;
  final ChallengeKind kind;
  final List<String> options;
  final List<int> answer;
  final Json content;
  ChallengeDefinition({
    required this.id,
    required this.kind,
    required this.prompt,
    required this.explanation,
    List<String> options = const [],
    List<int> answer = const [],
    Json content = const {},
  }) : options = List.unmodifiable(options),
       answer = List.unmodifiable(answer),
       content = Map.unmodifiable(content);

  bool valid(Json draft) => switch (kind) {
    ChallengeKind.singleSelect =>
      draft['choice'] is int &&
          (draft['choice'] as int) >= 0 &&
          (draft['choice'] as int) < options.length,
    ChallengeKind.sequenceTokens || ChallengeKind.fashionProcedure =>
      _permutation(draft['order'], options.length),
    ChallengeKind.matchPairs => _permutation(draft['pairs'], options.length),
    ChallengeKind.typedReflection =>
      (draft['text'] as String? ?? '').trim().length >= 12,
    ChallengeKind.mediaObservation =>
      draft['observed'] == true &&
          (draft['text'] as String? ?? '').trim().length >= 12,
    ChallengeKind.musicImitate =>
      draft['retry'] == true || (draft['taps'] as List? ?? []).length == 5,
    ChallengeKind.drawing =>
      (draft['points'] as List? ?? []).length >= 3 &&
          (draft['text'] as String? ?? '').trim().length >= 5,
    ChallengeKind.projectReflection => projectFields.every(
      (f) => (draft[f] as String? ?? '').trim().length >= 12,
    ),
  };

  /// Optional authored hint (LES-16).
  String? get hint => content['hint'] as String?;

  /// Whether the learner may skip with "I don't know yet" (LES-16).
  bool get skippable => content['skippable'] == true;

  /// Self-reported kinds never count as independent evidence.
  bool get selfReported =>
      kind == ChallengeKind.typedReflection ||
      kind == ChallengeKind.mediaObservation ||
      kind == ChallengeKind.drawing ||
      kind == ChallengeKind.projectReflection;

  static bool _permutation(dynamic value, int length) =>
      value is List &&
      value.length == length &&
      value.toSet().length == length &&
      value.every((v) => v is int && v >= 0 && v < length);

  Grade grade(Json draft) {
    if (!valid(draft)) {
      return const Grade(FeedbackState.retry, 'Add a response first.');
    }
    if (kind == ChallengeKind.musicImitate) {
      if (draft['retry'] == true) {
        return const Grade(
          FeedbackState.retry,
          'Take your time. Watch the beat again, or use the accessible count option.',
        );
      }
      if (draft['accessible'] == true) {
        return const Grade(
          FeedbackState.correct,
          'Count practice recorded as self-reported evidence; timing was not assessed.',
        );
      }
      final taps = List<num>.from(draft['taps']);
      final gaps = List.generate(4, (i) => taps[i + 1] - taps[i]);
      final mean = gaps.reduce((a, b) => a + b) / 4;
      if (mean <= 0 || mean > 4000) {
        return const Grade(
          FeedbackState.retry,
          'Reset and tap five steady beats.',
        );
      }
      final spread =
          gaps.map((g) => (g - mean).abs()).reduce((a, b) => a + b) / 4 / mean;
      return Grade(
        spread <= .18 ? FeedbackState.correct : FeedbackState.nearCorrect,
        spread <= .18
            ? 'Your tap intervals stayed close to one another. This measures screen taps, not an audio performance.'
            : 'You kept five beats. Make the spaces between taps more even.',
      );
    }
    if (kind == ChallengeKind.projectReflection) {
      return const Grade(
        FeedbackState.correct,
        'Project evidence saved as your own report. Sumi does not independently verify the finished work.',
      );
    }
    if (kind == ChallengeKind.typedReflection ||
        kind == ChallengeKind.mediaObservation ||
        kind == ChallengeKind.drawing) {
      return const Grade(
        FeedbackState.correct,
        'Evidence saved as your own observation. This is not an independent assessment of practical skill.',
      );
    }
    final actual = kind == ChallengeKind.singleSelect
        ? [draft['choice'] as int]
        : List<int>.from(
            draft[kind == ChallengeKind.matchPairs ? 'pairs' : 'order'],
          );
    final matches = List.generate(
      answer.length,
      (i) => actual[i] == answer[i],
    ).where((v) => v).length;
    return Grade(
      matches == answer.length
          ? FeedbackState.correct
          : matches > 0 && answer.length > 1
          ? FeedbackState.nearCorrect
          : FeedbackState.incorrect,
      explanation,
    );
  }

  Json toJson() => {
    'id': id,
    'kind': kind.name,
    'prompt': prompt,
    'explanation': explanation,
    'options': options,
    'answer': answer,
    'content': content,
  };
  factory ChallengeDefinition.fromJson(Json j) => ChallengeDefinition(
    id: j['id'],
    kind: ChallengeKind.values.byName(j['kind']),
    prompt: j['prompt'],
    explanation: j['explanation'],
    options: List<String>.from(j['options']),
    answer: List<int>.from(j['answer']),
    content: Json.from(j['content']),
  );
}

/// ARC-04 / ARC-05 / LES-15: a pure loader. Each node's challenges come from
/// `skills[].challenges` in the content data; IDs are namespaced by node so
/// saved attempts never collide across nodes. There is no discipline branch.
///
/// Legacy fallback (content without authored challenges, such as an older
/// catalogue): the node's authored concept question, then a resource
/// observation and a reflection. Nothing is invented: no answer keys are made
/// up for content that has none.
List<ChallengeDefinition> challengesFor(Catalog catalog, Milestone node) {
  if (node.challenges.isNotEmpty) {
    return [
      for (final raw in node.challenges)
        ChallengeDefinition.fromJson({
          'options': const <String>[],
          'answer': const <int>[],
          'content': const <String, dynamic>{},
          ...raw,
          'id': '${node.id}:${raw['id']}',
        }),
    ];
  }
  final lesson = node.lesson;
  return [
    if (lesson != null &&
        lesson['options'] is List &&
        lesson['correct'] is int &&
        lesson['prompt'] is String)
      ChallengeDefinition(
        id: '${node.id}:concept',
        kind: ChallengeKind.singleSelect,
        prompt: lesson['prompt'],
        explanation: lesson['explanation'] ?? '',
        options: List<String>.from(lesson['options']),
        answer: [lesson['correct']],
        content: {
          if (lesson['hint'] is String) 'hint': lesson['hint'],
          'skippable': true,
        },
      ),
    if (node.resourceId.isNotEmpty &&
        catalog.resource(node.resourceId) != null)
      ChallengeDefinition(
        id: '${node.id}:observe',
        kind: ChallengeKind.mediaObservation,
        prompt: 'Study the reference. What will you look for in your own work?',
        explanation: 'Connect an observation to the project you want to make.',
        content: {
          'reference': lesson?['example'] ?? node.subtitle,
          'resourceId': node.resourceId,
        },
      ),
    ChallengeDefinition(
      id: '${node.id}:reflect',
      kind: ChallengeKind.typedReflection,
      prompt: 'What did you try, notice, and want to change next?',
      explanation:
          'A specific observation gives your next practice session a useful starting point.',
      content: {'task': lesson?['task'] ?? node.deliverable},
    ),
  ];
}
