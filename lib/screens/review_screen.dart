import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/app/theme/app_typography.dart';
import 'package:hearassist_data_collector/config/categories.dart';
import 'package:hearassist_data_collector/providers/dataset_provider.dart';
import 'package:hearassist_data_collector/providers/recording_provider.dart';
import 'package:hearassist_data_collector/providers/settings_provider.dart';
import 'package:hearassist_data_collector/widgets/metadata_form.dart';

/// Screen displayed after a recording completes to review audio and metadata before saving.
class ReviewScreen extends StatefulWidget {
  final String category;
  final String tempFilePath;
  final int durationSeconds;

  const ReviewScreen({
    super.key,
    required this.category,
    required this.tempFilePath,
    required this.durationSeconds,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSaving = false;

  late MetadataValues _metadataValues;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    final settings = context.read<SettingsProvider>();
    _metadataValues = MetadataValues(
      environment: settings.lastEnvironment,
      distance: settings.lastDistance,
      noiseLevel: settings.lastNoiseLevel,
      notes: '',
    );

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setFilePath(widget.tempFilePath);
      _totalDuration = _player.duration ?? Duration(seconds: widget.durationSeconds);

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing &&
                state.processingState != ProcessingState.completed;
            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
            }
          });
        }
      });

      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    } catch (e) {
      debugPrint('Error loading audio file: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position >= _totalDuration) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final settings = context.read<SettingsProvider>();
    final recordingProvider = context.read<RecordingProvider>();

    try {
      await _player.stop();

      // Remember last choices
      await settings.setLastMetadataChoices(
        environment: _metadataValues.environment,
        distance: _metadataValues.distance,
        noiseLevel: _metadataValues.noiseLevel,
      );

      final filename = await recordingProvider.saveRecording(
        collector: settings.collectorName,
        device: settings.deviceLabel,
        environment: _metadataValues.environment,
        distance: _metadataValues.distance,
        noiseLevel: _metadataValues.noiseLevel,
        notes: _metadataValues.notes,
      );

      if (mounted) {
        // Refresh dataset counts
        context.read<DatasetProvider>().refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Saved: $filename')),
              ],
            ),
            backgroundColor: AppColors.successEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recording: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmAndDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Recording?'),
        content: const Text(
          'Are you sure you want to discard this audio sample? It will be permanently deleted.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorCoral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _player.stop();
      if (!mounted) return;
      await context.read<RecordingProvider>().discardRecording();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording discarded'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    final tempFile = File(widget.tempFilePath);
    if (tempFile.existsSync()) {
      try {
        tempFile.deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryObj = SoundCategory.getCategoryById(widget.category);
    final settings = context.watch<SettingsProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmAndDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Recording'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmAndDiscard,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio Playback Preview Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.borderIce,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: _isPlaying
                                  ? AppColors.secondaryCobalt
                                  : AppColors.primaryObsidian,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: _togglePlayback,
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryObj?.displayName ?? widget.category,
                                  style: isDark
                                      ? AppTypography.cardTitleDark
                                      : AppTypography.cardTitle,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Duration: ${widget.durationSeconds}s • 16 kHz Mono WAV',
                                  style: isDark
                                      ? AppTypography.secondaryDescriptionDark
                                      : AppTypography.secondaryDescription,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _totalDuration.inMilliseconds > 0
                              ? (_position.inMilliseconds /
                                      _totalDuration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryCobalt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Metadata Form Header
                Text(
                  'Sample Metadata',
                  style: isDark
                      ? AppTypography.sectionHeadingDark
                      : AppTypography.sectionHeading,
                ),
                const SizedBox(height: 4),
                Text(
                  'Record contextual environmental variables saved into metadata.csv',
                  style: isDark
                      ? AppTypography.secondaryDescriptionDark
                      : AppTypography.secondaryDescription,
                ),
                const SizedBox(height: 16),

                // Metadata Form
                MetadataForm(
                  initialEnvironment: settings.lastEnvironment,
                  initialDistance: settings.lastDistance,
                  initialNoiseLevel: settings.lastNoiseLevel,
                  onChanged: (vals) => _metadataValues = vals,
                ),

                const SizedBox(height: 28),

                // Save & Discard Buttons
                Row(
                  children: [
                    // Discard Button (visually distinct, red outline)
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _confirmAndDiscard,
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text('Discard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorCoral,
                          side: const BorderSide(color: AppColors.errorCoral, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Save Button (prominent Cobalt/Navy)
                    Expanded(
                      flex: 6,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(_isSaving ? 'Saving...' : 'Save Sample'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondaryCobalt,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
