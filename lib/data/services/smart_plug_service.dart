import 'dart:typed_data';
import 'transport/ble_transport_interface.dart';
import 'application/zuli_protocol.dart';

/// High-level service for smart plug operations
/// Orchestrates the Zuli protocol and BLE transport layers
class SmartPlugService {
  final BleTransportInterface _transport;

  SmartPlugService(this._transport);

  /// Initialize the service (check permissions, etc.)
  Future<void> initialize() async {
    final isAvailable = await _transport.isBluetoothAvailable();
    if (!isAvailable) {
      throw const BleException(
        message: 'Bluetooth is not available',
        errorType: BleErrorType.bluetoothNotAvailable,
      );
    }

    final hasPermissions = await _transport.requestPermissions();
    if (!hasPermissions) {
      throw const BleException(
        message: 'Bluetooth permissions denied',
        errorType: BleErrorType.permissionDenied,
      );
    }
  }

  /// Scan for Zuli smart plugs
  /// Returns a stream of discovered smart plug devices
  Stream<BleDevice> scanForSmartPlugs({Duration? timeout}) {
    return _transport.startScan(
      timeout: timeout ?? const Duration(seconds: 10),
      serviceUuids: [ZuliProtocol.advertisedZuliService],
    ).where((device) => _isZuliSmartPlug(device));
  }

  /// Check if a discovered device is a Zuli smart plug
  bool _isZuliSmartPlug(BleDevice device) {
    // Check if device name contains "Zuli" or has the Zuli service
    return device.name.contains('Zuli') || 
           device.localName?.contains('Zuli') == true ||
           device.serviceData.containsKey(ZuliProtocol.advertisedZuliService);
  }

  Future<void> _ensureConnected(String deviceId) async {
    if (!await _transport.isConnected(deviceId)) {
      await connectToSmartPlug(deviceId);
    }
  }

  /// Connect to a smart plug device
  Future<void> connectToSmartPlug(String deviceId) async {
    try {
      await _transport.connect(deviceId);
    } catch (e) {
      throw BleException(
        message: 'Failed to connect to smart plug: $e',
        deviceId: deviceId,
        errorType: BleErrorType.connectionFailed,
      );
    }
  }

  /// Disconnect from a smart plug device
  Future<void> disconnectFromSmartPlug(String deviceId) async {
    try {
      await _transport.disconnect(deviceId);
    } catch (e) {
      throw BleException(
        message: 'Failed to disconnect from smart plug: $e',
        deviceId: deviceId,
        errorType: BleErrorType.connectionLost,
      );
    }
  }

  /// Turn on a smart plug with optional brightness
  Future<void> turnOnSmartPlug(String deviceId, {int brightness = 100}) async {
    final packet = ZuliProtocol.on(brightness: brightness);
    await _sendCommand(deviceId, packet);
  }

  /// Turn off a smart plug
  Future<void> turnOffSmartPlug(String deviceId) async {
    final packet = ZuliProtocol.off();
    await _sendCommand(deviceId, packet);
  }

  /// Read power consumption from a smart plug
  Future<PowerReading> readSmartPlugPower(String deviceId) async {
    final packet = ZuliProtocol.readPower();
    final response = await _sendCommand(deviceId, packet);
    return ZuliProtocol.parseReadPower(response);
  }

  /// Set the mode of a smart plug (appliance vs dimmable)
  Future<void> setSmartPlugMode(String deviceId, {bool isAppliance = true}) async {
    final packet = ZuliProtocol.setMode(isAppliance: isAppliance);
    await _sendCommand(deviceId, packet);
  }

  /// Set the clock on a smart plug
  Future<void> setSmartPlugClock(String deviceId, DateTime time) async {
    final packet = ZuliProtocol.setClock(time);
    await _sendCommand(deviceId, packet);
  }

  /// Get the current time from a smart plug
  Future<DateTime> getSmartPlugClock(String deviceId) async {
    final packet = ZuliProtocol.getClock();
    final response = await _sendCommand(deviceId, packet);
    return ZuliProtocol.parseGetClock(response);
  }

