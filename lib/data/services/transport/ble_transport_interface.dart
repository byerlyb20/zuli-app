import 'dart:typed_data';

/// Represents a BLE device discovered during scanning
class BleDevice {
  final String id;
  final String name;
  final String? localName;
  final int rssi;
  final Map<String, List<String>> serviceData;

  const BleDevice({
    required this.id,
    required this.name,
    this.localName,
    required this.rssi,
    required this.serviceData,
  });

  @override
  String toString() {
    return 'BleDevice(id: $id, name: $name, rssi: $rssi)';
  }
}

/// Represents the state of a BLE connection
enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

/// Abstract interface for BLE transport operations
/// This allows the application layer to be plugin-agnostic
abstract class BleTransportInterface {
  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable();

  /// Request Bluetooth permissions (Android) or authorization (iOS)
  Future<bool> requestPermissions();

  /// Start scanning for BLE devices
  /// Returns a stream of discovered devices
  Stream<BleDevice> startScan({
    required Duration timeout,
    List<String>? serviceUuids,
  });

  /// Stop scanning for BLE devices
  Future<void> stopScan();

  /// Connect to a BLE device
  Future<void> connect(String deviceId);

  /// Disconnect from a BLE device
  Future<void> disconnect(String deviceId);

  /// Get the current connection state for a device
  Stream<BleConnectionState> getConnectionState(String deviceId);

  /// Send a packet to a connected device and wait for response
  /// Returns the response packet
  Future<void> sendPacket(String deviceId, String serviceUuid, String characteristicUuid, Uint8List packet);

  /// Subscribe to notifications from a device
  /// Returns a stream of received packets
  Stream<Uint8List> subscribeToNotifications(String deviceId);

  /// Unsubscribe from notifications
  Future<void> unsubscribeFromNotifications(String deviceId);

  /// Check if a device is currently connected
  Future<bool> isConnected(String deviceId);

  /// Get the RSSI (signal strength) of a connected device
  Future<int> getRssi(String deviceId);

  /// Dispose of resources
  Future<void> dispose();
}

/// Exception thrown when BLE operations fail
class BleException implements Exception {
  final String message;
  final String? deviceId;
  final BleErrorType errorType;

  const BleException({
    required this.message,
    this.deviceId,
    required this.errorType,
  });

  @override
  String toString() {
    return 'BleException($errorType): $message${deviceId != null ? ' (Device: $deviceId)' : ''}';
  }
}

/// Types of BLE errors
enum BleErrorType {
  bluetoothNotAvailable,
  permissionDenied,
  deviceNotFound,
  connectionFailed,
  connectionLost,
  timeout,
  invalidResponse,
  serviceNotFound,
  characteristicNotFound,
  writeFailed,
  readFailed,
  unknown,
} 