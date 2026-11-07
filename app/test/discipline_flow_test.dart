import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/main.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'support/memory_preferences.dart';

class LoadedStore extends LocalStore {
  final List<Catalog> tracks;
  LoadedStore(this.tracks) : super(preferences: MemoryPreferences());
  @override
  Future<List<Catalog>> disciplines() async => tracks;
}

void main() {
  testWidgets('onboarding and persistence migration test', (tester) async {
    tester.view.physicalSize = Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = MemoryPreferences();
    final v2Json = {
      'track_id': 'music',
      'goal': 'Master rhythm',
      'daily_minutes': 30,
      'attempts': [],
      'completed': ['music-pulse'],
    };
    prefs.values['sumi.learning.v2.music'] = jsonEncode(v2Json);

    final store = LocalStore(preferences: prefs);
    final loaded = await store.load('music');
    expect(loaded.dailyMinutes, 20);
    expect(loaded.completed, {'music-pulse'});
    expect(prefs.values['sumi.learning.v4.music'], isNotNull);

    final tracks = await tester.runAsync(store.disciplines);
    final loadedStore = LoadedStore(tracks!);
    await tester.pumpWidget(SumiApp(store: loadedStore));
    await tester.pumpAndSettle();
    expect(
      find.text('Learn anything by doing it, one clear step at a time.'),
      findsOneWidget,
    );
  });
}
