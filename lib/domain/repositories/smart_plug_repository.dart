import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/smart_plug.dart';

abstract class SmartPlugRepository extends ChangeNotifier {
  /// Fetches all smart plugs from the data source
  Future<void> discoverSmartPlugs();

  /// Returns an unmodifiable view of all known smart plugs
  UnmodifiableListView<SmartPlug> get smartPlugs;
  
  /// Toggles the power state of a specific smart plug
  Future<void> setPower(String plugId, bool newState);
  
  /// Gets a specific smart plug by ID
  Future<SmartPlug?> getSmartPlugById(String plugId);
} 