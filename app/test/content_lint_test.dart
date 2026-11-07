import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// QA-03 / GOV-05 (DC §11.7): banned copy never ships.
void main() {
  Iterable<File> shippedDart() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('_debug.dart'));

  final content = File('assets/disciplines.json').readAsStringSync();

  test('no Duolingo names or reference-slot labels in shipped code or content', () {
    for (final f in [...shippedDart(), File('assets/disciplines.json')]) {
      final text = f.readAsStringSync();
      expect(text.contains('Duolingo'), isFalse, reason: f.path);
      expect(RegExp(r'DUO_[A-Z]').hasMatch(text), isFalse, reason: f.path);
    }
  });

  test('banned learner labels and false claims are absent', () {
    final banned = <Pattern>[
      'Encrypted local guest storage',
      'Daily practice nudges enabled',
      RegExp(r'\b(fast|slow|visual|auditory|kinaesthetic|kinesthetic) learner', caseSensitive: false),
      RegExp(r'\bIQ\b'),
      RegExp(r'\btalent(ed)?\b', caseSensitive: false),
      '24-hour retention',
      'Sumi Cloud AI guidance',
      'relayed securely to Sumi backend',
    ];
    for (final f in [...shippedDart(), File('assets/disciplines.json')]) {
      for (final line in f.readAsLinesSync()) {
        // Statements that deny a claim ("never uses talent labels") are fine.
        if (RegExp(r'\b(never|not a|no)\b', caseSensitive: false).hasMatch(line)) {
          continue;
        }
        for (final b in banned) {
          expect(line.contains(b), isFalse, reason: '${f.path}: $line');
        }
      }
    }
  });

  test('Music and Fashion content has no coding residue or placeholder links', () {
    for (final b in ['uploaded code', 'Python', 'repository', 'example.com', 'sumi.local']) {
      expect(content.contains(b), isFalse, reason: b);
    }
  });

  test('no placeholder links in shipped code', () {
    final link = RegExp(r"""https?://[^\s'"]*(example\.com|sumi\.local)""");
    for (final f in shippedDart()) {
      expect(link.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });
}
