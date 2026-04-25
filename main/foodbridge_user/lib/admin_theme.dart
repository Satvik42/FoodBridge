import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminColors {
  static const bg        = Color(0xFFF4F6F9);
  static const bg2       = Color(0xFFEAEDF2);
  static const cardBg    = Colors.white;
  static const navy      = Color(0xFF1A2744);
  static const navy2     = Color(0xFF243460);
  static const accent    = Color(0xFF2D6A4F);   // same green as user app
  static const accentL   = Color(0xFFD8F3DC);
  static const amber     = Color(0xFFE9A825);
  static const amberL    = Color(0xFFFDF3D7);
  static const coral     = Color(0xFFD85A30);
  static const coralL    = Color(0xFFFAECE7);
  static const blue      = Color(0xFF1A73E8);
  static const blueL     = Color(0xFFE8F0FE);
  static const purple    = Color(0xFF7B5EA7);
  static const purpleL   = Color(0xFFF0EBF8);
  static const textPrimary   = Color(0xFF1A2744);
  static const textSecondary = Color(0xFF4A5E7A);
  static const textMuted     = Color(0xFF8A9BBE);
  static const border    = Color(0x1A1A2744);
  static const divider   = Color(0xFFE2E8F0);
}

class AdminTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AdminColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AdminColors.navy,
      background: AdminColors.bg,
    ),
    textTheme: GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AdminColors.textPrimary,
      displayColor: AdminColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AdminColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AdminColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AdminColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminColors.bg2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AdminColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AdminColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AdminColors.navy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AdminColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        textStyle: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
