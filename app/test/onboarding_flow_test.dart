import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/design_system/components.dart';
import 'package:sumi/challenge_screen.dart';
import 'package:sumi/main.dart';
import 'package:sumi/models.dart';
import 'package:sumi/onboarding/onboarding_copy.dart';
import 'package:sumi/onboarding/workload_estimator.dart';
import 'package:sumi/services.dart';

import 'support/memory_preferences.dart';

class LoadedStore extends LocalStore {
  final List<Catalog> tracks;
  LoadedStore(this.tracks, MemoryPreferences prefs) : super(preferences: prefs);
  @override
  Future<List<Catalog>> disciplines() async => tracks;
}

/// ONB-01 to ONB-12 and CUS-01, driven through the real app shell.
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

  bool enabled(WidgetTester tester, String label) =>
      tester.widget<TactileButton>(find.widgetWithText(TactileButton, label)).onPressed != null;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) => tapText(tester, OnboardingCopy.cta);

  /// Promise → discipline → outcome → motivation → level → preview → goal →
  /// route. Returns with the route chosen.
  Future<void> throughRoute(WidgetTester tester, String route, {String track = 'Music'}) async {
    expect(find.text(OnboardingCopy.promiseTitle), findsOneWidget);
    await tapText(tester, OnboardingCopy.promiseCta);

    expect(find.text(OnboardingCopy.disciplineHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tapText(tester, tracks.firstWhere((t) => t.title.startsWith(track)).title);
    expect(enabled(tester, OnboardingCopy.cta), isTrue);
    await next(tester);

    expect(find.text(OnboardingCopy.outcomeHeading), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a' * 19);
    await tester.pump();
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tester.enterText(find.byType(TextField), 'a' * 201);
    await tester.pump();
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tester.enterText(find.byType(TextField), 'Keep a steady rhythm through a song');
    await tester.pump();
    expect(enabled(tester, OnboardingCopy.cta), isTrue);
    await next(tester);

    expect(find.text(OnboardingCopy.motivationHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tapText(tester, OnboardingCopy.motivations.first);
    expect(find.text(OnboardingCopy.motivationSupport[OnboardingCopy.motivations.first]!), findsOneWidget);
    await next(tester);

    expect(find.text(OnboardingCopy.levelHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tapText(tester, OnboardingCopy.levels.first);
    await next(tester);

    expect(find.text(OnboardingCopy.previewHeading), findsOneWidget);
    expect(find.textContaining('Discipline: '), findsNothing);
    await next(tester);

    expect(find.text(OnboardingCopy.goalHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tapText(tester, '10 min/day');
    expect(find.textContaining('At 10 minutes a day, the first project is roughly'), findsOneWidget);
    await next(tester);

    expect(find.text(OnboardingCopy.routeHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isFalse);
    await tapText(tester, route);
  }

  testWidgets('Basics: every step gates CONTINUE, route reveal shows, first lesson opens', (tester) async {
    phone(tester);
    final prefs = MemoryPreferences();
    await tester.pumpWidget(SumiApp(store: LoadedStore(tracks, prefs)));
    await tester.pumpAndSettle();
    await throughRoute(tester, OnboardingCopy.routeBasicsTitle);
    await next(tester);

    // ONB-08: Basics skips the baseline and goes straight to the reveal.
    expect(find.text(OnboardingCopy.baselineHeading), findsNothing);
    expect(find.text(OnboardingCopy.revealHeading), findsOneWidget);
    expect(find.text(OnboardingCopy.revealChoice), findsOneWidget);
    await tapText(tester, OnboardingCopy.revealCta);
    await tester.pumpAndSettle();

    // ONB-10: the first lesson opens, with three light CHECK items first.
    expect(find.byType(ChallengeScreen), findsOneWidget);
    final record = LearningState.fromJson(jsonDecode(prefs.values['sumi.learning.v4.music']!));
    expect(record.onboarding.completionState, isTrue);
    expect(record.goalRecord!.startingRoute, 'basics');
    expect(record.goal, 'Keep a steady rhythm through a song');
    final session = record.sessions.values.single as Map;
    final ids = (session['challenges'] as List).map((c) => c['id'] as String).toList();
    expect(ids.take(3).every((id) => id.contains(':check:')), isTrue);
  });

  testWidgets('Find my level runs the selected track baseline before the reveal', (tester) async {
    phone(tester);
    final prefs = MemoryPreferences();
    await tester.pumpWidget(SumiApp(store: LoadedStore(tracks, prefs)));
    await tester.pumpAndSettle();
    await throughRoute(tester, OnboardingCopy.routeLevelTitle, track: 'Fashion');
    await next(tester);
    expect(find.text(OnboardingCopy.baselineHeading), findsOneWidget);
    // ONB-12: Fashion was selected, so Fashion's record holds the answers.
    final fashion = LearningState.fromJson(jsonDecode(prefs.values['sumi.learning.v4.fashion']!));
    expect(fashion.onboarding.selectedDiscipline, 'fashion');
    expect(fashion.onboarding.startingRoute, 'level');
    await tapText(tester, OnboardingCopy.baselineCta);
    final fashionTrack = tracks.firstWhere((t) => t.id == 'fashion');
    expect(find.text(fashionTrack.questions.first.prompt), findsOneWidget);
  });

  testWidgets('back and resume keep each answer', (tester) async {
    phone(tester);
    final prefs = MemoryPreferences();
    await tester.pumpWidget(SumiApp(store: LoadedStore(tracks, prefs)));
    await tester.pumpAndSettle();
    await throughRoute(tester, OnboardingCopy.routeBasicsTitle);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingCopy.goalHeading), findsOneWidget);
    // Kill and restore: a fresh app on the same storage resumes here.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(SumiApp(store: LoadedStore(tracks, prefs)));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingCopy.goalHeading), findsOneWidget);
    expect(enabled(tester, OnboardingCopy.cta), isTrue);
  });

  testWidgets('Something else creates an isolated provisional goal (CUS-01)', (tester) async {
    phone(tester);
    final prefs = MemoryPreferences();
    await tester.pumpWidget(SumiApp(store: LoadedStore(tracks, prefs)));
    await tester.pumpAndSettle();
    await tapText(tester, OnboardingCopy.promiseCta);
    await tapText(tester, OnboardingCopy.customTitle);
    await next(tester);
    await tester.enterText(find.byType(TextField).last, 'Throw a small pot');
    await tester.pump();
    await tester.tap(find.widgetWithText(TactileButton, OnboardingCopy.cta).last);
    await tester.pumpAndSettle();
    expect(find.text('Sumi needs a plan for “Throw a small pot”.'), findsOneWidget);
    expect(find.text('PROVISIONAL'), findsOneWidget);
    final goals = jsonDecode(prefs.values['sumi.custom-goals.v1']!) as List;
    expect(goals, hasLength(1));
    final id = goals.single['id'] as String;
    expect(prefs.values['sumi.active-track.v3'], id);
    final record = LearningState.fromJson(jsonDecode(prefs.values['sumi.learning.v4.$id']!));
    expect(record.trackId, id);
    expect(record.completed, isEmpty);
    // Music's own record is untouched by the custom goal.
    final music = LearningState.fromJson(jsonDecode(prefs.values['sumi.learning.v4.music']!));
    expect(music.onboarding.outcome, isEmpty);
    expect(music.goal, isEmpty);
    // The honest way back to reviewed content.
    await tapText(tester, 'CHOOSE MUSIC OR FASHION FOR NOW');
    expect(find.text(OnboardingCopy.disciplineHeading), findsOneWidget);
  });

  test('workload estimate is always a range', () {
    for (final t in tracks) {
      for (final m in OnboardingState.minuteOptions) {
        final (a, b) = estimateFirstProjectSessions(t, m);
        expect(a, greaterThanOrEqualTo(1));
        expect(b, greaterThan(a));
      }
    }
  });
}
