import 'package:flutter/material.dart';

import '../design_system/motion.dart';
import '../mascot/sumi_mascot.dart';
import '../theme.dart';

/// LES-17: shown only when opening a lesson takes longer than 150 ms.
class LessonLoadingScreen extends StatelessWidget {
  final bool reducedMotion;
  const LessonLoadingScreen({super.key, this.reducedMotion = false});

  static const delay = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context, learnerSetting: reducedMotion);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SumiColors.canvas,
        body: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Getting your step ready…',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: SumiMascot(
                    anim: SumiAnim.think,
                    size: 120,
                    reducedMotion: reduced || !SumiMotion.loopsEnabled,
                  ),
                ),
                const SizedBox(height: 16),
                ExcludeSemantics(
                  child: Text(
                    'Getting your step ready…',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
