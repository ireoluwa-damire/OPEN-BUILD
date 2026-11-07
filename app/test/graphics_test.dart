import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/graphics/sumi_graphics.dart';
import 'package:sumi/theme.dart';

/// GOV-04 / PTH-13: every original graphic paints, at every size, with no
/// errors; the review sheet doubles as a golden (QA-01).
void main() {
  Widget sheet() => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SumiWordmark(width: 144),
                const SizedBox(width: 24),
                const SumiWordmark(width: 48, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(width: 340, child: RouteHero(height: 232)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final s in ['music', 'fashion', 'custom'])
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: DisciplineScene(scene: s, size: 120),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final k in SumiGlyphKind.values)
                  SumiGlyph(k, size: 32, color: SumiColors.ink),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                for (final k in SumiEmptyKind.values) SumiEmptyIllustration(k, size: 96),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('graphics review sheet', (tester) async {
    tester.view.physicalSize = const Size(460, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(sheet());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/graphics_sheet.png'));
  });

  testWidgets('graphics paint at small and large sizes and stay decorative', (tester) async {
    for (final size in [16.0, 24.0, 48.0, 200.0]) {
      await tester.pumpWidget(MaterialApp(
        home: Wrap(children: [
          for (final k in SumiGlyphKind.values) SumiGlyph(k, size: size),
          DisciplineScene(scene: 'music', size: size),
          SumiEmptyIllustration(SumiEmptyKind.caughtUp, size: size),
        ]),
      ));
      expect(tester.takeException(), isNull);
    }
    // Decorative graphics carry no semantics; the wordmark is labelled.
    await tester.pumpWidget(const MaterialApp(home: Column(children: [SumiWordmark(), SumiGlyph(SumiGlyphKind.flame)])));
    expect(find.bySemanticsLabel('Sumi'), findsOneWidget);
  });
}
