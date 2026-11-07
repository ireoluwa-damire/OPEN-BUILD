import 'package:flutter/material.dart';
import '../design_system/motion.dart';
import '../mascot/sumi_mascot.dart';
import '../theme.dart';
import 'challenge_definition.dart';
import 'learning_session_controller.dart';
import 'learning_session_state.dart';

/// Lesson footer (LES-03) and graded feedback panel (LES-04 to LES-07,
/// LES-18). The neutral state holds only CHECK; graded panels rise in its
/// place after the attempt has been persisted.
class FeedbackPanel extends StatelessWidget {
  final LearningSessionController controller;
  final VoidCallback onExplain;
  const FeedbackPanel({
    super.key,
    required this.controller,
    required this.onExplain,
  });

  static String correctHeading(LearningSessionState s) =>
      s.attempts.where((a) => a.outcome == FeedbackState.correct).length.isOdd
      ? 'Correct!'
      : 'Nice work.';

  /// The authored right answer in words (LES-05 "Correct answer:").
  static String? correctAnswerText(ChallengeDefinition c) {
    switch (c.kind) {
      case ChallengeKind.singleSelect:
        return c.answer.isEmpty ? null : c.options[c.answer.single];
      case ChallengeKind.sequenceTokens:
      case ChallengeKind.fashionProcedure:
        return c.answer.map((i) => c.options[i]).join(' → ');
      case ChallengeKind.matchPairs:
        final right = List<String>.from(c.content['right'] as List? ?? []);
        if (right.length != c.options.length) return null;
        return [
          for (var i = 0; i < c.options.length; i++)
            '${c.options[i]} = ${right[c.answer[i]]}',
        ].join(' · ');
      default:
        return null;
    }
  }

  /// Per-part rubric for multi-part answers (LES-06).
  static List<(String, bool)> rubric(ChallengeDefinition c, Map draft) {
    final key = switch (c.kind) {
      ChallengeKind.matchPairs => 'pairs',
      ChallengeKind.sequenceTokens || ChallengeKind.fashionProcedure => 'order',
      _ => null,
    };
    if (key == null || draft[key] is! List) return const [];
    final actual = List<int>.from(draft[key]);
    if (actual.length != c.answer.length) return const [];
    return [
      for (var i = 0; i < c.answer.length; i++)
        (
          c.kind == ChallengeKind.matchPairs
              ? c.options[i]
              : 'Step ${i + 1}',
          actual[i] == c.answer[i],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final feedback = state.feedbackState;
    final visible = feedback != FeedbackState.hidden;
    final reduced = reduceMotion(
      context,
      learnerSetting: controller.learning.reducedMotion,
    );
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : SumiMotion.sheet,
      switchInCurve: SumiMotion.sheetCurve,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(
          '${state.challenge.id}:${feedback.name}:${controller.error != null}',
        ),
        child: visible || controller.error != null
            ? _graded(context, state, feedback, reduced)
            : _neutral(context, state),
      ),
    );
  }

