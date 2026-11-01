import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // Brand Palette
  static const Color nav = Color(0xFF061A35);
  static const Color nav2 = Color(0xFF0A254A);
  static const Color navLight = Color(0xFF13386B);
  static const Color orange = Color(0xFFFF8A00);
  static const Color orangeHover = Color(0xFFE67A00);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color blue = Color(0xFF2F77FF);
  static const Color blueHover = Color(0xFF1E64E8);
  static const Color blueLight = Color(0xFFEEF5FF);
  static const Color bg = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF475569);
  static const Color muted = Color(0xFF64748B);
  static const Color line = Color(0xFFDFE7F2);
  static const Color lineLight = Color(0xFFEEF2F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF071A34);
  static const Color darkCard = Color(0xFF0B274D);
  static const Color darkCardHover = Color(0xFF0F3260);
  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFECFDF5);
  static const Color red = Color(0xFFEF4444);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);

  // Currency Formatter
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static String formatINR(double value, {bool removeDecimals = false}) {
    String formatted = _currencyFormatter.format(value);
    if (removeDecimals && formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    return formatted;
  }

  // Box Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(2, 17, 37, 0.05),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color.fromRGBO(2, 17, 37, 0.12),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> sidebarShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.35),
      blurRadius: 24,
      offset: Offset(-2, 8),
    ),
  ];

  // Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        secondary: orange,
        surface: surface,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFDFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD8E2EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD8E2EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: blue, width: 1.8),
        ),
        hoverColor: Colors.white,
        labelStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA0AEC0),
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
