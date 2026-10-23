# IoT Monitor — iOS Mobile App

Aplikasi monitoring IoT berbasis Flutter (khusus iOS) untuk memantau sensor DHT22 (suhu & kelembapan), status saklar perangkat (LED), dan lokasi perangkat secara real-time.

Dibangun dengan desain **Glassmorphism / Real-Time Operations** (tema gelap, kartu transparan berbayang, indikator status berdenyut, dan tipografi teknis Fira Code & Fira Sans).

---

## Fitur Utama

- **Suhu & Kelembapan Real-Time:** Menampilkan data sensor DHT22 secara langsung dengan animasi transisi angka halus.
- **Indikator Live:** Badge status otomatis mendeteksi apakah data masih segar (`LIVE`), tertunda (`TERTUNDA`), atau dijeda (`DIJEDA`).
- **Kontrol Auto-Refresh:** Tombol jeda/lanjut dan refresh manual dengan pull-to-refresh.
- **Informasi Lokasi:** Menampilkan nama lokasi dan koordinat latitude & longitude perangkat.
- **Status Perangkat (LED):** Menampilkan status saklar perangkat (`Menyala` / `Mati`) dengan visualisasi lampu.
- **Dukungan Aksesibilitas:** Mendukung Dynamic Type dan Reduced Motion (animasi otomatis mati jika sistem mengaktifkan reduced motion).
- **Offline Fonts:** Font Fira Sans dan Fira Code sudah di-bundle di dalam folder `assets/fonts/` (tidak butuh koneksi internet untuk memuat font).

---

## Konfigurasi Backend

Aplikasi mengambil data dari backend REST API (FastAPI). Secara default aplikasi mengarah ke `http://127.0.0.1:8000` saat dijalankan di simulator iOS.

Untuk mengubah URL server saat dijalankan di perangkat fisik atau server production, gunakan parameter `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=https://api-iot.domainkamu.com
```

Atau ubah default URL di `lib/config/app_config.dart`.

---

## Cara Menjalankan

### Persyaratan
- macOS dengan **Xcode** terpasang
- **Flutter SDK** (versi 3.24+ / 3.47+)
- CocoaPods (`pod --version`)

### Langkah-langkah

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Jalankan test unit:
   ```bash
   flutter test
   ```

3. Jalankan di iOS Simulator:
   ```bash
   flutter run
   ```

4. Build untuk simulator / release:
   ```bash
   # Debug Simulator
   flutter build ios --simulator --debug

   # Release (memerlukan sertifikat Apple Developer)
   flutter build ipa
   ```

---

## Struktur Folder

```text
lib/
├── config/
│   └── app_config.dart       # Konfigurasi URL backend & polling interval
├── models/
│   ├── device_location.dart  # Model data lokasi perangkat
│   ├── device_status.dart    # Model status saklar lampu
│   └── sensor_reading.dart   # Model bacaan sensor DHT22
├── screens/
│   └── home_screen.dart      # Halaman utama dashboard monitoring
├── services/
│   └── api_service.dart      # HTTP client untuk komunikasi ke FastAPI
├── theme/
│   └── app_theme.dart        # Palet warna dark tech & typography token
└── widgets/
    ├── app_background.dart   # Background gradien + radial glow effect
    ├── glass_card.dart       # Komponen kartu efek frosted glass
    ├── metric_value.dart     # Widget angka besar dengan transisi animasi
    └── status_indicators.dart# Badge LIVE berdenyut dan pill status LED
```

---

## Lisensi

Dibuat untuk tugas mata kuliah Internet of Things (IoT).
