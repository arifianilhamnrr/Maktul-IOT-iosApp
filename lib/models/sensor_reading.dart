/// Model pembacaan sensor sesuai kontrak Labsheet 2 (`GET /api/sensor`).
class SensorReading {
  const SensorReading({
    required this.id,
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.createdAt,
    this.lokasi,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String deviceId;
  final double? temperature;
  final double? humidity;
  final DateTime? createdAt;
  final String? lokasi;
  final double? latitude;
  final double? longitude;

  /// Alias getter untuk kompatibilitas kode sebelumnya
  double? get suhu => temperature;
  double? get kelembapan => humidity;

  factory SensorReading.fromJson(Map<String, dynamic> j) {
    final tempVal = (j['temperature'] ?? j['suhu']) as num?;
    final humVal = (j['humidity'] ?? j['kelembapan']) as num?;
    final rawDate = (j['created_at'] ?? '').toString();

    return SensorReading(
      id: ((j['id'] as num?) ?? 0).toInt(),
      deviceId: (j['device_id'] ?? '').toString(),
      temperature: tempVal?.toDouble(),
      humidity: humVal?.toDouble(),
      createdAt: rawDate.isEmpty ? null : DateTime.tryParse(rawDate)?.toLocal(),
      lokasi: j['lokasi'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'created_at': createdAt?.toIso8601String(),
        'lokasi': lokasi,
        'latitude': latitude,
        'longitude': longitude,
      };
}
