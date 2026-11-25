import 'package:flutter/foundation.dart';
import 'package:hearassist_data_collector/services/settings_service.dart';

/// Provider for managing and persisting user settings.
class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SettingsService get settingsService => _settingsService;

  String _collectorName = '';
  String _deviceLabel = '';
  int _recordingDuration = 3; // strictly 2 or 3, default 3
  int _targetPerCategory = 200;
  String _lastEnvironment = 'bedroom';
  String _lastDistance = 'medium (1–3m)';
  String _lastNoiseLevel = 'moderate';

  String get collectorName => _collectorName;
  String get deviceLabel => _deviceLabel;
  int get recordingDuration => _recordingDuration;
  int get targetPerCategory => _targetPerCategory;
  String get lastEnvironment => _lastEnvironment;
  String get lastDistance => _lastDistance;
  String get lastNoiseLevel => _lastNoiseLevel;

  SettingsProvider() {
    init();
  }

  Future<void> init() async {
    await _settingsService.init();
    _collectorName = _settingsService.collectorName;
    _deviceLabel = _settingsService.deviceLabel;
    final dur = _settingsService.recordingDurationSeconds;
    _recordingDuration = (dur == 2) ? 2 : 3;
    _targetPerCategory = _settingsService.targetPerCategory;
    _lastEnvironment = _settingsService.lastEnvironment.isNotEmpty
        ? _settingsService.lastEnvironment
        : 'bedroom';
    _lastDistance = _settingsService.lastDistance.isNotEmpty
        ? _settingsService.lastDistance
        : 'medium (1–3m)';
    _lastNoiseLevel = _settingsService.lastNoiseLevel.isNotEmpty
        ? _settingsService.lastNoiseLevel
        : 'moderate';

    _isInitialized = true;
    notifyListeners();
  }

  /// Explicitly saves all core settings when the user taps "Save Changes".
  Future<void> saveSettings({
    required String collectorName,
    required String deviceLabel,
    required int recordingDuration,
    required int targetPerCategory,
  }) async {
    _collectorName = collectorName.trim();
    _deviceLabel = deviceLabel.trim();
    _recordingDuration = (recordingDuration == 2) ? 2 : 3;
    _targetPerCategory = targetPerCategory > 0 ? targetPerCategory : 200;

    await _settingsService.setCollectorName(_collectorName);
    await _settingsService.setDeviceLabel(_deviceLabel);
    await _settingsService.setRecordingDurationSeconds(_recordingDuration);
    await _settingsService.setTargetPerCategory(_targetPerCategory);
    notifyListeners();
  }

  Future<void> setCollectorName(String value) async {
    _collectorName = value.trim();
    await _settingsService.setCollectorName(_collectorName);
    notifyListeners();
  }

  Future<void> setDeviceLabel(String value) async {
    _deviceLabel = value.trim();
    await _settingsService.setDeviceLabel(_deviceLabel);
    notifyListeners();
  }

  Future<void> setRecordingDuration(int value) async {
    _recordingDuration = (value == 2) ? 2 : 3;
    await _settingsService.setRecordingDurationSeconds(_recordingDuration);
    notifyListeners();
  }

  Future<void> setTargetPerCategory(int value) async {
    _targetPerCategory = value > 0 ? value : 200;
    await _settingsService.setTargetPerCategory(_targetPerCategory);
    notifyListeners();
  }

  Future<void> setLastMetadataChoices({
    required String environment,
    required String distance,
    required String noiseLevel,
  }) async {
    _lastEnvironment = environment;
    _lastDistance = distance;
    _lastNoiseLevel = noiseLevel;
    await _settingsService.setLastEnvironment(environment);
    await _settingsService.setLastDistance(distance);
    await _settingsService.setLastNoiseLevel(noiseLevel);
    notifyListeners();
  }
}
