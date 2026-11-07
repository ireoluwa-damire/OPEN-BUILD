import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../models.dart';
import '../review/review_scheduler.dart';
import '../theme.dart';
import '../graphics/sumi_graphics.dart';

/// One Practice row: a node plus the human reason it is listed (PRA-01).
class PracticeItem {
  final Milestone node;
  final String reason;
  const PracticeItem(this.node, this.reason);
}

/// The five Practice sections in order (PRA-01). Empty sections are hidden.
class PracticeSections {
  final List<PracticeItem> reviewDue, repair, strengthen, project, followUp;
  final ReviewItem? nextUpcoming;
  const PracticeSections({
    required this.reviewDue,
    required this.repair,
    required this.strengthen,
    required this.project,
    required this.followUp,
    this.nextUpcoming,
  });

  bool get isEmpty =>
      reviewDue.isEmpty &&
      repair.isEmpty &&
      strengthen.isEmpty &&
      project.isEmpty &&
      followUp.isEmpty;
  int get count =>
      reviewDue.length +
      repair.length +
      strengthen.length +
      project.length +
      followUp.length;

  /// Built from the review schedule and saved evidence only (EVD-03). A node
  /// appears in at most one section, so the tab never lists every milestone.
  factory PracticeSections.build(
    Catalog catalog,
    LearningState learning,
    DateTime now,
  ) {
    final used = <String>{};
    final nodes = {for (final m in catalog.milestones) m.id: m};
    List<PracticeItem> take(Iterable<PracticeItem> items) {
      final out = <PracticeItem>[];
      for (final i in items) {
        if (used.add(i.node.id)) out.add(i);
      }
      return out;
    }

    final due = take(
      ReviewScheduler.dueItems(learning.reviewSchedule, now)
          .where((r) => nodes.containsKey(r.nodeId))
          .map((r) => PracticeItem(nodes[r.nodeId]!, r.reason)),
    );
    final repair = take(
      catalog.milestones
          .where(
            (m) =>
                learning.completed.contains(m.id) &&
                learning.reviewSchedule[m.id]?.outcome == 'incorrect',
          )
          .map(
            (m) => PracticeItem(
              m,
              'You had a tricky moment here. Repair it while it’s fresh.',
            ),
          ),
    );
    final strengthen = take(
      catalog.milestones
          .where((m) {
            final s = learning.getEvidenceState(m, catalog);
            return learning.completed.contains(m.id) &&
                (s == EvidenceState.supported || s == EvidenceState.exposed);
          })
          .map(
            (m) => PracticeItem(
              m,
              'You’ve practised this with support. Try it on your own.',
            ),
          ),
    );
    final project = take(
      catalog.milestones
          .where(
            (m) =>
                m.type == NodeType.projectStep &&
                learning.completed.contains(m.id),
          )
          .map(
            (m) => PracticeItem(
              m,
              'Rehearse your project step and note one change.',
            ),
          ),
    );
    // Demo window only: the delayed follow-up check (labelled early < 24 h).
    final followUp = <PracticeItem>[];
    if (learning.baselineDone(catalog) &&
        !learning.recallDone(catalog) &&
        catalog.recallQuestions.isNotEmpty) {
      final early =
          now.difference(learning.attempts.first.recordedAt) <
          const Duration(hours: 24);
      final first = catalog.milestones.firstOrNull;
      if (first != null && !used.contains(first.id)) {
        followUp.add(
          PracticeItem(
            first,
            early
                ? 'Early follow-up: checked less than 24 hours after your starting check.'
                : 'Day 2 check: see what stayed with you since your starting check.',
          ),
        );
      }
    }
    return PracticeSections(
      reviewDue: due,
      repair: repair,
      strengthen: strengthen,
      project: project,
      followUp: followUp,
      nextUpcoming: ReviewScheduler.nextUpcoming(learning.reviewSchedule, now),
    );
  }
}

/// PRA-01 / PRA-02 (DC §8.11). Every item opens a normal lesson session,
/// which completes through the same transaction as the path.
class PracticeTab extends StatelessWidget {
  final Catalog catalog;
  final LearningState learning;
  final Future<void> Function(Milestone) onOpenMilestone;
  final Future<void> Function()? onFollowUp;
  final DateTime Function() clock;

  const PracticeTab({
    super.key,
    required this.catalog,
    required this.learning,
    required this.onOpenMilestone,
    this.onFollowUp,
    this.clock = DateTime.now,
  });


  String _date(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sections = PracticeSections.build(catalog, learning, clock());
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    Widget section(String label, List<PracticeItem> items, {bool followUp = false}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                label.toUpperCase(),
                style: t.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PracticeRow(
                item: item,
                glyph: glyphForNode(item.node.type),
                onTap: () => followUp && onFollowUp != null
                    ? onFollowUp!()
                    : onOpenMilestone(item.node),
              ),
            ),
        ],
      );
    }

    final next = sections.nextUpcoming;
    return Scaffold(
      appBar: AppBar(title: Text('Practice', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: SumiColors.violetShadow,
              borderRadius: BorderRadius.circular(SumiRadius.r16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SumiColors.violet,
                borderRadius: BorderRadius.circular(SumiRadius.r16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Practice',
                            style: t.titleLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sections.count} ${sections.count == 1 ? 'item' : 'items'} ready',
                          style: t.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const ExcludeSemantics(
                    child: SumiGlyph(SumiGlyphKind.practice, size: 64, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (sections.isEmpty)
            EmptyState(
              illustration: const SumiEmptyIllustration(SumiEmptyKind.caughtUp),
              icon: Icons.check_circle_outline_rounded,
              heading: 'You’re caught up',
              body: next == null
                  ? 'New reviews appear after you practise.'
                  : 'New reviews appear after you practise. Next one: ${_date(next.dueAt)}.',
              actionLabel: learning.current(catalog) == null
                  ? null
                  : 'PRACTISE ANYWAY',
              onAction: () {
                final current = learning.current(catalog);
                if (current != null) onOpenMilestone(current);
              },
            )
          else ...[
            section('Review due', sections.reviewDue),
            section('Repair mistakes', sections.repair),
            section('Strengthen a capability', sections.strengthen),
            section('Rehearse the project', sections.project),
            section(
              'Early follow-up / Day 2 check',
              sections.followUp,
              followUp: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final PracticeItem item;
  final SumiGlyphKind glyph;
  final VoidCallback onTap;
  const _PracticeRow({
    required this.item,
    required this.glyph,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SumiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      semanticLabel: '${item.node.title}. ${item.reason}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: SumiColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(child: SumiGlyph(glyph, color: SumiColors.successInk)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.node.title, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.reason, style: t.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: SumiColors.muted),
          ],
        ),
      ),
    );
  }
}
