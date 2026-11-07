import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/learning_path/learning_path_controller.dart';
import 'package:sumi/learning_path/learning_path_state.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/learning_session/learning_session_controller.dart';
import 'package:sumi/learning_session/learning_session_state.dart';
import 'package:sumi/engagement/points_policy.dart';
import 'support/memory_preferences.dart';

// Mutable failure controls are deliberate in this storage test double.
// ignore: must_be_immutable
class ControlledPreferences extends MemoryPreferences {
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> setString(String key, String value) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('simulated full disk');
    await super.setString(key, value);
  }
}

Json correctDraft(ChallengeDefinition c) => switch (c.kind) {
  ChallengeKind.singleSelect => {'choice': c.answer.single},
  ChallengeKind.sequenceTokens ||
  ChallengeKind.fashionProcedure => {'order': c.answer},
  ChallengeKind.matchPairs => {'pairs': c.answer},
  ChallengeKind.musicImitate => {
    'taps': [0, 600, 1200, 1800, 2400],
  },
  ChallengeKind.typedReflection => {
    'text': 'I tried a small sample and will adjust the spacing.',
  },
  ChallengeKind.mediaObservation => {
    'observed': true,
    'text': 'I noticed the example uses even spacing.',
  },
  ChallengeKind.drawing => {
    'points': [
      [.1, .1],
      [.5, .5],
      [.9, .9],
    ],
    'text': 'Inspect the seam allowance',
  },
  ChallengeKind.projectReflection => {
    'made': 'A short four-bar rhythm on paper',
    'happened': 'Bar three had one beat too many',
    'change': 'Count each bar aloud before writing',
  },
};

