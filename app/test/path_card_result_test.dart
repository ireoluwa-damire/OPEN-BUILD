import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/engagement/points_policy.dart';
import 'package:sumi/learning_path/path_screen.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/main.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/session_result/session_result.dart';
import 'package:sumi/session_result/session_result_screen.dart';
import 'package:sumi/theme.dart';

import 'support/memory_preferences.dart';

/// PTH-02 / PTH-08 / PTH-09 / TUT-01 / RES-01 / RES-04.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  setUpAll(() async {
    tracks = (jsonDecode(await rootBundle.loadString('assets/disciplines.json'))['tracks'] as List)
        .map((j) => Catalog(Json.from(j)))
        .toList();
  });
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<LearningState> pumpPath(WidgetTester tester) async {
    phone(tester);
    final learning = LearningState(trackId: 'music', reducedMotion: true);
    learning.engagement.qualifyDailyStreak();
    learning.engagement.addReward('x', 35, 0);
    await tester.pumpWidget(
      MaterialApp(
        theme: sumiTheme(),
        home: LearnTab(
          catalog: tracks.first,
          learning: learning,
          store: LocalStore(preferences: MemoryPreferences()),
          onOpenMilestone: (_) async => null,
          onOpenResource: (_) async {},
          onAssess: () {},
          onAskTutor: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return learning;
  }

  testWidgets('status row shows streak and points; no tutor icon on the path', (tester) async {
    await pumpPath(tester);
    expect(find.bySemanticsLabel('1 day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('35 points'), findsOneWidget);
    expect(find.byTooltip('Tutor'), findsNothing);
    expect(find.textContaining(' pts'), findsNothing);
    await tester.tap(find.bySemanticsLabel('35 points'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Points measure practice, not mastery.'), findsOneWidget);
  });

  testWidgets('available card shows the guaranteed reward; locked card names the prerequisite', (tester) async {
    await pumpPath(tester);
    final music = tracks.first;
    final first = music.milestones.first;
    final reward = PointsPolicy.baseReward(first, challengesFor(music, first).length);
    await tester.tap(find.byType(PathNodeWidget).first);
    await tester.pumpAndSettle();
    expect(find.text('START +$reward POINTS'), findsOneWidget);
    await tester.tap(find.byTooltip('Close node card'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PathNodeWidget).at(1));
    await tester.pumpAndSettle();
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('Finish “${first.title}” to unlock this step.'), findsOneWidget);
    await tester.tap(find.text('GO TO ${first.title.toUpperCase()}'));
    await tester.pumpAndSettle();
    expect(find.text('START +$reward POINTS'), findsOneWidget);
  });

  testWidgets('result screen: Today row, Next card, CONTINUE and RETURN TO PATH', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var continued = 0, returned = 0;
    final result = SessionResult(
      sessionId: 's',
      duration: const Duration(seconds: 95),
      correctCount: 4,
      incorrectCount: 0,
      nearCorrectCount: 0,
      retryCount: 0,
      firstAttemptAccuracy: 1,
      pointsAwarded: 120,
      completedNode: 'music-pulse',
      accolade: SessionAccolade.accuracy,
      celebrationType: 'rhythm',
      evidencePayload: {
        'music': {'assessedChallengeCount': 3, 'categories': ['concept'], 'attempts': []},
      },
      streakDays: 3,
      minutesToday: 6,
      dailyGoal: 10,
      streakExtended: true,
      nextNodeId: 'music-u1-video',
      nextNodeTitle: 'Watch and apply',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: sumiTheme(),
        home: SessionResultScreen(
          result: result,
          reducedMotion: true,
          onContinue: () => continued++,
          onReturn: () => returned++,
          onReview: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Perfect step!'), findsOneWidget);
    expect(find.text('6/10 min today'), findsOneWidget);
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('+1 DAY'), findsOneWidget);
    expect(find.text('Next: Watch and apply'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.tap(find.text('RETURN TO PATH'));
    expect(continued, 1);
    expect(returned, 1);
  });
}
