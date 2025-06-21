import 'dart:async';
import 'dart:typed_data';
import 'ble_transport_interface.dart';

/// Mock implementation of BLE transport for testing
/// Simulates BLE operations without requiring actual hardware
class MockBleTransport implements BleTransportInterface {
  final Map<String, BleConnectionState> _connectionStates = {};
  final Map<String, StreamController<BleConnectionState>> _connectionControllers = {};
  final Map<String, StreamController<Uint8List>> _notificationControllers = {};
  
  // Mock device data
  final List<BleDevice> _mockDevices = [
    const BleDevice(
      id: 'mock-device-1',
      name: 'Living Room Lamp',
      localName: 'Zuli Smart Plug',
      rssi: -45,
      serviceData: {},
    ),
    const BleDevice(
      id: 'mock-device-2',
      name: 'Kitchen Coffee Maker',
      localName: 'Zuli Smart Plug',
      rssi: -52,
      serviceData: {},
    ),
  ];

  @override
  Future<bool> isBluetoothAvailable() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Stream<BleDevice> startScan({
    Duration? timeout,
    List<String>? serviceUuids,
  }) {
    final controller = StreamController<BleDevice>();
    
    // Simulate device discovery
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      for (final device in _mockDevices) {
        controller.add(device);
      }
      
      // Stop after timeout or after a few discoveries
      if (timeout != null) {
        timer.cancel();
        controller.close();
      }
    });
    
    // Auto-close after timeout
    if (timeout != null) {
      Timer(timeout, () {
        if (!controller.isClosed) {
          controller.close();
        }
      });
    }
    
    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    // No-op for mock
  }

  @override
  Future<void> connect(String deviceId) async {
    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    _connectionStates[deviceId] = BleConnectionState.connected;
    _getConnectionController(deviceId).add(BleConnectionState.connected);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    // Simulate disconnection delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _connectionStates[deviceId] = BleConnectionState.disconnected;
    _getConnectionController(deviceId).add(BleConnectionState.disconnected);
  }

  @override
  Stream<BleConnectionState> getConnectionState(String deviceId) {
    return _getConnectionController(deviceId).stream;
  }

  @override
  Future<Uint8List> sendPacket(String deviceId, Uint8List packet) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if device is connected
    if (_connectionStates[deviceId] != BleConnectionState.connected) {
      throw BleException(
        message: 'Device not connected',
        deviceId: deviceId,
        errorType: BleErrorType.connectionLost,
      );
    }
    
    // Simulate response based on command
    return _generateMockResponse(packet);
  }

  @override
  Stream<Uint8List> subscribeToNotifications(String deviceId) {
    final controller = _getNotificationController(deviceId);
    return controller.stream;
  }

  @override
  Future<void> unsubscribeFromNotifications(String deviceId) async {
    final controller = _notificationControllers[deviceId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  @override
  Future<bool> isConnected(String deviceId) async {
    return _connectionStates[deviceId] == BleConnectionState.connected;
  }

  @override
  Future<int> getRssi(String deviceId) async {
    // Return mock RSSI value
    return -50;
  }

  @override
  Future<void> discoverServices(String deviceId) async {
    // Simulate service discovery delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> dispose() async {
    // Close all controllers
    for (final controller in _connectionControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    for (final controller in _notificationControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }

  /// Generate mock response based on the command packet
  Uint8List _generateMockResponse(Uint8List packet) {
    final command = packet[0];
    
    switch (command) {
      case 23: // CMD_ON
        return Uint8List.fromList([23, 0]); // Success response
        
      case 24: // CMD_OFF
        return Uint8List.fromList([24, 0]); // Success response
        
      case 32: // CMD_POWER_READ
        // Mock power reading: 60W, 120V, 0.5A, power factor 0.95
        return Uint8List.fromList([
          32, 0, // Command and status
          500, 0, // 500mA current
          60, 0, 0, // 60W power (little endian)
          95, 0, // Power factor 95%
          120, 0, 0, // 120V voltage (little endian)
        ]);
        
      case 9: // CMD_CLOCK_GET
        final now = DateTime.now();
        return Uint8List.fromList([
          9, 0, // Command and status
          now.year & 0xFF, (now.year >> 8) & 0xFF, // Year
          now.month, now.day, // Month, day
          0, // Padding
          now.hour, now.minute, now.second, // Time
        ]);
        
      default:
        return Uint8List.fromList([command, 0]); // Generic success response
    }
  }

  /// Get or create connection state controller for a device
  StreamController<BleConnectionState> _getConnectionController(String deviceId) {
    if (!_connectionControllers.containsKey(deviceId)) {
      _connectionControllers[deviceId] = StreamController<BleConnectionState>.broadcast();
      // Initialize with disconnected state
      _connectionControllers[deviceId]!.add(BleConnectionState.disconnected);
    }
    return _connectionControllers[deviceId]!;
  }

  /// Get or create notification controller for a device
  StreamController<Uint8List> _getNotificationController(String deviceId) {
    if (!_notificationControllers.containsKey(deviceId)) {
      _notificationControllers[deviceId] = StreamController<Uint8List>.broadcast();
    }
    return _notificationControllers[deviceId]!;
  }
} 