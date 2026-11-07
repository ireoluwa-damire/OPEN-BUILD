import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/use_cases.dart';
import '../assessment.dart';
import '../design_system/components.dart';
import '../design_system/motion.dart';
import '../learning_path/learning_path_state.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import 'onboarding_copy.dart';
import 'workload_estimator.dart';
import '../graphics/sumi_graphics.dart';

/// Step indices (S1 §9.1–9.10). Total 10 for the progress bar.
abstract final class OnboardingStep {
  static const promise = 0,
      discipline = 1,
      outcome = 2,
      motivation = 3,
      level = 4,
      preview = 5,
      goal = 6,
      route = 7,
      baseline = 8,
      reveal = 9;
  static const total = 10;
}

/// ONB-01 to ONB-12. One decision per screen, no defaults, every valid answer
/// saved at once through [SaveOnboardingAnswer], and resume on the same step
/// with the same selection. The flow is keyed by the active track, so the
/// baseline and the preview always use the selected catalogue (ONB-12).
class OnboardingFlow extends StatefulWidget {
  final Catalog catalog;
  final List<Catalog> disciplines;
  final LearningState learning;
  final LocalStore store;

  /// Switches the active track to [catalog] and records the selection on that
  /// track's own record (ONB-12).
  final Future<void> Function(Catalog catalog) onChooseDiscipline;

  /// Creates a unique custom goal (CUS-01).
  final Future<void> Function(String outcome) onChooseCustom;

  /// Called after [FinishOnboarding] succeeds; opens the first lesson.
  final VoidCallback onFinished;

  /// A track with saved progress the learner can return to (ONB-01).
  final Catalog? resumeTrack;
  final Future<void> Function(Catalog catalog)? onResume;

  const OnboardingFlow({
    super.key,
    required this.catalog,
    required this.disciplines,
    required this.learning,
    required this.store,
    required this.onChooseDiscipline,
    required this.onChooseCustom,
    required this.onFinished,
    this.resumeTrack,
    this.onResume,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final SaveOnboardingAnswer _save = SaveOnboardingAnswer(widget.store);
  late final TextEditingController _outcome = TextEditingController(
    text: widget.learning.onboarding.outcome,
  );
  Timer? _outcomeSave;
  String? _pendingDiscipline;
  bool _busy = false, _forward = true;
  String? _error;

  OnboardingState get o => widget.learning.onboarding;
  int get step => o.stepIndex.clamp(0, OnboardingStep.reveal);

  @override
  void initState() {
    super.initState();
    final selected = o.selectedDiscipline;
    if (selected != null && selected == widget.catalog.id) {
      _pendingDiscipline = selected;
    }
  }

  @override
  void dispose() {
    _outcomeSave?.cancel();
    _outcome.dispose();
    super.dispose();
  }

  bool get _reduced =>
      reduceMotion(context, learnerSetting: widget.learning.reducedMotion);

  Future<bool> _persist(void Function(OnboardingState o) change) async {
    try {
      await _save(widget.learning, change);
      if (mounted) setState(() => _error = null);
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Couldn’t save on this device. Your answer is still here. Try again.',
        );
      }
      return false;
    }
  }

