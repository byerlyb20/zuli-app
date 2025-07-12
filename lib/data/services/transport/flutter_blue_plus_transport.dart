import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_transport_interface.dart';

/// Real BLE transport implementation using flutter_blue_plus
class FlutterBluePlusTransport implements BleTransportInterface {
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionSubscriptions = {};
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions = {};
  final Map<String, Completer<Uint8List>> _pendingResponses = {};

  @override
  Future<bool> isBluetoothAvailable() async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        return false;
      }

      // Check if Bluetooth is on
      return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // Request location permission (required for BLE scanning on Android)
      await FlutterBluePlus.turnOn();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<BleDevice> startScan({
    Duration? timeout,
    List<String>? serviceUuids,
  }) async* {
    try {
      // Convert service UUIDs to the format expected by flutter_blue_plus
      List<Guid>? guids;
      if (serviceUuids != null) {
        guids = serviceUuids.map((uuid) => Guid(uuid)).toList();
      }

      // Start scanning
      if (guids != null) {
        await FlutterBluePlus.startScan(
          timeout: timeout ?? const Duration(seconds: 10),
          withServices: guids,
        );
      } else {
        await FlutterBluePlus.startScan(
          timeout: timeout ?? const Duration(seconds: 10),
        );
      }

      // Listen for scan results
      await for (final scanResult in FlutterBluePlus.scanResults) {
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
      final device = await _findDevice(deviceId);
      if (device == null) {
        throw BleException(
          message: 'Device not found',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevices[deviceId] = device;

      // Listen for connection state changes
      _connectionSubscriptions[deviceId] = device.connectionState.listen((state) {
        // Handle connection state changes if needed
      });

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
      final device = _connectedDevices[deviceId];
      if (device != null) {
        await device.disconnect();
        _connectedDevices.remove(deviceId);
        _connectionSubscriptions[deviceId]?.cancel();
        _connectionSubscriptions.remove(deviceId);
        _notificationSubscriptions[deviceId]?.cancel();
        _notificationSubscriptions.remove(deviceId);
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
    final device = _connectedDevices[deviceId];
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
  Future<Uint8List> sendPacket(String deviceId, Uint8List packet) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw BleException(
          message: 'Device not connected',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      // Discover services if not already done
      await discoverServices(deviceId);

      // Find the appropriate service and characteristic
      // This is a generic implementation - you'll need to customize based on your device
      final services = await device.discoverServices();
      if (services.isEmpty) {
        throw BleException(
          message: 'No services found',
          deviceId: deviceId,
          errorType: BleErrorType.serviceNotFound,
        );
      }

      // Use the first service and characteristic for now
      // In a real implementation, you'd specify the exact service and characteristic UUIDs
      final service = services.first;
      final characteristic = service.characteristics.first;

      // Write the packet
      await characteristic.write(packet);

      // Wait for response if the characteristic supports notifications
      if (characteristic.properties.notify || characteristic.properties.indicate) {
        final completer = Completer<Uint8List>();
        _pendingResponses[deviceId] = completer;

        // Set up notification listener
        await characteristic.setNotifyValue(true);
        final subscription = characteristic.onValueReceived.listen((value) {
          final completer = _pendingResponses.remove(deviceId);
          if (completer != null && !completer.isCompleted) {
            completer.complete(Uint8List.fromList(value));
          }
        });

        // Wait for response with timeout
        try {
          final response = await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              _pendingResponses.remove(deviceId);
              throw TimeoutException('Response timeout', const Duration(seconds: 5));
            },
          );
          subscription.cancel();
          return response;
        } catch (e) {
          subscription.cancel();
          rethrow;
        }
      } else {
        // For write-only characteristics, return empty response
        return Uint8List(0);
      }

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
  Stream<Uint8List> subscribeToNotifications(String deviceId) {
    final device = _connectedDevices[deviceId];
    if (device == null) {
      throw BleException(
        message: 'Device not connected',
        deviceId: deviceId,
        errorType: BleErrorType.deviceNotFound,
      );
    }

    return Stream.fromFuture(discoverServices(deviceId)).asyncExpand((_) async* {
      final services = await device.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            await characteristic.setNotifyValue(true);
            yield* characteristic.onValueReceived.map((value) => Uint8List.fromList(value));
          }
        }
      }
    });
  }

  @override
  Future<void> unsubscribeFromNotifications(String deviceId) async {
    final subscription = _notificationSubscriptions[deviceId];
    if (subscription != null) {
      await subscription.cancel();
      _notificationSubscriptions.remove(deviceId);
    }
  }

  @override
  Future<bool> isConnected(String deviceId) async {
    final device = _connectedDevices[deviceId];
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
      final device = _connectedDevices[deviceId];
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
  Future<void> discoverServices(String deviceId) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw BleException(
          message: 'Device not connected',
          deviceId: deviceId,
          errorType: BleErrorType.deviceNotFound,
        );
      }

      await device.discoverServices();
    } catch (e) {
      throw BleException(
        message: 'Failed to discover services: $e',
        deviceId: deviceId,
        errorType: BleErrorType.serviceNotFound,
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Cancel all subscriptions
    for (final subscription in _connectionSubscriptions.values) {
      await subscription.cancel();
    }
    for (final subscription in _notificationSubscriptions.values) {
      await subscription.cancel();
    }

    // Disconnect all devices
    for (final deviceId in _connectedDevices.keys.toList()) {
      await disconnect(deviceId);
    }

    // Clear maps
    _connectedDevices.clear();
    _connectionSubscriptions.clear();
    _notificationSubscriptions.clear();
    _pendingResponses.clear();
  }

  /// Helper method to find a device by ID
  Future<BluetoothDevice?> _findDevice(String deviceId) async {
    // First check if we already have the device
    if (_connectedDevices.containsKey(deviceId)) {
      return _connectedDevices[deviceId];
    }

    // Try to find it in the system
    try {
      return BluetoothDevice.fromId(deviceId);
    } catch (e) {
      return null;
    }
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