// Only for UI/evidence tests that never invoke native inference. Keep the real
// native-asset builder enabled for Android integration tests and app builds.
import 'dart:io';
import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/commands/test.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/mustache_template.dart';

Future<void> main(List<String> args) async {
  Cache.flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  exitCode = await runner.run(
    ['--no-version-check', 'test', '--no-pub', ...args],
    () => [TestCommand()],
    overrides: {
      TemplateRenderer: () => const MustacheTemplateRenderer(),
    },
    shutdownHooks: globals.shutdownHooks,
  );
}
