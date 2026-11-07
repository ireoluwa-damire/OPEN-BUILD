import 'package:flutter/material.dart';
import '../design_system/app_settings.dart';
import '../design_system/motion.dart';
import '../design_system/routes.dart';
import '../models.dart';
import '../theme.dart';
import '../session_result/session_result.dart';
import '../session_result/session_result_screen.dart';
import 'challenge_definition.dart';
import 'challenge_renderer_registry.dart';
import 'learning_session_controller.dart';
import 'learning_session_state.dart';
import 'explain_mistake_screen.dart';
import 'feedback_panel.dart';
import 'lesson_progress_header.dart';

class LessonShell extends StatefulWidget {
  final LearningSessionController controller;
  final Future<void> Function() onOpenResource;
  final Future<void> Function(String context)? onAskTutor;
  const LessonShell({
    super.key,
    required this.controller,
    required this.onOpenResource,
    this.onAskTutor,
  });
  @override
  State<LessonShell> createState() => _LessonShellState();
}

class _LessonShellState extends State<LessonShell> with WidgetsBindingObserver {
  LearningSessionController get controller => widget.controller;
  bool allowPop = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.lifecycle(false);
    }
    if (state == AppLifecycleState.resumed) controller.lifecycle(true);
  }

  bool get _hasWorkInProgress {
    final st = controller.state;
    return st.attempts.isNotEmpty || st.currentResponseDraft.isNotEmpty;
  }

  /// LES-10 / CF-29: confirm only when there is work in progress.
  Future<void> leave() async {
    if (controller.busy) return;
    if (controller.state.result != null) {
      await finish();
      return;
    }
    if (!_hasWorkInProgress) {
      if (await controller.setExit(SessionExitState.ending) && mounted) pop();
      return;
    }
    if (!await controller.setExit(SessionExitState.confirm) || !mounted) return;
    final exit = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      barrierColor: SumiColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Keep progress and leave?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your checked answers and current draft are saved on this device.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('KEEP LEARNING'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'SAVE & EXIT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SumiColors.mutedStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (exit == true) {
      if (await controller.setExit(SessionExitState.ending) && mounted) pop();
    } else {
      await controller.setExit(SessionExitState.none);
    }
  }

  /// Pops the lesson. [openNext] tells the path to open the next node's card
  /// after its events play (RES-04).
  void pop([bool openNext = false]) {
    setState(() => allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, openNext);
    });
  }

  Future<void> finish({bool openNext = true}) async {
    if (await controller.acknowledgeResult() && mounted) pop(openNext);
  }

  Future<void> _setLearnerFlag(
    BuildContext context,
    void Function(LearningState s) apply,
    void Function() refresh,
  ) async {
    try {
      await controller.store.transaction(controller.learning, (s) async {
        apply(s);
      });
      // Publish the saved settings so sound, haptics and motion follow them
      // straight away (SND-01/02), as Settings does.
      appSettings.value = LearnerSettings.fromJson(
        controller.learning.settings.toJson(),
      );
      if (context.mounted) refresh();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting could not be saved.')),
        );
      }
    }
  }

  /// LES-09: lesson settings. Changes persist immediately; the draft stays.
  Future<void> settings() async {
    if (!await controller.setSettings(true) || !mounted) return;
    var endSession = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      barrierColor: SumiColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l = controller.learning;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lesson settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound effects'),
                    value: l.soundEffectsEnabled,
                    onChanged: (v) => _setLearnerFlag(
                      context,
                      (s) => s.soundEffectsEnabled = v,
                      () => setSheetState(() {}),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Haptics'),
                    value: l.hapticsEnabled,
                    onChanged: (v) => _setLearnerFlag(
                      context,
                      (s) => s.hapticsEnabled = v,
                      () => setSheetState(() {}),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reduced motion'),
                    value: l.reducedMotion,
                    onChanged: (v) => _setLearnerFlag(
                      context,
                      (s) => s.reducedMotion = v,
                      () => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Focus never blocks learning or explanations.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        await controller.recoverFocus();
                        if (context.mounted) setSheetState(() {});
                      },
                      child: const Text('REFILL FOCUS'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: SumiColors.sky,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('DONE'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      endSession = true;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'END SESSION',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SumiColors.errorInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) await controller.setSettings(false);
    if (endSession && mounted) await leave();
  }

  Future<void> explain() async {
    if (!await controller.setExplanation(ExplanationState.authored) ||
        !mounted) {
      return;
    }
    await Navigator.push(
      context,
      slideRoute<void>(
        (context) => ExplainMistakeScreen(
          controller: controller,
          onOpenResource: widget.onOpenResource,
          onAskTutor: widget.onAskTutor,
        ),
        reducedMotion: controller.learning.reducedMotion,
      ),
    );
    if (mounted) await controller.setExplanation(ExplanationState.closed);
  }

  void review() {
    final state = controller.state;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Saved session evidence')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final a in state.attempts) ...[
                Text(
                  state.challenges
                      .firstWhere((c) => c.id == a.challengeId)
                      .prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  a.outcome.name,
                  style: TextStyle(color: feedbackColor(a.outcome)),
                ),
                const SizedBox(height: 10),
                ChallengeRendererRegistry.build(
                  ChallengeRenderContext(
                    challenge: state.challenges.firstWhere(
                      (c) => c.id == a.challengeId,
                    ),
                    draft: a.response,
                    feedback: a.outcome,
                    readOnly: true,
                    emit: (_) {},
                    openResource: widget.onOpenResource,
                  ),
                ),
                const Divider(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final state = controller.state;
      final child = state.result != null
          ? SessionResultScreen(
              result: SessionResult.fromJson(state.result!),
              onContinue: finish,
              onReturn: () => finish(openNext: false),
              onReview: review,
              reducedMotion:
                  controller.learning.reducedMotion ||
                  MediaQuery.disableAnimationsOf(context),
              busy: controller.busy,
              error: controller.error,
            )
          : Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(state.focus == 0 ? 92 : 64),
                child: LessonProgressHeader(
                  progress: state.persistedProgress,
                  total: state.originalCount,
                  focus: state.focus,
                  busy: controller.busy,
                  reducedMotion: reduceMotion(
                    context,
                    learnerSetting: controller.learning.reducedMotion,
                  ),
                  onExit: leave,
                  onSettings: settings,
                ),
              ),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        key: ValueKey(state.challenge.id),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        children: [
                          if (LearningSessionState.isRepair(state.challenge))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'REPAIR',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: SumiColors.violetInk),
                              ),
                            ),
                          Text(
                            state.challenge.prompt,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (state.challenge.hint != null &&
                              state.feedbackState == FeedbackState.hidden)
                            _HintToggle(
                              hint: state.challenge.hint!,
                              shown: state.currentResponseDraft['usedHint'] ==
                                  true,
                              onShow: () => controller.updateDraft({
                                ...state.currentResponseDraft,
                                'usedHint': true,
                              }),
                            ),
                          const SizedBox(height: 20),
                          ChallengeRendererRegistry.build(
                            ChallengeRenderContext(
                              challenge: state.challenge,
                              draft: state.currentResponseDraft,
                              feedback: state.feedbackState,
                              readOnly:
                                  controller.busy ||
                                  state.feedbackState != FeedbackState.hidden,
                              reducedMotion:
                                  controller.learning.reducedMotion ||
                                  MediaQuery.disableAnimationsOf(context),
                              emit: (intent) {
                                if (intent is ResponseChanged) {
                                  controller.updateDraft(intent.response);
                                }
                              },
                              openResource: () async {
                                if (await controller.checkpoint()) {
                                  await widget.onOpenResource();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .62,
                      ),
                      child: SingleChildScrollView(
                        child: FeedbackPanel(
                          controller: controller,
                          onExplain: explain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
      return PopScope(
        canPop: allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) leave();
        },
        child: child,
      );
    },
  );
}

/// LES-16: "Show hint" reveals one authored hint. Using it removes the
/// independence credit and the perfect bonus for this item.
class _HintToggle extends StatelessWidget {
  final String hint;
  final bool shown;
  final VoidCallback onShow;
  const _HintToggle({
    required this.hint,
    required this.shown,
    required this.onShow,
  });
  @override
  Widget build(BuildContext context) => shown
      ? Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SumiColors.skySoft,
            borderRadius: BorderRadius.circular(SumiRadius.r12),
          ),
          child: Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: SumiColors.infoInk),
          ),
        )
      : Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onShow,
            child: const Text(
              'Show hint',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: SumiColors.infoInk,
              ),
            ),
          ),
        );
}
