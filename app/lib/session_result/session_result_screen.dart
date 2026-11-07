import 'package:flutter/material.dart';
import '../mascot/sumi_mascot.dart';
import '../motion/celebration.dart';
import '../theme.dart';
import '../widgets.dart';
import 'session_result.dart';
import '../effects/effects_service.dart';
import '../design_system/components.dart';
import '../design_system/motion.dart';
import '../graphics/sumi_graphics.dart';

/// Lesson-complete celebration. Reads only the persisted [SessionResult].
/// One 1.4 s intro (hero pop → title → staggered stat tiles with count-up)
/// plus a one-shot confetti burst; reduced motion shows the final frame.
class SessionResultScreen extends StatefulWidget {
  final SessionResult result;
  final bool busy, reducedMotion;
  final String? error;
  /// CONTINUE: back to the path, play events, open the next node's card.
  final VoidCallback onContinue;

  /// RETURN TO PATH: the same, without opening the card (RES-04, CF-28).
  final VoidCallback? onReturn;
  final VoidCallback onReview;
  const SessionResultScreen({
    super.key,
    required this.result,
    required this.onContinue,
    required this.onReview,
    this.onReturn,
    required this.reducedMotion,
    this.busy = false,
    this.error,
  });
  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController intro = AnimationController(
    vsync: this,
    // CF-21: the whole sequence is at most 1,200 ms and can be skipped.
    duration: SumiMotion.celebrationLarge,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reducedMotion) {
      intro.value = 1;
    } else {
      EffectsService.instance.feedback(
        SumiSound.lessonComplete,
        SumiHaptic.medium,
      );
      intro.forward();
    }
  }

  @override
  void dispose() {
    intro.dispose();
    super.dispose();
  }

  static const _accolades = {
    SessionAccolade.accuracy: 'Every check right first time.',
    SessionAccolade.recovery: 'You worked through the tricky parts.',
    SessionAccolade.making: 'An idea made visible.',
    SessionAccolade.reflection: 'A thoughtful next step.',
    SessionAccolade.consistency: 'You showed up today.',
    SessionAccolade.listening: 'Great attention to rhythm.',
  };

  Animation<double> _seg(double a, double b, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(
        parent: intro,
        curve: Interval(a, b, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final evidence = r.evidencePayload.values.first as Map;
    final assessed = (evidence['assessedChallengeCount'] as int? ?? 0) > 0;
    final heroColor = switch (r.celebrationType) {
      'rhythm' => SumiColors.sky,
      'stitches' => SumiColors.violet,
      _ => SumiColors.primary,
    };
    final title = _seg(.2, .5);
    final secs = r.duration.inSeconds;
    final tiles = [
      _StatSpec(
        label: 'POINTS',
        color: SumiColors.amber,
        icon: Icons.bolt_rounded,
        count: r.pointsAwarded,
        format: (v) => '+$v',
      ),
      assessed
          ? _StatSpec(
              label: 'ACCURACY',
              color: SumiColors.primary,
              icon: Icons.track_changes_rounded,
              count: (r.firstAttemptAccuracy * 100).round(),
              format: (v) => '$v%',
            )
          : const _StatSpec(
              label: 'REFLECTION',
              color: SumiColors.primary,
              icon: Icons.edit_note_rounded,
              text: 'Saved',
            ),
      _StatSpec(
        label: 'TIME',
        color: SumiColors.sky,
        icon: Icons.timer_rounded,
        count: secs,
        format: (v) => '${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (intro.isAnimating) intro.value = 1;
        },
        child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      SizedBox(
                        height: 210,
                        child: AnimatedBuilder(
                          animation: intro,
                          builder: (context, _) => Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: RaysPainter(intro.value, heroColor),
                                ),
                              ),
                              SumiMascot(
                                anim: r.accolade == SessionAccolade.accuracy
                                    ? SumiAnim.inkBloom
                                    : SumiAnim.complete,
                                size: 210,
                                reducedMotion: widget.reducedMotion,
                                semanticLabel: 'Sumi celebrates',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: title,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .3),
                            end: Offset.zero,
                          ).animate(title),
                          child: Column(
                            children: [
                              Text(
                                r.accolade == SessionAccolade.accuracy
                                    ? 'Perfect step!'
                                    : 'Step complete!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: Color.lerp(
                                        heroColor,
                                        Colors.black,
                                        .2,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _accolades[r.accolade]!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _StatTile(
                                spec: tiles[i],
                                progress: _seg(
                                  .4 + i * .12,
                                  .72 + i * .12,
                                  Curves.easeOutBack,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (r.streakDays != null) ...[
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _seg(.7, 1),
                          child: _TodayRow(result: r),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _seg(.75, 1),
                        child: _EvidenceCard(
                          result: r,
                          evidence: evidence,
                          onReview: widget.onReview,
                        ),
                      ),
                      if (r.nextNodeTitle != null) ...[
                        const SizedBox(height: 16),
                        SumiCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_circle_right_rounded,
                                color: SumiColors.successInk,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Next: ${r.nextNodeTitle}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: SumiColors.border, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            widget.error!,
                            style: const TextStyle(color: SumiColors.coral),
                          ),
                        ),
                      TactileButton(
                        widget.busy ? 'SAVING…' : 'CONTINUE',
                        loading: widget.busy,
                        onPressed: widget.busy ? null : widget.onContinue,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TactileButton(
                              'RETURN TO PATH',
                              variant: TactileVariant.text,
                              onPressed: widget.busy
                                  ? null
                                  : (widget.onReturn ?? widget.onContinue),
                            ),
                          ),
                          Expanded(
                            child: TactileButton(
                              'Review saved responses',
                              variant: TactileVariant.text,
                              onPressed: widget.onReview,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiBurst(reducedMotion: widget.reducedMotion),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// RES-01 "Today" row: daily-goal ring, streak and "+1 DAY".
class _TodayRow extends StatelessWidget {
  final SessionResult result;
  const _TodayRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final minutes = result.minutesToday ?? 0;
    final goal = result.dailyGoal ?? 10;
    final streak = result.streakDays ?? 0;
    return Semantics(
      label:
          '$minutes of $goal minutes today. $streak-day streak.${result.streakExtended ? ' Plus one day.' : ''}',
      excludeSemantics: true,
      child: SumiCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: (minutes / goal).clamp(0.0, 1.0),
                strokeWidth: 5,
                color: SumiColors.primary,
                backgroundColor: SumiColors.disabled,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$minutes/$goal min today',
                style: t.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
            const SumiGlyph(SumiGlyphKind.flame, color: SumiColors.warningInk),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$streak-day streak',
                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (result.streakExtended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SumiColors.amberSoft,
                  borderRadius: BorderRadius.circular(SumiRadius.pill),
                ),
                child: Text(
                  '+1 DAY',
                  style: t.labelSmall?.copyWith(
                    color: SumiColors.warningInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatSpec {
  final String label;
  final Color color;
  final IconData icon;
  final int? count;
  final String Function(int)? format;
  final String? text;
  const _StatSpec({
    required this.label,
    required this.color,
    required this.icon,
    this.count,
    this.format,
    this.text,
  });
}

class _StatTile extends StatelessWidget {
  final _StatSpec spec;
  final Animation<double> progress;
  const _StatTile({required this.spec, required this.progress});
  @override
  Widget build(BuildContext context) {
    final finalValue = spec.text ?? spec.format!(spec.count!);
    return Semantics(
      label: '${spec.label.toLowerCase()} $finalValue',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final p = progress.value;
          final shown =
              spec.text ??
              spec.format!((spec.count! * p.clamp(0.0, 1.0)).round());
          return Opacity(
            opacity: p.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: .6 + .4 * p,
              child: Container(
                decoration: BoxDecoration(
                  color: spec.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          spec.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(spec.icon, color: spec.color, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              shown,
                              maxLines: 1,
                              style: TextStyle(
                                color: spec.color,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final SessionResult result;
  final Map evidence;
  final VoidCallback onReview;
  const _EvidenceCard({
    required this.result,
    required this.evidence,
    required this.onReview,
  });
  @override
  Widget build(BuildContext context) {
    final discipline = result.evidencePayload.keys.first;
    final categories = (evidence['categories'] as List? ?? const []);
    return Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT YOU SHOWED · ${discipline.toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in categories) Tag('$c')],
          ),
          const SizedBox(height: 12),
          Text(
            '${result.correctCount} checks passed · ${result.incorrectCount} incorrect · '
            '${result.nearCorrectCount} near-correct · ${result.retryCount} retries',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Reflections and practical observations are self-reported. '
            'Completing this step does not certify mastery.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onReview,
              child: const Text('Review saved responses'),
            ),
          ),
        ],
      ),
    );
  }
}
