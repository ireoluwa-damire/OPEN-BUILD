// Reproducible synthetic interaction capture, enabled explicitly with
// --dart-define=RECORD_SESSION=true. Never touches the learner's preferences.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/main.dart';
import 'package:sumi/models.dart';
import 'package:sumi/services.dart';
import 'package:sumi/challenge_screen.dart';
import 'package:sumi/learning_path/path_screen.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'support/memory_preferences.dart';
import 'session_contract_test.dart' show correctDraft;

class RecordingStore extends LocalStore {
  final List<Catalog> tracks;
  RecordingStore(this.tracks) : super(preferences: MemoryPreferences());
  @override
  Future<List<Catalog>> disciplines() async => tracks;
}

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
    if (const bool.fromEnvironment('RECORD_SESSION')) {
      debugDisableShadows = false;
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final loader = FontLoader('Arial')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File('C:/Windows/Fonts/arial.ttf').readAsBytes(),
            ),
          ),
        );
      await loader.load();
    }
  });
  for (var trackIndex = 0; trackIndex < 2; trackIndex++) {
    testWidgets(
      'record ${trackIndex == 0 ? 'music' : 'fashion'} session at both viewports',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final catalog = tracks[trackIndex];
        final store = RecordingStore(tracks);
        final learning = LearningState(
          trackId: catalog.id,
          goal: catalog.project,
          onboarding: OnboardingState(completionState: true, stepIndex: 9),
          attempts: catalog.questions
              .map((q) => Attempt(q.id, q.correct, false, 10))
              .toList(),
        );
        await store.save(learning);
        await store.setActiveTrack(catalog.id);
        final boundaryKey = GlobalKey();
        final output = Directory(
          '../preview/session-reconstruction/${catalog.id}',
        );
        await tester.runAsync(() async {
          await Directory('${output.path}/1080').create(recursive: true);
          await Directory('${output.path}/360').create(recursive: true);
        });
        var frame = 0;
        final markers = <Map<String, dynamic>>[];
        Future<void> record(String label, [int count = 6]) async {
          markers.add({'frame': frame, 'seconds': frame / 10, 'state': label});
          for (var i = 0; i < count; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull, reason: label);
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final fileName = frame.toString().padLeft(4, '0');
            await tester.runAsync(() async {
              for (final ratio in [3.0, 1.0]) {
                final rendered = await boundary.toImage(pixelRatio: ratio);
                final data = await rendered.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '${output.path}/${ratio == 3 ? '1080' : '360'}/$fileName.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                rendered.dispose();
              }
            });
            frame++;
          }
        }

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: SumiApp(store: store),
          ),
        );
        await tester.pumpAndSettle();
        await record('path');
        await tester.tap(find.byType(PathNodeWidget).first);
        await record('anchored card');
        await tester.tap(find.textContaining('START +'));
        await record('lesson launch', 8);
        final c = tester
            .widget<ChallengeScreen>(find.byType(ChallengeScreen))
            .controller;
        c.updateDraft({
          'choice':
              (c.state.challenge.answer.single + 1) %
              c.state.challenge.options.length,
        });
        await record('response ready', 4);
        await tester.tap(find.text('CHECK'));
        await record('incorrect feedback');
        await tester.tap(find.text('Explain my mistake / response'));
        await record('authored explanation');
        await tester.tap(find.text('Return to my response'));
        await record('same wrong response restored', 4);
        await tester.tap(find.text('RETRY'));
        await record('retry draft', 3);
        await tester.tap(find.byTooltip('Lesson settings'));
        await record('settings');
        await tester.tap(find.text('Back to lesson'));
        await record('settings return', 3);
        for (var index = 0; index < c.state.challenges.length; index++) {
          if (c.state.challenge.kind == ChallengeKind.sequenceTokens ||
              c.state.challenge.kind == ChallengeKind.fashionProcedure) {
            final near = List<int>.from(c.state.challenge.answer);
            final temp = near[2];
            near[2] = near[3];
            near[3] = temp;
            c.updateDraft({'order': near});
            await tester.pump();
            await tester.tap(find.text('CHECK'));
            await record('near-correct feedback');
            await tester.tap(find.text('RETRY'));
            await tester.pumpAndSettle();
          }
          if (c.state.challenge.kind == ChallengeKind.musicImitate) {
            c.updateDraft({'retry': true});
            await tester.pump();
            await tester.tap(find.text('CHECK'));
            await record('non-punitive retry');
            await tester.tap(find.text('RETRY'));
            await tester.pumpAndSettle();
          }
          c.updateDraft(correctDraft(c.state.challenge));
          await record('${c.state.challenge.kind.name} response', 5);
          await tester.tap(find.text('CHECK'));
          await record('saved correct feedback', 4);
          await tester.tap(find.text('CONTINUE'));
          await record('advance', 4);
        }
        expect(c.state.result, isNotNull);
        await record('persisted result', 10);
        await tester.tap(find.text('RETURN TO PATH'));
        await record('return, completion and unlock', 18);
        expect(
          find.byType(PathScreen),
          findsNothing,
        ); // LearnTab is the public subclass.
        expect(find.byType(LearnTab), findsOneWidget);
        expect((await store.load(catalog.id)).engagement.pointsTotal, 20);
        await tester.runAsync(
          () => File('${output.path}/timeline.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'fps': 10,
              'frames': frame,
              'logicalViewport': [360, 800],
              'physicalViewport': [1080, 2400],
              'syntheticEvidence': true,
              'markers': markers,
            }),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 300));
      },
      skip: !const bool.fromEnvironment('RECORD_SESSION'),
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
}
