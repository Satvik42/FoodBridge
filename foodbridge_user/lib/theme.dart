import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core backgrounds
  static const bg        = Color(0xFFF7F9F4);
  static const bg2       = Color(0xFFEEF2E8);
  static const bg3       = Color(0xFFE2EAD8);
  static const cardBg    = Colors.white;

  // Forest greens
  static const primary   = Color(0xFF2D6A4F);
  static const primary2  = Color(0xFF40916C);
  static const primary3  = Color(0xFF52B788);
  static const primaryL  = Color(0xFFD8F3DC);
  static const primaryXL = Color(0xFFECF9EE);

  // Accent — warm amber
  static const amber     = Color(0xFFB5830F);
  static const amberL    = Color(0xFFFDF3D7);
  static const amberMid  = Color(0xFFE9A825);

  // Status
  static const coral     = Color(0xFFD85A30);
  static const coralL    = Color(0xFFFAECE7);
  static const blue      = Color(0xFF1A73E8);
  static const blueL     = Color(0xFFE8F0FE);
  static const purple    = Color(0xFF7B5EA7);
  static const purpleL   = Color(0xFFF0EBF8);

  // Text
  static const textPrimary   = Color(0xFF1A2E1A);
  static const textSecondary = Color(0xFF4A5E4A);
  static const textMuted     = Color(0xFF7A8E7A);

  static const border    = Color(0x1A2D6A4F);
  static const divider   = Color(0xFFE0E8DC);

  // Additional colors for specific screens
  static const green      = Color(0xFF2D6A4F);
  static const greenMid   = Color(0xFF40916C);
  static const greenLight = Color(0xFFD8F3DC);
  static const amberLight = Color(0xFFFDF3D7);
  static const coralMid   = Color(0xFFE97451);
  static const coralLight = Color(0xFFFAECE7);
  static const blueLight  = Color(0xFFE8F0FE);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.bg,
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary2, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        textStyle: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg2,
      selectedColor: AppColors.primaryL,
      labelStyle: GoogleFonts.dmSans(fontSize: 12),
      side: const BorderSide(color: AppColors.border, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
