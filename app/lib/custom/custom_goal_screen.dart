import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../models.dart';
import '../on_device.dart';
import '../theme.dart';
import '../graphics/sumi_graphics.dart';

/// CUS-01 (DC §8.16): the honest provisional state for "Something else".
/// No invented lessons, quiz answers or links are shown. A validated plan
/// (CUS-02) is the only way this goal gets a path.
class CustomGoalScreen extends StatelessWidget {
  final Catalog catalog;
  final LearningState learning;
  final PhoneModelController phoneCoach;
  final VoidCallback onSetUpModel;
  final VoidCallback onChooseReviewed;

  /// Starts the on-device plan draft (CUS-02), when a model is ready.
  final VoidCallback? onDraftPlan;
  const CustomGoalScreen({
    super.key,
    required this.catalog,
    required this.learning,
    required this.phoneCoach,
    required this.onSetUpModel,
    required this.onChooseReviewed,
    this.onDraftPlan,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final outcome = learning.onboarding.outcome.isNotEmpty
        ? learning.onboarding.outcome
        : catalog.title;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    return ListenableBuilder(
      listenable: phoneCoach,
      builder: (context, _) {
        final modelReady =
            phoneCoach.supported &&
            phoneCoach.installed.isNotEmpty &&
            phoneCoach.activeName != null;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Sumi needs a plan for “$outcome”.',
                    style: t.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                SumiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SumiColors.amberSoft,
                          borderRadius: BorderRadius.circular(SumiRadius.pill),
                        ),
                        child: Text(
                          'PROVISIONAL',
                          style: t.labelSmall?.copyWith(
                            color: SumiColors.warningInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(outcome, style: t.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'This goal has its own record on this device. Music and Fashion progress are not affected.',
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (modelReady && onDraftPlan != null) ...[
                  Text(
                    '${phoneCoach.activeName} is ready on this device. It can draft a provisional plan; Sumi checks the plan before showing any steps.',
                    style: t.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TactileButton(
                    'DRAFT A PLAN ON THIS DEVICE',
                    onPressed: onDraftPlan,
                  ),
                  const SizedBox(height: 8),
                  TactileButton(
                    'CHOOSE MUSIC OR FASHION FOR NOW',
                    variant: TactileVariant.text,
                    onPressed: onChooseReviewed,
                  ),
                ] else
                  EmptyState(
                    illustration: const SumiEmptyIllustration(SumiEmptyKind.noModel),
                    icon: Icons.map_outlined,
                    heading: 'Sumi needs a plan for this goal',
                    body:
                        'Download an offline model in Settings to draft a plan, or choose Music or Fashion for now.',
                    actionLabel: 'SET UP AN OFFLINE MODEL',
                    onAction: onSetUpModel,
                    secondaryLabel: 'CHOOSE MUSIC OR FASHION FOR NOW',
                    onSecondary: onChooseReviewed,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
