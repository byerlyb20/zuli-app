import '../models/smart_plug.dart';

abstract class SmartPlugRepository {
  /// Fetches all smart plugs from the data source
  Future<List<SmartPlug>> getSmartPlugs();
  
  /// Toggles the power state of a specific smart plug
  Future<void> togglePower(String plugId, bool newState);
  
  /// Gets a specific smart plug by ID
  Future<SmartPlug?> getSmartPlugById(String plugId);
} 