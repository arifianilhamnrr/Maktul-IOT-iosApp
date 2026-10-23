/// Lokasi perangkat dari `GET /lokasi`.
class DeviceLocation {
  const DeviceLocation({
    required this.deviceId,
    this.lokasi,
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  final String deviceId;
  final String? lokasi;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  factory DeviceLocation.fromJson(Map<String, dynamic> json) {
    final updated = json['updated_at'] as String?;
    return DeviceLocation(
      deviceId: json['device_id'] as String,
      lokasi: json['lokasi'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: updated == null ? null : DateTime.parse(updated).toLocal(),
    );
  }
}
