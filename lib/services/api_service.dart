import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/device.dart';
import '../models/device_location.dart';
import '../models/device_status.dart';
import '../models/sensor_reading.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.body]);

  final String message;
  final String? body;

  @override
  String toString() => body == null ? message : '$message ($body)';
}

/// Klien HTTP untuk backend FastAPI (sesuai kontrak Labsheet 2).
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const Duration _timeout = Duration(seconds: 8);

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  /// Helper untuk mengambil list data (format JSON Array resmi Labsheet 2)
  Future<List<dynamic>> _getList(String path, [Map<String, String>? query]) async {
    final response = await _client.get(_uri(path, query)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw ApiException('HTTP ${response.statusCode}: $path', response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
    throw const FormatException('Expected JSON list');
  }

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    final response = await _client.get(_uri(path, query)).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}: $path', response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  /// Kontrak resmi Labsheet 2: GET /api/device
  Future<List<Device>> getDevices() async {
    try {
      final list = await _getList('/api/device');
      return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback ke endpoint legacy jika ada
      final list = await _getList('/device');
      return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  /// Kontrak resmi Labsheet 2: GET /api/sensor
  Future<List<SensorReading>> getSensors() async {
    try {
      final list = await _getList('/api/sensor');
      return list.map((e) => SensorReading.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback ke endpoint legacy
      final list = await _getList('/sensor');
      return list.map((e) => SensorReading.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<bool> health() async {
    try {
      final json = await _getJson('/health');
      return json['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Bacaan sensor terakhir
  Future<SensorReading?> latestSensor() async {
    try {
      final sensors = await getSensors();
      if (sensors.isNotEmpty) return sensors.first;
    } catch (_) {}
    try {
      final json = await _getJson('/sensor/latest');
      if (json['id'] == null) return null;
      return SensorReading.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Riwayat bacaan, terbaru lebih dulu
  Future<List<SensorReading>> sensorHistory({int limit = 20}) async {
    return getSensors();
  }

  /// Status lampu perangkat (LED / Relay)
  Future<List<DeviceStatus>> devices() async {
    final json = await _getJson('/device');
    final data = (json['data'] as List?) ?? (json is List ? json as List : const []);
    return data
        .cast<Map<String, dynamic>>()
        .map(DeviceStatus.fromJson)
        .toList();
  }

  /// Lokasi perangkat
  Future<List<DeviceLocation>> locations() async {
    final json = await _getJson('/lokasi');
    final data = (json['data'] as List?) ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(DeviceLocation.fromJson)
        .toList();
  }

  void dispose() => _client.close();
}
