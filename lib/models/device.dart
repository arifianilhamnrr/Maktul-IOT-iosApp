/// Model perangkat sesuai kontrak Labsheet 2 (`GET /api/device`).
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.location,
    this.status = 'registered',
  });

  final String id;
  final String name;
  final String location;
  final String status;

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['device_id'].toString(),
        name: (j['name'] ?? j['device_id']).toString(),
        location: (j['location'] ?? '-').toString(),
        status: (j['status'] ?? 'registered').toString(),
      );

  Map<String, dynamic> toJson() => {
        'device_id': id,
        'name': name,
        'location': location,
        'status': status,
      };
}
