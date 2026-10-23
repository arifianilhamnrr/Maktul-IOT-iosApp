import 'package:flutter_test/flutter_test.dart';
import 'package:iot_mobile/models/device.dart';
import 'package:iot_mobile/models/device_location.dart';
import 'package:iot_mobile/models/device_status.dart';
import 'package:iot_mobile/models/sensor_reading.dart';

void main() {
  group('Device (Labsheet 2)', () {
    test('membaca JSON perangkat dari /api/device', () {
      final device = Device.fromJson({
        'device_id': 'ESP32-001',
        'name': 'Smart Classroom',
        'location': 'Lab Komputer',
        'status': 'registered',
      });

      expect(device.id, 'ESP32-001');
      expect(device.name, 'Smart Classroom');
      expect(device.location, 'Lab Komputer');
      expect(device.status, 'registered');
    });

    test('menggunakan default jika field kosong', () {
      final device = Device.fromJson({
        'device_id': 'ESP32-002',
      });

      expect(device.id, 'ESP32-002');
      expect(device.name, 'ESP32-002');
      expect(device.location, '-');
      expect(device.status, 'registered');
    });
  });

  group('SensorReading', () {
    test('membaca JSON dari backend', () {
      final reading = SensorReading.fromJson({
        'id': 7,
        'device_id': 'esp32_lampu',
        'suhu': 27.4,
        'kelembapan': 61.8,
        'lokasi': 'UIN Prof. K.H. Saifuddin Zuhri Purbalingga',
        'latitude': -7.388784,
        'longitude': 109.347833,
        'created_at': '2026-10-23T03:28:24+00:00',
      });

      expect(reading.id, 7);
      expect(reading.deviceId, 'esp32_lampu');
      expect(reading.suhu, 27.4);
      expect(reading.temperature, 27.4);
      expect(reading.kelembapan, 61.8);
      expect(reading.humidity, 61.8);
      expect(reading.latitude, closeTo(-7.388784, 1e-9));
      expect(reading.createdAt?.toUtc(), DateTime.utc(2026, 10, 23, 3, 28, 24));
    });

    test('membaca format resmi Labsheet 2 (temperature & humidity)', () {
      final reading = SensorReading.fromJson({
        'id': 1,
        'device_id': 'ESP32-001',
        'temperature': 28.5,
        'humidity': 70.2,
        'created_at': '2026-10-23T03:30:00+00:00',
      });

      expect(reading.id, 1);
      expect(reading.deviceId, 'ESP32-001');
      expect(reading.temperature, 28.5);
      expect(reading.suhu, 28.5);
      expect(reading.humidity, 70.2);
      expect(reading.kelembapan, 70.2);
    });

    test('kelembapan boleh null', () {
      final reading = SensorReading.fromJson({
        'id': 1,
        'device_id': 'esp32_lampu',
        'suhu': 26,
        'created_at': '2026-10-23T03:28:24+00:00',
      });

      expect(reading.kelembapan, isNull);
    });
  });

  group('DeviceStatus', () {
    test('status 1 berarti menyala', () {
      final device = DeviceStatus.fromJson({
        'id': 2,
        'device_id': 'esp32_lampu',
        'status': 1,
        'created_at': '2026-10-23T03:33:21+00:00',
      });

      expect(device.menyala, isTrue);
    });

    test('status 0 berarti mati', () {
      final device = DeviceStatus.fromJson({
        'id': 3,
        'device_id': 'esp32_lampu_2',
        'status': 0,
        'created_at': '2026-10-23T03:33:21+00:00',
      });

      expect(device.menyala, isFalse);
    });
  });

  group('DeviceLocation', () {
    test('membaca koordinat', () {
      final loc = DeviceLocation.fromJson({
        'device_id': 'esp32_lampu',
        'lokasi': 'UIN Saizu',
        'latitude': -7.388784,
        'longitude': 109.347833,
        'updated_at': '2026-10-23T03:34:56+00:00',
      });

      expect(loc.lokasi, 'UIN Saizu');
      expect(loc.latitude, closeTo(-7.388784, 1e-9));
      expect(loc.longitude, closeTo(109.347833, 1e-9));
    });
  });
}
