import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sumi/on_device.dart';
import 'package:sumi/phone_models_screen.dart';
import 'package:sumi/phone_model_types.dart';
import 'package:sumi/services.dart';
import 'package:sumi/models.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'verified download and local inference on Android without inference HTTP',
    (tester) async {
      final coach = PhoneModelController();
      await tester.pumpWidget(
        MaterialApp(home: PhoneModelsScreen(controller: coach)),
      );
      await tester.runAsync(coach.initialize);
      final choice = coach.choices.first;
      expect(choice.id, 'qwen3-small');
      await tester.runAsync(() async {
        if (!coach.installed.any((m) => m['id'] == choice.id)) {
          await coach.download(choice);
        }
        await coach.select(choice.id);
      });
      final tracks = await tester.runAsync(() => LocalStore().disciplines());
      final state = LearningState(
        trackId: 'music',
        goal: 'Keep an even four-beat pattern',
      );
      final watch = Stopwatch()..start();
      String? reply;
      await tester.runAsync(
        () => HttpOverrides.runZoned(
          () async {
            reply = await coach.reply(buildCoachPrompt(tracks!.first, state));
          },
          createHttpClient: (_) =>
              throw StateError('HTTP is forbidden during local inference'),
        ),
      );
      expect(reply?.trim(), isNotEmpty);
      expect(coach.status, contains('Generated on this device'));
      final support = await tester.runAsync(getApplicationSupportDirectory);
      final report = {
        'platform': Platform.operatingSystem,
        'model': choice.name,
        'sha256': choice.sha256,
        'bytes': choice.bytes,
        'download_verified': true,
        'inference_http_forbidden': true,
        'elapsed_seconds': watch.elapsedMilliseconds / 1000,
        'device': coach.device,
        'reply': reply,
        'status': coach.status,
        'recorded_at': DateTime.now().toIso8601String(),
        'note':
            'Synthetic test prompt; no learner answers or personal profiles were changed.',
      };
      await tester.runAsync(
        () => File(
          '${support!.path}/phone-models/on-device-smoke.json',
        ).writeAsString(jsonEncode(report), flush: true),
      );
      debugPrint('SUMI_PHONE_SMOKE ${jsonEncode(report)}');
      await tester.pump(Duration(seconds: 1));
    },
    timeout: Timeout(Duration(minutes: 30)),
  );
}
