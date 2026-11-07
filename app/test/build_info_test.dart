import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/build_info.dart';

/// GOV-03: About shows the real version from pubspec.yaml.
void main() {
  test('build info matches pubspec', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final version = line.split(':').last.trim();
    expect('${BuildInfo.version}+${BuildInfo.build}', version);
  });
}