  /// Read energy info from a smart plug
  Future<EnergyInfo> readSmartPlugEnergyInfo(String deviceId) async {
    final packet = ZuliProtocol.readEnergyInfo();
    final response = await _sendCommand(deviceId, packet);
    return ZuliProtocol.parseReadEnergyInfo(response);
  }

  /// Reset a smart plug
  Future<void> resetSmartPlug(String deviceId) async {
    final packet = ZuliProtocol.resetPlug();
    await _sendCommand(deviceId, packet);
  }

  /// Get comprehensive smart plug status
  /// This combines multiple operations to get a complete picture
  Future<SmartPlugStatus> getSmartPlugStatus(String deviceId) async {
    try {
      // Read power consumption
      final powerReading = await readSmartPlugPower(deviceId);
      
      // Get current time
      final currentTime = await getSmartPlugClock(deviceId);
      
      return SmartPlugStatus(
        deviceId: deviceId,
        powerReading: powerReading,
        lastSeen: currentTime,
        isOnline: true, // If we can read power, device is online
      );
    } catch (e) {
      return SmartPlugStatus(
        deviceId: deviceId,
        powerReading: null,
        lastSeen: DateTime.now(),
        isOnline: false,
        error: e.toString(),
      );
    }
  }

  /// Send a command packet and wait for response
  /// Handles error checking and response validation
  Future<Uint8List> _sendCommand(String deviceId, Uint8List packet) async {
    try {
      await _ensureConnected(deviceId);
      await _transport.setCharacteristic(
        deviceId,
        ZuliProtocol.zuliService,
        ZuliProtocol.commandPipeCharacteristic,
        packet,
      );
      final response = await _transport.readCharacteristic(
        deviceId,
        ZuliProtocol.zuliService,
        ZuliProtocol.commandPipeCharacteristic,
      );
      
      // Check response status
      final status = ZuliProtocol.parseResponseStatus(response);
      if (status != ZuliProtocol.statusSuccess) {
        throw BleException(
          message: 'Command failed with status: $status',
          deviceId: deviceId,
          errorType: BleErrorType.invalidResponse,
        );
      }
      
      return response;
    } catch (e) {
      if (e is BleException) {
        rethrow;
      }
      throw BleException(
        message: 'Failed to send command: $e',
        deviceId: deviceId,
        errorType: BleErrorType.writeFailed,
      );
    }
  }

  /// Check if a smart plug is connected
  Future<bool> isSmartPlugConnected(String deviceId) {
    return _transport.isConnected(deviceId);
  }

  /// Get connection state stream for a smart plug
  Stream<BleConnectionState> getSmartPlugConnectionState(String deviceId) {
    return _transport.getConnectionState(deviceId);
  }

  /// Get RSSI (signal strength) of a connected smart plug
  Future<int> getSmartPlugRssi(String deviceId) {
    return _transport.getRssi(deviceId);
  }

  /// Dispose of resources
  Future<void> dispose() {
    return _transport.dispose();
  }
}

/// Comprehensive status information for a smart plug
class SmartPlugStatus {
  final String deviceId;
  final PowerReading? powerReading;
  final DateTime lastSeen;
  final bool isOnline;
  final String? error;

  const SmartPlugStatus({
    required this.deviceId,
    this.powerReading,
    required this.lastSeen,
    required this.isOnline,
    this.error,
  });

  /// Get current power usage in watts
  double get currentPowerUsage => powerReading?.powerWatts ?? 0.0;

  /// Get current voltage in volts
  double get currentVoltage => powerReading?.voltageVolts ?? 0.0;

  /// Get current in amps
  double get currentAmps => powerReading?.currentAmps ?? 0.0;

  @override
  String toString() {
    return 'SmartPlugStatus(deviceId: $deviceId, '
           'isOnline: $isOnline, '
           'power: ${currentPowerUsage.toStringAsFixed(2)}W, '
           'lastSeen: $lastSeen)';
  }
} 