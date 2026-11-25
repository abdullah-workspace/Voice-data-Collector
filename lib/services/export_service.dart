import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hearassist_data_collector/services/storage_service.dart';

/// Creates a ZIP archive of the entire HearAssistDataset directory.
class ExportService {
  final StorageService _storageService;

  ExportService({required StorageService storageService})
      : _storageService = storageService;

  /// Collects all files from the HearAssistDataset directory, creates a
  /// ZIP named `HearAssistDataset_YYYY-MM-DD.zip` in the cache directory,
  /// preserves the directory structure, reports [onProgress] (0.0 – 1.0),
  /// and returns the path to the ZIP file.
  Future<String> exportDataset(
    void Function(double progress) onProgress,
  ) async {
    final datasetPath = await _storageService.getDatasetPath();
    final datasetDir = Directory(datasetPath);

    if (!await datasetDir.exists()) {
      throw StateError('Dataset directory does not exist: $datasetPath');
    }

    // Gather all files.
    final allFiles = <File>[];
    await for (final entity in datasetDir.list(recursive: true)) {
      if (entity is File) {
        allFiles.add(entity);
      }
    }

    final archive = Archive();
    final totalFiles = allFiles.length;

    for (int i = 0; i < totalFiles; i++) {
      final file = allFiles[i];
      final relativePath =
          p.relative(file.path, from: datasetPath).replaceAll(r'\', '/');
      final bytes = await file.readAsBytes();

      archive.addFile(
        ArchiveFile(relativePath, bytes.length, bytes),
      );

      onProgress(totalFiles > 0 ? (i + 1) / totalFiles : 1.0);
    }

    // Encode as ZIP.
    final zipBytes = ZipEncoder().encode(archive);

    // Write ZIP to cache directory.
    final cacheDir = await getTemporaryDirectory();
    final dateStamp = DateTime.now().toIso8601String().substring(0, 10);
    final zipFilename = 'HearAssistDataset_$dateStamp.zip';
    final zipPath = p.join(cacheDir.path, zipFilename);

    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);

    return zipPath;
  }
}
