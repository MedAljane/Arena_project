import 'package:flutter/material.dart';

/// Palette shared by dark AND light admin theme variants.
/// Static references that don't change with theme go here;
/// theme-specific colours live in [AdminTheme].
class AdminColors {
  // ── Accent (same in both modes) ──────────────────────────────────────────
  static const neonGreen = Color(0xFF2ECC71);
  static const indigo    = Color(0xFF4F46E5);
  static const indigoLight = Color(0xFF6366F1);
  static const danger    = Color(0xFFEF4444);
  static const warning   = Color(0xFFFFC107);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const darkBg      = Color(0xFF0F1117);
  static const darkCard    = Color(0xFF1A1D2E);
  static const darkSurface = Color(0xFF1E2132);
  static const darkBorder  = Color(0xFF2A2D3E);
  static const darkText    = Color(0xFFE2E8F0);
  static const darkMuted   = Color(0xFF94A3B8);
  static const darkSubtle  = Color(0xFF4A5060);
  static const darkInput   = Color(0xFF0F1117);

  // ── Light mode ────────────────────────────────────────────────────────────
  static const lightBg      = Color(0xFFF8FAFC);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF1F5F9);
  static const lightBorder  = Color(0xFFE2E8F0);
  static const lightText    = Color(0xFF0F172A);
  static const lightMuted   = Color(0xFF475569);
  static const lightSubtle  = Color(0xFF94A3B8);
  static const lightInput   = Color(0xFFFFFFFF);

  // ── Status badges ─────────────────────────────────────────────────────────
  static const emerald = Color(0xFF10B981);
  static const sky     = Color(0xFF0EA5E9);
  static const violet  = Color(0xFF8B5CF6);
  static const amber   = Color(0xFFF59E0B);
  static const teal    = Color(0xFF14B8A6);
  static const rose    = Color(0xFFF43F5E);
}
