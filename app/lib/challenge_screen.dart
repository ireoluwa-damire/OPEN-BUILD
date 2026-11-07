import 'learning_session/lesson_shell.dart';

/// Stable route name; behavior belongs to the durable session controller.
class ChallengeScreen extends LessonShell {
  const ChallengeScreen({
    super.key,
    required super.controller,
    required super.onOpenResource,
    super.onAskTutor,
  });
}
