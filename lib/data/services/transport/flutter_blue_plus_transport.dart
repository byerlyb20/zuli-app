import 'dart:async';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';
import 'ble_transport_interface.dart';

/// Real BLE transport implementation using flutter_blue_plus
class FlutterBluePlusTransport implements BleTransportInterface {
  final Map<String, Completer<Uint8List>> _pendingResponses = {};

  @override
  Future<bool> isBluetoothAvailable() async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        return false;
      }

      // Check if Bluetooth is on
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // TODO: Does turnOn() actually request permissions on Android? Needs implementation on iOS regardless
      // Request location permission (required for BLE scanning on Android)
      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<BleDevice> startScan({
    required Duration timeout,
    List<String>? serviceUuids,
  }) async* {
    try {
      // Convert service UUIDs to the format expected by flutter_blue_plus
      List<Guid>? guids;
      if (serviceUuids != null) {
        guids = serviceUuids.map((uuid) => Guid(uuid)).toList();
      }

      // iOS takes a while to init BLE...? idk but see this GitHub issue:
      // https://github.com/chipweinberger/flutter_blue_plus/issues/681
      await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

      // Start scanning
      Logger.root.info("Starting scan");
      if (guids != null) {
        await FlutterBluePlus.startScan(
          timeout: timeout,
          withServices: guids,
        );
      } else {
        await FlutterBluePlus.startScan(
          timeout: timeout,
        );
      }
      Logger.root.info("Scan started successfully");

      // Listen for scan results
      final scanStreamWithTimeout = FlutterBluePlus.scanResults.timeout(timeout, onTimeout: (sink) {
        sink.close();
      });
      Logger.root.info("Collecting scan results");
      await for (final scanResult in scanStreamWithTimeout) {
        for (final result in scanResult) {
          final device = BleDevice(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isNotEmpty 
                ? result.device.platformName 
                : result.device.remoteId.toString(),
            localName: result.advertisementData.advName,
            rssi: result.rssi,
            serviceData: _convertServiceData(result.advertisementData.serviceData),
          );
          yield device;
        }
      }
    } catch (e) {
      throw BleException(
        message: 'Failed to start scanning: $e',
        errorType: BleErrorType.unknown,
      );
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      throw BleException(
        message: 'Failed to stop scanning: $e',
        errorType: BleErrorType.unknown,
      );
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    try {
      // Find the device
      final device = _findDevice(deviceId);
      if (device == null) {
        throw BleException(
          message: 'Device not found',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 10));
      await device.discoverServices();

    } catch (e) {
      throw BleException(
        message: 'Failed to connect: $e',
        deviceId: deviceId,
        errorType: BleErrorType.connectionFailed,
      );
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    try {
      final device = _findDevice(deviceId);
      if (device != null) {
        await device.disconnect();
      }
    } catch (e) {
      throw BleException(
        message: 'Failed to disconnect: $e',
        deviceId: deviceId,
        errorType: BleErrorType.unknown,
      );
    }
  }

  @override
  Stream<BleConnectionState> getConnectionState(String deviceId) {
    final device = _findDevice(deviceId);
    if (device == null) {
      return Stream.value(BleConnectionState.disconnected);
    }

    return device.connectionState.map((state) {
      switch (state) {
        case BluetoothConnectionState.disconnected:
          return BleConnectionState.disconnected;
        case BluetoothConnectionState.connecting:
          return BleConnectionState.connecting;
        case BluetoothConnectionState.connected:
          return BleConnectionState.connected;
        case BluetoothConnectionState.disconnecting:
          return BleConnectionState.disconnecting;
      }
    });
  }

  @override
  Future<void> setCharacteristic(String deviceId, String serviceUuid, String characteristicUuid, Uint8List packet) async {
    try {
      final device = _findDevice(deviceId);
      if (device == null) {
        throw BleException(
          message: 'Device not connected',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      final characteristic = await _findCharacteristic(device, serviceUuid, characteristicUuid);

      // Write the packet
      await characteristic.write(packet);

    } catch (e) {
      if (e is TimeoutException) {
        throw BleException(
          message: 'Response timeout',
          deviceId: deviceId,
          errorType: BleErrorType.timeout,
        );
      }
      throw BleException(
        message: 'Failed to send packet: $e',
        deviceId: deviceId,
        errorType: BleErrorType.writeFailed,
      );
    }
  }

  @override
  Future<Uint8List> readCharacteristic(String deviceId, String serviceUuid, String characteristicUuid) async {
    try {
      final device = _findDevice(deviceId);
      if (device == null) {
        throw BleException(
          message: 'Device not connected',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      final characteristic = await _findCharacteristic(device, serviceUuid, characteristicUuid);
      return Uint8List.fromList(await characteristic.read());

    } catch (e) {
      if (e is TimeoutException) {
        throw BleException(
          message: 'Response timeout',
          deviceId: deviceId,
          errorType: BleErrorType.timeout,
        );
      }
      throw BleException(
        message: 'Failed to send packet: $e',
        deviceId: deviceId,
        errorType: BleErrorType.writeFailed,
      );
    }
  }

  @override
  Future<bool> isConnected(String deviceId) async {
    final device = _findDevice(deviceId);
    if (device == null) {
      return false;
    }

    try {
      final state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getRssi(String deviceId) async {
    try {
      final device = _findDevice(deviceId);
      if (device == null) {
        throw BleException(
          message: 'Device not connected',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      return await device.readRssi();
    } catch (e) {
      throw BleException(
        message: 'Failed to read RSSI: $e',
        deviceId: deviceId,
        errorType: BleErrorType.unknown,
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Disconnect all devices
    for (final device in FlutterBluePlus.connectedDevices) {
      await device.disconnect();
    }

    // Clear maps
    _pendingResponses.clear();
  }

  /// Helper method to find a device by ID
  BluetoothDevice? _findDevice(String deviceId) {
    // Try to find it in the system
    try {
      return BluetoothDevice.fromId(deviceId);
    } catch (e) {
      return null;
    }
  }

  Future<BluetoothCharacteristic> _findCharacteristic(BluetoothDevice device, String serviceUuid, String characteristicUuid) async {
    // There appears to be a bug in the characteristic caching so we must discover services every time :(
    final services = await device.discoverServices();
    final service = services.firstWhereOrNull(
      (service) => service.uuid.toString() == serviceUuid
    );
    final characteristic = service?.characteristics.firstWhereOrNull(
      (characteristic) => characteristic.uuid.toString() == characteristicUuid
    );
    if (characteristic == null) {
      throw BleException(
        message: 'Characteristic not found',
        deviceId: device.remoteId.toString(),
        errorType: BleErrorType.characteristicNotFound,
      );
    }
    return characteristic;
  }

  /// Helper method to convert service data format
  Map<String, List<String>> _convertServiceData(Map<Guid, List<int>> serviceData) {
    final converted = <String, List<String>>{};
    for (final entry in serviceData.entries) {
      converted[entry.key.toString()] = entry.value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();
    }
    return converted;
  }
} 