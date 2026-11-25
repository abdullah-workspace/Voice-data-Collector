import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/providers/recording_provider.dart';
import 'package:hearassist_data_collector/providers/settings_provider.dart';
import 'package:hearassist_data_collector/screens/review_screen.dart';
import 'package:hearassist_data_collector/widgets/audio_level_meter.dart';
import 'package:hearassist_data_collector/widgets/recording_button.dart';

/// Screen for recording an audio sample for a selected category.
class RecordScreen extends StatefulWidget {
  final String category;

  const RecordScreen({
    super.key,
    required this.category,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with WidgetsBindingObserver {
  late final SoundCategory _category;
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _category = SoundCategory.getCategoryById(widget.category) ??
        SoundCategory.allCategories.first;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final recordingProvider = context.read<RecordingProvider>();
      if (recordingProvider.isRecording) {
        recordingProvider.cancelRecording();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleRecordTapped() async {
    final recordingProvider = context.read<RecordingProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (recordingProvider.isRecording) {
      await recordingProvider.cancelRecording();
      return;
    }

    if (settingsProvider.collectorName.isEmpty ||
        settingsProvider.deviceLabel.isEmpty) {
      _showConfigurationWarning();
      return;
    }

    setState(() => _isCheckingPermission = true);

    try {
      final status = await recordingProvider.checkAndRequestPermission();

      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        _showPermanentlyDeniedDialog();
        return;
      }

      if (!status.isGranted) {
        _showPermissionDeniedSnackBar();
        return;
      }

      final duration = (settingsProvider.recordingDuration == 2) ? 2 : 3;

      await recordingProvider.startRecording(
        category: _category.folderName,
        durationSeconds: duration,
      );

      _waitForReviewTransition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingPermission = false);
    }
  }

  void _waitForReviewTransition() {
    final recordingProvider = context.read<RecordingProvider>();

    void listener() {
      if (!mounted) return;
      if (recordingProvider.isReviewing &&
          recordingProvider.tempFilePath != null) {
        recordingProvider.removeListener(listener);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              category: _category.folderName,
              tempFilePath: recordingProvider.tempFilePath!,
              durationSeconds: recordingProvider.totalDurationSeconds,
            ),
          ),
        );
      }
    }

    recordingProvider.addListener(listener);
  }

  void _showConfigurationWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collector Details Required'),
        content: const Text(
          'Please configure your Collector Name and Device Label in Settings before recording. '
          'This ensures proper attribution and filename generation.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'Microphone permission is permanently denied. '
          'Please enable microphone access in Android Settings to capture audio samples.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone access is required to record environmental audio.'),
        backgroundColor: AppColors.errorCoral,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recording = context.watch<RecordingProvider>();
    final settings = context.watch<SettingsProvider>();
    final targetDuration = (settings.recordingDuration == 2) ? 2 : 3;

    return Scaffold(
      appBar: AppBar(
        title: Text('Record ${_category.displayName}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Category Card Header
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.borderIce,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCobalt.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _category.icon,
                        color: AppColors.secondaryCobalt,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _category.displayName,
                            style: isDark
                                ? AppTypography.cardTitleDark
                                : AppTypography.cardTitle,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _category.description,
                            style: isDark
                                ? AppTypography.secondaryDescriptionDark
                                : AppTypography.secondaryDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Countdown Circular Gauge
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: recording.isRecording
                      ? AppColors.secondaryCobalt.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkSurface : AppColors.surfacePureWhite),
                  border: Border.all(
                    color: recording.isRecording
                        ? AppColors.secondaryCobalt
                        : (isDark ? AppColors.darkBorder : AppColors.borderIce),
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        recording.isRecording
                            ? '${recording.remainingSeconds}'
                            : '${targetDuration}s',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: recording.isRecording
                              ? AppColors.secondaryCobalt
                              : (isDark ? AppColors.darkTextPrimary : AppColors.primaryObsidian),
                        ),
                      ),
                      Text(
                        recording.isRecording ? 'RECORDING' : 'READY',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color: recording.isRecording
                              ? AppColors.secondaryCobalt
                              : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status Indicator Text
              Text(
                recording.isRecording
                    ? 'Capturing acoustic audio sample...'
                    : 'Tap the button below to start $targetDuration-second recording',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: recording.isRecording
                      ? AppColors.secondaryCobalt
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Live Audio Input Level Meter
              if (recording.isRecording)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AudioLevelMeter(
                    level: recording.amplitude,
                    isActive: recording.isRecording,
                  ),
                ),

              const SizedBox(height: 36),

              // Record Button & Technical Specification
              RecordingButton(
                isRecording: recording.isRecording,
                isEnabled: !_isCheckingPermission,
                onPressed: _handleRecordTapped,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'WAV • PCM 16-bit • 16,000 Hz Mono',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
