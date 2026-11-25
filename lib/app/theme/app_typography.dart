import 'package:flutter/material.dart';
import 'package:hearassist_data_collector/app/theme/app_colors.dart';

/// Centralized typography system for HearAssist Data Collector.
class AppTypography {
  AppTypography._();

  // Screen Headings (24–28 px)
  static const TextStyle screenHeading = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const TextStyle screenHeadingDark = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  // Section Headings (18–20 px)
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle sectionHeadingDark = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Card Titles (15–17 px)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle cardTitleDark = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    height: 1.3,
  );

  // Body Text (14–16 px)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextPrimary,
    height: 1.45,
  );

  // Secondary Descriptions (12.5–13.5 px)
  static const TextStyle secondaryDescription = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle secondaryDescriptionDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    height: 1.4,
  );

  // Labels (12–14 px)
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.1,
  );

  // Buttons (14–16 px)
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.0,
  );

  // Captions (11–12 px)
  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const TextStyle captionDark = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextMuted,
    height: 1.3,
  );

  // Metadata Tags / Monospace (12–13 px)
  static const TextStyle metadata = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle metadataDark = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.2,
  );
}
