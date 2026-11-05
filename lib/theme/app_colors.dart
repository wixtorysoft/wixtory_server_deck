import 'package:flutter/material.dart';

class AppColors {
  // Void & Dark Surfaces
  static const Color voidBg = Color(0xFF080B12);
  static const Color surface = Color(0xFF0E1524);
  static const Color surfaceLight = Color(0xFF151F33);
  static const Color card = Color(0xFF19243C);
  static const Color cardElevated = Color(0xFF202E4C);

  // Borders & Dividers
  static const Color border = Color(0x1AFFFFFF); // 10% white
  static const Color borderHighlight = Color(0x3338BDF8); // 20% sky blue
  static const Color divider = Color(0x12FFFFFF);

  // Terminal & Cyber Accents
  static const Color cyberGreen = Color(0xFF10B981); // Emerald
  static const Color cyberCyan = Color(0xFF06B6D4);  // Aqua Cyan
  static const Color electricViolet = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);
  static const Color sky = Color(0xFF38BDF8);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textTerminal = Color(0xFF4ADE80);

  // Status
  static const Color online = Color(0xFF10B981);
  static const Color connecting = Color(0xFFF59E0B);
  static const Color offline = Color(0xFF64748B);
  static const Color error = Color(0xFFEF4444);

  // Terminal Background
  static const Color terminalBg = Color(0xFF05080E);
  static const Color terminalCursor = Color(0xFF10B981);

  // Palette choices for server tags
  static const List<int> serverColorPalette = [
    0xFF10B981, // Emerald
    0xFF06B6D4, // Cyan
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFFF97316, // Orange
    0xFF14B8A6, // Teal
  ];
}
