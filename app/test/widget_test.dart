import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/assessment.dart';
import 'package:sumi/models.dart';
import 'package:sumi/theme.dart';

void main() {
  testWidgets(
    'small-screen baseline saves an answer before revealing feedback',
    (tester) async {
      tester.view.physicalSize = Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalog = (await tester.runAsync(
        () async => Catalog(
          jsonDecode(
            await rootBundle.loadString('assets/disciplines.json'),
          )['tracks'][0],
        ),
      ))!;
      final recorded = <Attempt>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: sumiTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: AssessmentScreen(
            catalog: catalog,
            existing: [],
            onAttempt: (a) async {
              recorded.add(a);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(recorded, isEmpty);
      await tester.ensureVisible(find.text('The regular underlying beat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The regular underlying beat'));
      await tester.pump();
      await tester.tap(find.text('Check my answer'));
      await tester.pumpAndSettle();
      expect(recorded.single.answerIndex, 0);
      expect(recorded.single.usedHint, isFalse);
      expect(find.text('That’s a useful connection.'), findsOneWidget);
      expect(find.text('Next small question'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
