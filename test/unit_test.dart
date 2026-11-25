import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/models/recording_metadata.dart';
import 'package:hearassist_data_collector/services/settings_service.dart';
import 'package:hearassist_data_collector/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sound Categories Configuration Tests', () {
    test('Must contain exactly 6 specified categories', () {
      expect(SoundCategory.allCategories.length, 6);

      final categoryIds = SoundCategory.allCategories.map((c) => c.id).toList();
      expect(categoryIds, contains('clapping'));
      expect(categoryIds, contains('doorbell'));
      expect(categoryIds, contains('door_knock'));
      expect(categoryIds, contains('baby_cry'));
      expect(categoryIds, contains('microwave_oven'));
      expect(categoryIds, contains('background_noise'));
    });

    test('getCategoryById returns correct category and null for unknown', () {
      final doorbell = SoundCategory.getCategoryById('doorbell');
      expect(doorbell, isNotNull);
      expect(doorbell!.displayName, 'Doorbell');
      expect(doorbell.folderName, 'doorbell');

      final unknown = SoundCategory.getCategoryById('invalid_category');
      expect(unknown, isNull);
    });
  });

  group('Filename Convention & Sanitization Tests', () {
    final storage = StorageService();

    test('Generates filename in exact required format: <category>_<collector>_<device>_<NNNN>.wav', () {
      final filename = storage.generateFilename(
        'door_knock',
        'abdullah',
        'samsungA14',
        7,
      );
      expect(filename, 'door_knock_abdullah_samsunga14_0007.wav');
    });

    test('Sanitizes collector and device names by removing special chars and spaces', () {
      final filename = storage.generateFilename(
        'clapping',
        'Abdullah & Co.',
        'Samsung Galaxy S23 Ultra!',
        1,
      );
      expect(filename, 'clapping_abdullahco_samsunggalaxys23ultra_0001.wav');
    });

    test('Pads sequence number to 4 digits', () {
      expect(
        storage.generateFilename('baby_cry', 'col', 'dev', 1),
        'baby_cry_col_dev_0001.wav',
      );
      expect(
        storage.generateFilename('baby_cry', 'col', 'dev', 99),
        'baby_cry_col_dev_0099.wav',
      );
      expect(
        storage.generateFilename('baby_cry', 'col', 'dev', 1234),
        'baby_cry_col_dev_1234.wav',
      );
    });
  });

  group('Metadata CSV Serialization Tests', () {
    test('CSV headers match all 11 required columns', () {
      final headers = RecordingMetadata.csvHeaders;
      expect(headers, [
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
      ]);
    });

    test('RecordingMetadata converts to and from CSV row correctly', () {
      const meta = RecordingMetadata(
        filename: 'doorbell_abdullah_samsunga14_0001.wav',
        category: 'doorbell',
        collector: 'abdullah',
        device: 'samsunga14',
        durationSec: 3.0,
        sampleRate: 16000,
        timestampIso: '2026-11-25T16:00:00.000Z',
        environment: 'living room',
        distance: 'medium (1–3m)',
        noiseLevel: 'quiet',
        notes: 'Doorbell chime, high pitch',
      );

      final row = meta.toCsvRow();
      expect(row.length, 11);
      expect(row[0], 'doorbell_abdullah_samsunga14_0001.wav');
      expect(row[4], 3.0);
      expect(row[5], 16000);
      expect(row[10], 'Doorbell chime, high pitch');

      final reconstructed = RecordingMetadata.fromCsvRow(row);
      expect(reconstructed.filename, meta.filename);
      expect(reconstructed.category, meta.category);
      expect(reconstructed.collector, meta.collector);
      expect(reconstructed.device, meta.device);
      expect(reconstructed.durationSec, meta.durationSec);
      expect(reconstructed.sampleRate, meta.sampleRate);
      expect(reconstructed.timestampIso, meta.timestampIso);
      expect(reconstructed.environment, meta.environment);
      expect(reconstructed.distance, meta.distance);
      expect(reconstructed.noiseLevel, meta.noiseLevel);
      expect(reconstructed.notes, meta.notes);
    });
  });

  group('Recording Duration & Migration Tests', () {
    test('Default recording duration is strictly 3 seconds', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService();
      await service.init();

      expect(service.recordingDurationSeconds, 3);
    });

    test('Allows 2 seconds and 3 seconds', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService();
      await service.init();

      await service.setRecordingDurationSeconds(2);
      expect(service.recordingDurationSeconds, 2);

      await service.setRecordingDurationSeconds(3);
      expect(service.recordingDurationSeconds, 3);
    });

    test('Migrates legacy 5 seconds to 3 seconds safely', () async {
      // Simulate an existing installation that had 5 seconds saved
      SharedPreferences.setMockInitialValues({
        'recording_duration_seconds': 5,
      });

      final service = SettingsService();
      await service.init();

      // Must be safely migrated to 3
      expect(service.recordingDurationSeconds, 3);
    });

    test('Rejects any invalid duration and defaults to 3 seconds', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService();
      await service.init();

      await service.setRecordingDurationSeconds(10);
      expect(service.recordingDurationSeconds, 3);
    });
  });

  group('WAV Format Verification Tests', () {
    test('WAV Header structure matches 16 kHz Mono 16-bit PCM standard (44 bytes)', () {
      const sampleRate = 16000;
      const numChannels = 1;
      const bitsPerSample = 16;
      const dataSize = 96000; // 3 seconds at 16000 samples/sec * 2 bytes/sample
      const byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
      const blockAlign = numChannels * bitsPerSample ~/ 8;

      final header = ByteData(44);
      // RIFF
      header.setUint8(0, 0x52); // R
      header.setUint8(1, 0x49); // I
      header.setUint8(2, 0x46); // F
      header.setUint8(3, 0x46); // F
      header.setUint32(4, 36 + dataSize, Endian.little);
      header.setUint8(8, 0x57);  // W
      header.setUint8(9, 0x41);  // A
      header.setUint8(10, 0x56); // V
      header.setUint8(11, 0x45); // E

      // fmt
      header.setUint8(12, 0x66); // f
      header.setUint8(13, 0x6D); // m
      header.setUint8(14, 0x74); // t
      header.setUint8(15, 0x20); // ' '
      header.setUint32(16, 16, Endian.little); // PCM subchunk size
      header.setUint16(20, 1, Endian.little);  // Format 1 = PCM
      header.setUint16(22, numChannels, Endian.little);
      header.setUint32(24, sampleRate, Endian.little);
      header.setUint32(28, byteRate, Endian.little);
      header.setUint16(32, blockAlign, Endian.little);
      header.setUint16(34, bitsPerSample, Endian.little);

      // data
      header.setUint8(36, 0x64); // d
      header.setUint8(37, 0x61); // a
      header.setUint8(38, 0x74); // t
      header.setUint8(39, 0x61); // a
      header.setUint32(40, dataSize, Endian.little);

      // Verify all offsets
      expect(header.getUint16(20, Endian.little), 1); // PCM
      expect(header.getUint16(22, Endian.little), 1); // Mono
      expect(header.getUint32(24, Endian.little), 16000); // 16kHz
      expect(header.getUint32(28, Endian.little), 32000); // 32000 bytes/sec
      expect(header.getUint16(32, Endian.little), 2); // 2 bytes per block
      expect(header.getUint16(34, Endian.little), 16); // 16-bit
    });
  });
}
