import 'package:flutter_test/flutter_test.dart';
import 'package:iot_mobile/models/device_location.dart';
import 'package:iot_mobile/models/device_status.dart';
import 'package:iot_mobile/models/sensor_reading.dart';

void main() {
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
      expect(reading.kelembapan, 61.8);
      expect(reading.latitude, closeTo(-7.388784, 1e-9));
      expect(reading.createdAt.toUtc(), DateTime.utc(2026, 10, 23, 3, 28, 24));
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
      final lokasi = DeviceLocation.fromJson({
        'device_id': 'esp32_lampu',
        'lokasi': 'UIN Prof. K.H. Saifuddin Zuhri Purbalingga',
        'latitude': -7.388784,
        'longitude': 109.347833,
        'updated_at': '2026-10-23T03:33:21+00:00',
      });

      expect(lokasi.latitude, closeTo(-7.388784, 1e-9));
      expect(lokasi.longitude, closeTo(109.347833, 1e-9));
      expect(lokasi.updatedAt, isNotNull);
    });
  });
}
