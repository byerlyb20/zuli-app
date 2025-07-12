import 'package:flutter/foundation.dart';
import '../../../domain/models/smart_plug.dart';

class SmartPlugDetailViewModel extends ChangeNotifier {
  SmartPlug? _smartPlug;
  
  SmartPlugDetailViewModel({SmartPlug? smartPlug}) {
    _smartPlug = smartPlug;
  }
  
  // Getters
  bool get isOn => _smartPlug?.isPoweredOn ?? false;
  String get deviceName => _smartPlug?.friendlyName ?? 'Unknown Device';
  double get powerUsage => _smartPlug?.currentPowerUsage ?? 0.0;
  bool get isOnline => _smartPlug?.isOnline ?? false;
  DateTime? get lastSeen => _smartPlug?.lastSeen;
  double get brightness => _smartPlug?.brightness ?? 0.0;
  
  // Initialize or update the smart plug data
  void updateSmartPlug(SmartPlug smartPlug) {
    _smartPlug = smartPlug;
    notifyListeners();
  }

  // Toggle power state
  void togglePower(bool value) {
    if (_smartPlug == null) return;
    
    _smartPlug = _smartPlug!.copyWith(
      isPoweredOn: value,
      currentPowerUsage: value ? _smartPlug!.currentPowerUsage : 0.0,
    );
    notifyListeners();
  }

  // Update device name
  void updateDeviceName(String name) {
    if (_smartPlug == null) return;
    
    _smartPlug = _smartPlug!.copyWith(friendlyName: name);
    notifyListeners();
  }

  // Update brightness and recalculate power usage
  void updateBrightness(double value) {
    if (_smartPlug == null) return;
    
    // Ensure brightness is between 0 and 100
    value = value.clamp(0.0, 100.0);
    
    _smartPlug = _smartPlug!.copyWith(
      brightness: value,
    );
    notifyListeners();
  }
} 