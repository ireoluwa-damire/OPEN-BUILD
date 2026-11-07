import 'package:flutter/material.dart';
import '../design_system/motion.dart';
import '../theme.dart';

/// LES-01: exit, progress, Focus and settings.
class LessonProgressHeader extends StatelessWidget {
  final int progress, total, focus;
  final bool busy, reducedMotion;
  final VoidCallback onExit, onSettings;
  const LessonProgressHeader({
    super.key,
    required this.progress,
    required this.total,
    required this.focus,
    required this.onExit,
    required this.onSettings,
    this.busy = false,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : progress / total;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Pause lesson',
                    iconSize: 28,
                    color: SumiColors.muted,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onExit,
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Lesson progress, $progress of $total',
                      child: ExcludeSemantics(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: value),
                          duration: reducedMotion
                              ? Duration.zero
                              : SumiMotion.micro,
                          curve: SumiMotion.microCurve,
                          builder: (context, v, _) =>
                              _ProgressBar(value: v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'Focus $focus of 5',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 22,
                            color: focus == 0
                                ? SumiColors.disabledText
                                : SumiColors.coral,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$focus',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: SumiColors.ink,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Lesson settings',
                    onPressed: busy ? null : onSettings,
                    color: SumiColors.muted,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
            if (focus == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SumiColors.violetSoft,
                    borderRadius: BorderRadius.circular(SumiRadius.pill),
                  ),
                  child: const Text(
                    'PRACTICE MODE',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: .6,
                      fontWeight: FontWeight.w700,
                      color: SumiColors.violetInk,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(SumiRadius.pill),
    child: SizedBox(
      height: 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: SumiColors.disabled),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SumiColors.primary,
                borderRadius: BorderRadius.circular(SumiRadius.pill),
              ),
              child: Align(
                alignment: const Alignment(0, -.5),
                child: FractionallySizedBox(
                  widthFactor: .9,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(SumiRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
