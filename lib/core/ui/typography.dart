import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Operations Command" type system for SH Malik mobile.
///
/// - **Display & numerals:** Archivo — a confident grotesque. Numbers use
///   tabular figures so stats and ledgers align like a fleet/finance readout.
/// - **Body & labels:** Manrope — clean, legible, a touch of character.
/// - **Eyebrow:** uppercase, wide-tracked Manrope — the "manifest label" motif.
class AppType {
  AppType._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Big confident headings (screen titles, hero text).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
    double height = 1.05,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Tabular numerals for stats, money and counts.
  static TextStyle number(
    double size, {
    FontWeight weight = FontWeight.w800,
    Color? color,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: _tabular,
      );

  /// Body / general text.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Uppercase, wide-tracked label (section eyebrows, manifest tags).
  static TextStyle eyebrow({
    double size = 11,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 2.0,
      );
}
