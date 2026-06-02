import 'package:flutter/material.dart';

/// Central color palette for the Arena app.
/// All UI colors must be sourced from here — never use raw hex literals in widgets.
abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF122553);
  static const Color surface = Color(0xFF1E275F);
  static const Color surfaceVariant = Color(0xFF2A336B);

  // ── Brand / Accent ─────────────────────────────────────────────────────────
  static const Color neonGreen = Color(0xFF2ECC71);

  // ── Chips ──────────────────────────────────────────────────────────────────
  static const Color chipInactiveBg = Color.fromRGBO(1, 18, 58, 1);
  static const Color chipInactiveBorder = Color.fromRGBO(37, 46, 66, 1);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);

  // ── Decorative ─────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF282828);
  static const Color starColor = Color(0xFFFFC107);
}
