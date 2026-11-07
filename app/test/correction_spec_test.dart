import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/main.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/theme.dart';
import 'package:sumi/challenge_screen.dart';
import 'package:sumi/learning_path/path_screen.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/learning_session/challenge_renderer_registry.dart';
import 'package:sumi/learning_session/learning_session_controller.dart';
import 'support/memory_preferences.dart';
import 'session_contract_test.dart' show correctDraft;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  setUpAll(() async {
    tracks =
        (jsonDecode(
                  await rootBundle.loadString('assets/disciplines.json'),
                )['tracks']
                as List)
            .map((j) => Catalog(Json.from(j)))
            .toList();
  });
  void viewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget path(LearningState learning, LocalStore store, {double scale = 1}) =>
      MaterialApp(
        theme: sumiTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: LearnTab(
          catalog: tracks.first,
          learning: learning,
          store: store,
          onOpenMilestone: (_) async => null,
          onOpenResource: (_) async {},
          onAssess: () {},
          onAskTutor: () {},
        ),
      );

  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(430, 932),
    const Size(600, 960),
  ]) {
    testWidgets('path and anchored card fit $size without moving nodes', (
      tester,
    ) async {
      viewport(tester, size);
      final state = LearningState(trackId: 'music', reducedMotion: true);
      final store = LocalStore(preferences: MemoryPreferences());
      await tester.pumpWidget(path(state, store));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PathNodeWidget).first);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byType(PathNodeWidget).first);
      await tester.tap(find.byType(PathNodeWidget).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(NodeActionOverlay), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.getTopLeft(find.byType(PathNodeWidget).first), before);
      // Tapping another visible node replaces the card; it never stacks.
      final card = tester.getRect(find.byType(NodeActionOverlay));
      final nodes = find.byType(PathNodeWidget);
      final screen = Offset.zero & size;
      var other = -1;
      for (var i = 0; i < nodes.evaluate().length; i++) {
        final center = tester.getCenter(nodes.at(i));
        if (i != 1 && !card.inflate(12).contains(center) && screen.contains(center)) {
          other = i;
          break;
        }
      }
      expect(other, isNot(-1));
      await tester.tap(nodes.at(other));
      await tester.pumpAndSettle();
      expect(find.byType(NodeActionOverlay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NodeActionOverlay),
          matching: find.text(tracks.first.milestones[other].title),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(8, 100));
      await tester.pumpAndSettle();
      expect(find.byType(NodeActionOverlay), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  testWidgets(
    'guide and sections navigate; lesson round trip restores exact scroll',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final state = LearningState(trackId: 'music', reducedMotion: true);
      final store = LocalStore(preferences: MemoryPreferences());
      await tester.pumpWidget(path(state, store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Unit Guidebook'));
      await tester.pumpAndSettle();
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Key ideas'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sections'));
      await tester.pumpAndSettle();
      expect(find.text('Sections & units'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -180));
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      await tester.tap(find.byType(PathNodeWidget).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('START +'));
      await tester.pumpAndSettle();
      final after = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      expect(after, before);
      expect((await store.load('music')).pathContext['offset'], before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'session keeps draft across settings and wrong answer across explanation',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final c = await LearningSessionController.open(
        store: LocalStore(preferences: MemoryPreferences()),
        learning: LearningState(trackId: 'music'),
        catalog: tracks.first,
        node: tracks.first.milestones.first,
        unitId: 'music:unit:0',
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: sumiTheme(),
          home: ChallengeScreen(controller: c, onOpenResource: () async {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'CHECK'))
            .onPressed,
        isNull,
      );
      final options = c.state.challenge.options;
      await tester.tap(find.text(options[2]));
      await tester.pump();
      await tester.tap(find.byTooltip('Lesson settings'));
      await tester.pumpAndSettle();
      // Plan §13: intentional copy changes (LES-01, LES-05, LES-08, LES-09).
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(c.state.currentResponseDraft['choice'], 2);
      final promptPosition = tester.getTopLeft(
        find.text(c.state.challenge.prompt),
      );
      await tester.tap(find.text('CHECK'));
      await tester.pumpAndSettle();
      expect(find.text('Not quite yet.'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Focus 4 of 5')), findsWidgets);
      expect(
        tester.getTopLeft(find.text(c.state.challenge.prompt)),
        promptPosition,
      );
      await tester.tap(find.text('EXPLAIN MY MISTAKE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE LESSON'));
      await tester.pumpAndSettle();
      expect(c.state.currentResponseDraft['choice'], 2);
      expect(c.state.feedbackState, FeedbackState.incorrect);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('all renderer families support review at large text size', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final defs = tracks.expand((c) => challengesFor(c, c.milestones.first));
    for (final d in defs) {
      await tester.pumpWidget(
        MaterialApp(
          theme: sumiTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ChallengeRendererRegistry.build(
                    ChallengeRenderContext(
                      challenge: d,
                      draft: correctDraft(d),
                      feedback: FeedbackState.correct,
                      readOnly: true,
                      emit: (_) => fail('Review must not submit'),
                      openResource: () async {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: d.kind.name);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('path supports real 200 percent text scaling', (tester) async {
    viewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      path(
        LearningState(trackId: 'music'),
        LocalStore(preferences: MemoryPreferences()),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (w) =>
            w is PathNodeWidget &&
            w.milestone.id == tracks.first.milestones.first.id,
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PathNodeWidget).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
