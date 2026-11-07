import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/application/use_cases.dart';
import 'package:sumi/models.dart';
import 'package:sumi/on_device.dart';
import 'package:sumi/services.dart';
import 'package:sumi/settings/settings_screen.dart';
import 'package:sumi/theme.dart';
import 'package:sumi/tutor_system.dart';

import 'support/memory_preferences.dart';

/// SET-01 / SET-02 / SET-04 / SET-05 / TUT-03.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  setUpAll(() async {
    tracks = (jsonDecode(await rootBundle.loadString('assets/disciplines.json'))['tracks'] as List)
        .map((j) => Catalog(Json.from(j)))
        .toList();
  });

  Future<(LearningState, LocalStore)> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = LocalStore(preferences: MemoryPreferences());
    final learning = LearningState(trackId: 'music', goal: 'Keep a steady rhythm');
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: sumiTheme(),
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return SettingsScreen(
              disciplines: tracks,
              catalog: tracks.first,
              learning: learning,
              store: store,
              phoneCoach: PhoneModelController(),
              onUpdate: (change) async {
                await UpdateSetting(store)(learning, change);
                rebuild(() {});
              },
              onSwitchDiscipline: (_) async {},
              onDataReplaced: (_) async {},
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (learning, store);
  }

  testWidgets('sections are in the specified order', (tester) async {
    await pump(tester);
    const order = [
      'PROFILE ON THIS DEVICE',
      'LEARNING PREFERENCES',
      'NOTIFICATIONS AND REMINDERS',
      'ACCESSIBILITY',
      'OFFLINE AI MODELS',
      'CLOUD AI',
      'STORAGE AND PRIVACY',
      'ABOUT AND LICENCES',
    ];
    final ys = [for (final label in order) tester.getTopLeft(find.text(label)).dy];
    expect([...ys]..sort(), ys);
  });

  testWidgets('every subtitle is derived from state', (tester) async {
    final (learning, _) = await pump(tester);
    expect(find.text(SettingsCopy.guest), findsOneWidget);
    expect(find.text(SettingsCopy.dailyGoal(learning)), findsOneWidget);
    expect(find.text(SettingsCopy.goal(learning)), findsOneWidget);
    expect(find.text(SettingsCopy.reminders), findsOneWidget);
    expect(find.text(SettingsCopy.cloud), findsOneWidget);
    expect(find.text(SettingsCopy.accessibility(learning.settings)), findsOneWidget);
    expect(find.textContaining('Stored on this device (not encrypted)'), findsOneWidget);
    expect(find.text(SettingsCopy.about()), findsOneWidget);
    expect(find.textContaining('Encrypted'), findsNothing);
    expect(find.textContaining('enabled for'), findsNothing);
  });

  testWidgets('reminders cannot be switched on', (tester) async {
    final (learning, _) = await pump(tester);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    final reminder = tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(of: find.text('Practice reminders'), matching: find.byType(Row)).first,
        matching: find.byType(Switch),
      ),
    );
    expect(switches, isNotEmpty);
    expect(reminder.value, isFalse);
    expect(reminder.onChanged, isNull);
    expect(learning.toJson().containsKey('reminders_enabled'), isFalse);
  });

  testWidgets('a toggle changes state and its subtitle together', (tester) async {
    final (learning, _) = await pump(tester);
    expect(learning.soundEffectsEnabled, isTrue);
    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();
    expect(learning.soundEffectsEnabled, isFalse);
    final row = find.ancestor(of: find.text('Sound effects'), matching: find.byType(Row)).first;
    expect(find.descendant(of: row, matching: find.text('Off')), findsOneWidget);
  });

  testWidgets('accessibility: high contrast and text size persist', (tester) async {
    final (learning, store) = await pump(tester);
    await tester.tap(find.text('Accessibility').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Larger (×1.15)'));
    await tester.pumpAndSettle();
    expect(learning.settings.highContrast, isTrue);
    expect(learning.settings.textMode, 'large');
    final saved = await store.load('music');
    expect(saved.settings.highContrast, isTrue);
    expect(saved.settings.textScale, 1.15);
  });

  test('cloud provider never answers while not configured (TUT-03)', () async {
    final provider = SumiCloudTutorProvider(backendUrl: 'https://relay.invalid');
    expect(provider.isConfigured, isFalse);
    await expectLater(
      provider.queryCloud(
        envelope: TutorContextEnvelope(
          requestId: 'r',
          disciplineId: 'music',
          goalId: 'g',
          currentCapabilityId: 'c',
          recentEvidenceSummary: '',
          learnerPreferencesSummary: '',
          approvedResourceIds: const [],
          requestedAction: 'general_coaching',
        ),
        prompt: 'hi',
      ),
      throwsA(isA<CloudNotConfigured>()),
    );
  });
}
