/// Status saklar perangkat (LED) dari `GET /device`.
class DeviceStatus {
  const DeviceStatus({
    required this.id,
    required this.deviceId,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String deviceId;
  final int status;
  final DateTime createdAt;

  bool get menyala => status == 1;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
