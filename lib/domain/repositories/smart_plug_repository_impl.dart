import 'dart:async';
import 'dart:collection';

import '../models/smart_plug.dart';
import 'smart_plug_repository.dart';
import '../../data/services/smart_plug_service.dart';
import '../../data/services/transport/ble_transport_interface.dart';

class SmartPlugRepositoryImpl extends SmartPlugRepository {
  final SmartPlugService _service;
  final Map<String, SmartPlug> _cachedPlugs = {};

  SmartPlugRepositoryImpl(BleTransportInterface transport)
      : _service = SmartPlugService(transport);

  @override
  UnmodifiableListView<SmartPlug> get smartPlugs {
    return UnmodifiableListView(_cachedPlugs.values.toList());
  }

  @override
  Future<void> discoverSmartPlugs() async {
    final discoveryStream = _service.scanForSmartPlugs(
      timeout: const Duration(seconds: 10),
    );
    await for (final device in discoveryStream) {
      final status = await _getDeviceStatus(device.id);
      _updateSmartPlug(status);
    }
  }

  @override
  Future<void> setPower(String plugId, bool newState) async {
    try {
      // Business logic: Validate the request
      if (!_cachedPlugs.containsKey(plugId)) {
        throw Exception('Smart plug not found: $plugId');
      }
      
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
      _updateSmartPlug(updatedPlug);
    } catch (e) {
      // Business logic: Update device as offline if operation fails
      if (_cachedPlugs.containsKey(plugId)) {
        final offlinePlug = _cachedPlugs[plugId]!.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        );
        _updateSmartPlug(offlinePlug);
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
      _updateSmartPlug(status);
      
      return status;
    } catch (e) {
      // Return cached data if available, even if stale
      return _cachedPlugs[plugId];
    }
  }

  /// Updates a smart plug in the cache and notifies listeners
  void _updateSmartPlug(SmartPlug plug) {
    _cachedPlugs[plug.id] = plug;
    notifyListeners();
  }

  /// Get device status by connecting and reading data
  Future<SmartPlug> _getDeviceStatus(String deviceId) async {
    try {
      final status = await _service.getSmartPlugStatus(deviceId);
        
      // Convert service status to domain model
      return SmartPlug(
        id: deviceId,
        friendlyName: _getFriendlyName(deviceId),
        isOnline: status.isOnline,
        isPoweredOn: status.currentPowerUsage > 0,
        currentPowerUsage: status.currentPowerUsage,
        lastSeen: status.lastSeen,
      );
    } catch (e) {
      // Return offline device if connection fails
      return SmartPlug(
        id: deviceId,
        friendlyName: _getFriendlyName(deviceId),
        isOnline: false,
        isPoweredOn: false,
        currentPowerUsage: 0.0,
        lastSeen: DateTime.now(),
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
}