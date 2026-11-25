import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hearassist_data_collector/app/theme/app_colors.dart';
import 'package:hearassist_data_collector/models/recording_model.dart';

/// Item in the library list showing audio playback and delete controls.
class RecordingListItem extends StatefulWidget {
  final RecordingModel recording;
  final VoidCallback onDelete;

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.onDelete,
  });

  @override
  State<RecordingListItem> createState() => _RecordingListItemState();
}

class _RecordingListItemState extends State<RecordingListItem> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
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
      if (mounted) {
        setState(() => _position = pos);
      }
    });
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.setFilePath(widget.recording.filepath);
        _totalDuration = _player.duration ?? widget.recording.duration;
        await _player.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback error: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    final ms = (d.inMilliseconds % 1000) ~/ 100;
    return '$seconds.${ms}s';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfacePureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isPlaying
              ? AppColors.secondaryCobalt
              : (isDark ? AppColors.darkBorder : AppColors.borderIce),
          width: _isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                // Play / Pause Circle Button
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: _isPlaying
                        ? AppColors.secondaryCobalt
                        : AppColors.primaryObsidian,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(42, 42),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _togglePlay,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recording.filename,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCobalt.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.recording.category,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryCobalt,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(widget.recording.duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatFileSize(widget.recording.fileSizeBytes),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.errorCoral,
                    size: 20,
                  ),
                  tooltip: 'Delete recording',
                ),
              ],
            ),

            // Progress bar if playing
            if (_isPlaying) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _totalDuration.inMilliseconds > 0
                      ? (_position.inMilliseconds / _totalDuration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 3,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryCobalt),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
