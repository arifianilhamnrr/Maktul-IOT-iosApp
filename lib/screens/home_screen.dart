import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/device_location.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_value.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_card.dart';
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

  SensorReading? _sensor;
  List<DeviceStatus> _devices = const [];
  DeviceLocation? _lokasi;
  DateTime? _terakhirUpdate;

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

  Future<void> _muat({bool silent = false}) async {
    if (!silent) setState(() => _memuat = true);

    try {
      final sensor = await _api.latestSensor();
      final devices = await _api.devices();
      final lokasi = await _api.locations();

      if (!mounted) return;

      setState(() {
        _sensor = sensor;
        _devices = devices;
        _lokasi = lokasi.isEmpty ? null : lokasi.first;
        _error = null;
        _terakhirUpdate = DateTime.now();
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _memuat = false;
      });
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

  void _tampilInfoPerangkat(String nama, String pin, String stream, bool nyala) {
    showNeoToast(
      context,
      message: '$nama (${nyala ? 'MENYALA' : 'MATI'}) • $pin • $stream',
      icon: nyala ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
      backgroundColor: nyala ? NeoColors.yellow : NeoColors.muted,
    );
  }

  LiveStatus get _statusData {
    if (!_autoRefresh) return LiveStatus.paused;
    if (_terakhirUpdate == null) return LiveStatus.waiting;

    final umur = DateTime.now().difference(_terakhirUpdate!);
    final batas = AppConfig.refreshInterval * 3;
    return umur <= batas ? LiveStatus.live : LiveStatus.stale;
  }

  String _labelPerangkat(String deviceId) {
    switch (deviceId) {
      case 'esp32_lampu':
        return 'Lampu 1';
      case 'esp32_lampu_2':
        return 'Lampu 2';
      default:
        return deviceId;
    }
  }

  String _pinPerangkat(String deviceId) {
    switch (deviceId) {
      case 'esp32_lampu':
        return 'GPIO 18 • BLYNK V0';
      case 'esp32_lampu_2':
        return 'GPIO 19 • BLYNK V1';
      default:
        return 'GPIO -- • V--';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (_memuat && _sensor == null)
                const _KartuMemuat()
              else if (_sensor == null && _error == null)
                _KartuKosong(onRetry: () => _muat())
              else ...[
                _KartuSensorUtama(
                  sensor: _sensor,
                  terakhirUpdate: _terakhirUpdate,
                  jam: _jam,
                ),
                const SizedBox(height: 10),
                _KartuLokasi(
                  lokasi: _lokasi,
                  sensor: _sensor,
                  onSalin: _salinKoordinat,
                ),
              ],
              const SizedBox(height: 14),
              _JudulBagian(
                judul: 'STATUS PERANGKAT',
                jumlah: _devices.length,
              ),
              const SizedBox(height: 8),
              _DaftarPerangkat(
                devices: _devices,
                label: _labelPerangkat,
                pin: _pinPerangkat,
                onTapPerangkat: _tampilInfoPerangkat,
              ),
              const SizedBox(height: 20),
              _FooterServer(
                url: AppConfig.apiBaseUrl,
                terhubung: _error == null && _sensor != null,
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
                  // Stiker tilted fisik
                  Transform.rotate(
                    angle: -0.04, // -2.3 derajat miring khas sticker brutalism
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
    required this.sensor,
    required this.terakhirUpdate,
    required this.jam,
  });

  final SensorReading? sensor;
  final DateTime? terakhirUpdate;
  final DateFormat jam;

  @override
  Widget build(BuildContext context) {
    final suhu = sensor?.suhu;
    final kelembapan = sensor?.kelembapan;

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
          const SizedBox(height: 10),
          MetricValue(
            nilai: suhu == null ? '--' : suhu.toStringAsFixed(1),
            satuan: '°C',
            semantik: suhu == null
                ? 'Suhu belum tersedia'
                : 'Suhu ${suhu.toStringAsFixed(1)} derajat Celsius',
          ),
          const SizedBox(height: 8),
          // Indikator level suhu bersegmen brutalist
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
                    color: const Color(0xFFCFFAFE), // pastel cyan solid
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
                    color: const Color(0xFFEDE9FE), // pastel lavender solid
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
          const Row(
            children: [
              Icon(Icons.memory_rounded, size: 13, color: NeoColors.textMuted),
              SizedBox(width: 6),
              Text(
                'DHT22 • PIN GPIO 4 • ESP32 DOIT',
                style: TextStyle(
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

/// Meter 4 level suhu khas instrumen brutalist
class _MeterLevelSuhu extends StatelessWidget {
  const _MeterLevelSuhu({required this.suhu});

  final double? suhu;

  @override
  Widget build(BuildContext context) {
    final s = suhu ?? 25.0;
    final int level;
    if (s < 22) {
      level = 0; // Sejuk
    } else if (s <= 27) {
      level = 1; // Nyaman
    } else if (s <= 32) {
      level = 2; // Hangat
    } else {
      level = 3; // Panas
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

class _JudulBagian extends StatelessWidget {
  const _JudulBagian({required this.judul, required this.jumlah});

  final String judul;
  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          judul,
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
    );
  }
}

class _DaftarPerangkat extends StatelessWidget {
  const _DaftarPerangkat({
    required this.devices,
    required this.label,
    required this.pin,
    required this.onTapPerangkat,
  });

  final List<DeviceStatus> devices;
  final String Function(String) label;
  final String Function(String) pin;
  final void Function(String nama, String pin, String stream, bool nyala) onTapPerangkat;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return NeoCard(
        backgroundColor: Colors.white,
        child: const Text(
          'Belum ada status perangkat. Tekan saklar di aplikasi Blynk atau Wokwi.',
          style: TextStyle(
            fontFamily: NeoText.body,
            fontWeight: FontWeight.w600,
            color: NeoColors.textMuted,
          ),
        ),
      );
    }

    final urut = [...devices]..sort((a, b) => a.deviceId.compareTo(b.deviceId));

    return Column(
      children: [
        for (final device in urut) ...[
          _BarisPerangkat(
            key: ValueKey(device.deviceId),
            device: device,
            label: label(device.deviceId),
            pinInfo: pin(device.deviceId),
            onTap: () => onTapPerangkat(
              label(device.deviceId),
              pin(device.deviceId),
              device.deviceId,
              device.menyala,
            ),
          ),
          if (device != urut.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BarisPerangkat extends StatelessWidget {
  const _BarisPerangkat({
    super.key,
    required this.device,
    required this.label,
    required this.pinInfo,
    required this.onTap,
  });

  final DeviceStatus device;
  final String label;
  final String pinInfo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nyala = device.menyala;

    return NeoCard(
      backgroundColor: nyala ? const Color(0xFFFEFCE8) : NeoColors.card,
      shadowOffset: 3.0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: nyala ? NeoColors.yellow : NeoColors.muted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.ink, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.ink,
                  offset: Offset(1.8, 1.8),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              nyala ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
              size: 22,
              color: NeoColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: NeoText.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: NeoColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pinInfo,
                  style: NeoText.monoKecil,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(menyala: nyala),
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

class _KartuKosong extends StatelessWidget {
  const _KartuKosong({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NeoColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.ink, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.ink,
                  offset: Offset(2.5, 2.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              color: NeoColors.ink,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'BELUM ADA DATA SENSOR',
            style: TextStyle(
              fontFamily: NeoText.display,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: NeoColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jalankan simulator ESP32 (Wokwi) dan pastikan backend FastAPI menyala.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: NeoText.body,
              color: NeoColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          NeoButton(
            onPressed: onRetry,
            backgroundColor: NeoColors.lime,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 18),
                SizedBox(width: 6),
                Text('MUAT ULANG'),
              ],
            ),
          ),
        ],
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
