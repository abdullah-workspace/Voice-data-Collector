/// Represents a single audio recording captured during data collection.
class RecordingModel {
  final String filename;
  final String filepath;
  final String category;
  final Duration duration;
  final DateTime createdAt;
  final int fileSizeBytes;

  const RecordingModel({
    required this.filename,
    required this.filepath,
    required this.category,
    required this.duration,
    required this.createdAt,
    required this.fileSizeBytes,
  });

  RecordingModel copyWith({
    String? filename,
    String? filepath,
    String? category,
    Duration? duration,
    DateTime? createdAt,
    int? fileSizeBytes,
  }) {
    return RecordingModel(
      filename: filename ?? this.filename,
      filepath: filepath ?? this.filepath,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  @override
  String toString() {
    return 'RecordingModel(filename: $filename, category: $category, '
        'duration: $duration, createdAt: $createdAt, '
        'fileSizeBytes: $fileSizeBytes)';
  }
}
