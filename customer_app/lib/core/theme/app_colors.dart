import 'package:flutter/material.dart';

/// Techbes brand color palette derived from the web app's Tailwind config.
class AppColors {
  AppColors._();

  // ── Emerald accent (primary) ─────────────────────────────────────────
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);

  // ── Slate neutrals ──────────────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ── Blue accent ──────────────────────────────────────────────────────
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);

  // ── Amber (ratings) ──────────────────────────────────────────────────
  static const Color amber400 = Color(0xFFFBBF24);

  // ── Status colors ────────────────────────────────────────────────────
  static const Color success = emerald500;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = blue600;

  // ── Dark theme surface palette ───────────────────────────────────────
  static const Color darkSurface = Color(0xFF121218);
  static const Color darkCard = Color(0xFF1A1A24);
  static const Color darkElevated = Color(0xFF22222E);
  static const Color darkBorder = Color(0xFF2A2A38);
}
