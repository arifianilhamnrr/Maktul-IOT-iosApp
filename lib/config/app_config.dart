import 'package:flutter/foundation.dart';

/// Konfigurasi alamat backend.
///
/// Default menyesuaikan platform:
///   - Android emulator : 10.0.2.2 (alias ke localhost laptop)
///   - iOS simulator    : 127.0.0.1
///   - Web / desktop    : 127.0.0.1
///
/// Untuk HP fisik, jalankan dengan IP LAN laptop:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
class AppConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  /// Interval refresh otomatis di halaman utama.
  static const Duration refreshInterval = Duration(seconds: 5);
}
