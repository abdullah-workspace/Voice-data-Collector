import 'package:flutter/material.dart';

/// Centralized color palette for HearAssist Data Collector.
/// Aesthetic: Acoustic Studio (Warm Slate, Teal & Crisp Recording Accents)
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color primarySlate = Color(
    0xFF1E293B,
  ); // Deep Slate (Headers, primary actions)
  static const Color secondaryTeal = Color(
    0xFF0D9488,
  ); // Acoustic Teal (Waveforms, active toggles, highlights)
  static const Color backgroundWarm = Color(
    0xFFF6F7F9,
  ); // Soft Studio Gray (App canvas)
  static const Color surfacePureWhite = Color(
    0xFFFFFFFF,
  ); // Crisp White (Prompt cards, bottom sheets)

  // Typography & Text
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Ink Slate (Prompt text, primary labels)
  static const Color textSecondary = Color(
    0xFF475569,
  ); // Muted Slate (Instructions, metadata)
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Mist Gray (Timestamps, placeholders)

  // Borders & Dividers
  static const Color borderCrisp = Color(0xFFE2E8F0); // Clean Divider
  static const Color borderSubtle = Color(0xFFF1F5F9); // Subtle Card Outline

  // Semantic & Audio Status
  static const Color recordingPulse = Color(
    0xFFE11D48,
  ); // Studio Crimson (Live mic active state)
  static const Color successEmerald = Color(
    0xFF059669,
  ); // Synced / Verified Audio
  static const Color warningAmber = Color(0xFFD97706); // Pending Offline Upload
  static const Color errorCoral = Color(0xFFDC2626); // Validation / Noise Error

  // Backwards-compatible aliases (keeps your existing widget code working)
  static const Color primaryObsidian = primarySlate;
  static const Color secondaryCobalt = secondaryTeal;
  static const Color backgroundAlabaster = backgroundWarm;
  static const Color primaryNavy = primarySlate;
  static const Color background = backgroundWarm;
  static const Color surface = surfacePureWhite;
  static const Color borderIce = borderCrisp;
  static const Color border = borderCrisp;
  static const Color borderLight = borderSubtle;
  static const Color success = successEmerald;
  static const Color warning = warningAmber;
  static const Color error = errorCoral;

  // Dark Theme Palette (Studio Night Mode)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
}