/// GAM-01: points for an all-correct, first-try, no-hint first completion:
/// 10 checked + 5 first try + 5 no hint per challenge, the node's completion
/// bonus, and the perfect-lesson bonus.
int perfectPoints(LearningSessionController c, Milestone node) =>
    c.state.challenges.where((x) => !LearningSessionState.isRepair(x)).length *
        20 +
    PointsPolicy.completionFor(node.type).$2 +
    PointsPolicy.perfect;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  late ControlledPreferences prefs;
  late LocalStore store;
  late LearningState learning;
  Future<LearningSessionController> open([int track = 0]) =>
      LearningSessionController.open(
        store: store,
        learning: learning,
        catalog: tracks[track],
        node: tracks[track].milestones.first,
        unitId: '${tracks[track].id}:unit:0',
      );
  setUpAll(() async {
    tracks =
        (jsonDecode(
                  await rootBundle.loadString('assets/disciplines.json'),
                )['tracks']
                as List)
            .map((j) => Catalog(Json.from(j)))
            .toList();
  });
  setUp(() {
    prefs = ControlledPreferences();
    store = LocalStore(preferences: prefs);
    learning = LearningState(trackId: 'music');
  });

  test(
    'failed and delayed attempts cannot change Focus, points or feedback',
    () async {
      final c = await open();
      addTearDown(c.dispose);
      c.updateDraft({'choice': 3});
      prefs.gate = Completer<void>();
      final submitting = c.submit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.submissionState, SubmissionState.grading);
      expect(c.state.feedbackState, FeedbackState.hidden);
      expect(c.state.focus, 5);
      expect(c.state.attempts, isEmpty);
      expect(learning.engagement.pointsTotal, 0);
      prefs.fail = true;
      prefs.gate!.complete();
      expect(await submitting, isFalse);
      expect(c.state.focus, 5);
      expect(c.state.currentResponseDraft['choice'], 3);
      expect(learning.completed, isEmpty);
      prefs.fail = false;
      prefs.gate = null;
      expect(await c.submit(), isTrue);
      expect(c.state.focus, 4);
      expect(c.state.feedbackState, FeedbackState.incorrect);
      expect(c.state.attempts, hasLength(1));
    },
  );

  test(
    'draft, wrong selection, settings and explanation survive restoration',
    () async {
      var c = await open();
      c.updateDraft({'choice': 2});
      await c.checkpoint();
      await c.setSettings(true);
      await c.lifecycle(false);
      c.dispose();
      learning = await store.load('music');
      c = await open();
      expect(c.state.currentResponseDraft['choice'], 2);
      expect(c.state.settingsOpen, isFalse);
      await c.submit();
      await c.setExplanation(ExplanationState.authored);
      c.dispose();
      learning = await store.load('music');
      c = await open();
      addTearDown(c.dispose);
      expect(c.state.feedbackState, FeedbackState.incorrect);
      expect(c.state.currentResponseDraft['choice'], 2);
      expect(c.state.focus, 4);
      expect(c.state.attempts, hasLength(1));
      expect(c.state.explanationState, ExplanationState.closed);
      // LES-05 / CF-05: an incorrect answer continues and is requeued.
      expect(await c.advance(), isTrue);
      expect(
        c.state.challenges.where(LearningSessionState.isRepair),
        hasLength(1),
      );
    },
  );

  test(
    'near-correct and retry are distinct; focus recovery never blocks learning',
    () async {
      final c = await open();
      addTearDown(c.dispose);
      Future<void> passUntil(ChallengeKind kind) async {
        while (c.state.challenge.kind != kind) {
          c.updateDraft(correctDraft(c.state.challenge));
          await c.submit();
          await c.advance();
        }
      }

      await passUntil(ChallengeKind.sequenceTokens);
      final answer = c.state.challenge.answer;
      // Swap the last two tokens: some positions right, some wrong.
      c.updateDraft({
        'order': [...answer.take(answer.length - 2), answer.last, answer[answer.length - 2]],
      });
      await c.submit();
      expect(c.state.feedbackState, FeedbackState.nearCorrect);
      expect(c.state.focus, 5);
      await c.retry();
      c.updateDraft(correctDraft(c.state.challenge));
      await c.submit();
      await c.advance();
      await passUntil(ChallengeKind.musicImitate);
      c.updateDraft({'retry': true});
      await c.submit();
      expect(c.state.feedbackState, FeedbackState.retry);
      await c.recoverFocus();
      expect(c.state.focus, 5);
      await c.retry();
      expect(c.state.currentResponseDraft, isEmpty);
    },
  );

  test('accessible rhythm reports do not inflate assessed accuracy', () async {
    final c = await open();
    addTearDown(c.dispose);
    for (var i = 0; i < c.state.challenges.length; i++) {
      c.updateDraft(
        c.state.challenge.kind == ChallengeKind.musicImitate
            ? {
                'accessible': true,
                'taps': [0, 1, 2, 3, 4],
              }
            : correctDraft(c.state.challenge),
      );
      await c.submit();
      await c.advance();
    }
    final assessed = c.state.challenges
        .where(
          (x) =>
              !LearningSessionState.isRepair(x) &&
              !x.selfReported &&
              x.kind != ChallengeKind.musicImitate,
        )
        .length;
    expect(
      c.state.result!['evidencePayload']['music']['assessedChallengeCount'],
      assessed,
    );
    expect(c.state.result!['firstAttemptAccuracy'], 1.0);
  });

  for (var track = 0; track < 2; track++) {
    test(
      '${track == 0 ? 'Music' : 'Fashion'} completes atomically, restores result, and replay is idempotent',
      () async {
        learning = LearningState(trackId: tracks[track].id);
        var c = await open(track);
        for (var i = 0; i < c.state.challenges.length; i++) {
          c.updateDraft(correctDraft(c.state.challenge));
          expect(await c.submit(), isTrue);
          if (i + 1 < c.state.challenges.length) {
            expect(await c.advance(), isTrue);
          }
        }
        prefs.fail = true;
        expect(await c.advance(), isFalse);
        expect(learning.completed, isEmpty);
        expect(learning.engagement.pointsTotal, 0);
        expect(learning.pathEvents, isEmpty);
        expect(c.state.result, isNull);
        prefs.fail = false;
        await c.checkpoint();
        expect(await c.advance(), isTrue);
        expect(learning.completed, {tracks[track].milestones.first.id});
        final expected = perfectPoints(c, tracks[track].milestones.first);
        int lessonPoints() => learning.engagement.rewardTransactions
            .where((t) => !t.rewardType.startsWith('quest'))
            .fold(0, (n, t) => n + t.pointsDelta);
        expect(lessonPoints(), expected);
        expect(learning.engagement.streakDays, 1);
        expect(
          c.state.result!['evidencePayload'].keys.single,
          tracks[track].id,
        );
        expect(c.state.result!['firstAttemptAccuracy'], 1.0);
        final id = c.state.sessionId;
        c.dispose();
        learning = await store.load(tracks[track].id);
        c = await open(track);
        expect(c.state.sessionId, id);
        expect(c.state.result, isNotNull);
        await c.acknowledgeResult();
        c.dispose();
        c = await open(track);
        for (var i = 0; i < c.state.challenges.length; i++) {
          c.updateDraft(correctDraft(c.state.challenge));
          await c.submit();
          await c.advance();
        }
        expect(c.state.result!['pointsAwarded'], 0);
        expect(lessonPoints(), expected);
        c.dispose();
      },
    );
  }

  test(
    'concurrent saves keep the newest draft and do not overwrite a submitted attempt',
    () async {
      final c = await open();
      addTearDown(c.dispose);
      c.updateDraft({'choice': 2});
      prefs.gate = Completer<void>();
      final firstSave = c.checkpoint();
      c.updateDraft(correctDraft(c.state.challenge));
      final submit = c.submit();
      prefs.gate!.complete();
      await firstSave;
      await submit;
      expect(c.state.feedbackState, FeedbackState.correct);
      final restored = LearningSessionState.fromJson(
        Json.from((await store.load('music')).sessions[c.state.sessionId]),
      );
      expect(restored.feedbackState, FeedbackState.correct);
      expect(restored.attempts, hasLength(1));
    },
  );

  test(
    'path triggers play once, in order, after persisted completion; scroll restores',
    () async {
      final path = LearningPathController(
        catalog: tracks.first,
        learning: learning,
        store: store,
      );
      final node = tracks.first.milestones.first;
      path.press(node.id);
      expect(path.presentation(node).isPressed, isTrue);
      path.press(null);
      path.scrollTo(173.25);
      await path.persistContext();
      await store.transaction(learning, (s) async {
        s.completed.add(node.id);
        s.pathEvents.addAll([
          {'id': 'event1', 'nodeId': node.id, 'trigger': 'completeNode'},
          {
            'id': 'event2',
            'nodeId': tracks.first.milestones[1].id,
            'trigger': 'unlock',
          },
        ]);
      });
      path.refresh();
      expect(path.presentation(tracks.first.milestones[1]).isActive, isFalse);
      final fired = <String>{};
      path.addListener(() {
        for (final n in tracks.first.milestones) {
          final p = path.presentation(n);
          if (p.pendingTrigger != PathTrigger.none) fired.add(p.eventId!);
        }
      });
      await path.playPending(reducedMotion: true);
      await path.playPending(reducedMotion: true);
      expect(fired.toList(), ['event1', 'event2']);
      expect(learning.pathEvents, isEmpty);
      expect(path.presentation(tracks.first.milestones[1]).isActive, isTrue);
      path.dispose();
      final restored = LearningPathController(
        catalog: tracks.first,
        learning: await store.load('music'),
        store: store,
      );
      expect(restored.scrollOffset, 173.25);
      restored.dispose();
    },
  );

  test(
    'all eight renderer definitions grade valid responses and reject untouched input',
    () {
      final definitions = tracks
          .expand((c) => c.milestones.expand((m) => challengesFor(c, m)))
          .toList();
      expect(
        definitions.map((c) => c.kind).toSet(),
        ChallengeKind.values.toSet(),
      );
      for (final definition in definitions) {
        expect(definition.valid({}), isFalse);
        expect(definition.valid(correctDraft(definition)), isTrue);
        expect(
          definition.grade(correctDraft(definition)).outcome,
          FeedbackState.correct,
        );
      }
    },
  );
}
