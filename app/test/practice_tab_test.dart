import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/models.dart';
import 'package:sumi/review/review_scheduler.dart';
import 'package:sumi/tabs/practice_tab.dart';
import 'package:sumi/theme.dart';

/// PRA-01 / EVD-03.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog music;
  final now = DateTime(2026, 11, 5, 10);
  setUpAll(() async {
    music = Catalog(
      Json.from(
        (jsonDecode(await rootBundle.loadString('assets/disciplines.json'))['tracks'] as List).first,
      ),
    );
  });

  Future<void> pump(WidgetTester tester, LearningState learning, List<Milestone> opened) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: sumiTheme(),
        home: PracticeTab(
          catalog: music,
          learning: learning,
          clock: () => now,
          onOpenMilestone: (m) async => opened.add(m),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty state names the next review date', (tester) async {
    final learning = LearningState(trackId: 'music');
    learning.reviewSchedule['music-pulse'] = ReviewScheduler.schedule(
      nodeId: 'music-pulse',
      outcome: 'transferred',
      now: now,
    );
    await pump(tester, learning, []);
    expect(find.text('You’re caught up'), findsOneWidget);
    expect(find.textContaining('Next one: 15 Nov.'), findsOneWidget);
  });

  testWidgets('due items are grouped with a reason and open a lesson', (tester) async {
    final learning = LearningState(trackId: 'music');
    learning.completed.addAll(['music-pulse', 'music-u1-video', 'music-duration']);
    learning.reviewSchedule['music-pulse'] = ReviewScheduler.schedule(
      nodeId: 'music-pulse',
      outcome: 'independent',
      now: now.subtract(const Duration(days: 3)),
    );
    learning.reviewSchedule['music-duration'] = ReviewScheduler.schedule(
      nodeId: 'music-duration',
      outcome: 'incorrect',
      now: now.add(const Duration(hours: 1)),
    );
    final opened = <Milestone>[];
    await pump(tester, learning, opened);
    expect(find.text('REVIEW DUE'), findsOneWidget);
    expect(find.text('REPAIR MISTAKES'), findsOneWidget);
    expect(find.text(ReviewScheduler.schedule(nodeId: 'x', outcome: 'independent', now: now).reason), findsOneWidget);
    // Never a generic list of every milestone (S3 P5.3).
    expect(find.text('Shape a small phrase'), findsNothing);
    await tester.tap(find.text('Find a steady pulse'));
    await tester.pumpAndSettle();
    expect(opened.single.id, 'music-pulse');
  });
}
