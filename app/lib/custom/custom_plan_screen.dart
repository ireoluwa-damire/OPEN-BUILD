import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../models.dart';
import '../theme.dart';
import 'custom_plan.dart';

/// CUS-02: drafts a provisional plan with the on-device model, checks it, and
/// lets the learner confirm, trim or redraft it. Nothing is saved until the
/// learner confirms, and the app stays usable if drafting fails.
class CustomPlanScreen extends StatefulWidget {
  final String goalId, outcome, modelName;
  final int dailyMinutes;

  /// Runs the on-device model (`PhoneModelController.reply`).
  final Future<String> Function(String prompt) draft;
  final VoidCallback? onStop;
  final Future<void> Function(List<Json> steps) onConfirm;
  final VoidCallback onChooseReviewed;
  const CustomPlanScreen({
    super.key,
    required this.goalId,
    required this.outcome,
    required this.modelName,
    required this.dailyMinutes,
    required this.draft,
    required this.onConfirm,
    required this.onChooseReviewed,
    this.onStop,
  });

  @override
  State<CustomPlanScreen> createState() => _CustomPlanScreenState();
}

class _CustomPlanScreenState extends State<CustomPlanScreen> {
  bool _drafting = false, _saving = false;
  PlanCheck? _check;
  List<Json> _steps = [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _drafting = true;
      _check = null;
    });
    PlanCheck check;
    try {
      final raw = await widget.draft(
        CustomPlan.prompt(widget.outcome, widget.dailyMinutes),
      );
      check = CustomPlan.parse(raw, goalId: widget.goalId);
    } catch (_) {
      check = const PlanCheck.rejected(
        'The on-device model couldn’t finish a plan. Nothing was saved.',
      );
    }
    if (!mounted) return;
    setState(() {
      _drafting = false;
      _check = check;
      _steps = List.of(check.steps);
    });
  }

  void _remove(int i) {
    final next = [..._steps]..removeAt(i);
    // Re-chain prerequisites after a removal.
    for (var k = 0; k < next.length; k++) {
      next[k] = {
        ...next[k],
        'prerequisites': [if (k > 0) next[k - 1]['id']],
      };
    }
    setState(() => _steps = next);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    final check = _check;
    final valid = CustomPlan.validate(_steps).ok;
    return Scaffold(
      appBar: AppBar(title: Text('Draft a plan', style: t.titleMedium)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Text('“${widget.outcome}”', style: t.headlineMedium),
          const SizedBox(height: 8),
          if (CustomPlan.isHighRisk(widget.outcome))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'This topic can be risky, so the plan stays with theory and safe preparation.',
                style: t.bodyLarge,
              ),
            ),
          if (_drafting) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                '${widget.modelName} is drafting on this device…',
                textAlign: TextAlign.center,
                style: t.bodyLarge,
              ),
            ),
            if (widget.onStop != null) ...[
              const SizedBox(height: 16),
              TactileButton('STOP', variant: TactileVariant.outline, onPressed: widget.onStop),
            ],
          ] else if (check != null && !check.ok) ...[
            const SizedBox(height: 16),
            InlineError(check.problem!),
            const SizedBox(height: 24),
            TactileButton('TRY AGAIN', onPressed: _run),
            const SizedBox(height: 8),
            TactileButton(
              'CHOOSE MUSIC OR FASHION FOR NOW',
              variant: TactileVariant.text,
              onPressed: widget.onChooseReviewed,
            ),
          ] else if (check != null) ...[
            Text(
              'Drafted by ${widget.modelName} on this device and checked by Sumi. Steps are provisional; each one asks for your own notes, not quiz answers.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SumiCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}. ${_steps[i]['title']}', style: t.titleMedium),
                            if ((_steps[i]['subtitle'] as String).isNotEmpty)
                              Text(_steps[i]['subtitle'] as String, style: t.bodyMedium),
                            Text('${_steps[i]['minutes']} min', style: t.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove step ${i + 1}',
                        onPressed: _steps.length > CustomPlan.minSteps ? () => _remove(i) : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TactileButton(
              'CONFIRM THIS PLAN',
              loading: _saving,
              onPressed: valid && !_saving
                  ? () async {
                      setState(() => _saving = true);
                      try {
                        await widget.onConfirm(_steps);
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => _check = const PlanCheck.rejected(
                              'Couldn’t save the plan on this device. Try again.',
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            TactileButton('DRAFT AGAIN', variant: TactileVariant.text, onPressed: _run),
          ],
        ],
      ),
    );
  }
}
