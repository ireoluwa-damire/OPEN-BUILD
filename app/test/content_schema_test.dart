import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi/learning_path/learning_path_state.dart';
import 'package:sumi/learning_session/challenge_definition.dart';
import 'package:sumi/models.dart';

/// ARC-04 / ARC-05 / LES-15 content schema checks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Catalog> tracks;
  setUpAll(() async {
    tracks = (jsonDecode(await rootBundle.loadString('assets/disciplines.json'))['tracks'] as List)
        .map((j) => Catalog(Json.from(j)))
        .toList();
  });

  test('IDs are unique, prerequisites resolve and are acyclic', () {
    for (final c in tracks) {
      final ids = c.milestones.map((m) => m.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: c.id);
      final seen = <String>{};
      for (final m in c.milestones) {
        expect(seen.containsAll(m.prerequisites), isTrue, reason: m.id);
        seen.add(m.id);
      }
    }
  });

  test('every track has all seven node types and units from data', () {
    for (final c in tracks) {
      expect(c.milestones.map((m) => m.type).toSet(), NodeType.values.toSet(), reason: c.id);
      final units = LearningUnit.forCatalog(c);
      expect(units.length, c.units.length);
      expect(units.expand((u) => u.nodes).length, c.milestones.length);
      for (final u in units) {
        expect(u.guide['key_ideas'], isNotEmpty, reason: u.id);
      }
    }
  });

  test('every challenge is valid, gradeable and unique per node', () {
    for (final c in tracks) {
      final signatures = <String>{};
      for (final m in c.milestones) {
        final defs = challengesFor(c, m);
        expect(defs.length, greaterThanOrEqualTo(2), reason: m.id);
        expect(defs.map((d) => d.kind).toSet().length, greaterThanOrEqualTo(2), reason: m.id);
        expect(defs.map((d) => d.id).toSet(), hasLength(defs.length));
        expect(signatures.add(jsonEncode(defs.map((d) => d.toJson()..remove('id')).toList())), isTrue,
            reason: 'duplicate challenge list at ${m.id}');
        for (final d in defs) {
          expect(d.valid(const {}), isFalse, reason: d.id);
          final res = d.content['resourceId'];
          if (res is String) expect(c.resource(res), isNotNull, reason: d.id);
        }
      }
    }
  });

  test('video nodes resolve to a catalogue video', () {
    for (final c in tracks) {
      for (final m in c.milestones.where((m) => m.type == NodeType.videoResource)) {
        expect(c.resource(m.resourceId), isNotNull, reason: m.id);
      }
    }
  });

  test('checkpoints include transfer items with new examples', () {
    for (final c in tracks) {
      for (final m in c.milestones.where((m) => m.type == NodeType.checkpoint)) {
        expect(challengesFor(c, m).any((d) => d.content['context'] == 'transfer'), isTrue, reason: m.id);
      }
    }
  });

  test('no discipline branching in lib (ARC-05)', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      // Branching on a track ID is banned; data keys such as `scene` are fine.
      if (RegExp(r"""(\.id|trackId|catalogId)\s*==\s*'(music|fashion)'""").hasMatch(text)) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
