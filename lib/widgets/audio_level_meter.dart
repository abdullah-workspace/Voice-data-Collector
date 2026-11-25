import 'package:flutter/material.dart';
import 'package:hearassist_data_collector/app/theme/app_colors.dart';

/// Horizontal bar showing live audio amplitude.
class AudioLevelMeter extends StatelessWidget {
  final double level; // 0.0 to 1.0
  final bool isActive;

  const AudioLevelMeter({
    super.key,
    required this.level,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedLevel = level.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Input Audio Level',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            Text(
              '${(clampedLevel * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryCobalt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceElevated
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * clampedLevel,
                    height: 8,
                    decoration: BoxDecoration(
                      color: clampedLevel > 0.85
                          ? AppColors.errorCoral
                          : AppColors.secondaryCobalt,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
