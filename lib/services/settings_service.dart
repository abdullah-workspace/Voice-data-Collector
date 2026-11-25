import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings using SharedPreferences.
class SettingsService {
  static const String _keyCollectorName = 'collector_name';
  static const String _keyDeviceLabel = 'device_label';
  static const String _keyRecordingDuration = 'recording_duration_seconds';
  static const String _keyTargetPerCategory = 'target_per_category';
  static const String _keyLastEnvironment = 'last_environment';
  static const String _keyLastDistance = 'last_distance';
  static const String _keyLastNoiseLevel = 'last_noise_level';

  late final SharedPreferences _prefs;

  /// Initializes the service by obtaining the SharedPreferences instance.
  /// Automatically migrates any legacy duration (e.g. 5 seconds) to 3 seconds.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Migrate any legacy duration (e.g. 5s or non-supported values) to 3s
    final currentDuration = _prefs.getInt(_keyRecordingDuration);
    if (currentDuration != null &&
        currentDuration != 2 &&
        currentDuration != 3) {
      await _prefs.setInt(_keyRecordingDuration, 3);
    }
  }

  // ── Collector Name ──────────────────────────────────────────────────────

  String get collectorName => _prefs.getString(_keyCollectorName) ?? '';

  Future<void> setCollectorName(String value) async {
    await _prefs.setString(_keyCollectorName, value);
  }

  // ── Device Label ────────────────────────────────────────────────────────

  String get deviceLabel => _prefs.getString(_keyDeviceLabel) ?? '';

  Future<void> setDeviceLabel(String value) async {
    await _prefs.setString(_keyDeviceLabel, value);
  }

  // ── Recording Duration (seconds: strictly 2 or 3, default 3) ────────────

  int get recordingDurationSeconds {
    final val = _prefs.getInt(_keyRecordingDuration) ?? 3;
    if (val != 2 && val != 3) {
      _prefs.setInt(_keyRecordingDuration, 3);
      return 3;
    }
    return val;
  }

  Future<void> setRecordingDurationSeconds(int value) async {
    final validValue = (value == 2) ? 2 : 3;
    await _prefs.setInt(_keyRecordingDuration, validValue);
  }

  // ── Target Per Category ────────────────────────────────────────────────

  int get targetPerCategory => _prefs.getInt(_keyTargetPerCategory) ?? 200;

  Future<void> setTargetPerCategory(int value) async {
    await _prefs.setInt(_keyTargetPerCategory, value);
  }

  // ── Last Environment ───────────────────────────────────────────────────

  String get lastEnvironment => _prefs.getString(_keyLastEnvironment) ?? '';

  Future<void> setLastEnvironment(String value) async {
    await _prefs.setString(_keyLastEnvironment, value);
  }

  // ── Last Distance ──────────────────────────────────────────────────────

  String get lastDistance => _prefs.getString(_keyLastDistance) ?? '';

  Future<void> setLastDistance(String value) async {
    await _prefs.setString(_keyLastDistance, value);
  }

  // ── Last Noise Level ───────────────────────────────────────────────────

  String get lastNoiseLevel => _prefs.getString(_keyLastNoiseLevel) ?? '';

  Future<void> setLastNoiseLevel(String value) async {
    await _prefs.setString(_keyLastNoiseLevel, value);
  }
}
