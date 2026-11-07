import 'dart:convert';

import '../models.dart';
import '../tutor_system.dart';

/// Result of checking a drafted plan (CUS-02). [steps] is empty when the plan
/// was rejected; [problem] then says why in plain words.
class PlanCheck {
  final List<Json> steps;
  final String? problem;
  const PlanCheck.ok(this.steps) : problem = null;
  const PlanCheck.rejected(this.problem) : steps = const [];
  bool get ok => problem == null;
}

/// CUS-02: drafting and validating a provisional plan for a custom goal.
///
/// The on-device model only proposes step titles. Sumi never invents quiz
/// answer keys or links for a custom goal: every step uses generic authored
/// formats (a reflection, and a project report on the last step), and the
/// plan fails closed when anything looks wrong.
abstract final class CustomPlan {
  static const minSteps = 3, maxSteps = 8;
  static const maxTotalMinutes = 600;

  static const _unsafe = [
    'weapon',
    'explosive',
    'illegal drug',
    'self-harm',
    'poison',
  ];

  /// Topics where Sumi keeps steps to theory and safe practice.
  static const _highRisk = [
    'electrical',
    'wiring',
    'welding',
    'chemistry',
    'firearm',
    'climbing',
    'diving',
    'chainsaw',
  ];

  static bool isHighRisk(String outcome) {
    final o = outcome.toLowerCase();
    return _highRisk.any(o.contains);
  }

  static String prompt(String outcome, int dailyMinutes) {
    final theory = isHighRisk(outcome)
        ? ' This topic can be dangerous: keep every step to theory, safety knowledge and supervised planning; never hands-on risky work.'
        : '';
    return 'Plan small learning steps for this goal: "$outcome". '
        'Reply with JSON only, no other text: '
        '{"steps":[{"title":"...","subtitle":"one sentence","minutes":10,"deliverable":"something small the learner makes or writes"}]}. '
        'Use $minSteps to $maxSteps steps, each 5 to 45 minutes, about $dailyMinutes minutes a day. '
        'No links, no websites, no quiz answers.$theory';
  }

  /// Extracts and validates the first JSON object in [raw]. IDs and
  /// prerequisites are assigned by Sumi (a simple chain), never by the model.
  static PlanCheck parse(String raw, {required String goalId}) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return const PlanCheck.rejected(
        'The model didn’t return a plan Sumi could read.',
      );
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw.substring(start, end + 1));
    } catch (_) {
      return const PlanCheck.rejected(
        'The model didn’t return a plan Sumi could read.',
      );
    }
    final list = decoded is Map ? decoded['steps'] : null;
    if (list is! List) {
      return const PlanCheck.rejected('The plan had no steps.');
    }
    final steps = <Json>[];
    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      if (s is! Map) continue;
      final title = (s['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      steps.add({
        'id': '$goalId-step-${i + 1}',
        'title': title,
        'subtitle': (s['subtitle'] ?? '').toString().trim(),
        'deliverable': (s['deliverable'] ?? '').toString().trim(),
        'minutes': s['minutes'] is int ? s['minutes'] : int.tryParse('${s['minutes']}') ?? 15,
        'prerequisites': [if (steps.isNotEmpty) steps.last['id']],
      });
    }
    return validate(steps);
  }

  /// CUS-02 validator: step count, cycles and unknown prerequisites, workload,
  /// unsafe content and invented links. Fails closed.
  static PlanCheck validate(List<Json> steps) {
    if (steps.length < minSteps || steps.length > maxSteps) {
      return PlanCheck.rejected(
        'A plan needs $minSteps to $maxSteps steps; this one had ${steps.length}.',
      );
    }
    final ids = steps.map((s) => s['id']).toSet();
    if (ids.length != steps.length) {
      return const PlanCheck.rejected('Two steps shared the same ID.');
    }
    for (final s in steps) {
      final text = jsonEncode(s).toLowerCase();
      if (RegExp(r'https?://|www\.|\.com\b|\.org\b').hasMatch(text)) {
        return const PlanCheck.rejected(
          'The plan included a link. Sumi only uses reviewed links.',
        );
      }
      if (_unsafe.any(text.contains)) {
        return const PlanCheck.rejected(
          'Sumi can’t make a plan with unsafe steps.',
        );
      }
    }
    final total = steps.fold<int>(0, (n, s) => n + (s['minutes'] as int));
    if (total > maxTotalMinutes) {
      return const PlanCheck.rejected('The plan was too long for a first route.');
    }
    final graphOk = CustomPlanValidator().validateDraftGraph(
      milestones: steps,
      canonicalResources: const [],
    );
    if (!graphOk) {
      return const PlanCheck.rejected(
        'The plan’s steps or timings didn’t check out.',
      );
    }
    return PlanCheck.ok(steps);
  }

  /// Skills for `Catalog.custom`: generic authored formats only.
  static List<Json> skills(List<Json> steps) => [
    for (var i = 0; i < steps.length; i++)
      {
        ...steps[i],
        'type': i == steps.length - 1 ? 'project_step' : 'micro_lesson',
        'unit_id': 'custom-unit-1',
        'resource_id': '',
        'challenges': [
          {
            'id': 'plan',
            'kind': 'typedReflection',
            'prompt': 'Before you start “${steps[i]['title']}”: what will you try first?',
            'explanation':
                'Writing a first move makes the step concrete. This is your own note, not a graded answer.',
            'content': {'task': steps[i]['deliverable'] ?? ''},
          },
          if (i == steps.length - 1)
            {
              'id': 'project',
              'kind': 'projectReflection',
              'prompt': 'Report on what you made for “${steps[i]['title']}”.',
              'explanation':
                  'Your project report is saved as your own evidence. Sumi does not verify it.',
              'content': {'task': steps[i]['deliverable'] ?? ''},
            }
          else
            {
              'id': 'reflect',
              'kind': 'typedReflection',
              'prompt': 'What happened, and what will you change next time?',
              'explanation':
                  'A specific observation gives your next session a starting point.',
              'content': {'task': steps[i]['deliverable'] ?? ''},
            },
        ],
      },
  ];
}
