import 'package:flutter/foundation.dart';

/// Represents a Bluetooth Low Energy (BLE) smart plug device with its properties and state
@immutable
class SmartPlug {
  final String id;
  final String friendlyName;
  final String serialNumber;
  final String modelNumber;
  final String manufacturer;
  final bool isOnline;
  final bool isPoweredOn;
  final double currentPowerUsage; // in watts
  final DateTime lastSeen;
  final String firmwareVersion;
  final String macAddress; // BLE device MAC address
  final double brightness; // brightness level from 0.0 to 100.0

  const SmartPlug({
    required this.id,
    required this.friendlyName,
    required this.serialNumber,
    required this.modelNumber,
    required this.manufacturer,
    required this.isOnline,
    required this.isPoweredOn,
    required this.currentPowerUsage,
    required this.lastSeen,
    required this.firmwareVersion,
    required this.macAddress,
    this.brightness = 0.0,
  });

  /// Creates a copy of this SmartPlug with the given fields replaced with new values
  SmartPlug copyWith({
    String? id,
    String? friendlyName,
    String? serialNumber,
    String? modelNumber,
    String? manufacturer,
    bool? isOnline,
    bool? isPoweredOn,
    double? currentPowerUsage,
    DateTime? lastSeen,
    String? firmwareVersion,
    String? macAddress,
    double? brightness,
  }) {
    return SmartPlug(
      id: id ?? this.id,
      friendlyName: friendlyName ?? this.friendlyName,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      isOnline: isOnline ?? this.isOnline,
      isPoweredOn: isPoweredOn ?? this.isPoweredOn,
      currentPowerUsage: currentPowerUsage ?? this.currentPowerUsage,
      lastSeen: lastSeen ?? this.lastSeen,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      macAddress: macAddress ?? this.macAddress,
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
          serialNumber == other.serialNumber &&
          modelNumber == other.modelNumber &&
          manufacturer == other.manufacturer &&
          isOnline == other.isOnline &&
          isPoweredOn == other.isPoweredOn &&
          currentPowerUsage == other.currentPowerUsage &&
          lastSeen == other.lastSeen &&
          firmwareVersion == other.firmwareVersion &&
          brightness == other.brightness &&
          macAddress == other.macAddress;

  @override
  int get hashCode =>
      id.hashCode ^
      friendlyName.hashCode ^
      serialNumber.hashCode ^
      modelNumber.hashCode ^
      manufacturer.hashCode ^
      isOnline.hashCode ^
      isPoweredOn.hashCode ^
      currentPowerUsage.hashCode ^
      lastSeen.hashCode ^
      firmwareVersion.hashCode ^
      brightness.hashCode ^
      macAddress.hashCode;

  @override
  String toString() {
    return 'SmartPlug(id: $id, friendlyName: $friendlyName, serialNumber: $serialNumber, modelNumber: $modelNumber, manufacturer: $manufacturer, isOnline: $isOnline, isPoweredOn: $isPoweredOn, currentPowerUsage: $currentPowerUsage, lastSeen: $lastSeen, firmwareVersion: $firmwareVersion, macAddress: $macAddress, brightness: $brightness)';
  }
} 