import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

import 'package:hearassist_data_collector/models/recording_metadata.dart';
import 'package:hearassist_data_collector/services/storage_service.dart';

/// Manages the metadata.csv file within the HearAssistDataset directory.
class MetadataService {
  static const String _csvFilename = 'metadata.csv';

  final StorageService _storageService;

  MetadataService({required StorageService storageService})
      : _storageService = storageService;

  /// Returns the full path to metadata.csv.
  Future<String> _getCsvPath() async {
    final datasetPath = await _storageService.getDatasetPath();
    return p.join(datasetPath, _csvFilename);
  }

  /// Creates metadata.csv with headers if it doesn't already exist.
  Future<void> initializeCsv() async {
    final csvPath = await _getCsvPath();
    final file = File(csvPath);

    if (!await file.exists()) {
      const converter = ListToCsvConverter();
      final headerLine = converter.convert([RecordingMetadata.csvHeaders]);
      await file.writeAsString('$headerLine\n');
    }
  }

  /// Appends a single row of [metadata] to metadata.csv.
  Future<void> appendRow(RecordingMetadata metadata) async {
    final csvPath = await _getCsvPath();
    final file = File(csvPath);

    const converter = ListToCsvConverter();
    final rowLine = converter.convert([metadata.toCsvRow()]);
    await file.writeAsString('$rowLine\n', mode: FileMode.append);
  }

  /// Removes the row whose filename matches [filename] from metadata.csv.
  ///
  /// Reads all rows, filters out the matching one, and rewrites the file.
  Future<void> removeRow(String filename) async {
    final csvPath = await _getCsvPath();
    final file = File(csvPath);

    if (!await file.exists()) return;

    final contents = await file.readAsString();
    const parser = CsvToListConverter(eol: '\n');
    final rows = parser.convert(contents);

    if (rows.isEmpty) return;

    // First row is the header.
    final header = rows.first;
    final dataRows = rows.skip(1).where((row) {
      return row.isNotEmpty && row[0].toString() != filename;
    }).toList();

    const converter = ListToCsvConverter();
    final buffer = StringBuffer();
    buffer.writeln(converter.convert([header]));
    for (final row in dataRows) {
      buffer.writeln(converter.convert([row]));
    }

    await file.writeAsString(buffer.toString());
  }

  /// Parses metadata.csv and returns all entries as a list of
  /// [RecordingMetadata].
  Future<List<RecordingMetadata>> readAll() async {
    final csvPath = await _getCsvPath();
    final file = File(csvPath);

    if (!await file.exists()) return [];

    final contents = await file.readAsString();
    const parser = CsvToListConverter(eol: '\n');
    final rows = parser.convert(contents);

    if (rows.length <= 1) return []; // Only header or empty.

    return rows
        .skip(1) // Skip header row.
        .where((row) => row.length >= 11)
        .map((row) => RecordingMetadata.fromCsvRow(row))
        .toList();
  }
}
