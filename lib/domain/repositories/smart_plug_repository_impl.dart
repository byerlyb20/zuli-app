import '../models/smart_plug.dart';
import 'smart_plug_repository.dart';
import '../../data/services/application/smart_plug_service.dart';
import '../../data/services/transport/ble_transport_interface.dart';

class SmartPlugRepositoryImpl implements SmartPlugRepository {
  final SmartPlugService _service;
  final Map<String, SmartPlug> _cachedPlugs = {};

  SmartPlugRepositoryImpl(BleTransportInterface transport)
      : _service = SmartPlugService(transport);

  @override
  Future<List<SmartPlug>> getSmartPlugs() async {
    try {
      // Initialize the service if needed
      await _service.initialize();
      
      // Scan for devices
      final devices = <SmartPlug>[];
      await for (final device in _service.scanForSmartPlugs()) {
        // Try to get status for each device
        final status = await _getDeviceStatus(device.id);
        if (status != null) {
          devices.add(status);
          _cachedPlugs[device.id] = status;
        }
      }
      
      return devices;
    } catch (e) {
      // Business logic: Return cached devices if available, even if scan fails
      if (_cachedPlugs.isNotEmpty) {
        return _cachedPlugs.values.toList();
      }
      rethrow;
    }
  }

  @override
  Future<void> togglePower(String plugId, bool newState) async {
    try {
      // Business logic: Validate the request
      if (!_cachedPlugs.containsKey(plugId)) {
        throw Exception('Smart plug not found: $plugId');
      }

      // Connect to the device
      await _service.connectToSmartPlug(plugId);
      
      try {
        // Send the command
        if (newState) {
          await _service.turnOnSmartPlug(plugId);
        } else {
          await _service.turnOffSmartPlug(plugId);
        }
        
        // Update cached data
        final updatedPlug = _cachedPlugs[plugId]!.copyWith(
          isPoweredOn: newState,
          currentPowerUsage: newState ? _cachedPlugs[plugId]!.currentPowerUsage : 0.0,
          lastSeen: DateTime.now(),
        );
        _cachedPlugs[plugId] = updatedPlug;
        
      } finally {
        // Always disconnect after operation
        await _service.disconnectFromSmartPlug(plugId);
      }
    } catch (e) {
      // Business logic: Update device as offline if operation fails
      if (_cachedPlugs.containsKey(plugId)) {
        _cachedPlugs[plugId] = _cachedPlugs[plugId]!.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  @override
  Future<SmartPlug?> getSmartPlugById(String plugId) async {
    try {
      // Check cache first
      if (_cachedPlugs.containsKey(plugId)) {
        final cached = _cachedPlugs[plugId]!;
        
        // Business logic: If device was seen recently, return cached data
        if (DateTime.now().difference(cached.lastSeen).inMinutes < 5) {
          return cached;
        }
      }
      
      // Try to get fresh status
      final status = await _getDeviceStatus(plugId);
      if (status != null) {
        _cachedPlugs[plugId] = status;
      }
      
      return status;
    } catch (e) {
      // Return cached data if available, even if stale
      return _cachedPlugs[plugId];
    }
  }

  /// Get device status by connecting and reading data
  Future<SmartPlug?> _getDeviceStatus(String deviceId) async {
    try {
      await _service.connectToSmartPlug(deviceId);
      
      try {
        final status = await _service.getSmartPlugStatus(deviceId);
        
        // Convert service status to domain model
        return SmartPlug(
          id: deviceId,
          friendlyName: _getFriendlyName(deviceId),
          serialNumber: _generateSerialNumber(deviceId),
          modelNumber: 'M001', // Default model
          manufacturer: 'Zuli',
          isOnline: status.isOnline,
          isPoweredOn: status.currentPowerUsage > 0,
          currentPowerUsage: status.currentPowerUsage,
          lastSeen: status.lastSeen,
          firmwareVersion: '1.0.0', // Would come from device in real implementation
          macAddress: deviceId, // Using device ID as MAC address for now
        );
      } finally {
        await _service.disconnectFromSmartPlug(deviceId);
      }
    } catch (e) {
      // Return offline device if connection fails
      return SmartPlug(
        id: deviceId,
        friendlyName: _getFriendlyName(deviceId),
        serialNumber: _generateSerialNumber(deviceId),
        modelNumber: 'M001',
        manufacturer: 'Zuli',
        isOnline: false,
        isPoweredOn: false,
        currentPowerUsage: 0.0,
        lastSeen: DateTime.now(),
        firmwareVersion: '1.0.0',
        macAddress: deviceId,
      );
    }
  }

  /// Business logic: Generate friendly names for devices
  String _getFriendlyName(String deviceId) {
    switch (deviceId) {
      case 'mock-device-1':
        return 'Living Room Lamp';
      case 'mock-device-2':
        return 'Kitchen Coffee Maker';
      default:
        return 'Smart Plug ${deviceId.split('-').last}';
    }
  }

  /// Business logic: Generate serial numbers for devices
  String _generateSerialNumber(String deviceId) {
    return 'SN${deviceId.split('-').last.padLeft(3, '0')}';
  }
}