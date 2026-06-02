import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFFEA580C),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardColor: Colors.white,
        textTheme: GoogleFonts.manropeTextTheme(),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.transparent,
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFEA580C),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.transparent,
        ),
      );
}

class AppColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Card / panel surface
  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  // Input field fill / secondary surface
  static Color surfaceVariant(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  // Dividers / card borders
  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // High-contrast body text
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1E293B);

  // Dark-navy text that flips to white in dark mode
  static Color textNavy(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1E0800);

  // Bottom nav container
  static Color navBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  // Nav indicator pill
  static Color navIndicator(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF1E0800).withValues(alpha: 0.08);

  // Selected nav icon
  static Color navIcon(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1E0800);

  // Unselected filter chip background
  static Color chipUnselected(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
}
