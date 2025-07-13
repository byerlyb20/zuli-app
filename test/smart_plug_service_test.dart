import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:zuli_flutter_app/data/services/transport/mock_ble_transport.dart';
import 'package:zuli_flutter_app/data/services/smart_plug_service.dart';
import 'package:zuli_flutter_app/data/services/application/zuli_protocol.dart';

void main() {
  group('SmartPlugService Tests', () {
    late MockBleTransport mockTransport;
    late SmartPlugService service;

    setUp(() {
      mockTransport = MockBleTransport();
      service = SmartPlugService(mockTransport);
    });

    tearDown(() async {
      await mockTransport.dispose();
    });

    test('should initialize successfully', () async {
      await expectLater(service.initialize(), completes);
    });

    test('should scan for smart plugs', () async {
      await service.initialize();
      
      final devices = <String>[];
      await for (final device in service.scanForSmartPlugs(timeout: const Duration(seconds: 1))) {
        devices.add(device.id);
      }
      
      expect(devices, contains('mock-device-1'));
      expect(devices, contains('mock-device-2'));
    });

    test('should connect to smart plug', () async {
      await service.initialize();
      await expectLater(service.connectToSmartPlug('mock-device-1'), completes);
    });

    test('should turn on smart plug', () async {
      await service.initialize();
      await expectLater(service.turnOnSmartPlug('mock-device-1'), completes);
    });

    test('should turn off smart plug', () async {
      await service.initialize();
      await expectLater(service.turnOffSmartPlug('mock-device-1'), completes);
    });

    test('should read power consumption', () async {
      await service.initialize();
      
      final powerReading = await service.readSmartPlugPower('mock-device-1');
      
      expect(powerReading.powerWatts, 60.0);
      expect(powerReading.voltageVolts, 120.0);
      expect(powerReading.currentAmps, 0.5);
    });

    test('should get smart plug status', () async {
      await service.initialize();
      
      final status = await service.getSmartPlugStatus('mock-device-1');
      
      expect(status.deviceId, 'mock-device-1');
      expect(status.isOnline, true);
      expect(status.currentPowerUsage, 60.0);
    });
  });

  group('ZuliProtocol Tests', () {
    test('should generate ON command packet', () {
      final packet = ZuliProtocol.on(brightness: 50);
      expect(packet[0], ZuliProtocol.cmdOn);
      expect(packet[5], 50);
    });

    test('should generate OFF command packet', () {
      final packet = ZuliProtocol.off();
      expect(packet[0], ZuliProtocol.cmdOff);
    });

    test('should generate POWER_READ command packet', () {
      final packet = ZuliProtocol.readPower();
      expect(packet[0], ZuliProtocol.cmdPowerRead);
    });

    test('should parse power reading response', () {
      final response = Uint8List.fromList([
        32, 0, // Command and status
        500, 0, // 500mA current
        60, 0, 0, // 60W power (little endian)
        95, 0, // Power factor 95%
        120, 0, 0, // 120V voltage (little endian)
      ]);
      
      final powerReading = ZuliProtocol.parseReadPower(response);
      
      expect(powerReading.powerWatts, 60.0);
      expect(powerReading.voltageVolts, 120.0);
      expect(powerReading.currentAmps, 0.5);
      expect(powerReading.powerFactor, 95);
    });
  });
} 