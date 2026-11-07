import 'package:flutter/material.dart';
import '../theme.dart';
import 'challenge_renderer_registry.dart';
import 'feedback_panel.dart';
import 'learning_session_controller.dart';

/// LES-08: a dedicated explanation that never changes the grade or draft.
class ExplainMistakeScreen extends StatefulWidget {
  final LearningSessionController controller;
  final Future<void> Function() onOpenResource;
  final Future<void> Function(String context)? onAskTutor;
  const ExplainMistakeScreen({
    super.key,
    required this.controller,
    required this.onOpenResource,
    this.onAskTutor,
  });
  @override
  State<ExplainMistakeScreen> createState() => _ExplainMistakeScreenState();
}

class _ExplainMistakeScreenState extends State<ExplainMistakeScreen> {
  String? helpful;
  bool saving = false;

  Future<void> rate(String value) async {
    if (saving || helpful != null) return;
    setState(() => saving = true);
    final ok = await widget.controller.recordLearnerFeedback(
      'explanation_$value',
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) helpful = value;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t save that. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = widget.controller.state;
    final attempt = state.feedbackAttempt;
    final answer = FeedbackPanel.correctAnswerText(state.challenge);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          'Explain my mistake',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(state.challenge.prompt, style: t.titleLarge),
          const SizedBox(height: 20),
          Text('YOUR ANSWER', style: t.labelSmall),
          const SizedBox(height: 8),
          ChallengeRendererRegistry.build(
            ChallengeRenderContext(
              challenge: state.challenge,
              draft: attempt?.response ?? state.currentResponseDraft,
              feedback: state.feedbackState,
              readOnly: true,
              emit: (_) {},
              openResource: widget.onOpenResource,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SumiRadius.r16),
              border: Border.all(color: SumiColors.border, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (answer != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SumiColors.skySoft,
                      borderRadius: BorderRadius.circular(SumiRadius.r8),
                    ),
                    child: Text(
                      'Correct answer: $answer',
                      style: t.bodyLarge?.copyWith(
                        color: SumiColors.infoInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(state.challenge.explanation, style: t.bodyLarge),
                if (attempt != null &&
                    attempt.reason.isNotEmpty &&
                    attempt.reason != state.challenge.explanation) ...[
                  const SizedBox(height: 8),
                  Text(attempt.reason, style: t.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Was this helpful?', style: t.bodyLarge)),
              IconButton(
                tooltip: 'Helpful',
                isSelected: helpful == 'helpful',
                onPressed: helpful == null ? () => rate('helpful') : null,
                icon: const Icon(Icons.thumb_up_alt_outlined),
                selectedIcon: const Icon(Icons.thumb_up_alt_rounded),
              ),
              IconButton(
                tooltip: 'Not helpful',
                isSelected: helpful == 'not_helpful',
                onPressed: helpful == null ? () => rate('not_helpful') : null,
                icon: const Icon(Icons.thumb_down_alt_outlined),
                selectedIcon: const Icon(Icons.thumb_down_alt_rounded),
              ),
            ],
          ),
          if (helpful != null)
            Text('Thanks — noted for this lesson.', style: t.bodySmall),
          const SizedBox(height: 16),
          if (widget.onAskTutor != null) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.offline_bolt_rounded),
                label: const Text('EXPLAIN IT ANOTHER WAY'),
                onPressed: () => widget.onAskTutor!(
                  'Explain this another way, briefly. Challenge: ${state.challenge.prompt}\n'
                  'Authored explanation: ${state.challenge.explanation}',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Uses the offline model on this phone if one is installed. Your grade does not change.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SumiColors.sky,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('CONTINUE LESSON'),
            ),
          ),
        ],
      ),
    );
  }
}
