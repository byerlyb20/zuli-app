import 'package:flutter/foundation.dart';
import '../../../domain/models/smart_plug.dart';

class SmartPlugsViewModel extends ChangeNotifier {
  List<SmartPlug> _smartPlugs = [];
  bool _isLoading = false;
  String? _error;

  List<SmartPlug> get smartPlugs => List.unmodifiable(_smartPlugs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // TODO: Inject smart plug repository when available
  SmartPlugsViewModel();

  Future<void> loadSmartPlugs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual repository call
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _smartPlugs = [
        SmartPlug(
          id: '1',
          friendlyName: 'Living Room Lamp',
          serialNumber: 'SN001',
          modelNumber: 'M001',
          manufacturer: 'Zuli',
          isOnline: true,
          isPoweredOn: true,
          currentPowerUsage: 60.0,
          lastSeen: DateTime.now(),
          firmwareVersion: '1.0.0',
          macAddress: '00:11:22:33:44:55',
        ),
        SmartPlug(
          id: '2',
          friendlyName: 'Kitchen Coffee Maker',
          serialNumber: 'SN002',
          modelNumber: 'M001',
          manufacturer: 'Zuli',
          isOnline: true,
          isPoweredOn: false,
          currentPowerUsage: 0.0,
          lastSeen: DateTime.now(),
          firmwareVersion: '1.0.0',
          macAddress: '00:11:22:33:44:66',
        ),
      ];
    } catch (e) {
      _error = 'Failed to load smart plugs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePower(String plugId, bool newState) async {
    try {
      final index = _smartPlugs.indexWhere((plug) => plug.id == plugId);
      if (index == -1) return;

      // TODO: Replace with actual repository call
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      _smartPlugs[index] = _smartPlugs[index].copyWith(isPoweredOn: newState);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle power: $e';
      notifyListeners();
    }
  }
} 