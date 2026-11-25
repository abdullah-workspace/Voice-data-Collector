import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hearassist_data_collector/config/categories.dart';

/// Manages the HearAssistDataset directory structure on external storage.
class StorageService {
  static const String _datasetFolder = 'HearAssistDataset';

  /// Creates the root dataset directory and all 6 category subdirectories.
  Future<void> initializeDirectories() async {
    final datasetPath = await getDatasetPath();
    final datasetDir = Directory(datasetPath);

    if (!await datasetDir.exists()) {
      await datasetDir.create(recursive: true);
    }

    for (final category in SoundCategory.allCategories) {
      final categoryDir = Directory(p.join(datasetPath, category.folderName));
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }
    }
  }

  /// Returns the absolute path to the dataset root directory.
  ///
  /// Uses the app-specific external files directory on Android, falling back
  /// to application documents directory in test or non-Android environments.
  Future<String> getDatasetPath() async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {
      // Fallback for testing environments where external storage is unavailable
      baseDir = await getApplicationDocumentsDirectory();
    }
    baseDir ??= await getApplicationDocumentsDirectory();
    return p.join(baseDir.path, _datasetFolder);
  }

  /// Returns the absolute path to a specific category folder.
  Future<String> getCategoryPath(String category) async {
    final datasetPath = await getDatasetPath();
    return p.join(datasetPath, category);
  }

  /// Scans existing WAV files in [category], parses the `_NNNN` suffix,
  /// and returns `max + 1` (starting at 1 when the folder is empty).
  Future<int> getNextFileNumber(String category) async {
    final categoryPath = await getCategoryPath(category);
    final dir = Directory(categoryPath);

    if (!await dir.exists()) {
      return 1;
    }

    int maxNumber = 0;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.wav')) {
        final basename = p.basenameWithoutExtension(entity.path);
        // Pattern: <category>_<collector>_<device>_<NNNN>
        final match = RegExp(r'_(\d+)$').firstMatch(basename);
        if (match != null) {
          final number = int.tryParse(match.group(1)!) ?? 0;
          if (number > maxNumber) {
            maxNumber = number;
          }
        }
      }
    }

    return maxNumber + 1;
  }

  /// Generates a filename in the format `<category>_<collector>_<device>_<NNNN>.wav`.
  ///
  /// Sanitizes [collector] and [device] by lowercasing, removing
  /// non-alphanumeric characters, and trimming.
  String generateFilename(
    String category,
    String collector,
    String device,
    int number,
  ) {
    final sanitizedCollector =
        collector.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
    final sanitizedDevice =
        device.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
    final paddedNumber = number.toString().padLeft(4, '0');
    return '${category}_${sanitizedCollector}_${sanitizedDevice}_$paddedNumber.wav';
  }

  /// Copies the temporary recording at [tempPath] into the [category]
  /// directory with the given [filename]. Returns the final path.
  Future<String> saveRecording(
    String tempPath,
    String category,
    String filename,
  ) async {
    final categoryPath = await getCategoryPath(category);
    final destinationPath = p.join(categoryPath, filename);
    final tempFile = File(tempPath);
    await tempFile.copy(destinationPath);
    return destinationPath;
  }

  /// Deletes the recording file at [filepath].
  Future<void> deleteRecording(String filepath) async {
    final file = File(filepath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns the number of `.wav` files in the given [category] folder.
  Future<int> getCategoryCount(String category) async {
    final categoryPath = await getCategoryPath(category);
    final dir = Directory(categoryPath);

    if (!await dir.exists()) {
      return 0;
    }

    int count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.wav')) {
        count++;
      }
    }
    return count;
  }

  /// Returns the total number of `.wav` files across all categories.
  Future<int> getTotalCount() async {
    int total = 0;
    for (final category in SoundCategory.allCategories) {
      total += await getCategoryCount(category.folderName);
    }
    return total;
  }

  /// Returns the total storage used (in bytes) by all files in the dataset.
  Future<int> getTotalStorageUsed() async {
    final datasetPath = await getDatasetPath();
    final dir = Directory(datasetPath);

    if (!await dir.exists()) {
      return 0;
    }

    int totalBytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  /// Safely deletes a temporary file at [path].
  Future<void> deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Silently ignore errors when cleaning up temp files.
    }
  }

  /// Lists all `.wav` recordings for a specific category (or all categories if null).
  Future<List<File>> listRecordingFiles({String? category}) async {
    final List<File> files = [];
    final datasetPath = await getDatasetPath();

    final categoriesToScan = category != null
        ? [category]
        : SoundCategory.allCategories.map((c) => c.folderName).toList();

    for (final cat in categoriesToScan) {
      final dir = Directory(p.join(datasetPath, cat));
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.wav')) {
            files.add(entity);
          }
        }
      }
    }

    // Sort newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
