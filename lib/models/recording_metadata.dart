/// Metadata for a recording, matching the CSV export columns.
class RecordingMetadata {
  final String filename;
  final String category;
  final String collector;
  final String device;
  final double durationSec;
  final int sampleRate;
  final String timestampIso;
  final String environment;
  final String distance;
  final String noiseLevel;
  final String notes;

  const RecordingMetadata({
    required this.filename,
    required this.category,
    required this.collector,
    required this.device,
    required this.durationSec,
    required this.sampleRate,
    required this.timestampIso,
    required this.environment,
    required this.distance,
    required this.noiseLevel,
    required this.notes,
  });

  /// CSV column headers in the order they appear in export files.
  static List<String> get csvHeaders => [
        'filename',
        'category',
        'collector',
        'device',
        'duration_sec',
        'sample_rate',
        'timestamp_iso',
        'environment',
        'distance',
        'noise_level',
        'notes',
      ];

  /// Converts this metadata to a CSV row (list of values in header order).
  List<dynamic> toCsvRow() {
    return [
      filename,
      category,
      collector,
      device,
      durationSec,
      sampleRate,
      timestampIso,
      environment,
      distance,
      noiseLevel,
      notes,
    ];
  }

  /// Creates a [RecordingMetadata] from a CSV row (list of values in header order).
  factory RecordingMetadata.fromCsvRow(List<dynamic> row) {
    return RecordingMetadata(
      filename: row[0]?.toString() ?? '',
      category: row[1]?.toString() ?? '',
      collector: row[2]?.toString() ?? '',
      device: row[3]?.toString() ?? '',
      durationSec: (row[4] is double)
          ? row[4] as double
          : double.tryParse(row[4]?.toString() ?? '0') ?? 0.0,
      sampleRate: (row[5] is int)
          ? row[5] as int
          : int.tryParse(row[5]?.toString() ?? '0') ?? 0,
      timestampIso: row[6]?.toString() ?? '',
      environment: row[7]?.toString() ?? '',
      distance: row[8]?.toString() ?? '',
      noiseLevel: row[9]?.toString() ?? '',
      notes: row[10]?.toString() ?? '',
    );
  }

  RecordingMetadata copyWith({
    String? filename,
    String? category,
    String? collector,
    String? device,
    double? durationSec,
    int? sampleRate,
    String? timestampIso,
    String? environment,
    String? distance,
    String? noiseLevel,
    String? notes,
  }) {
    return RecordingMetadata(
      filename: filename ?? this.filename,
      category: category ?? this.category,
      collector: collector ?? this.collector,
      device: device ?? this.device,
      durationSec: durationSec ?? this.durationSec,
      sampleRate: sampleRate ?? this.sampleRate,
      timestampIso: timestampIso ?? this.timestampIso,
      environment: environment ?? this.environment,
      distance: distance ?? this.distance,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'RecordingMetadata(filename: $filename, category: $category, '
        'collector: $collector, duration: ${durationSec}s)';
  }
}
