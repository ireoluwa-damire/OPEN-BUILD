import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../design_system/routes.dart';
import '../learning_path/learning_path_state.dart';
import '../models.dart';
import '../on_device.dart';
import '../profile/evidence_detail_screen.dart';
import '../theme.dart';
import '../graphics/sumi_graphics.dart';

/// PRO-01 / PRO-02 (DC §8.12). Engagement (practice) and evidence (what was
/// shown) are separate panels. Focus is lesson-only and is not shown here
/// (CF-15).
class ProfileTab extends StatelessWidget {
  final Catalog catalog;
  final List<Catalog> disciplines;
  final LearningState learning;
  final PhoneModelController phoneCoach;
  final Future<void> Function(Catalog) onSwitchDiscipline;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAdaptation;
  final VoidCallback onOpenStreak;
  final Future<void> Function(String sessionId, String attemptId)
  onRemoveEvidence;

  const ProfileTab({
    super.key,
    required this.catalog,
    required this.disciplines,
    required this.learning,
    required this.phoneCoach,
    required this.onSwitchDiscipline,
    required this.onOpenSettings,
    required this.onOpenAdaptation,
    required this.onOpenStreak,
    required this.onRemoveEvidence,
  });

  static const _unitFills = [
    SumiColors.unitTeal,
    SumiColors.unitPlum,
    SumiColors.unitOlive,
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = learning.engagement;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    final palette = LearningUnit.forCatalog(catalog).firstOrNull?.paletteIndex ?? 0;
    final lessonsThisWeek = e.rewardTransactions.where((tx) {
      final now = EngagementState.clock();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return const ['lesson', 'review', 'project', 'checkpoint'].contains(tx.rewardType) &&
          !tx.timestamp.toLocal().isBefore(monday);
    }).length;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
      ),
    );

    Widget stat(SumiGlyphKind icon, Color color, String value, String name, {VoidCallback? onTap}) =>
        SumiCard(
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          semanticLabel: '$name: $value',
          child: Row(
            children: [
              SumiGlyph(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: t.titleLarge?.copyWith(fontFeatures: tabularFigures),
                    ),
                    Text(name, style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );

    final modelLine = !phoneCoach.supported
        ? 'Offline AI runs in the installed mobile app'
        : phoneCoach.activeName != null
        ? 'On this device: ${phoneCoach.activeName} ready'
        : 'No offline model installed';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: t.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _unitFills[palette % 3],
              borderRadius: BorderRadius.circular(SumiRadius.r16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: DisciplineScene(scene: catalog.scene, size: 44),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalog.title,
                        style: t.titleLarge?.copyWith(color: Colors.white),
                      ),
                      if (learning.goal.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          learning.goal,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          label('THIS WEEK'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              stat(
                SumiGlyphKind.flame,
                SumiColors.warningInk,
                '${e.streakDays}',
                'day streak',
                onTap: onOpenStreak,
              ),
              stat(SumiGlyphKind.points, SumiColors.successInk, '${e.pointsWeek}', 'points this week'),
              stat(SumiGlyphKind.check, SumiColors.infoInk, '$lessonsThisWeek', 'steps this week'),
              stat(SumiGlyphKind.spark, SumiColors.violetInk, '${e.sparksBalance}', 'sparks'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Points measure practice, not mastery.',
            style: t.bodyMedium,
          ),
          label('WHAT YOU’VE SHOWN'),
          if (catalog.milestones.isEmpty)
            Text('No steps yet for this goal.', style: t.bodyLarge)
          else
            for (final m in catalog.milestones)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EvidenceCard(
                  node: m,
                  state: learning.getEvidenceState(m, catalog),
                  count: EvidenceEvent.forNode(learning, catalog, m).length,
                  onTap: () => Navigator.of(context).push(
                    slideRoute<void>(
                      (_) => EvidenceDetailScreen(
                        learning: learning,
                        catalog: catalog,
                        node: m,
                        onRemove: onRemoveEvidence,
                      ),
                      reducedMotion: learning.reducedMotion,
                    ),
                  ),
                ),
              ),
          label('HOW SUMI IS ADAPTING'),
          SumiCard(
            onTap: onOpenAdaptation,
            semanticLabel: 'How Sumi is adapting. See what Sumi has observed and change your preferences.',
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: SumiColors.infoInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'See what Sumi has observed and change your preferences.',
                    style: t.bodyLarge,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: SumiColors.muted),
              ],
            ),
          ),
          label('AI'),
          SumiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modelLine, style: t.bodyLarge),
                const SizedBox(height: 4),
                Text('Cloud AI: Not configured', style: t.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Lessons and authored explanations work without any model. Nothing you type leaves this device.',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
          label('DISCIPLINES'),
          for (final d in disciplines.where((d) => !d.isCustom))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChoiceRow(
                label: d.title,
                state: d.id == catalog.id ? ChoiceState.selected : ChoiceState.idle,
                onTap: d.id == catalog.id ? null : () => onSwitchDiscipline(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final Milestone node;
  final EvidenceState state;
  final int count;
  final VoidCallback onTap;
  const _EvidenceCard({
    required this.node,
    required this.state,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final label = EvidenceDetailScreen.stateLabel(state);
    final uncertainty = switch (state) {
      EvidenceState.unseen || EvidenceState.exposed => 'not enough evidence yet',
      EvidenceState.supported => 'early',
      EvidenceState.independent => 'growing',
      EvidenceState.needsReview => 'needs a fresh check',
      _ => 'strong',
    };
    return SumiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      semanticLabel: '${node.title}. $label. $count pieces of evidence, $uncertainty. Why Sumi believes this.',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: state == EvidenceState.unseen
                        ? SumiColors.surfaceSoft
                        : SumiColors.primarySoft,
                    borderRadius: BorderRadius.circular(SumiRadius.pill),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: t.labelSmall?.copyWith(
                      color: state == EvidenceState.unseen
                          ? SumiColors.mutedStrong
                          : SumiColors.successInk,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(node.title, style: t.titleMedium),
                const SizedBox(height: 2),
                Text('$count ${count == 1 ? 'piece' : 'pieces'} of evidence · $uncertainty', style: t.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SumiColors.muted),
        ],
      ),
    );
  }
}
