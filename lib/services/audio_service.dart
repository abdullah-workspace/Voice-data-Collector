import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Wraps the `record` package (AudioRecorder API) for WAV recording
/// at 16 kHz mono.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;

  /// Whether a recording session is currently active.
  bool get isRecording => _isRecording;

  /// Requests microphone permission and returns whether it was granted.
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  /// Starts recording to [path] in WAV format (16 kHz, mono, 16-bit PCM).
  ///
  /// On platforms where `AudioEncoder.wav` is not supported (e.g. some
  /// Android devices), falls back to `AudioEncoder.pcm16bits` and the
  /// WAV header is written manually when recording stops.
  Future<void> startRecording(String path) async {
    if (_isRecording) return;

    // Try WAV encoder first; fall back to raw PCM if unsupported.
    final wavSupported = await _recorder.isEncoderSupported(AudioEncoder.wav);

    final config = RecordConfig(
      encoder: wavSupported ? AudioEncoder.wav : AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 256000,
    );

    await _recorder.start(config, path: path);
    _isRecording = true;
  }

  /// Stops the current recording session and returns the output file path,
  /// or `null` if no recording was active.
  ///
  /// If raw PCM was used (WAV encoder unsupported), a WAV header is
  /// prepended to the file.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path != null) {
      await _ensureWavHeader(path);
    }

    return path;
  }

  /// Cancels the current recording, stops and deletes the output file.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Returns a stream of normalised amplitude values (0.0 – 1.0),
  /// polled every 100 ms.
  Stream<double> getAmplitudeStream() {
    late StreamController<double> controller;
    Timer? timer;

    controller = StreamController<double>(
      onListen: () {
        timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
          try {
            final amplitude = await _recorder.getAmplitude();
            // amplitude.current is in dBFS (typically –160 … 0).
            // Normalise to 0.0 – 1.0.
            final double dbValue = amplitude.current;
            const double minDb = -60.0;
            final normalised =
                ((dbValue - minDb) / (0.0 - minDb)).clamp(0.0, 1.0);
            controller.add(normalised);
          } catch (_) {
            // Recorder may not be active; ignore.
          }
        });
      },
      onCancel: () {
        timer?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Releases resources held by the recorder.
  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    _recorder.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// If the file at [path] does not begin with a RIFF/WAV header, it is
  /// treated as raw PCM-16 data and a proper WAV header is prepended.
  Future<void> _ensureWavHeader(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    if (bytes.length < 4) return;

    // Check for existing RIFF header.
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return; // Already a WAV file.
    }

    // Raw PCM data – write a WAV header.
    const int sampleRate = 16000;
    const int numChannels = 1;
    const int bitsPerSample = 16;
    final int dataSize = bytes.length;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const int blockAlign = numChannels * bitsPerSample ~/ 8;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // Sub-chunk size
    header.setUint16(20, 1, Endian.little);  // Audio format (PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());
    wavBytes.setRange(44, 44 + dataSize, bytes);

    await file.writeAsBytes(wavBytes);
  }
}
