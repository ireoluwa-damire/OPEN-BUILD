import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/custom/custom_plan.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/models.dart';

/// CUS-02: drafted plans are validated and fail closed.
void main() {
  const good =
      'Sure! {"steps":[{"title":"Learn the parts of a pot","subtitle":"Names","minutes":15,"deliverable":"A labelled sketch"},'
      '{"title":"Wedge clay","subtitle":"Prepare","minutes":20,"deliverable":"Two wedged balls"},'
      '{"title":"Pinch a small pot","subtitle":"Make","minutes":30,"deliverable":"One pinch pot"}]}';

  test('a sensible draft becomes a chained plan with generic formats only', () {
    final check = CustomPlan.parse(good, goalId: 'custom_1');
    expect(check.ok, isTrue);
    expect(check.steps.map((s) => s['id']), ['custom_1-step-1', 'custom_1-step-2', 'custom_1-step-3']);
    expect(check.steps[1]['prerequisites'], ['custom_1-step-1']);
    final catalog = Catalog.custom(
      OnboardingState(outcome: 'Throw a small pot'),
      id: 'custom_1',
      skills: CustomPlan.skills(check.steps),
    );
    expect(catalog.milestones, hasLength(3));
    expect(catalog.milestones.last.type, NodeType.projectStep);
    for (final m in catalog.milestones) {
      for (final d in challengesFor(catalog, m)) {
        // No invented answer keys for a custom goal.
        expect(d.answer, isEmpty);
        expect(d.selfReported, isTrue);
      }
    }
  });

  test('links, unsafe steps, bad sizes and unreadable output are rejected', () {
    expect(CustomPlan.parse('no json here', goalId: 'g').ok, isFalse);
    expect(CustomPlan.parse('{"steps":[{"title":"Only one","minutes":10}]}', goalId: 'g').ok, isFalse);
    expect(
      CustomPlan.parse(good.replaceFirst('Names', 'See https://example.org'), goalId: 'g').ok,
      isFalse,
    );
    expect(CustomPlan.parse(good.replaceFirst('Wedge clay', 'Build a weapon'), goalId: 'g').ok, isFalse);
    expect(CustomPlan.parse(good.replaceFirst('"minutes":30', '"minutes":300'), goalId: 'g').ok, isFalse);
  });

  test('high-risk topics are narrowed to theory in the prompt', () {
    expect(CustomPlan.isHighRisk('Do my own electrical wiring'), isTrue);
    expect(CustomPlan.prompt('Do my own electrical wiring', 10), contains('theory'));
    expect(CustomPlan.prompt('Bake bread', 10), isNot(contains('theory')));
  });
}
