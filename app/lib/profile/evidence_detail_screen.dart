import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../learning_session/challenge_definition.dart';
import '../learning_session/learning_session_state.dart';
import '../models.dart';
import '../theme.dart';

/// One traceable piece of evidence (EVD-04). [eventId] is the saved attempt
/// or session ID the claim comes from.
class EvidenceEvent {
  final String eventId, task, outcome, source;
  final DateTime date;
  final bool usedHint, selfReported, removable;
  final String? sessionId;
  const EvidenceEvent({
    required this.eventId,
    required this.task,
    required this.outcome,
    required this.source,
    required this.date,
    this.usedHint = false,
    this.selfReported = false,
    this.removable = false,
    this.sessionId,
  });

  /// Every attempt that supports a capability: baseline, follow-up and lesson
  /// attempts, newest first.
  static List<EvidenceEvent> forNode(
    LearningState learning,
    Catalog catalog,
    Milestone node,
  ) {
    final out = <EvidenceEvent>[];
    for (final a in learning.attempts) {
      final q = catalog.questions.where((q) => q.id == a.questionId).firstOrNull;
      if (q == null || q.skill != node.id) continue;
      out.add(
        EvidenceEvent(
          eventId: 'baseline:${a.questionId}',
          task: q.prompt,
          outcome: a.answerIndex == null
              ? 'skipped'
              : a.answerIndex == q.correct
              ? 'correct'
              : 'incorrect',
          source: 'Starting check',
          date: a.recordedAt,
          usedHint: a.usedHint,
        ),
      );
    }
    for (final a in learning.recallAttempts) {
      final q = catalog.recallQuestions
          .where((q) => q.id == a.questionId)
          .firstOrNull;
      if (q == null || q.skill != node.id) continue;
      out.add(
        EvidenceEvent(
          eventId: 'recall:${a.questionId}',
          task: q.prompt,
          outcome: a.answerIndex == q.correct ? 'correct' : 'incorrect',
          source: 'Follow-up check',
          date: a.recordedAt,
          usedHint: a.usedHint,
        ),
      );
    }
    for (final raw in learning.sessions.values) {
      if (raw is! Map) continue;
      final LearningSessionState session;
      try {
        session = LearningSessionState.fromJson(Json.from(raw));
      } catch (_) {
        continue;
      }
      if (session.nodeId != node.id) continue;
      for (final a in session.attempts) {
        final c = session.challenges
            .where((c) => c.id == a.challengeId)
            .firstOrNull;
        if (c == null) continue;
        final removed = a.response['removed'] == true;
        out.add(
          EvidenceEvent(
            eventId: a.id,
            sessionId: session.sessionId,
            task: c.prompt,
            outcome: removed
                ? 'removed by you'
                : a.response['skipped'] == true
                ? 'skipped'
                : a.outcome.name,
            source: c.selfReported
                ? 'Your own report (not independently checked)'
                : 'Lesson check',
            date: a.recordedAt,
            usedHint: a.response['usedHint'] == true,
            selfReported: c.selfReported,
            removable:
                c.kind == ChallengeKind.projectReflection && !removed,
          ),
        );
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }
}

/// EVD-04: "Why Sumi believes this".
class EvidenceDetailScreen extends StatefulWidget {
  final LearningState learning;
  final Catalog catalog;
  final Milestone node;

  /// Removes one self-reported project entry through a transaction.
  final Future<void> Function(String sessionId, String attemptId) onRemove;
  const EvidenceDetailScreen({
    super.key,
    required this.learning,
    required this.catalog,
    required this.node,
    required this.onRemove,
  });

  static String stateLabel(EvidenceState s) => switch (s) {
    EvidenceState.unseen => 'Not started',
    EvidenceState.exposed => 'Seen',
    EvidenceState.supported => 'With support',
    EvidenceState.independent => 'On your own',
    EvidenceState.recalled => 'Recalled later',
    EvidenceState.transferred => 'Used in a new context',
    EvidenceState.needsReview => 'Review due',
  };

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  String? _error;

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = widget.learning.getEvidenceState(widget.node, widget.catalog);
    final events = EvidenceEvent.forNode(
      widget.learning,
      widget.catalog,
      widget.node,
    );
    final review = widget.learning.reviewSchedule[widget.node.id];
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: Text('Why Sumi believes this', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Text(widget.node.title, style: t.headlineMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.insights_rounded, size: 16),
                label: Text(EvidenceDetailScreen.stateLabel(state)),
              ),
            ],
          ),
          if (review != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next review: ${_date(review.dueAt)} · ${review.reason}',
              style: t.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Practical work you report yourself is shown as your own report. Sumi does not independently verify it.',
            style: t.bodyMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InlineError(_error!),
          ],
          const SizedBox(height: 16),
          if (events.isEmpty)
            const EmptyState(
              icon: Icons.history_edu_rounded,
              heading: 'No evidence yet',
              body: 'Answers you check in lessons appear here with their dates.',
            )
          else
            for (final e in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SumiCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            switch (e.outcome) {
                              'correct' => Icons.check_circle_rounded,
                              'incorrect' => Icons.cancel_rounded,
                              'nearCorrect' => Icons.change_circle_rounded,
                              _ => Icons.radio_button_unchecked_rounded,
                            },
                            size: 20,
                            color: switch (e.outcome) {
                              'correct' => SumiColors.successInk,
                              'incorrect' => SumiColors.errorInk,
                              _ => SumiColors.mutedStrong,
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_date(e.date)} · ${e.outcome == 'nearCorrect' ? 'almost' : e.outcome}${e.usedHint ? ' · hint used' : ''}',
                              style: t.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(e.task, style: t.bodyLarge),
                      const SizedBox(height: 4),
                      Text(e.source, style: t.bodyMedium),
                      Text('Event: ${e.eventId}', style: t.labelSmall),
                      if (e.removable && e.sessionId != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await widget.onRemove(e.sessionId!, e.eventId);
                                if (mounted) setState(() => _error = null);
                              } catch (_) {
                                if (mounted) {
                                  setState(
                                    () => _error =
                                        'Couldn’t remove this entry. Try again.',
                                  );
                                }
                              }
                            },
                            child: const Text('REMOVE MY REPORT'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
