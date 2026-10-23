import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
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

/// Klien HTTP untuk backend FastAPI.
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

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    final response =
        await _client.get(_uri(path, query)).timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}', response.body);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> health() async {
    try {
      final json = await _getJson('/health');
      return json['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Bacaan sensor terakhir, atau `null` kalau belum ada data.
  Future<SensorReading?> latestSensor() async {
    final json = await _getJson('/sensor/latest');
    if (json['id'] == null) return null;
    return SensorReading.fromJson(json);
  }

  /// Riwayat bacaan, terbaru lebih dulu.
  Future<List<SensorReading>> sensorHistory({int limit = 20}) async {
    final json = await _getJson('/sensor', {'limit': '$limit'});
    final data = (json['data'] as List?) ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(SensorReading.fromJson)
        .toList();
  }

  /// Status terakhir setiap perangkat.
  Future<List<DeviceStatus>> devices() async {
    final json = await _getJson('/device');
    final data = (json['data'] as List?) ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(DeviceStatus.fromJson)
        .toList();
  }

  /// Lokasi perangkat.
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
