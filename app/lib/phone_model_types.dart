import 'models.dart';

class PhoneModelChoice {
  final String id,
      name,
      repo,
      file,
      revision,
      sha256,
      license,
      note,
      quantization;
  final int bytes, suggestedRamGb;
  PhoneModelChoice(Json j)
    : id = j['id'],
      name = j['name'],
      repo = j['repo'],
      file = j['file'],
      revision = j['revision'],
      sha256 = j['sha256'],
      license = j['license'],
      note = j['note'],
      quantization = j['quantization'],
      bytes = j['bytes'],
      suggestedRamGb = j['suggested_ram_gb'];
  String get sizeLabel => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(2)} GB'
      : '${(bytes / 1000000).round()} MB';
}

String buildCoachPrompt(Catalog catalog, LearningState state) {
  final next = state.current(catalog);
  return 'Discipline: ${catalog.title}. Learner goal: ${state.goal}. '
      'Available practice: ${state.dailyMinutes} minutes/day. '
      'Latest independent connections: ${state.latestEvidence(catalog).join(', ')}. '
      'Next reviewed exercise: ${next?.title ?? "Reflect on the completed route"}. '
      'Task: ${next?.deliverable ?? catalog.project}. '
      'In two short plain-text sentences, suggest one practical next action '
      'and how to check its result. Stay within this discipline and exercise. '
      'Do not assign a grade, claim mastery, invent resource links, or change the route. '
      'An early two-day check-in is a demo, not proof of long-term retention.';
}