  Future<void> _goTo(int next) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _forward = next > step;
    });
    await _persist((o) => o.stepIndex = next);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _back() async {
    if (step == OnboardingStep.promise) return;
    var previous = step - 1;
    // The baseline step exists only on the Find my level route (ONB-08).
    if (previous == OnboardingStep.baseline && o.startingRoute != 'level') {
      previous = OnboardingStep.route;
    }
    await _goTo(previous);
  }

  bool _valid(int s) {
    switch (s) {
      case OnboardingStep.discipline:
        return _pendingDiscipline != null;
      case OnboardingStep.outcome:
        final n = _outcome.text.trim().length;
        return n >= 20 && n <= 200;
      case OnboardingStep.motivation:
        return o.motivation != null;
      case OnboardingStep.level:
        return o.proficiency != null;
      case OnboardingStep.goal:
        return o.dailyMinutes != null;
      case OnboardingStep.route:
        return o.startingRoute != null;
      case OnboardingStep.baseline:
        return widget.learning.baselineDone(widget.catalog);
      default:
        return true;
    }
  }

  Future<void> _continue() async {
    if (_busy || !_valid(step)) return;
    switch (step) {
      case OnboardingStep.discipline:
        final id = _pendingDiscipline!;
        final chosen = widget.disciplines.where((d) => d.id == id).firstOrNull;
        if (chosen == null) return;
        setState(() => _busy = true);
        try {
          await widget.onChooseDiscipline(chosen);
        } catch (_) {
          if (mounted) {
            setState(
              () => _error = 'This discipline could not be opened. Try again.',
            );
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        return;
      case OnboardingStep.outcome:
        _outcomeSave?.cancel();
        final text = _outcome.text.trim();
        if (await _persist((o) => o.outcome = text)) {
          await _goTo(OnboardingStep.motivation);
        }
        return;
      case OnboardingStep.route:
        await _goTo(
          o.startingRoute == 'level'
              ? OnboardingStep.baseline
              : OnboardingStep.reveal,
        );
        return;
      case OnboardingStep.reveal:
        setState(() => _busy = true);
        try {
          await FinishOnboarding(
            widget.store,
          )(widget.learning, trackId: widget.catalog.id);
          widget.onFinished();
        } catch (_) {
          if (mounted) {
            setState(
              () => _error =
                  'Couldn’t save your route on this device. Try again.',
            );
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        return;
      default:
        await _goTo(step + 1);
    }
  }

  Future<void> _runBaseline() async {
    final record = RecordAttempt(widget.store);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentScreen(
          catalog: widget.catalog,
          existing: List.of(widget.learning.attempts),
          onAttempt: (a) => record(widget.learning, widget.catalog, a),
        ),
      ),
    );
    if (!mounted) return;
    if (widget.learning.baselineDone(widget.catalog)) {
      await _goTo(OnboardingStep.reveal);
    } else {
      setState(() {});
    }
  }

  Future<void> _openCustomSheet() async {
    final outcome = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SumiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const _CustomGoalSheet(),
    );
    if (outcome == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onChooseCustom(outcome);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t save your goal. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = step;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = SumiLayout.gutter(width);
    final body = KeyedSubtree(
      key: ValueKey('onboarding-step-$s'),
      child: s == OnboardingStep.promise
          ? _promise(context)
          : ListView(
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 24),
              children: [_stepContent(context, s)],
            ),
    );
    return PopScope(
      canPop: s == OnboardingStep.promise,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: SumiColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              if (s != OnboardingStep.promise)
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: _busy ? null : _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: SumiColors.muted,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SumiProgressBar(
                          value: (s + 1) / OnboardingStep.total,
                          semanticLabel: 'Setup progress',
                          semanticValue: s + 1,
                          semanticMax: OnboardingStep.total,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: _reduced ? Duration.zero : SumiMotion.screen,
                  switchInCurve: SumiMotion.screenCurve,
                  switchOutCurve: SumiMotion.screenCurve,
                  transitionBuilder: (child, animation) {
                    final incoming =
                        child.key == ValueKey('onboarding-step-$s');
                    final dir = (_forward == incoming) ? 1.0 : -1.0;
                    return SlideTransition(
                      position: Tween(
                        begin: Offset(dir, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: body,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                  child: InlineError(_error!, onRetry: _continue),
                ),
              if (s != OnboardingStep.promise) _footer(context, s, gutter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, int s, double gutter) {
    final label = switch (s) {
      OnboardingStep.reveal => OnboardingCopy.revealCta,
      OnboardingStep.baseline =>
        widget.learning.attempts.isEmpty
            ? OnboardingCopy.baselineCta
            : widget.learning.baselineDone(widget.catalog)
            ? OnboardingCopy.cta
            : OnboardingCopy.baselineResume,
      _ => OnboardingCopy.cta,
    };
    final VoidCallback? action;
    if (_busy) {
      action = null;
    } else if (s == OnboardingStep.baseline &&
        !widget.learning.baselineDone(widget.catalog)) {
      action = _runBaseline;
    } else if (s == OnboardingStep.discipline &&
        _pendingDiscipline == 'custom') {
      action = _openCustomSheet;
    } else {
      action = _valid(s) ? _continue : null;
    }
    return Container(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 16),
      decoration: const BoxDecoration(
        color: SumiColors.surface,
        border: Border(top: BorderSide(color: SumiColors.border, width: 2)),
      ),
      child: TactileButton(label, onPressed: action, loading: _busy),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    ),
  );

  Widget _stepContent(BuildContext context, int s) => switch (s) {
    OnboardingStep.discipline => _discipline(context),
    OnboardingStep.outcome => _outcomeStep(context),
    OnboardingStep.motivation => _motivation(context),
    OnboardingStep.level => _level(context),
    OnboardingStep.preview => _preview(context),
    OnboardingStep.goal => _goal(context),
    OnboardingStep.route => _route(context),
    OnboardingStep.baseline => _baseline(context),
    _ => _reveal(context),
  };

  // ONB-01
  Widget _promise(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    final resume = widget.resumeTrack;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const SumiWordmark(width: 144),
              const SizedBox(height: 16),
              // ONB-01 hero: knowledge tiles flowing along the ink route to
              // the learner's destination (Phase 9).
              const RouteHero(height: 232),
              const SizedBox(height: 24),
              Text(
                OnboardingCopy.promiseTitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: t.displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                OnboardingCopy.promiseSupport,
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: SumiColors.mutedStrong),
              ),
              const SizedBox(height: 32),
              TactileButton(
                OnboardingCopy.promiseCta,
                onPressed: _busy ? null : () => _goTo(OnboardingStep.discipline),
              ),
              if (resume != null && widget.onResume != null) ...[
                const SizedBox(height: 12),
                TactileButton(
                  OnboardingCopy.promiseResume,
                  variant: TactileVariant.outline,
                  onPressed: _busy ? null : () => widget.onResume!(resume),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ONB-02
  Widget _discipline(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    Widget card(String id, String title, String subtitle, IconData? icon) {
      final selected = _pendingDiscipline == id;
      return ChoiceRow(
        label: title,
        subtitle: subtitle,
        state: selected ? ChoiceState.selected : ChoiceState.idle,
        leading: const DisciplineScene(scene: 'custom', size: 44),
        onTap: _busy
            ? null
            : () {
                selectionHaptic(widget.learning.hapticsEnabled);
                setState(() => _pendingDiscipline = id);
              },
      );
    }

    final tracks = widget.disciplines.where((d) => !d.isCustom).toList();
    final columns = width >= 320 ? 2 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, OnboardingCopy.disciplineHeading),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 2 ? .78 : 2.2,
          children: [
            for (final d in tracks)
              _DisciplineCard(
                title: d.title,
                subtitle:
                    OnboardingCopy.disciplineSubtitles[d.id] ?? d.description,
                scene: d.scene,
                selected: _pendingDiscipline == d.id,
                onTap: _busy
                    ? null
                    : () {
                        selectionHaptic(widget.learning.hapticsEnabled);
                        setState(() => _pendingDiscipline = d.id);
                      },
              ),
          ],
        ),
        const SizedBox(height: 12),
        card(
          'custom',
          OnboardingCopy.customTitle,
          OnboardingCopy.customSubtitle,
          null,
        ),
        if (_pendingDiscipline == 'custom') ...[
          const SizedBox(height: 12),
          Text(
            'You’ll describe it on the next screen. Sumi only shows lessons once a plan is validated.',
            style: t.bodyMedium,
          ),
        ],
      ],
    );
  }

  // ONB-03
  Widget _outcomeStep(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final length = _outcome.text.trim().length;
    final tooLong = length > 200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.outcomeHeading),
        if (widget.catalog.outcomeChips.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final chip in widget.catalog.outcomeChips.take(4))
                SumiChip(
                  label: chip,
                  prompt: true,
                  onTap: () {
                    _outcome.text = chip.length >= 20
                        ? chip
                        : '$chip so I can use it in a real project';
                    _outcome.selection = TextSelection.collapsed(
                      offset: _outcome.text.length,
                    );
                    _scheduleOutcomeSave();
                    setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text('Your outcome', style: t.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _outcome,
          minLines: 3,
          maxLines: 5,
          scrollPadding: const EdgeInsets.only(bottom: 160),
          inputFormatters: [LengthLimitingTextInputFormatter(240)],
          decoration: InputDecoration(
            helperText: OnboardingCopy.outcomeHelper,
            helperMaxLines: 2,
            counterText: '$length/200',
            counterStyle: t.bodySmall?.copyWith(
              color: tooLong ? SumiColors.errorInk : SumiColors.mutedStrong,
            ),
            errorText: tooLong ? 'Keep it to 200 characters or fewer.' : null,
          ),
          onChanged: (_) {
            _scheduleOutcomeSave();
            setState(() {});
          },
        ),
        const SizedBox(height: 20),
        Text('Deadline (optional)', style: t.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final d in OnboardingCopy.deadlines)
              SumiChip(
                label: d == 'Custom date' && _isDate(o.deadline)
                    ? o.deadline!
                    : d,
                selected: d == 'Custom date'
                    ? _isDate(o.deadline)
                    : o.deadline == d,
                onTap: () => d == 'Custom date'
                    ? _pickDate()
                    : _persist((o) => o.deadline = o.deadline == d ? null : d),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Anything Sumi should plan around? (optional)', style: t.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final c in OnboardingCopy.constraints)
              SumiChip(
                label: c,
                selected: o.constraints.contains(c),
                onTap: () => _persist((o) {
                  if (!o.constraints.remove(c)) o.constraints.add(c);
                }),
              ),
          ],
        ),
      ],
    );
  }

  static bool _isDate(String? v) =>
      v != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      initialDate: now.add(const Duration(days: 30)),
    );
    if (picked == null) return;
    await _persist((o) => o.deadline = EngagementState.dayKey(picked));
  }

  void _scheduleOutcomeSave() {
    _outcomeSave?.cancel();
    final text = _outcome.text.trim();
    if (text.length < 20 || text.length > 200) return;
    _outcomeSave = Timer(const Duration(milliseconds: 400), () {
      _persist((o) => o.outcome = text);
    });
  }

  Widget _choiceList(
    List<String> options,
    String? selected,
    void Function(OnboardingState o, String value) apply, {
    SumiGlyphKind? glyph,
    List<String>? trailing,
  }) => Column(
    children: [
      for (var i = 0; i < options.length; i++) ...[
        ChoiceRow(
          label: options[i],
          subtitle: trailing?[i],
          index: i + 1,
          count: options.length,
          state: selected == options[i]
              ? ChoiceState.selected
              : ChoiceState.idle,
          leading: glyph == null
              ? null
              : SumiGlyph(glyph, size: 28, color: SumiColors.mutedStrong),
          onTap: () {
            selectionHaptic(widget.learning.hapticsEnabled);
            _persist((o) => apply(o, options[i]));
          },
        ),
        const SizedBox(height: 12),
      ],
    ],
  );

  // ONB-04
  Widget _motivation(BuildContext context) {
    final support = OnboardingCopy.motivationSupport[o.motivation];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.motivationHeading),
        _choiceList(
          OnboardingCopy.motivations,
          o.motivation,
          (o, v) => o.motivation = v,
          glyph: SumiGlyphKind.quest,
        ),
        if (support != null)
          Semantics(
            liveRegion: true,
            child: Text(support, style: Theme.of(context).textTheme.bodyLarge),
          ),
      ],
    );
  }

  // ONB-05 (self-report only: never changes evidence)
  Widget _level(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(context, OnboardingCopy.levelHeading),
      _choiceList(
        OnboardingCopy.levels,
        o.proficiency,
        (o, v) => o.proficiency = v,
        glyph: SumiGlyphKind.practice,
      ),
    ],
  );

  // ONB-06
  Widget _preview(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rows = widget.catalog.previewCapabilities.length >= 3
        ? widget.catalog.previewCapabilities.take(3).toList()
        : OnboardingCopy.previewGeneric(
            o.outcome.isEmpty ? widget.catalog.title : o.outcome,
          );
    const icons = [
      SumiGlyphKind.lesson,
      SumiGlyphKind.project,
      SumiGlyphKind.review,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.previewHeading),
        if (widget.catalog.isCustom) ...[
          _tag('PROVISIONAL'),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: SumiColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SumiGlyph(icons[i], color: SumiColors.successInk),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(rows[i], style: t.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: SumiColors.amberSoft,
      borderRadius: BorderRadius.circular(SumiRadius.pill),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: sumiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: SumiColors.warningInk,
      ),
    ),
  );

  // ONB-07
  Widget _goal(BuildContext context) {
    final minutes = o.dailyMinutes;
    final range = minutes == null
        ? null
        : estimateFirstProjectSessions(widget.catalog, minutes);
    final options = OnboardingCopy.goalLabels.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.goalHeading),
        for (var i = 0; i < options.length; i++) ...[
          ChoiceRow(
            label: '${options[i]} min/day',
            index: i + 1,
            count: options.length,
            state: minutes == options[i]
                ? ChoiceState.selected
                : ChoiceState.idle,
            leading: Text(
              OnboardingCopy.goalLabels[options[i]]!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            onTap: () {
              selectionHaptic(widget.learning.hapticsEnabled);
              _persist((o) => o.dailyMinutes = options[i]);
            },
          ),
          const SizedBox(height: 12),
        ],
        if (range != null) ...[
          _tag('PROVISIONAL'),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              OnboardingCopy.workload(minutes!, range.$1, range.$2),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ],
    );
  }

  // ONB-08
  Widget _route(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(context, OnboardingCopy.routeHeading),
      ChoiceRow(
        label: OnboardingCopy.routeBasicsTitle,
        subtitle: OnboardingCopy.routeBasicsBody,
        index: 1,
        count: 2,
        state: o.startingRoute == 'basics'
            ? ChoiceState.selected
            : ChoiceState.idle,
        leading: const SumiGlyph(SumiGlyphKind.lesson, size: 32, color: SumiColors.mutedStrong),
        onTap: () => _persist((o) => o.startingRoute = 'basics'),
      ),
      const SizedBox(height: 12),
      ChoiceRow(
        label: OnboardingCopy.routeLevelTitle,
        subtitle: OnboardingCopy.routeLevelBody,
        index: 2,
        count: 2,
        state: o.startingRoute == 'level'
            ? ChoiceState.selected
            : ChoiceState.idle,
        leading: const SumiGlyph(SumiGlyphKind.observe, size: 32, color: SumiColors.mutedStrong),
        onTap: () => _persist((o) => o.startingRoute = 'level'),
      ),
    ],
  );

  // ONB-09 entry
  Widget _baseline(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final answered = widget.catalog.questions
        .where((q) => widget.learning.attempts.any((a) => a.questionId == q.id))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.baselineHeading),
        Text(OnboardingCopy.baselineBody, style: t.bodyLarge),
        if (answered > 0) ...[
          const SizedBox(height: 16),
          Text(
            '$answered of ${widget.catalog.questions.length} answered. Your answers are saved.',
            style: t.bodyMedium,
          ),
        ],
      ],
    );
  }

  // ONB-10
  Widget _reveal(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final learning = widget.learning;
    final c = widget.catalog;
    final basics = o.startingRoute != 'level';
    final checks = c.questions
        .where((q) => learning.attempts.any((a) => a.questionId == q.id))
        .length;
    final independent = learning.independent(c).length;
    final confidence = basics || checks < 3
        ? 'EARLY'
        : independent >= 4
        ? 'SUPPORTED'
        : 'GROWING';
    final units = LearningUnit.forCatalog(c);
    final preview = c.milestones.take(5).toList();
    final firstProject = c.milestones
        .where((m) => m.type == NodeType.projectStep)
        .firstOrNull;
    final range = estimateFirstProjectSessions(c, o.dailyMinutes ?? 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, OnboardingCopy.revealHeading),
        SumiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.title, style: t.bodySmall),
              const SizedBox(height: 4),
              Text(o.outcome, style: t.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${o.dailyMinutes ?? 10} min/day · ${o.deadline == null || o.deadline == 'None' ? 'No deadline' : o.deadline}',
                style: t.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                basics
                    ? OnboardingCopy.revealChoice
                    : OnboardingCopy.revealEvidence(checks),
                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _tag(confidence),
          ],
        ),
        const SizedBox(height: 16),
        _MiniPath(nodes: preview, reducedMotion: _reduced),
        const SizedBox(height: 16),
        if (firstProject != null)
          Text('First thing you’ll make: ${firstProject.deliverable}', style: t.bodyLarge),
        const SizedBox(height: 8),
        Text(
          'Roughly ${range.$1}–${range.$2} sessions to your first project · ${units.length} units',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        SumiCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(OnboardingCopy.revealWhy, style: t.titleMedium),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What Sumi observed', style: t.bodySmall),
                const SizedBox(height: 4),
                Text(
                  basics
                      ? 'You chose to start from the basics, so there are no starting checks yet. Your first lesson includes three light checks.'
                      : '$checks starting checks answered; $independent answered correctly on the first try without a hint.',
                  style: t.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text('What Sumi assumed', style: t.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'Your experience level (“${o.proficiency ?? 'not given'}”) and the session estimate are starting guesses. They change as you practise.',
                  style: t.bodyLarge,
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final String title, subtitle;
  final String scene;
  final bool selected;
  final VoidCallback? onTap;
  const _DisciplineCard({
    required this.title,
    required this.subtitle,
    required this.scene,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $subtitle${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            color: selected ? SumiColors.skyShadow : SumiColors.borderShadow,
            borderRadius: BorderRadius.circular(SumiRadius.r16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? SumiColors.skySoft : Colors.white,
              borderRadius: BorderRadius.circular(SumiRadius.r16),
              border: Border.all(
                color: selected ? SumiColors.sky : SumiColors.border,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : SumiColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(SumiRadius.r16),
                      ),
                      child: DisciplineScene(scene: scene, size: 72),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: t.titleMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: t.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.check_circle_rounded, color: SumiColors.sky, size: 24),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ONB-10 mini path preview: the first nodes at a small scale, revealed with
/// `pathReveal` (instant under reduced motion).
class _MiniPath extends StatelessWidget {
  final List<Milestone> nodes;
  final bool reducedMotion;
  const _MiniPath({required this.nodes, required this.reducedMotion});


  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Route preview: ${nodes.map((n) => n.title).join(', ')}',
    excludeSemantics: true,
    child: Column(
      children: [
        for (var i = 0; i < nodes.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
            duration: reducedMotion
                ? Duration.zero
                : SumiMotion.pathReveal + Duration(milliseconds: 60 * i),
            curve: SumiMotion.cardCurve,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: (i % 4 == 1) ? 0 : (i % 4 == 3 ? 64 : 32),
                right: (i % 4 == 1) ? 64 : (i % 4 == 3 ? 0 : 32),
                bottom: 8,
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: i == 0 ? SumiColors.primary : SumiColors.disabled,
                  shape: BoxShape.circle,
                  border: Border(
                    bottom: BorderSide(
                      color: i == 0 ? SumiColors.primaryShadow : SumiColors.borderShadow,
                      width: 4,
                    ),
                  ),
                ),
                child: Center(
                  child: SumiGlyph(
                    glyphForNode(nodes[i].type),
                    color: i == 0 ? Colors.white : SumiColors.disabledText,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CustomGoalSheet extends StatefulWidget {
  const _CustomGoalSheet();
  @override
  State<_CustomGoalSheet> createState() => _CustomGoalSheetState();
}

class _CustomGoalSheetState extends State<_CustomGoalSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final text = _controller.text.trim();
    final valid = text.length >= 3 && text.length <= 200;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final gutter = SumiLayout.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: SumiColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(OnboardingCopy.customSheetLabel, style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: InputDecoration(
              counterText: '${text.length}/200',
              hintText: 'For example: throw a simple pot on a wheel',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TactileButton(
            OnboardingCopy.cta,
            onPressed: valid ? () => Navigator.pop(context, text) : null,
          ),
        ],
      ),
    );
  }
}
