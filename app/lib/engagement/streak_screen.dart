import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../models.dart';
import '../theme.dart';
import '../graphics/sumi_graphics.dart';

/// GAM-06 (DC §8.15): a personal streak view. No comparison with anyone else
/// (GAM-08). Only a completed lesson, due review or project step counts.
class StreakScreen extends StatefulWidget {
  final EngagementState Function() engagement;
  final DateTime Function() clock;

  /// GAM-05: spends 30 sparks on one recovery token.
  final Future<void> Function()? onBuyToken;
  const StreakScreen({
    super.key,
    required this.engagement,
    this.clock = DateTime.now,
    this.onBuyToken,
  });

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final engagement = widget.engagement();
    final clock = widget.clock;
    final t = Theme.of(context).textTheme;
    final now = clock();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 13; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: Text('Streak', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
        children: [
          Row(
            children: [
              const SumiGlyph(SumiGlyphKind.flame, color: SumiColors.warningInk, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${engagement.streakDays}-day streak',
                  style: t.headlineMedium?.copyWith(fontFeatures: tabularFigures),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            engagement.qualifiedToday
                ? 'Today counts. Nice work.'
                : 'Finish one lesson, review or project step today to keep it going.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('LAST 14 DAYS', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in days)
                _DayDot(
                  label: names[d.weekday - 1],
                  date: d,
                  kind: engagement.qualifyingDays[EngagementState.dayKey(d)],
                  isToday: d == today,
                ),
            ],
          ),
          const SizedBox(height: 24),
          SumiCard(
            child: Row(
              children: [
                const SumiGlyph(SumiGlyphKind.shield, color: SumiColors.infoInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${engagement.recoveryTokens} of 2 recovery tokens. You earn one every 7 days in a row. A token covers one missed day automatically.',
                    style: t.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onBuyToken != null) ...[
            const SizedBox(height: 12),
            TactileButton(
              'USE 30 SPARKS FOR A TOKEN',
              variant: TactileVariant.outline,
              onPressed: engagement.sparksBalance >= 30 &&
                      engagement.recoveryTokens < 2
                  ? () async {
                      try {
                        await widget.onBuyToken!();
                        if (mounted) setState(() => _error = null);
                      } catch (_) {
                        if (mounted) {
                          setState(() => _error = 'Couldn’t save that. Try again.');
                        }
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              'You have ${engagement.sparksBalance} sparks. Sparks never unlock lessons or help.',
              style: t.bodyMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              InlineError(_error!),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'Opening the app, reading a resource or downloading a model never counts. Streaks use your local calendar days.',
            style: t.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final DateTime date;
  final String? kind;
  final bool isToday;
  const _DayDot({
    required this.label,
    required this.date,
    required this.kind,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final done = kind != null;
    final token = kind == 'recovery_token';
    final state = token
        ? 'covered by a recovery token'
        : done
        ? 'practised'
        : 'not practised';
    return Semantics(
      label: '${EngagementState.dayKey(date)}, $state${isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: token
                  ? SumiColors.skySoft
                  : done
                  ? SumiColors.amberSoft
                  : SumiColors.surfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday ? SumiColors.ink : SumiColors.border,
                width: isToday ? 2 : 1,
              ),
            ),
            child: done || token
                ? Center(
                    child: SumiGlyph(
                      token ? SumiGlyphKind.shield : SumiGlyphKind.flame,
                      size: 18,
                      color: token ? SumiColors.infoInk : SumiColors.warningInk,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
