import 'package:flutter/material.dart';

/// Palet warna Neobrutalism (high-contrast, pop pastel accents, hard black borders).
abstract final class NeoColors {
  // Canvas dasar
  static const Color background = Color(0xFFF9F6EE); // retro warm cream
  static const Color backgroundAlt = Color(0xFFF0EAE1); // darker cream
  static const Color card = Color(0xFFFFFFFF); // crisp white
  static const Color ink = Color(0xFF121212); // stark brutalist black

  // Aksen Pop Art & Status
  static const Color lime = Color(0xFFA3E635); // neon lime (LIVE / optimal)
  static const Color yellow = Color(0xFFFFDE59); // vivid pop yellow (stickers / active)
  static const Color yellowPastel = Color(0xFFFEF08A); // soft yellow card background
  static const Color cyan = Color(0xFF7DD3FC); // pastel cyan (cool / water)
  static const Color lavender = Color(0xFFDDD6FE); // soft lavender violet (time / meta)
  static const Color coral = Color(0xFFFF6B6B); // hot coral (errors / high heat)
  static const Color orange = Color(0xFFFB923C); // warm orange (warm temps)
  static const Color muted = Color(0xFFE2E8F0); // off state gray
  static const Color textMuted = Color(0xFF555555); // secondary text
}

/// Token tipografi Neobrutalism (Space Grotesk + Fira Code).
abstract final class NeoText {
  static const String display = 'SpaceGrotesk';
  static const String mono = 'FiraCode';
  static const String body = 'FiraSans';

  /// Judul utama / Hero Display
  static const TextStyle hero = TextStyle(
    fontFamily: display,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
    color: NeoColors.ink,
  );

  /// Judul seksi
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: display,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: NeoColors.ink,
  );

  /// Angka besar telemetri (Fira Code)
  static const TextStyle angkaBesar = TextStyle(
    fontFamily: mono,
    fontSize: 46,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
    color: NeoColors.ink,
  );

  /// Angka sedang telemetri (Fira Code)
  static const TextStyle angkaSedang = TextStyle(
    fontFamily: mono,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    color: NeoColors.ink,
  );

  /// Label kategori sticker (UPPERCASE)
  static const TextStyle label = TextStyle(
    fontFamily: display,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: NeoColors.ink,
  );

  /// Label tombol / chip
  static const TextStyle button = TextStyle(
    fontFamily: display,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: NeoColors.ink,
  );

  /// Monospace kecil untuk hardware pin / URL
  static const TextStyle monoKecil = TextStyle(
    fontFamily: mono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: NeoColors.textMuted,
  );
}

/// Konfigurasi border & hard shadow Neobrutalism
abstract final class NeoBox {
  static const double borderWidth = 2.5;
  static const double shadowOffset = 4.0;
  static const double radiusVal = 14.0;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(radiusVal));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));

  static Border border({double width = borderWidth, Color color = NeoColors.ink}) {
    return Border.all(color: color, width: width);
  }

  static List<BoxShadow> shadow({
    double offset = shadowOffset,
    Color color = NeoColors.ink,
  }) {
    return [
      BoxShadow(
        color: color,
        offset: Offset(offset, offset),
        blurRadius: 0, // Neobrutalism strictly uses 0 blur!
      ),
    ];
  }
}

ThemeData buildNeoTheme() {
  const scheme = ColorScheme.light(
    primary: NeoColors.ink,
    onPrimary: Colors.white,
    secondary: NeoColors.lime,
    onSecondary: NeoColors.ink,
    surface: NeoColors.background,
    onSurface: NeoColors.ink,
    error: NeoColors.coral,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: NeoColors.background,
    fontFamily: NeoText.body,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      color: NeoColors.ink,
      thickness: 2.5,
      space: 2.5,
    ),
  );
}
