import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../models/device_location.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_value.dart';
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
    if (_autoRefresh) _muat(silent: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () => _muat(silent: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _Header(
                    status: _statusData,
                    lokasi: _lokasi?.lokasi ?? _sensor?.lokasi,
                    autoRefresh: _autoRefresh,
                    memuat: _memuat,
                    onToggleAuto: _toggleAutoRefresh,
                    onRefresh: () => _muat(),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (_error != null) ...[
                    _KartuError(
                      pesan: _error!,
                      onRetry: () => _muat(),
                    ),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  if (_memuat && _sensor == null)
                    const _KartuMemuat()
                  else if (_sensor == null && _error == null)
                    _KartuKosong(onRetry: () => _muat())
                  else ...[
                    _KartuUtama(
                      sensor: _sensor,
                      terakhirUpdate: _terakhirUpdate,
                      jam: _jam,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _KartuLokasi(lokasi: _lokasi, sensor: _sensor),
                  ],
                  const SizedBox(height: AppSpace.section),
                  _JudulBagian(
                    judul: 'PERANGKAT',
                    keterangan: '${_devices.length} terdaftar',
                  ),
                  const SizedBox(height: AppSpace.md),
                  _DaftarPerangkat(
                    devices: _devices,
                    label: _labelPerangkat,
                  ),
                  const SizedBox(height: AppSpace.section),
                  Center(
                    child: Text(
                      'Sumber: FastAPI • ${AppConfig.apiBaseUrl}',
                      textAlign: TextAlign.center,
                      style: AppText.monoKecil.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.status,
    required this.lokasi,
    required this.autoRefresh,
    required this.memuat,
    required this.onToggleAuto,
    required this.onRefresh,
  });

  final LiveStatus status;
  final String? lokasi;
  final bool autoRefresh;
  final bool memuat;
  final VoidCallback onToggleAuto;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Text(
                    'IoT Monitor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lokasi ?? 'Menunggu lokasi perangkat',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            LiveBadge(status: status),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            _TombolPil(
              ikon: autoRefresh
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              label: autoRefresh ? 'Jeda' : 'Lanjut',
              onPressed: onToggleAuto,
            ),
            _TombolPil(
              ikon: Icons.refresh,
              label: 'Muat ulang',
              onPressed: memuat ? null : onRefresh,
            ),
          ],
        ),
      ],
    );
  }
}

class _TombolPil extends StatelessWidget {
  const _TombolPil({
    required this.ikon,
    required this.label,
    required this.onPressed,
  });

  final IconData ikon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(ikon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        disabledForegroundColor: AppColors.mutedForeground,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: AppText.body,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _KartuUtama extends StatelessWidget {
  const _KartuUtama({
    required this.sensor,
    required this.terakhirUpdate,
    required this.jam,
  });

  final SensorReading? sensor;
  final DateTime? terakhirUpdate;
  final DateFormat jam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suhu = sensor?.suhu;
    final kelembapan = sensor?.kelembapan;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SUHU RUANGAN', style: AppText.label),
              const Spacer(),
              const Icon(Icons.thermostat, size: 18, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          MetricValue(
            nilai: suhu == null ? '--' : suhu.toStringAsFixed(1),
            satuan: '°C',
            semantik: suhu == null
                ? 'Suhu belum tersedia'
                : 'Suhu ${suhu.toStringAsFixed(1)} derajat Celsius',
          ),
          const SizedBox(height: AppSpace.lg),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: AppSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatKecil(
                  ikon: Icons.water_drop_outlined,
                  judul: 'KELEMBAPAN',
                  nilai: kelembapan == null
                      ? '-- %'
                      : '${kelembapan.toStringAsFixed(0)} %',
                  semantik: kelembapan == null
                      ? 'Kelembapan belum tersedia'
                      : 'Kelembapan ${kelembapan.toStringAsFixed(0)} persen',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: _StatKecil(
                  ikon: Icons.schedule,
                  judul: 'DIPERBARUI',
                  nilai: terakhirUpdate == null
                      ? '--:--:--'
                      : jam.format(terakhirUpdate!),
                  semantik: terakhirUpdate == null
                      ? 'Belum pernah diperbarui'
                      : 'Terakhir diperbarui ${jam.format(terakhirUpdate!)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Data terakhir dari sensor DHT22',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatKecil extends StatelessWidget {
  const _StatKecil({
    required this.ikon,
    required this.judul,
    required this.nilai,
    required this.semantik,
  });

  final IconData ikon;
  final String judul;
  final String nilai;
  final String semantik;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantik,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 6),
              Flexible(child: Text(judul, style: AppText.label)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.angkaKecil,
          ),
        ],
      ),
    );
  }
}

class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({required this.lokasi, required this.sensor});

  final DeviceLocation? lokasi;
  final SensorReading? sensor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nama = lokasi?.lokasi ?? sensor?.lokasi ?? 'Lokasi belum diatur';
    final lat = lokasi?.latitude ?? sensor?.latitude;
    final lon = lokasi?.longitude ?? sensor?.longitude;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lat == null || lon == null
                      ? 'Koordinat belum tersedia'
                      : '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.monoKecil,
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
  const _JudulBagian({required this.judul, required this.keterangan});

  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(judul, style: AppText.label),
        const Spacer(),
        Text(keterangan, style: AppText.monoKecil.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _DaftarPerangkat extends StatelessWidget {
  const _DaftarPerangkat({required this.devices, required this.label});

  final List<DeviceStatus> devices;
  final String Function(String) label;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Text(
          'Belum ada status perangkat. Tekan saklar di aplikasi Blynk.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedForeground,
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
          ),
          if (device != urut.last) const SizedBox(height: AppSpace.sm),
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
  });

  final DeviceStatus device;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nyala = device.menyala;

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: nyala
                  ? AppColors.warning.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              nyala ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 22,
              color: nyala ? AppColors.warning : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.deviceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.monoKecil.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          StatusPill(menyala: nyala),
        ],
      ),
    );
  }
}

class _KartuMemuat extends StatelessWidget {
  const _KartuMemuat();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.section),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
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
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sensors_off,
              color: AppColors.mutedForeground,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Belum ada data sensor',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Jalankan ESP32 (atau Wokwi) dan pastikan backend FastAPI menyala.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Muat ulang'),
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
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: 'Terjadi kesalahan: $pesan',
      child: GlassCard(
        tint: AppColors.destructive,
        borderColor: AppColors.destructive.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.destructive, size: 20),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak bisa menghubungi backend',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesan,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
