import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'adaptation_screen.dart';
import 'application/use_cases.dart';
import 'assessment.dart';
import 'challenge_screen.dart';
import 'custom/custom_goal_screen.dart';
import 'custom/custom_plan.dart';
import 'custom/custom_plan_screen.dart';
import 'design_system/app_settings.dart';
import 'design_system/bottom_nav.dart';
import 'design_system/routes.dart';
import 'engagement/streak_screen.dart';
import 'learning_path/learning_path_state.dart';
import 'learning_path/path_screen.dart';
import 'learning_session/learning_session_controller.dart';
import 'learning_session/lesson_loading_screen.dart';
import 'models.dart';
import 'on_device.dart';
import 'onboarding/onboarding_flow.dart';
import 'phone_models_screen.dart';
import 'resource_detail_screen.dart';
import 'resource_system.dart';
import 'services.dart';
import 'settings/settings_screen.dart';
import 'shell/recovery_screen.dart';
import 'tabs/library_tab.dart';
import 'tabs/practice_tab.dart';
import 'tabs/profile_tab.dart';
import 'theme.dart';
import 'tutor_chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SumiApp());
}


class SumiApp extends StatelessWidget {
  final LocalStore? store;
  const SumiApp({super.key, this.store});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<LearnerSettings>(
    valueListenable: appSettings,
    builder: (context, settings, _) => MaterialApp(
      title: 'Sumi · a little closer',
      debugShowCheckedModeBanner: false,
      theme: sumiTheme(highContrast: settings.highContrast),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, box) {
            final framed = box.maxWidth > 600;
            final width = math.min(600.0, box.maxWidth);
            final height = box.maxHeight - (framed ? 32 : 0);
            final media = MediaQuery.of(context);
            return ColoredBox(
              color: SumiColors.disabled,
              child: Center(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(framed ? 26 : 0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(framed ? 26 : 0),
                    child: MediaQuery(
                      data: media.copyWith(
                        size: Size(width, height),
                        // A11Y-04: "Larger" multiplies the system text size.
                        textScaler: settings.textScale == 1.0
                            ? media.textScaler
                            : _ScaledTextScaler(
                                media.textScaler,
                                settings.textScale,
                              ),
                        disableAnimations:
                            media.disableAnimations || settings.reducedMotion,
                      ),
                      child: child!,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: LearningHome(store: store),
    ),
  );
}

class _ScaledTextScaler extends TextScaler {
  final TextScaler base;
  final double factor;
  const _ScaledTextScaler(this.base, this.factor);
  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.scale(14) / 14 * factor;
  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler && other.base == base && other.factor == factor;
  @override
  int get hashCode => Object.hash(base, factor);
}

class LearningHome extends StatefulWidget {
  final LocalStore? store;
  const LearningHome({super.key, this.store});
  @override
  State<LearningHome> createState() => _LearningHomeState();
}

class _LearningHomeState extends State<LearningHome>
    with WidgetsBindingObserver {
  late final store = widget.store ?? LocalStore();
  late ResourceRepository repository = ResourceRepository();
  final ranker = ResourceRanker();
  final phoneCoach = PhoneModelController();
  List<Catalog> disciplines = [];
  Catalog? catalog;
  LearningState? saved;
  LearningState get learning => saved!;
  Catalog? resumeTrack;
  int tab = 0; // 0: Learn, 1: Practice, 2: Library, 3: Profile
  bool loaded = false;
  bool _sessionOpen = false;
  bool _recovery = false;
  String? bootError;

  late final _updateSetting = UpdateSetting(store);
  late final _resourceUse = RecordResourceUse(store);
  late final _toggleSave = ToggleSaveResource(store);
  late final _recordAttempt = RecordAttempt(store);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    phoneCoach.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && phoneCoach.generating) {
      phoneCoach.cancel();
    }
  }

  void _publishSettings() {
    final s = saved?.settings;
    if (s != null) appSettings.value = LearnerSettings.fromJson(s.toJson());
  }

  /// SHL-05: loads content, custom goals and the active learner record. An
  /// unreadable record shows the recovery screen, never a silent reset.
  Future<void> boot() async {
    setState(() {
      bootError = null;
      _recovery = false;
    });
    try {
      final reviewed = await store.disciplines();
      final custom = [
        for (final g in await store.customGoals())
          if (g['id'] is String)
            Catalog.custom(
              OnboardingState(outcome: g['outcome'] as String? ?? ''),
              id: g['id'] as String,
              skills: _planSkills(g['plan']),
            ),
      ];
      final all = [...reviewed, ...custom];
      final selected = await store.activeTrack();
      final content =
          all.where((c) => c.id == selected).firstOrNull ?? all.firstOrNull;
      final data = content == null ? null : await store.load(content.id);
      Catalog? resume;
      if (data != null && !data.onboarding.completionState) {
        for (final c in reviewed.where((c) => c.id != content!.id)) {
          try {
            final other = await store.load(c.id);
            if (other.onboarding.completionState) {
              resume = c;
              break;
            }
          } catch (_) {}
        }
      }
      if (!mounted) return;
      setState(() {
        catalog = content;
        saved = data;
        disciplines = all;
        resumeTrack = resume;
        repository = ResourceRepository(
          localCatalogue: reviewed.expand((c) => c.resources).toList(),
        );
        loaded = true;
      });
      _publishSettings();
    } on MigrationException {
      if (mounted) setState(() => _recovery = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => bootError =
              'We couldn’t open your learning space. Please try again.',
        );
      }
    }
  }

  static List<Json> _planSkills(dynamic plan) {
    if (plan is! List) return const [];
    final steps = plan.whereType<Map>().map((m) => Json.from(m)).toList();
    return CustomPlan.validate(steps).ok ? CustomPlan.skills(steps) : const [];
  }

  /// CUS-02: confirm a validated plan, finish this goal's onboarding, and
  /// show its provisional path.
  Future<void> _confirmPlan(List<Json> steps) async {
    final c = catalog!;
    await FinishOnboarding(store)(learning, trackId: c.id);
    await store.saveCustomPlan(c.id, steps);
    final withPlan = Catalog.custom(
      OnboardingState(outcome: learning.onboarding.outcome),
      id: c.id,
      skills: CustomPlan.skills(steps),
    );
    if (!mounted) return;
    setState(() {
      disciplines = [
        for (final d in disciplines) d.id == c.id ? withPlan : d,
      ];
      catalog = withPlan;
      tab = 0;
    });
  }

  void _openPlanDraft() {
    final c = catalog!;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (routeContext) => CustomPlanScreen(
          goalId: c.id,
          outcome: learning.onboarding.outcome.isNotEmpty
              ? learning.onboarding.outcome
              : c.title,
          modelName: phoneCoach.activeName ?? 'The offline model',
          dailyMinutes: learning.dailyMinutes,
          draft: (prompt) => phoneCoach.reply(prompt),
          onStop: phoneCoach.cancel,
          onConfirm: (steps) async {
            await _confirmPlan(steps);
            if (routeContext.mounted) Navigator.pop(routeContext);
          },
          onChooseReviewed: () {
            Navigator.pop(routeContext);
            _backToReviewed();
          },
        ),
      ),
    );
  }

  Future<void> _startFresh() async {
    final id = await store.activeTrack();
    if (id != null) await store.clearTrack(id);
    await boot();
  }

  Future<void> selectDiscipline(Catalog selected) async {
    try {
      final state = await store.load(selected.id);
      await store.setActiveTrack(selected.id);
      if (!mounted) return;
      setState(() {
        catalog = selected;
        saved = state;
        tab = 0;
      });
      _publishSettings();
    } catch (_) {
      message('This discipline could not be opened. Try again.');
    }
  }

  /// ONB-02 / ONB-12: switch to the chosen track and record the choice on that
  /// track's own record, then continue onboarding there.
  Future<void> chooseDiscipline(Catalog chosen) async {
    final state = await store.load(chosen.id);
    if (!state.onboarding.completionState) {
      await SaveOnboardingAnswer(store)(state, (o) {
        o.selectedDiscipline = chosen.id;
        if (o.stepIndex < OnboardingStep.outcome) {
          o.stepIndex = OnboardingStep.outcome;
        }
      });
    }
    await store.setActiveTrack(chosen.id);
    if (!mounted) return;
    setState(() {
      catalog = chosen;
      saved = state;
      tab = 0;
    });
    _publishSettings();
  }

  /// CUS-01: a unique goal with its own isolated record.
  Future<void> chooseCustom(String outcome) async {
    final id = Catalog.newCustomId();
    final custom = Catalog.custom(OnboardingState(outcome: outcome), id: id);
    final record = LearningState(
      trackId: id,
      goal: outcome,
      settings: LearnerSettings.fromJson(learning.settings.toJson()),
      onboarding: OnboardingState(
        selectedDiscipline: id,
        outcome: outcome,
        stepIndex: OnboardingStep.discipline,
      ),
    );
    await store.addCustomGoal({
      'id': id,
      'outcome': outcome,
      'created_at': DateTime.now().toIso8601String(),
    }, record);
    await store.setActiveTrack(id);
    if (!mounted) return;
    setState(() {
      disciplines = [...disciplines, custom];
      catalog = custom;
      saved = record;
    });
  }

  Future<void> _backToReviewed() async {
    final first = disciplines.where((d) => !d.isCustom).firstOrNull;
    if (first == null) return;
    final state = await store.load(first.id);
    if (!state.onboarding.completionState) {
      await SaveOnboardingAnswer(
        store,
      )(state, (o) => o.stepIndex = OnboardingStep.discipline);
    }
    await store.setActiveTrack(first.id);
    if (!mounted) return;
    setState(() {
      catalog = first;
      saved = state;
    });
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  /// One setting change in one transaction (ARC-01).
  Future<void> updateSetting(void Function(LearningState s) change) async {
    await _updateSetting(learning, change);
    if (mounted) setState(() {});
    _publishSettings();
  }

  Future<void> openResource(Resource resource) async {
    try {
      if (!await launchUrl(
        Uri.parse(resource.url),
        mode: LaunchMode.externalApplication,
      )) {
        message('We couldn’t open the resource. Try again in a moment.');
      }
    } catch (_) {
      message('We couldn’t open this resource on your device.');
    }
  }

  /// LIB-03 / LIB-04: impressions and opens are events only.
  Future<void> openResourceDetail(
    Resource resource, {
    String? reasoning,
    VoidCallback? onTakeCheckActivity,
  }) async {
    try {
      await _resourceUse(learning, resource, ResourceEventType.impression);
    } catch (_) {
      // An impression that fails to save never blocks reading the details.
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResourceDetailScreen(
          resource: resource,
          learning: learning,
          reasoning: reasoning,
          onOpenResource: (r) async {
            try {
              await _resourceUse(learning, r, ResourceEventType.opened);
            } catch (_) {}
            await openResource(r);
          },
          onToggleSave: toggleSaveResource,
          onTakeCheckActivity: onTakeCheckActivity,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> toggleSaveResource(Resource resource) async {
    try {
      await _toggleSave(learning, resource);
    } catch (_) {
      message('Couldn’t save that change on this device. Try again.');
    }
    if (mounted) setState(() {});
  }

  Future<void> openTutorChat([String? initialPrompt]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorChatScreen(
          initialPrompt: initialPrompt,
          catalog: catalog!,
          learning: learning,
          repository: repository,
          phoneCoach: phoneCoach,
          onPersist: () async {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  /// Opens a lesson. Returns true when the learner chose CONTINUE on the
  /// result screen, so the path opens the next node's card (RES-04).
  Future<bool> openMilestone(Milestone milestone, {bool lightChecks = false}) async {
    if (_sessionOpen) return false;
    final c = catalog!;
    if (!milestone.prerequisites.every(learning.completed.contains)) {
      message('Finish the prerequisite steps first.');
      return false;
    }
    _sessionOpen = true;
    LearningSessionController? session;
    try {
      final recommendations = ranker.rank(
        candidates: repository.getAllResources(discipline: c.id),
        state: learning,
        catalog: c,
        targetCapability: milestone.id,
      );
      final recommended =
          recommendations
              .where((r) => r.resource.id == milestone.resourceId)
              .firstOrNull ??
          recommendations.firstOrNull;
      final resource = recommended?.resource ?? c.resource(milestone.resourceId);
      final unit = LearningUnit.forCatalog(
        c,
      ).firstWhere((u) => u.nodes.any((n) => n.id == milestone.id));
      // LES-17: a loading screen appears only if opening takes > 150 ms.
      var loadingShown = false;
      final loadingTimer = Timer(LessonLoadingScreen.delay, () {
        if (!mounted) return;
        loadingShown = true;
        Navigator.push(
          context,
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            pageBuilder: (_, _, _) =>
                LessonLoadingScreen(reducedMotion: learning.reducedMotion),
          ),
        );
      });
      try {
        session = await LearningSessionController.open(
          store: store,
          learning: learning,
          catalog: c,
          node: milestone,
          unitId: unit.id,
          lightChecks: lightChecks,
        );
      } finally {
        loadingTimer.cancel();
        if (loadingShown && mounted) Navigator.pop(context);
      }
      if (!mounted) return false;
      final openNext = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => ChallengeScreen(
            controller: session!,
            onOpenResource: () async {
              if (resource != null) {
                await openResourceDetail(
                  resource,
                  reasoning: recommended?.reasoning,
                );
              }
            },
            onAskTutor: (prompt) => openTutorChat(prompt),
          ),
        ),
      );
      return openNext == true;
    } catch (_) {
      message(
        'This lesson could not be saved or opened. Your progress is unchanged. Try again.',
      );
      return false;
    } finally {
      _sessionOpen = false;
      session?.dispose();
      if (mounted) setState(() {});
    }
  }

  /// ONB-10: START FIRST LESSON shows the path and opens the first lesson.
  void _onboardingFinished() {
    setState(() => tab = 0);
    final next = const GetNextLearningSession()(learning, catalog!);
    if (next == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openMilestone(next.node, lightChecks: next.lightChecks);
    });
  }

  Future<void> _openBaseline() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentScreen(
          catalog: catalog!,
          existing: List.of(learning.attempts),
          onAttempt: (a) => _recordAttempt(learning, catalog!, a),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openFollowUp() async {
    final recall = RecordRecallAttempt(store);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentScreen(
          catalog: catalog!.forRecall(),
          existing: List.of(learning.recallAttempts),
          title: 'Follow-up check',
          onAttempt: (a) => recall(learning, a),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openSettings() {
    Navigator.push(
      context,
      slideRoute<void>(
        (_) => SettingsScreen(
          disciplines: disciplines,
          catalog: catalog!,
          learning: learning,
          store: store,
          phoneCoach: phoneCoach,
          onUpdate: updateSetting,
          onSwitchDiscipline: selectDiscipline,
          onDataReplaced: (trackId) async {
            if (trackId == catalog?.id) await selectDiscipline(catalog!);
          },
        ),
        reducedMotion: learning.reducedMotion,
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openModels() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PhoneModelsScreen(controller: phoneCoach),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recovery) {
      return RecoveryScreen(onRetry: boot, onStartFresh: _startFresh);
    }
    if (bootError != null) {
      return RecoveryScreen(onRetry: boot, onStartFresh: _startFresh);
    }
    if (!loaded) return const BootScreen();

    if (catalog == null || saved == null) {
      return const Scaffold(body: Center(child: Text('No disciplines available.')));
    }

    if (catalog!.isCustom && catalog!.milestones.isEmpty) {
      return CustomGoalScreen(
        key: ValueKey('custom-${catalog!.id}'),
        catalog: catalog!,
        learning: learning,
        phoneCoach: phoneCoach,
        onSetUpModel: _openModels,
        onChooseReviewed: _backToReviewed,
        onDraftPlan: _openPlanDraft,
      );
    }

    if (!learning.onboarding.completionState) {
      return OnboardingFlow(
        key: ValueKey('onboarding-${catalog!.id}'),
        catalog: catalog!,
        disciplines: disciplines,
        learning: learning,
        store: store,
        onChooseDiscipline: chooseDiscipline,
        onChooseCustom: chooseCustom,
        onFinished: _onboardingFinished,
        resumeTrack: resumeTrack,
        onResume: selectDiscipline,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: [
          LearnTab(
            key: ValueKey(catalog!.id),
            store: store,
            onOpenResource: (r) => openResourceDetail(r),
            catalog: catalog!,
            learning: learning,
            onOpenMilestone: openMilestone,
            onAskTutor: openTutorChat,
            onAssess: _openBaseline,
          ),
          PracticeTab(
            catalog: catalog!,
            learning: learning,
            onOpenMilestone: openMilestone,
            onFollowUp: _openFollowUp,
            clock: EngagementState.clock,
          ),
          LibraryTab(
            catalog: catalog!,
            allDisciplines: disciplines.where((d) => !d.isCustom).toList(),
            learning: learning,
            repository: repository,
            ranker: ranker,
            onOpenResourceDetail: (r) => openResourceDetail(r),
            onToggleSave: toggleSaveResource,
            onUpdate: updateSetting,
          ),
          ProfileTab(
            catalog: catalog!,
            disciplines: disciplines,
            learning: learning,
            phoneCoach: phoneCoach,
            onSwitchDiscipline: selectDiscipline,
            onOpenSettings: _openSettings,
            onOpenStreak: () => Navigator.push(
              context,
              slideRoute<void>(
                (_) => StreakScreen(
                  engagement: () => learning.engagement,
                  clock: EngagementState.clock,
                  onBuyToken: () async {
                    await BuyRecoveryToken(store)(learning);
                    if (mounted) setState(() {});
                  },
                ),
                reducedMotion: learning.reducedMotion,
              ),
            ),
            onOpenAdaptation: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdaptationScreen(
                  profile: () => learning.adaptationProfile,
                  onUpdate: (change) =>
                      updateSetting((s) => change(s.adaptationProfile)),
                  onResetInferred: () => updateSetting(
                    (s) => s.adaptationProfile.resetInferredPreferences(),
                  ),
                ),
              ),
            ),
            onRemoveEvidence: (sessionId, attemptId) async {
              await RemoveSelfReportedEvidence(
                store,
              )(learning, sessionId, attemptId);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      bottomNavigationBar: SumiBottomNav(
        selectedIndex: tab,
        onSelected: (i) => setState(() => tab = i),
      ),
    );
  }
}

/// The Learn tab: the path for the active track.
class LearnTab extends PathScreen {
  const LearnTab({
    super.key,
    required super.catalog,
    required super.learning,
    required super.store,
    required super.onOpenMilestone,
    required super.onOpenResource,
    required super.onAssess,
    required super.onAskTutor,
  });
}
