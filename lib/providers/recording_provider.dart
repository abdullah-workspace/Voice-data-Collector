import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hearassist_data_collector/models/recording_metadata.dart';
import 'package:hearassist_data_collector/services/audio_service.dart';
import 'package:hearassist_data_collector/services/metadata_service.dart';
import 'package:hearassist_data_collector/services/storage_service.dart';

enum RecordingState { idle, recording, reviewing, saving }

/// Provider for managing audio recording, live amplitude, countdown, and saving.
class RecordingProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  late final MetadataService _metadataService;

  RecordingState _state = RecordingState.idle;
  String? _currentCategory;
  String? _tempFilePath;
  double _amplitude = 0.0;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 3;
  bool _isSaving = false;

  Timer? _countdownTimer;
  StreamSubscription<double>? _amplitudeSubscription;

  RecordingState get state => _state;
  bool get isRecording => _state == RecordingState.recording;
  bool get isReviewing => _state == RecordingState.reviewing;
  bool get isSaving => _isSaving;
  String? get currentCategory => _currentCategory;
  String? get tempFilePath => _tempFilePath;
  double get amplitude => _amplitude;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;

  RecordingProvider() {
    _metadataService = MetadataService(storageService: _storageService);
  }

  /// Requests microphone permission and returns status.
  Future<PermissionStatus> checkAndRequestPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return status;
    }
    return await Permission.microphone.request();
  }

  /// Starts recording for [category] with a duration of [durationSeconds].
  Future<void> startRecording({
    required String category,
    required int durationSeconds,
  }) async {
    if (_state == RecordingState.recording) return;

    final permissionStatus = await checkAndRequestPermission();
    if (!permissionStatus.isGranted) {
      throw StateError('Microphone permission not granted.');
    }

    final safeDuration = (durationSeconds == 2) ? 2 : 3;
    _currentCategory = category;
    _totalDurationSeconds = safeDuration;
    _remainingSeconds = safeDuration;
    _state = RecordingState.recording;
    _amplitude = 0.0;
    notifyListeners();

    try {
      // Keep screen awake during recording
      await WakelockPlus.enable();

      final tempDir = await getTemporaryDirectory();
      final tempFilename =
          'temp_record_${DateTime.now().millisecondsSinceEpoch}.wav';
      _tempFilePath = p.join(tempDir.path, tempFilename);

      await _audioService.startRecording(_tempFilePath!);

      // Listen to amplitude stream
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = _audioService.getAmplitudeStream().listen((amp) {
        _amplitude = amp;
        notifyListeners();
      });

      // Countdown timer
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          _remainingSeconds = 0;
          timer.cancel();
          _stopAndTransitionToReview();
        }
      });
    } catch (e) {
      await cancelRecording();
      rethrow;
    }
  }

  Future<void> _stopAndTransitionToReview() async {
    _countdownTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitude = 0.0;

    try {
      await WakelockPlus.disable();
    } catch (_) {}

    try {
      final recordedPath = await _audioService.stopRecording();
      if (recordedPath != null && await File(recordedPath).exists()) {
        _tempFilePath = recordedPath;
        _state = RecordingState.reviewing;
      } else {
        _state = RecordingState.idle;
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _state = RecordingState.idle;
    }
    notifyListeners();
  }

  /// Cancels recording and cleans up temporary file.
  Future<void> cancelRecording() async {
    _countdownTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitude = 0.0;

    try {
      await WakelockPlus.disable();
    } catch (_) {}

    await _audioService.cancelRecording();

    if (_tempFilePath != null) {
      await _storageService.deleteTempFile(_tempFilePath!);
      _tempFilePath = null;
    }

    _state = RecordingState.idle;
    _currentCategory = null;
    notifyListeners();
  }

  /// Discards the current review sample and resets to idle.
  Future<void> discardRecording() async {
    if (_tempFilePath != null) {
      await _storageService.deleteTempFile(_tempFilePath!);
      _tempFilePath = null;
    }
    _state = RecordingState.idle;
    _currentCategory = null;
    notifyListeners();
  }

  /// Saves the reviewed recording to dataset and writes CSV metadata.
  Future<String> saveRecording({
    required String collector,
    required String device,
    required String environment,
    required String distance,
    required String noiseLevel,
    required String notes,
  }) async {
    if (_tempFilePath == null || _currentCategory == null || _isSaving) {
      throw StateError('Cannot save: invalid state or already saving.');
    }

    _isSaving = true;
    notifyListeners();

    try {
      final category = _currentCategory!;
      final nextNumber = await _storageService.getNextFileNumber(category);
      final filename = _storageService.generateFilename(
        category,
        collector,
        device,
        nextNumber,
      );

      // Save audio file to category directory
      final finalPath = await _storageService.saveRecording(
        _tempFilePath!,
        category,
        filename,
      );

      // Verify file exists
      final savedFile = File(finalPath);
      if (!await savedFile.exists() || await savedFile.length() == 0) {
        throw StateError('Failed to save audio file to disk.');
      }

      // Append metadata row
      final metadata = RecordingMetadata(
        filename: filename,
        category: category,
        collector: collector,
        device: device,
        durationSec: _totalDurationSeconds.toDouble(),
        sampleRate: 16000,
        timestampIso: DateTime.now().toUtc().toIso8601String(),
        environment: environment,
        distance: distance,
        noiseLevel: noiseLevel,
        notes: notes,
      );

      await _metadataService.appendRow(metadata);

      // Clean up temp file
      await _storageService.deleteTempFile(_tempFilePath!);
      _tempFilePath = null;
      _state = RecordingState.idle;
      _currentCategory = null;

      return filename;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