  Widget _button(
    String label, {
    required VoidCallback? onPressed,
    Color background = SumiColors.primary,
    Color foreground = Colors.white,
    Key? key,
  }) => SizedBox(
    height: 56,
    width: double.infinity,
    child: FilledButton(
      key: key,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: SumiColors.disabled,
        disabledForegroundColor: SumiColors.disabledText,
      ),
      onPressed: controller.busy ? null : onPressed,
      child: Text(controller.busy ? 'SAVING…' : label),
    ),
  );

  Widget _neutral(BuildContext context, LearningSessionState state) {
    final secondary = state.challenge.skippable
        ? 'I DON\'T KNOW YET'
        : state.challenge.kind == ChallengeKind.musicImitate ||
              state.challenge.kind == ChallengeKind.mediaObservation
        ? 'CAN\'T DO THIS NOW'
        : null;
    return Container(
      key: const ValueKey('feedback-panel'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: SumiColors.canvas,
        border: Border(top: BorderSide(color: SumiColors.border, width: 2)),
      ),
      child: Row(
        children: [
          if (secondary != null) ...[
            TextButton(
              onPressed: controller.busy ? null : controller.skip,
              child: Text(
                secondary,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: SumiColors.mutedStrong,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _button(
              state.challenge.kind == ChallengeKind.projectReflection
                  ? 'SAVE EVIDENCE'
                  : 'CHECK',
              onPressed: state.canCheck ? () => controller.submit() : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _graded(
    BuildContext context,
    LearningSessionState state,
    FeedbackState feedback,
    bool reduced,
  ) {
    final t = Theme.of(context).textTheme;
    final error = controller.error;
    final attempt = state.feedbackAttempt;
    final (Color soft, Color ink, Color fill, IconData icon, String heading) =
        error != null
        ? (
            SumiColors.coralSoft,
            SumiColors.errorInk,
            SumiColors.coral,
            Icons.cloud_off_rounded,
            'Not saved yet',
          )
        : switch (feedback) {
            FeedbackState.correct => (
              SumiColors.primarySoft,
              SumiColors.successInk,
              SumiColors.primary,
              Icons.check_rounded,
              correctHeading(state),
            ),
            FeedbackState.incorrect => (
              SumiColors.coralSoft,
              SumiColors.errorInk,
              SumiColors.coral,
              Icons.close_rounded,
              'Not quite yet.',
            ),
            FeedbackState.nearCorrect => (
              SumiColors.amberSoft,
              SumiColors.warningInk,
              SumiColors.amber,
              Icons.drag_handle_rounded,
              'Almost—one part needs work.',
            ),
            _ => (
              SumiColors.skySoft,
              SumiColors.infoInk,
              SumiColors.sky,
              Icons.refresh_rounded,
              'Let\'s try that again.',
            ),
          };
    final reason = error ?? attempt?.reason ?? '';
    final answer = feedback == FeedbackState.incorrect && error == null
        ? correctAnswerText(state.challenge)
        : null;
    final parts = feedback == FeedbackState.nearCorrect && attempt != null
        ? rubric(state.challenge, attempt.response)
        : const <(String, bool)>[];
    final announcement = [
      heading,
      if (answer != null) 'Correct answer: $answer',
      reason,
    ].join(' ');

    final actions = <Widget>[];
    if (error != null) {
      actions.add(
        _button(
          'RETRY SAVE',
          onPressed: () => controller.checkpoint(),
          background: SumiColors.coral,
        ),
      );
    } else {
      switch (feedback) {
        case FeedbackState.correct:
          actions.add(
            _button(
              'CONTINUE',
              onPressed: state.canContinue ? () => controller.advance() : null,
            ),
          );
        case FeedbackState.incorrect:
          actions
            ..add(
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SumiColors.coral, width: 2),
                    foregroundColor: SumiColors.errorInk,
                    backgroundColor: SumiColors.canvas,
                  ),
                  onPressed: controller.busy ? null : onExplain,
                  child: const Text('EXPLAIN MY MISTAKE'),
                ),
              ),
            )
            ..add(const SizedBox(height: 12))
            ..add(
              _button(
                'CONTINUE',
                onPressed: state.canContinue
                    ? () => controller.advance()
                    : null,
                background: SumiColors.coral,
              ),
            );
        case FeedbackState.nearCorrect:
          if (state.canTryAgain) {
            actions.add(
              _button(
                'TRY AGAIN',
                onPressed: () => controller.retry(),
                background: SumiColors.amber,
                foreground: SumiColors.ink,
              ),
            );
          }
          actions.add(
            state.canTryAgain
                ? TextButton(
                    onPressed: controller.busy
                        ? null
                        : () => controller.advance(),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SumiColors.warningInk,
                      ),
                    ),
                  )
                : _button(
                    'CONTINUE',
                    onPressed: () => controller.advance(),
                    background: SumiColors.amber,
                    foreground: SumiColors.ink,
                  ),
          );
        default:
          actions.add(
            _button(
              'TRY AGAIN',
              onPressed: state.canTryAgain ? () => controller.retry() : null,
              background: SumiColors.sky,
            ),
          );
      }
    }

    return Container(
      key: const ValueKey('feedback-panel'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: fill, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: announcement,
                  child: ExcludeSemantics(
                    child: Text(
                      heading,
                      style: t.titleLarge?.copyWith(color: ink),
                    ),
                  ),
                ),
              ),
              if (error == null)
                ExcludeSemantics(
                  child: SumiMascot(
                    key: const ValueKey('feedback-sumi'),
                    anim: switch (feedback) {
                      FeedbackState.correct => SumiAnim.correct,
                      FeedbackState.incorrect => SumiAnim.incorrect,
                      FeedbackState.nearCorrect => SumiAnim.hint,
                      _ => SumiAnim.recover,
                    },
                    replayKey: attempt,
                    size: 52,
                    reducedMotion: reduced,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (answer != null) ...[
                  Text(
                    'Correct answer:',
                    style: t.bodyLarge?.copyWith(color: ink),
                  ),
                  Text(
                    answer,
                    style: t.bodyLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (parts.isNotEmpty) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      for (final (label, ok) in parts)
                        Text(
                          '$label ${ok ? '✓' : '✕'}',
                          style: t.bodyLarge?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (reason.isNotEmpty)
                  Text(reason, style: t.bodyLarge?.copyWith(color: ink)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...actions,
        ],
      ),
    );
  }
}
