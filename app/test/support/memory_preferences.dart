import 'package:shared_preferences/shared_preferences.dart';

/// Keeps synthetic UI-test progress separate from the user's saved data.
class MemoryPreferences implements SharedPreferencesAsync {
  final Map<String, String> values = {};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'The test store supports string preferences only.',
  );
}
