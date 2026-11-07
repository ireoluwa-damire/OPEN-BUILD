import 'on_device.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'application/use_cases.dart';
import 'models.dart';
import 'phone_model_types.dart';

class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);
  @override
  String toString() => 'MigrationException: $message';
}

class LocalStore {
  final SharedPreferencesAsync _preferences;
  Future<void> _writes = Future.value();
  LocalStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<List<Catalog>> disciplines() async =>
      (jsonDecode(
                await rootBundle.loadString('assets/disciplines.json'),
              )['tracks']
              as List)
          .map((j) => Catalog(Json.from(j)))
          .toList();

  Future<String?> activeTrack() async {
    final v3Active = await _preferences.getString('sumi.active-track.v3');
    if (v3Active != null) return v3Active;
    final v2Active = await _preferences.getString('sumi.active-track.v2');
    if (v2Active != null) {
      await _preferences.setString('sumi.active-track.v3', v2Active);
      return v2Active;
    }
    return null;
  }

  Future<void> setActiveTrack(String id) async {
    await _preferences.setString('sumi.active-track.v3', id);
  }

  static const _customGoalsKey = 'sumi.custom-goals.v1';

  /// CUS-01: custom goals the learner created, each with its own record.
  Future<List<Json>> customGoals() async {
    try {
      final raw = await _preferences.getString(_customGoalsKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).map((g) => Json.from(g)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Registers a custom goal and writes its isolated learner record.
  Future<void> addCustomGoal(Json goal, LearningState record) =>
      _enqueue(() async {
        final raw = await _preferences.getString(_customGoalsKey);
        final goals = raw == null
            ? <dynamic>[]
            : List<dynamic>.from(jsonDecode(raw) as List);
        goals.add(goal);
        await _write(record);
        await _preferences.setString(_customGoalsKey, jsonEncode(goals));
      });

  /// CUS-02: stores a confirmed plan on the custom goal's registry entry.
  Future<void> saveCustomPlan(String goalId, List<Json> steps) =>
      _enqueue(() async {
        final raw = await _preferences.getString(_customGoalsKey);
        final goals = raw == null
            ? <dynamic>[]
            : List<dynamic>.from(jsonDecode(raw) as List);
        final i = goals.indexWhere((g) => g is Map && g['id'] == goalId);
        if (i < 0) throw StateError('Unknown custom goal $goalId');
        goals[i] = {...Map<String, dynamic>.from(goals[i] as Map), 'plan': steps};
        await _preferences.setString(_customGoalsKey, jsonEncode(goals));
      });

  static String _key(int version, String trackId) =>
      'sumi.learning.v$version.$trackId';

  /// Loads a learner record (ARC-03). Order: v4, then v3 (upgraded and written
  /// to the v4 key; the v3 key is never removed), then v2. A record that exists
  /// but cannot be read raises [MigrationException] so the app shows the
  /// recovery screen instead of silently resetting (SHL-05).
  Future<LearningState> load(String trackId) async {
    Future<String?> get(int version) async {
      try {
        return await _preferences.getString(_key(version, trackId));
      } catch (_) {
        return null;
      }
    }

    final v4Saved = await get(4);
    if (v4Saved != null) {
      try {
        final restored = LearningState.fromJson(Json.from(jsonDecode(v4Saved)));
        if (restored.trackId == trackId) return restored;
      } catch (_) {
        // Fall back to the retained v3 record below.
      }
    }

    final v3Saved = await get(3);
    if (v3Saved != null) {
      try {
        final upgraded = LearningState.fromJson(
          Json.from(jsonDecode(v3Saved)),
        );
        if (upgraded.trackId == trackId) {
          await _enqueue(() => _write(upgraded));
          return upgraded;
        }
      } catch (_) {
        // v3 invalid, attempt v2 recovery
      }
    }

    final v2Saved = await get(2);
    if (v2Saved != null) {
      try {
        final migrated = LearningState.fromV2(
          Json.from(jsonDecode(v2Saved)),
          trackId,
        );
        await _enqueue(() => _write(migrated));
        return migrated;
      } catch (_) {
        // v2 also failed validation or parsing
      }
    }

    if (v4Saved != null || v3Saved != null || v2Saved != null) {
      throw MigrationException(
        'Recoverable migration error: saved data for track $trackId could not be read',
      );
    }

    return LearningState(trackId: trackId);
  }

  /// Seeds a whole record. Production code mutates learner data only through
  /// [transaction] (ARC-01); this exists for tests and fixtures.
  @visibleForTesting
  Future<void> save(LearningState state) async {
    return _enqueue(() => _write(state));
  }

  Future<void> _write(LearningState state) => _preferences.setString(
    _key(LearningState.schemaVersion, state.trackId),
    jsonEncode(state.toJson()),
  );

  /// Every key this store has written for [trackId], for export and scoped
  /// deletion (SET-06).
  Future<Map<String, String>> rawRecords(String trackId) async {
    final out = <String, String>{};
    for (final v in [4, 3, 2]) {
      try {
        final value = await _preferences.getString(_key(v, trackId));
        if (value != null) out[_key(v, trackId)] = value;
      } catch (_) {}
    }
    return out;
  }

  /// Removes every stored version of one track's record (SET-06). Model files
  /// are stored elsewhere and are not touched.
  Future<void> clearTrack(String trackId) => _enqueue(() async {
    for (final v in [4, 3, 2]) {
      await _preferences.remove(_key(v, trackId));
    }
  });

  /// Writes an imported record after validating it (SET-06). The imported
  /// track must match [trackId]; the current record is replaced only after the
  /// new one parses.
  Future<LearningState> importRecord(String trackId, String raw) async {
    final parsed = LearningState.fromJson(Json.from(jsonDecode(raw)));
    if (parsed.trackId != trackId) {
      throw const FormatException('This export belongs to another discipline.');
    }
    await _enqueue(() => _write(parsed));
    return parsed;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object _) {});
    return next;
  }

  /// One serialized profile write contains attempts, rewards and path changes.
  /// A failed write leaves the live profile untouched and the queue usable.
  Future<void> transaction(
    LearningState state,
    Future<void> Function(LearningState candidate) action,
  ) => _enqueue(() async {
    final candidate = LearningState.fromJson(
      Json.from(jsonDecode(jsonEncode(state.toJson()))),
    );
    await action(candidate);
    await _write(candidate);
    state.applySnapshot(candidate);
  });
}

/// Compatibility façade over the use cases (ARC-02). New code should call
/// the use cases in `application/use_cases.dart` directly.
class LearningService {
  final LocalStore store;
  LearningService({required this.store});

  Future<void> recordAttempt(
    LearningState state,
    Catalog catalog,
    Attempt attempt,
  ) => RecordAttempt(store)(state, catalog, attempt);

  Future<void> recordResourceUse(LearningState state, Resource resource) =>
      RecordResourceUse(store)(state, resource, ResourceEventType.opened);

  Future<void> qualifyDailyGoal(LearningState state, [String reason = 'lesson']) =>
      QualifyDailyGoal(store)(state, reason);

  Milestone? getNextLearningSession(LearningState state, Catalog catalog) =>
      const GetNextLearningSession()(state, catalog)?.node;

  Future<String> askTutor(
    Catalog catalog,
    LearningState state,
    PhoneModelController phoneCoach,
    String prompt,
  ) async {
    final coachPrompt = buildCoachPrompt(catalog, state);
    if (phoneCoach.supported && phoneCoach.installed.isNotEmpty) {
      return await phoneCoach.reply('$coachPrompt\nUser question: $prompt');
    }
    return 'Based on your goal (${state.goal}) in ${catalog.title}: Focus on practicing the core concept step-by-step and check your results against your baseline.';
  }
}
