import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models.dart';
import '../services.dart';
import '../adaptation_system.dart';
import '../application/use_cases.dart';
import 'challenge_definition.dart';
import 'learning_session_state.dart';
import '../effects/effects_service.dart';

class LearningSessionController extends ChangeNotifier {
  final LocalStore store;
  final LearningState learning;
  final Catalog catalog;
  LearningSessionState _state;
  LearningSessionState get state => _state;
  bool busy = false, _disposed = false;
  String? error;
  Timer? _draftTimer;
  final Stopwatch _clock = Stopwatch();
  int _clockBase = 0;
  LearningSessionController._(
    this.store,
    this.learning,
    this.catalog,
    this._state,
  ) {
    _clockBase = _state.elapsedMilliseconds;
    _clock.start();
  }

  static Future<LearningSessionController> open({
    required LocalStore store,
    required LearningState learning,
    required Catalog catalog,
    required Milestone node,
    required String unitId,
    bool lightChecks = false,
  }) async {
    if (!node.prerequisites.every(learning.completed.contains)) {
      throw StateError('Prerequisite incomplete');
    }
    final goalId = learning.goalRecord?.id ?? 'goal_${catalog.id}';
    final previous = learning.sessions.values
        .map((j) => LearningSessionState.fromJson(Json.from(j)))
        .where(
          (s) =>
              s.nodeId == node.id &&
              s.goalId == goalId &&
              !s.resultAcknowledged,
        )
        .lastOrNull;
    final state =
        previous?.copyWith(
          lifecycleState: SessionLifecycleState.foreground,
          exitState: SessionExitState.none,
          settingsOpen: false,
          explanationState: ExplanationState.closed,
          submissionState: previous.submissionState == SubmissionState.grading
              ? SubmissionState.idle
              : previous.submissionState,
        ) ??
        LearningSessionState(
          sessionId: '${catalog.id}_${DateTime.now().microsecondsSinceEpoch}',
          goalId: goalId,
          unitId: unitId,
          nodeId: node.id,
          challenges: [
            // ONB-08: the Basics route adds three light CHECK items from the
            // baseline pool to the first lesson.
            if (lightChecks)
              for (final q in catalog.questions.take(3))
                ChallengeDefinition(
                  id: '${node.id}:check:${q.id}',
                  kind: ChallengeKind.singleSelect,
                  prompt: q.prompt,
                  explanation: q.explanation,
                  options: q.options,
                  answer: [q.correct],
                  content: {'check': true, 'hint': q.hint, 'skippable': true},
                ),
            ...challengesFor(catalog, node),
          ],
        );
    await store.transaction(learning, (s) async {
      s.sessions[state.sessionId] = state.toJson();
    });
    return LearningSessionController._(store, learning, catalog, state);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  LearningSessionState _timed(LearningSessionState value) => value.copyWith(
    elapsedMilliseconds: _clockBase + _clock.elapsedMilliseconds,
  );

  /// Publish draft changes immediately for typing. Ordered debounced checkpoints
  /// save them; submit/navigation flushes and always saves the exact response.
  void updateDraft(Json draft) {
    if (busy ||
        state.feedbackState != FeedbackState.hidden ||
        state.result != null) {
      return;
    }
    _state = state.copyWith(
      currentResponseDraft: draft,
      submissionState: SubmissionState.idle,
    );
    error = null;
    _notify();
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 250), () {
      checkpoint();
    });
  }

  Future<bool> _commit(
    LearningSessionState candidate, {
    Future<void> Function(LearningState, LearningSessionState)? mutation,
  }) async {
    if (busy) return false;
    _draftTimer?.cancel();
    busy = true;
    error = null;
    final before = _state;
    final saved = _timed(candidate);
    _state = state.copyWith(submissionState: SubmissionState.grading);
    _notify();
    try {
      await store.transaction(learning, (profile) async {
        profile.sessions[saved.sessionId] = saved.toJson();
        await mutation?.call(profile, saved);
      });
      _state = LearningSessionState.fromJson(
        Json.from(learning.sessions[saved.sessionId]),
      );
      return true;
    } catch (_) {
      _state = before.copyWith(
        submissionState: SubmissionState.failedToPersist,
      );
      error =
          'Couldn’t save on this device. Your response is still here. Try saving again.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> checkpoint() async {
    if (busy) return false;
    _draftTimer?.cancel();
    final captured = state;
    final snapshot = _timed(
      state.copyWith(
        submissionState: state.feedbackState == FeedbackState.hidden
            ? SubmissionState.idle
            : SubmissionState.persisted,
      ),
    );
    try {
      await store.transaction(learning, (s) async {
        s.sessions[snapshot.sessionId] = snapshot.toJson();
      });
      if (identical(_state, captured)) {
        _state = snapshot;
        error = null;
        _notify();
      }
      return true;
    } catch (_) {
      if (identical(_state, captured)) {
        error = 'Couldn’t save your draft. Try again.';
        _notify();
      }
      return false;
    }
  }

  Future<bool> submit() async {
    if (busy || !state.canCheck) return false;
    final grade = state.challenge.grade(state.currentResponseDraft);
    // LES-11 / CF-07: Focus drops once per challenge, only when the first
    // persisted attempt for that challenge is incorrect.
    final firstAttempt = state.attemptsFor(state.challenge.id).isEmpty;
    final attempt = GradedAttempt(
      id: '${state.sessionId}:${state.attempts.length}',
      challengeId: state.challenge.id,
      response: state.currentResponseDraft,
      outcome: grade.outcome,
      reason: grade.reason,
      recordedAt: DateTime.now(),
    );
    final saved = await _commit(
      state.copyWith(
        attempts: [...state.attempts, attempt],
        feedbackState: grade.outcome,
        submissionState: SubmissionState.persisted,
        focus: grade.outcome == FeedbackState.incorrect && firstAttempt
            ? (state.focus - 1).clamp(0, 5)
            : state.focus,
      ),
    );
    // MOT-02 / SND-01: feedback effects only after the attempt is persisted.
    if (saved) {
      switch (grade.outcome) {
        case FeedbackState.correct:
          EffectsService.instance.feedback(SumiSound.correct, SumiHaptic.light);
        case FeedbackState.nearCorrect:
          EffectsService.instance.feedback(SumiSound.partial, SumiHaptic.selection);
        case FeedbackState.incorrect:
          EffectsService.instance.feedback(SumiSound.incorrect, SumiHaptic.medium);
        case FeedbackState.retry || FeedbackState.hidden:
          break;
      }
    }
    return saved;
  }

  /// "I don't know yet" / "Can't do this now" (LES-16): records a skip with no
  /// evidence and no Focus cost, shows the answer, and requeues the item.
  Future<bool> skip() async {
    if (busy ||
        state.feedbackState != FeedbackState.hidden ||
        state.result != null) {
      return false;
    }
    final attempt = GradedAttempt(
      id: '${state.sessionId}:${state.attempts.length}',
      challengeId: state.challenge.id,
      response: {...state.currentResponseDraft, 'skipped': true},
      outcome: FeedbackState.incorrect,
      reason:
          'Skipped for now. ${state.challenge.explanation} This step comes back before the lesson ends.',
      recordedAt: DateTime.now(),
    );
    return _commit(
      state.copyWith(
        attempts: [...state.attempts, attempt],
        feedbackState: FeedbackState.incorrect,
        submissionState: SubmissionState.persisted,
      ),
    );
  }

  /// TRY AGAIN: near-correct (one revision) and ungraded retry only (LES-06/07).
  Future<bool> retry() async {
    if (busy || !state.canTryAgain) return false;
    return _commit(
      state.copyWith(
        currentResponseDraft: {},
        feedbackState: FeedbackState.hidden,
        submissionState: SubmissionState.idle,
      ),
    );
  }

  Future<bool> recoverFocus() => _commit(
    state.copyWith(
      focus: 5,
      submissionState: state.feedbackState == FeedbackState.hidden
          ? SubmissionState.idle
          : SubmissionState.persisted,
    ),
  );

  /// The repair copy appended after an incorrect or near-correct original
  /// (LES-05). Uses the authored parallel variant when the content has one.
  List<ChallengeDefinition> _withRepair(LearningSessionState s) {
    final current = s.challenge;
    if (s.feedbackState == FeedbackState.correct ||
        LearningSessionState.isRepair(current) ||
        s.challenges.any((c) => c.content['repair_of'] == current.id)) {
      return s.challenges;
    }
    final variant = current.content['parallel'];
    final source = variant is Map
        ? ChallengeDefinition.fromJson({
            'id': current.id,
            'kind': current.kind.name,
            'prompt': current.prompt,
            'explanation': current.explanation,
            'options': current.options,
            'answer': current.answer,
            'content': <String, dynamic>{},
            ...Map<String, dynamic>.from(variant),
          })
        : current;
    return [
      ...s.challenges,
      ChallengeDefinition(
        id: '${current.id}~repair',
        kind: source.kind,
        prompt: source.prompt,
        explanation: source.explanation,
        options: source.options,
        answer: source.answer,
        content: {
          ...Map<String, dynamic>.from(source.content)..remove('parallel'),
          'repair_of': current.id,
        },
      ),
    ];
  }

  Future<bool> advance() async {
    if (busy || !state.canContinue || state.result != null) return false;
    final queue = _withRepair(state);
    if (state.currentChallengeIndex + 1 < queue.length) {
      return _commit(
        state.copyWith(
          challenges: queue,
          currentChallengeIndex: state.currentChallengeIndex + 1,
          currentResponseDraft: {},
          feedbackState: FeedbackState.hidden,
          submissionState: SubmissionState.idle,
        ),
      );
    }
    return _commit(
      state,
      mutation: (profile, saved) async {
        // The result is rebuilt from saved attempts inside the same atomic
        // record as completion, rewards, evidence, streak and path events.
        const CompleteActivity().apply(
          profile: profile,
          catalog: catalog,
          saved: saved,
        );
      },
    );
  }

  /// Learner feedback about the current challenge or explanation (calibration
  /// row, "Was this helpful?"). Stored as an adaptation event; never changes
  /// the grade, draft or points.
  Future<bool> recordLearnerFeedback(String kind) async {
    final challengeId = state.challenge.id;
    try {
      await store.transaction(learning, (profile) async {
        profile.adaptationEvents.add(
          AdaptationEvent(
            id: '${state.sessionId}:feedback:${profile.adaptationEvents.length}',
            goalId: state.goalId,
            disciplineId: catalog.id,
            capabilityId: state.nodeId,
            type: AdaptationEventType.learnerFeedback,
            metadata: {'kind': kind, 'challengeId': challengeId},
          ),
        );
        AdaptationEngine().processEvents(
          profile: profile.adaptationProfile,
          events: profile.adaptationEvents,
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setSettings(bool open) => _commit(
    state.copyWith(
      settingsOpen: open,
      submissionState: state.feedbackState == FeedbackState.hidden
          ? SubmissionState.idle
          : SubmissionState.persisted,
    ),
  );
  Future<bool> setExplanation(ExplanationState value) => _commit(
    state.copyWith(
      explanationState: value,
      submissionState: state.feedbackState == FeedbackState.hidden
          ? SubmissionState.idle
          : SubmissionState.persisted,
    ),
  );
  Future<bool> setExit(SessionExitState value) => _commit(
    state.copyWith(
      exitState: value,
      submissionState: state.feedbackState == FeedbackState.hidden
          ? SubmissionState.idle
          : SubmissionState.persisted,
    ),
  );
  Future<bool> acknowledgeResult() =>
      _commit(state.copyWith(resultAcknowledged: true));

  Future<bool> lifecycle(bool foreground) async {
    if (foreground) {
      _clock.start();
    } else {
      _clock.stop();
    }
    // A write already in flight includes the draft it locked; follow it with
    // the lifecycle checkpoint rather than overwriting it with an older draft.
    while (busy && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_disposed) return false;
    return _commit(
      state.copyWith(
        lifecycleState: foreground
            ? SessionLifecycleState.foreground
            : SessionLifecycleState.backgrounded,
        submissionState: state.feedbackState == FeedbackState.hidden
            ? SubmissionState.idle
            : SubmissionState.persisted,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _draftTimer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
