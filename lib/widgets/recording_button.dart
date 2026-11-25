import 'package:flutter/material.dart';
import 'package:hearassist_data_collector/app/theme/app_colors.dart';

/// Large, accessible recording button with pulsing animation during recording.
class RecordingButton extends StatefulWidget {
  final bool isRecording;
  final bool isEnabled;
  final VoidCallback onPressed;

  const RecordingButton({
    super.key,
    required this.isRecording,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Electric Cobalt for active recording indicator, Rich Obsidian for idle controls
    final activeColor = AppColors.secondaryCobalt;
    final idleColor = AppColors.primaryObsidian;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.isRecording ? activeColor : idleColor)
                      .withValues(alpha: widget.isRecording ? 0.35 : 0.2),
                  blurRadius: widget.isRecording ? 18 : 8,
                  spreadRadius: widget.isRecording ? 3 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: widget.isRecording ? activeColor : idleColor,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.isEnabled ? widget.onPressed : null,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
