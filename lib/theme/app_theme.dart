import 'package:flutter/material.dart';

/// Palet warna dari design system "IoT Monitor" (dark tech + status green).
abstract final class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color backgroundAlt = Color(0xFF131C30);
  static const Color card = Color(0xFF1B2336);
  static const Color muted = Color(0xFF272F42);
  static const Color border = Color(0xFF475569);
  static const Color foreground = Color(0xFFF8FAFC);
  static const Color mutedForeground = Color(0xFF94A3B8);
  static const Color accent = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color destructive = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
}

/// Token tipografi dan jarak supaya konsisten antar komponen.
abstract final class AppText {
  static const String body = 'FiraSans';
  static const String mono = 'FiraCode';

  /// Angka besar pakai Fira Code agar terasa seperti panel telemetri.
  static const TextStyle angka = TextStyle(
    fontFamily: mono,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.foreground,
  );

  static const TextStyle angkaKecil = TextStyle(
    fontFamily: mono,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.foreground,
  );

  static const TextStyle label = TextStyle(
    fontFamily: body,
    fontSize: 11,
    height: 1.4,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
  );

  static const TextStyle monoKecil = TextStyle(
    fontFamily: mono,
    fontSize: 12,
    height: 1.4,
    color: AppColors.mutedForeground,
  );
}

/// Radius & jarak (ritme 4/8dp).
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 28;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusPill =
      BorderRadius.all(Radius.circular(999));
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Color(0xFF06210F),
    secondary: AppColors.info,
    onSecondary: Color(0xFF04202B),
    surface: AppColors.background,
    onSurface: AppColors.foreground,
    error: AppColors.destructive,
    onError: Colors.white,
    outline: AppColors.border,
    surfaceContainerHighest: AppColors.muted,
    onSurfaceVariant: AppColors.mutedForeground,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: AppText.body,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
      fontFamily: AppText.body,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppText.body,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.foreground),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.muted,
      contentTextStyle: TextStyle(color: AppColors.foreground),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(
          fontFamily: AppText.body,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(44, 44),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.foreground,
        minimumSize: const Size(44, 44),
      ),
    ),
  );
}
