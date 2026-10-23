/// Satu bacaan sensor dari `GET /sensor`.
class SensorReading {
  const SensorReading({
    required this.id,
    required this.deviceId,
    required this.suhu,
    required this.createdAt,
    this.kelembapan,
    this.lokasi,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String deviceId;
  final double suhu;
  final double? kelembapan;
  final String? lokasi;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      suhu: (json['suhu'] as num).toDouble(),
      kelembapan: (json['kelembapan'] as num?)?.toDouble(),
      lokasi: json['lokasi'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
