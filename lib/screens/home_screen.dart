import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/device.dart';
import '../models/device_location.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_value.dart';
import '../widgets/neo_alert_dialog.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_chart.dart';
import '../widgets/neo_toast.dart';
import '../widgets/status_indicators.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final DateFormat _jam = DateFormat('HH:mm:ss');

  Timer? _timer;
  bool _autoRefresh = true;
  bool _memuat = true;
  String? _error;

  List<Device> _devices = const [];
  List<SensorReading> _readings = const [];
  List<DeviceStatus> _deviceStatuses = const [];
  DeviceLocation? _lokasi;
  DateTime? _terakhirUpdate;

  // Filter device terpilih (Pengayaan a)
  String? _selectedDeviceId;

  // Tampilkan grafik histori suhu (Pengayaan b)
  bool _tampilkanGrafik = true;

  // Tracking alert suhu panas agar tidak spam dialog (Pengayaan d)
  DateTime? _terakhirPeringatanPanas;

  @override
  void initState() {
    super.initState();
    _muat();
    _aturTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    super.dispose();
  }

  void _aturTimer() {
    _timer?.cancel();
    if (!_autoRefresh) return;
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) {
      _muat(silent: true);
    });
  }

  void _toggleAutoRefresh() {
    setState(() => _autoRefresh = !_autoRefresh);
    _aturTimer();
    if (_autoRefresh) {
      _muat(silent: true);
      showNeoToast(
        context,
        message: 'AUTO-REFRESH DIAKTIFKAN (5 DETIK)',
        icon: Icons.play_arrow_rounded,
        backgroundColor: NeoColors.lime,
      );
    } else {
      showNeoToast(
        context,
        message: 'AUTO-REFRESH DIJEDA',
        icon: Icons.pause_rounded,
        backgroundColor: NeoColors.yellow,
      );
    }
  }

  /// Menentukan pembacaan sensor terbaru untuk device tertentu
  /// (Persis sesuai fungsi `latestFor` pada Halaman 7 Labsheet 2).
  SensorReading? latestFor(String deviceId) {
    final items = _readings.where((e) => e.deviceId == deviceId).toList();
    if (items.isEmpty) return null;
    items.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      final timeOrder = ta == null && tb == null
          ? 0
          : ta == null
              ? -1
              : tb == null
                  ? 1
                  : ta.compareTo(tb);
      return timeOrder != 0 ? timeOrder : a.id.compareTo(b.id);
    });
    return items.last;
  }

  Future<void> _muat({bool silent = false}) async {
    if (!silent) setState(() => _memuat = true);

    try {
      // Mengambil data secara asinkron dengan Future.wait
      // (Persis sesuai Langkah 6 Halaman 6 Labsheet 2)
      final results = await Future.wait([
        _api.getDevices(),
        _api.getSensors(),
        _api.devices(),
        _api.locations(),
      ]);

      if (!mounted) return;

      final fetchedDevices = results[0] as List<Device>;
      final fetchedReadings = results[1] as List<SensorReading>;
      final fetchedStatuses = results[2] as List<DeviceStatus>;
      final fetchedLocations = results[3] as List<DeviceLocation>;

      setState(() {
        _devices = fetchedDevices;
        _readings = fetchedReadings;
        _deviceStatuses = fetchedStatuses;
        _lokasi = fetchedLocations.isEmpty ? null : fetchedLocations.first;
        _error = null;
        _terakhirUpdate = DateTime.now();
        _memuat = false;
      });

      // Pemeriksaan suhu panas untuk pop-up dialog (Tugas Pengayaan d)
      _cekPeringatanSuhuPanas();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal menghubungi backend: $e';
        _memuat = false;
      });
    }
  }

  void _cekPeringatanSuhuPanas() {
    if (_readings.isEmpty) return;
    final readingTerbaru = _readings.first;
    final suhu = readingTerbaru.temperature;
    if (suhu == null) return;

    // Jika suhu >= 30.0 derajat Celsius dan belum pernah muncul dalam 1 menit
    if (suhu >= 30.0) {
      final sekarang = DateTime.now();
      if (_terakhirPeringatanPanas == null ||
          sekarang.difference(_terakhirPeringatanPanas!) > const Duration(minutes: 1)) {
        _terakhirPeringatanPanas = sekarang;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showNeoHeatAlert(
              context,
              deviceId: readingTerbaru.deviceId,
              suhu: suhu,
            );
          }
        });
      }
    }
  }

  void _salinKoordinat(double? lat, double? lon) {
    if (lat == null || lon == null) return;
    final teks = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: teks));
    showNeoToast(
      context,
      message: 'KOORDINAT TERSALIN: $teks',
      icon: Icons.check_circle_rounded,
      backgroundColor: NeoColors.lime,
    );
  }

  LiveStatus get _statusData {
    if (!_autoRefresh) return LiveStatus.paused;
    if (_terakhirUpdate == null) return LiveStatus.waiting;

    final umur = DateTime.now().difference(_terakhirUpdate!);
    final batas = AppConfig.refreshInterval * 3;
    return umur <= batas ? LiveStatus.live : LiveStatus.stale;
  }

  /// Daftar device setelah difilter oleh dropdown (Pengayaan a)
  List<Device> get _filteredDevices {
    if (_selectedDeviceId == null || _selectedDeviceId!.isEmpty) {
      return _devices;
    }
    return _devices.where((d) => d.id == _selectedDeviceId).toList();
  }

  /// Mengambil riwayat suhu untuk grafik (Pengayaan b)
  List<double> get _suhuHistory {
    final list = _readings
        .where((r) => r.temperature != null)
        .take(12)
        .map((r) => r.temperature!)
        .toList();
    return list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sensor reading paling representatif
    final readingUtama = _readings.isNotEmpty ? _readings.first : null;

    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: NeoColors.ink,
          backgroundColor: NeoColors.yellow,
          strokeWidth: 2.8,
          onRefresh: () => _muat(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
            children: [
              _Header(
                status: _statusData,
                autoRefresh: _autoRefresh,
                memuat: _memuat,
                onToggleAuto: _toggleAutoRefresh,
                onRefresh: () => _muat(),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                _KartuError(
                  pesan: _error!,
                  onRetry: () => _muat(),
                ),
                const SizedBox(height: 10),
              ],
              if (_memuat && _readings.isEmpty && _devices.isEmpty)
                const _KartuMemuat()
              else ...[
                _KartuSensorUtama(
                  reading: readingUtama,
                  terakhirUpdate: _terakhirUpdate,
                  jam: _jam,
                ),
                const SizedBox(height: 10),
                _KartuLokasi(
                  lokasi: _lokasi,
                  sensor: readingUtama,
                  onSalin: _salinKoordinat,
                ),
                const SizedBox(height: 12),
                // Tugas Pengayaan b: Grafik Histori Suhu
                _KartuGrafikHistori(
                  suhuList: _suhuHistory,
                  terbuka: _tampilkanGrafik,
                  onToggle: () => setState(() => _tampilkanGrafik = !_tampilkanGrafik),
                ),
              ],
              const SizedBox(height: 16),
              // Tugas Pengayaan a: Dropdown Pemilihan Device
              _HeaderPerangkatDenganFilter(
                devices: _devices,
                selectedId: _selectedDeviceId,
                onChanged: (id) => setState(() => _selectedDeviceId = id),
                jumlah: _filteredDevices.length,
              ),
              const SizedBox(height: 8),
              _DaftarKartuPerangkat(
                devices: _filteredDevices,
                latestFor: latestFor,
                deviceStatuses: _deviceStatuses,
                jam: _jam,
              ),
              const SizedBox(height: 20),
              _FooterServer(
                url: AppConfig.apiBaseUrl,
                terhubung: _error == null && _readings.isNotEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.autoRefresh,
    required this.memuat,
    required this.onToggleAuto,
    required this.onRefresh,
  });

  final LiveStatus status;
  final bool autoRefresh;
  final bool memuat;
  final VoidCallback onToggleAuto;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.rotate(
                    angle: -0.04,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoColors.yellow,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: NeoColors.ink, width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: NeoColors.ink,
                            offset: Offset(2.2, 2.2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'ESP32 TELEMETRY',
                        style: TextStyle(
                          fontFamily: NeoText.display,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: NeoColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'IoT Monitor',
                    style: NeoText.hero,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            LiveBadge(status: status),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            NeoButton(
              onPressed: onToggleAuto,
              backgroundColor: autoRefresh ? NeoColors.card : NeoColors.muted,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    autoRefresh
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(autoRefresh ? 'JEDA' : 'LANJUT'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            NeoButton(
              onPressed: memuat ? null : onRefresh,
              backgroundColor: NeoColors.cyan,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(memuat ? 'MEMUAT...' : 'MUAT ULANG'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KartuSensorUtama extends StatelessWidget {
  const _KartuSensorUtama({
    required this.reading,
    required this.terakhirUpdate,
    required this.jam,
  });

  final SensorReading? reading;
  final DateTime? terakhirUpdate;
  final DateFormat jam;

  @override
  Widget build(BuildContext context) {
    final suhu = reading?.temperature;
    final kelembapan = reading?.humidity;

    return NeoCard(
      backgroundColor: NeoColors.card,
      shadowOffset: 4.5,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NeoColors.ink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SUHU RUANGAN',
                  style: TextStyle(
                    fontFamily: NeoText.display,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NeoColors.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: NeoColors.ink, width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.ink,
                      offset: Offset(2.0, 2.0),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.thermostat_rounded,
                  size: 18,
                  color: NeoColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MetricValue(
            nilai: suhu == null ? '--' : suhu.toStringAsFixed(1),
            satuan: '°C',
            semantik: suhu == null
                ? 'Suhu belum tersedia'
                : 'Suhu ${suhu.toStringAsFixed(1)} derajat Celsius',
          ),
          const SizedBox(height: 8),
          _MeterLevelSuhu(suhu: suhu),
          const SizedBox(height: 10),
          Container(
            height: 2.2,
            color: NeoColors.ink,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFFAFE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.ink, width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.ink,
                        offset: Offset(2.0, 2.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water_drop_rounded, size: 15, color: NeoColors.ink),
                          SizedBox(width: 4),
                          Text('LEMBAP', style: NeoText.label),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        kelembapan == null ? '-- %' : '${kelembapan.toStringAsFixed(0)} %',
                        style: NeoText.angkaSedang,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _kategoriKelembapan(kelembapan),
                        style: const TextStyle(
                          fontFamily: NeoText.display,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: NeoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.ink, width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoColors.ink,
                        offset: Offset(2.0, 2.0),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 15, color: NeoColors.ink),
                          SizedBox(width: 4),
                          Text('UPDATE', style: NeoText.label),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        terakhirUpdate == null ? '--:--:--' : jam.format(terakhirUpdate!),
                        style: NeoText.angkaSedang,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'INTERVAL 5S',
                        style: TextStyle(
                          fontFamily: NeoText.display,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: NeoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.memory_rounded, size: 13, color: NeoColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'DHT22 • PIN GPIO 4 • DEVICE: ${reading?.deviceId ?? "ESP32"}',
                style: const TextStyle(
                  fontFamily: NeoText.mono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _kategoriKelembapan(double? val) {
    if (val == null) return '--';
    if (val < 40) return 'KERING';
    if (val <= 65) return 'OPTIMAL';
    return 'LEMBAP TINGGI';
  }
}

class _MeterLevelSuhu extends StatelessWidget {
  const _MeterLevelSuhu({required this.suhu});

  final double? suhu;

  @override
  Widget build(BuildContext context) {
    final s = suhu ?? 25.0;
    final int level;
    if (s < 22) {
      level = 0;
    } else if (s <= 27) {
      level = 1;
    } else if (s <= 32) {
      level = 2;
    } else {
      level = 3;
    }

    final segments = [
      ('SEJUK', const Color(0xFFBAE6FD)),
      ('NYAMAN', const Color(0xFFBBF7D0)),
      ('HANGAT', const Color(0xFFFEF08A)),
      ('PANAS', const Color(0xFFFECACA)),
    ];

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          Expanded(
            child: Container(
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (i == level) ? segments[i].$2 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: NeoColors.ink,
                  width: (i == level) ? 2.2 : 1.5,
                ),
                boxShadow: (i == level)
                    ? const [
                        BoxShadow(
                          color: NeoColors.ink,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                segments[i].$1,
                style: TextStyle(
                  fontFamily: NeoText.display,
                  fontSize: 10,
                  fontWeight: (i == level) ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
                  color: (i == level) ? NeoColors.ink : NeoColors.textMuted,
                ),
              ),
            ),
          ),
          if (i < segments.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({
    required this.lokasi,
    required this.sensor,
    required this.onSalin,
  });

  final DeviceLocation? lokasi;
  final SensorReading? sensor;
  final void Function(double? lat, double? lon) onSalin;

  @override
  Widget build(BuildContext context) {
    final nama = lokasi?.lokasi ?? sensor?.lokasi ?? 'UIN Prof. K.H. Saifuddin Zuhri Purbalingga';
    final lat = lokasi?.latitude ?? sensor?.latitude ?? -7.388784;
    final lon = lokasi?.longitude ?? sensor?.longitude ?? 109.347833;

    return NeoCard(
      backgroundColor: NeoColors.yellowPastel,
      shadowOffset: 3.5,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => onSalin(lat, lon),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NeoColors.yellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.ink, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.ink,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded, color: NeoColors.ink, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: NeoColors.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'KAMPUS 2',
                        style: TextStyle(
                          fontFamily: NeoText.display,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ketuk untuk salin',
                      style: TextStyle(
                        fontFamily: NeoText.mono,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: NeoText.display,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: NeoColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoColors.ink, width: 1.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontFamily: NeoText.mono,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.copy_rounded, size: 13, color: NeoColors.ink),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tugas Pengayaan b: Grafik Histori Suhu
class _KartuGrafikHistori extends StatelessWidget {
  const _KartuGrafikHistori({
    required this.suhuList,
    required this.terbuka,
    required this.onToggle,
  });

  final List<double> suhuList;
  final bool terbuka;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      backgroundColor: Colors.white,
      shadowOffset: 3.5,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: NeoColors.yellow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoColors.ink, width: 1.8),
                  ),
                  child: const Icon(Icons.show_chart_rounded, size: 18, color: NeoColors.ink),
                ),
                const SizedBox(width: 10),
                const Text(
                  'GRAFIK HISTORI SUHU',
                  style: TextStyle(
                    fontFamily: NeoText.display,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: NeoColors.ink,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: NeoColors.muted,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: NeoColors.ink, width: 1.2),
                  ),
                  child: Text(
                    terbuka ? 'SEMBUNYIKAN' : 'TAMPILKAN',
                    style: const TextStyle(
                      fontFamily: NeoText.display,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (terbuka) ...[
            const SizedBox(height: 12),
            NeoChart(values: suhuList, height: 90),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('← Terdahulu', style: NeoText.monoKecil),
                Text('Terbaru →', style: NeoText.monoKecil),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tugas Pengayaan a: Dropdown Filter Device
class _HeaderPerangkatDenganFilter extends StatelessWidget {
  const _HeaderPerangkatDenganFilter({
    required this.devices,
    required this.selectedId,
    required this.onChanged,
    required this.jumlah,
  });

  final List<Device> devices;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DAFTAR PERANGKAT',
              style: NeoText.sectionTitle,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: NeoColors.ink, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: NeoColors.ink,
                    offset: Offset(1.8, 1.8),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                '$jumlah DEVICE',
                style: const TextStyle(
                  fontFamily: NeoText.display,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: NeoColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Dropdown filter box bergaya Neobrutalism
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NeoColors.ink, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: NeoColors.ink,
                offset: Offset(2.0, 2.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedId,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: NeoColors.ink, size: 26),
              style: const TextStyle(
                fontFamily: NeoText.display,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: NeoColors.ink,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('• SEMUA PERANGKAT (TAMPILKAN SEMUA)'),
                ),
                for (final d in devices)
                  DropdownMenuItem<String?>(
                    value: d.id,
                    child: Text('• ${d.name} (${d.id})'),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Daftar kartu perangkat (Sesuai Halaman 8 Labsheet 2)
class _DaftarKartuPerangkat extends StatelessWidget {
  const _DaftarKartuPerangkat({
    required this.devices,
    required this.latestFor,
    required this.deviceStatuses,
    required this.jam,
  });

  final List<Device> devices;
  final SensorReading? Function(String) latestFor;
  final List<DeviceStatus> deviceStatuses;
  final DateFormat jam;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return NeoCard(
        backgroundColor: Colors.white,
        child: const Text(
          'Belum ada perangkat terdaftar di backend.',
          style: TextStyle(
            fontFamily: NeoText.body,
            fontWeight: FontWeight.w600,
            color: NeoColors.textMuted,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final device in devices) ...[
          _KartuDeviceLabsheet(
            key: ValueKey(device.id),
            device: device,
            latest: latestFor(device.id),
            deviceStatuses: deviceStatuses,
            jam: jam,
          ),
          if (device != devices.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Kartu Device individual persis seperti kode Langkah 6 Halaman 8 Labsheet 2,
/// namun diperkaya dengan visual Neobrutalism.
class _KartuDeviceLabsheet extends StatelessWidget {
  const _KartuDeviceLabsheet({
    super.key,
    required this.device,
    required this.latest,
    required this.deviceStatuses,
    required this.jam,
  });

  final Device device;
  final SensorReading? latest;
  final List<DeviceStatus> deviceStatuses;
  final DateFormat jam;

  bool? get _statusNyala {
    final cocok = deviceStatuses.where((s) => s.deviceId == device.id).toList();
    if (cocok.isEmpty) return null;
    return cocok.first.menyala;
  }

  @override
  Widget build(BuildContext context) {
    final temp = latest?.temperature;
    final hum = latest?.humidity;
    final nyala = _statusNyala;

    return NeoCard(
      backgroundColor: (nyala == true) ? const Color(0xFFFEFCE8) : NeoColors.card,
      shadowOffset: 3.5,
      padding: const EdgeInsets.all(14),
      onTap: () {
        HapticFeedback.lightImpact();
        showNeoToast(
          context,
          message: '${device.name} • Temp: ${temp?.toStringAsFixed(1) ?? "-"}°C',
          icon: Icons.info_outline_rounded,
          backgroundColor: NeoColors.yellow,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (nyala == true) ? NeoColors.yellow : NeoColors.muted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.ink, width: 2.0),
                ),
                child: Icon(
                  (nyala == true)
                      ? Icons.lightbulb_rounded
                      : Icons.devices_other_rounded,
                  size: 20,
                  color: NeoColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontFamily: NeoText.display,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.ink,
                      ),
                    ),
                    Text(
                      'Device: ${device.id}',
                      style: NeoText.monoKecil,
                    ),
                  ],
                ),
              ),
              if (nyala != null) ...[
                const SizedBox(width: 6),
                StatusPill(menyala: nyala),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: NeoColors.ink, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 14, color: NeoColors.ink),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Lokasi: ${device.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: NeoText.body,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFFAFE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoColors.ink, width: 1.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TEMPERATURE', style: NeoText.label),
                      const SizedBox(height: 2),
                      Text(
                        temp == null ? 'No data' : '${temp.toStringAsFixed(1)} °C',
                        style: const TextStyle(
                          fontFamily: NeoText.mono,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NeoColors.ink, width: 1.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HUMIDITY', style: NeoText.label),
                      const SizedBox(height: 2),
                      Text(
                        hum == null ? 'No data' : '${hum.toStringAsFixed(1)} %',
                        style: const TextStyle(
                          fontFamily: NeoText.mono,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last update: ${latest?.createdAt?.toLocal().toString() ?? "-"}',
            style: const TextStyle(
              fontFamily: NeoText.mono,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: NeoColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterServer extends StatelessWidget {
  const _FooterServer({required this.url, required this.terhubung});

  final String url;
  final bool terhubung;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NeoColors.ink, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(2.0, 2.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: terhubung ? NeoColors.lime : NeoColors.coral,
                shape: BoxShape.circle,
                border: Border.all(color: NeoColors.ink, width: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FASTAPI • $url',
              style: const TextStyle(
                fontFamily: NeoText.mono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: NeoColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuMemuat extends StatelessWidget {
  const _KartuMemuat();

  @override
  Widget build(BuildContext context) {
    return const NeoCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: NeoColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuError extends StatelessWidget {
  const _KartuError({required this.pesan, required this.onRetry});

  final String pesan;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      backgroundColor: const Color(0xFFFEE2E2),
      borderColor: NeoColors.ink,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NeoColors.coral,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.ink, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.ink,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GAGAL MENGHUBUNGI SERVER',
                  style: TextStyle(
                    fontFamily: NeoText.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: NeoColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: NeoText.body,
                    fontSize: 12,
                    color: NeoColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                NeoButton(
                  onPressed: onRetry,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: const Text('COBA LAGI'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
