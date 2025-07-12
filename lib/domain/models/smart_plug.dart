import 'package:flutter/foundation.dart';

/// Represents a Bluetooth Low Energy (BLE) smart plug device with its properties and state
@immutable
class SmartPlug {
  final String id;
  final String friendlyName;
  final bool isOnline;
  final bool isPoweredOn;
  final double currentPowerUsage; // in watts
  final DateTime lastSeen;
  final double brightness; // brightness level from 0.0 to 100.0

  const SmartPlug({
    required this.id,
    required this.friendlyName,
    required this.isOnline,
    required this.isPoweredOn,
    required this.currentPowerUsage,
    required this.lastSeen,
    this.brightness = 0.0,
  });

  /// Creates a copy of this SmartPlug with the given fields replaced with new values
  SmartPlug copyWith({
    String? id,
    String? friendlyName,
    bool? isOnline,
    bool? isPoweredOn,
    double? currentPowerUsage,
    DateTime? lastSeen,
    double? brightness,
  }) {
    return SmartPlug(
      id: id ?? this.id,
      friendlyName: friendlyName ?? this.friendlyName,
      isOnline: isOnline ?? this.isOnline,
      isPoweredOn: isPoweredOn ?? this.isPoweredOn,
      currentPowerUsage: currentPowerUsage ?? this.currentPowerUsage,
      lastSeen: lastSeen ?? this.lastSeen,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartPlug &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          friendlyName == other.friendlyName &&
          isOnline == other.isOnline &&
          isPoweredOn == other.isPoweredOn &&
          currentPowerUsage == other.currentPowerUsage &&
          lastSeen == other.lastSeen &&
          brightness == other.brightness;

  @override
  int get hashCode =>
      id.hashCode ^
      friendlyName.hashCode ^
      isOnline.hashCode ^
      isPoweredOn.hashCode ^
      currentPowerUsage.hashCode ^
      lastSeen.hashCode ^
      brightness.hashCode;

  @override
  String toString() {
    return 'SmartPlug(id: $id, friendlyName: $friendlyName, isOnline: $isOnline, isPoweredOn: $isPoweredOn, currentPowerUsage: $currentPowerUsage, lastSeen: $lastSeen, brightness: $brightness)';
  }
} 