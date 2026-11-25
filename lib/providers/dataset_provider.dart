import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/models/recording_model.dart';
import 'package:hearassist_data_collector/services/metadata_service.dart';
import 'package:hearassist_data_collector/services/storage_service.dart';

/// Provider for managing overall dataset state, file counts, and storage.
class DatasetProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  late final MetadataService _metadataService;

  Map<String, int> _categoryCounts = {};
  int _totalCount = 0;
  int _totalStorageBytes = 0;
  bool _isLoading = false;

  Map<String, int> get categoryCounts => _categoryCounts;
  int get totalCount => _totalCount;
  int get totalStorageBytes => _totalStorageBytes;
  bool get isLoading => _isLoading;
  StorageService get storageService => _storageService;
  MetadataService get metadataService => _metadataService;

  DatasetProvider() {
    _metadataService = MetadataService(storageService: _storageService);
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.initializeDirectories();
      await _metadataService.initializeCsv();
      await refresh();
    } catch (e) {
      debugPrint('Error initializing dataset: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final Map<String, int> counts = {};
    int total = 0;

    for (final category in SoundCategory.allCategories) {
      final count = await _storageService.getCategoryCount(category.folderName);
      counts[category.folderName] = count;
      total += count;
    }

    _categoryCounts = counts;
    _totalCount = total;
    _totalStorageBytes = await _storageService.getTotalStorageUsed();
    notifyListeners();
  }

  Future<List<RecordingModel>> loadRecordings({String? category}) async {
    final files = await _storageService.listRecordingFiles(category: category);
    final List<RecordingModel> models = [];

    for (final file in files) {
      final filename = p.basename(file.path);
      // Determine category from parent folder name
      final folderName = p.basename(file.parent.path);
      final stat = await file.stat();

      // Estimate duration from 16kHz 16-bit mono PCM: 32000 bytes/sec
      // Header is 44 bytes
      final dataBytes = stat.size > 44 ? stat.size - 44 : stat.size;
      final durationSec = dataBytes / 32000.0;
      final duration = Duration(milliseconds: (durationSec * 1000).round());

      models.add(
        RecordingModel(
          filename: filename,
          filepath: file.path,
          category: folderName,
          duration: duration,
          createdAt: stat.modified,
          fileSizeBytes: stat.size,
        ),
      );
    }

    return models;
  }

  Future<void> deleteRecording(RecordingModel recording) async {
    await _storageService.deleteRecording(recording.filepath);
    await _metadataService.removeRow(recording.filename);
    await refresh();
  }

  Future<void> onRecordingSaved() async {
    await refresh();
  }
}
