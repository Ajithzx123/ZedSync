import 'package:flutter/material.dart';

class AppColors {
  static const profit = Color(0xFF16A34A);
  static const loss = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const neutral = Color(0xFF64748B);
  static const seed = Color(0xFF2563EB);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: b);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: const ChipThemeData(showCheckmark: false),
    );
  }
}
