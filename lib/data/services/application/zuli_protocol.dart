import 'dart:typed_data';

/// Zuli Command Suite (ZCS) - Dart implementation
/// Provides packet generation and response parsing for Zuli smart plug protocol
class ZuliProtocol {
  // BLE Service and Characteristic UUIDs
  static const String advertisedZuliService = '04ee929b-bb13-4e77-8160-18552daf06e1';
  static const String zuliService = 'ffffff00-bb13-4e77-8160-18552daf06e1';
  static const String commandPipeCharacteristic = 'ffffff03-bb13-4e77-8160-18552daf06e1';

  // Command codes
  static const int cmdReset = 2;
  static const int cmdVersionRead = 6;
  static const int cmdFlagsRead = 7;
  static const int cmdClockSet = 8;
  static const int cmdClockGet = 9;
  static const int cmdNetworkSet = 10;
  static const int cmdNetworkGet = 11;
  static const int cmdModeSet = 16;
  static const int cmdModeGet = 17;
  static const int cmdAttributeSet = 21;
  static const int cmdAttributeGet = 22;
  static const int cmdOn = 23;
  static const int cmdOff = 24;
  static const int cmdRead = 25;
  static const int cmdPowerRead = 32;
  static const int cmdEnergyReadInfo = 33;
  static const int cmdEnergyReadAccum = 34;
  static const int cmdEnergyReadLatch = 35;
  static const int cmdEnergyLatchResetAll = 36;
  static const int cmdScheduleInfoGet = 48;
  static const int cmdScheduleGet = 49;
  static const int cmdScheduleEnable = 50;
  static const int cmdScheduleAdd = 51;
  static const int cmdScheduleRemove = 52;
  static const int cmdScheduleRemoveAll = 53;
  static const int cmdDefaultOutputSet = 80;
  static const int cmdDefaultOutputGet = 81;
  static const int cmdBookmark = 126;
  static const int cmdBatch = 127;

  // Status codes
  static const int statusSuccess = 0;
  static const int statusBusy = 5;
  static const int statusInvalidParam = 6;
  static const int statusBadLength = 15;
  static const int statusAlreadySet = 9;

  /// Returns the response status (second byte in the response)
  static int parseResponseStatus(Uint8List response) {
    return response[1];
  }

  /// Creates a packet to turn a smart plug on, optionally at a specified brightness
  /// [brightness] should be between 0 and 100 (defaults to 0, which is functionally equivalent to 100)
  /// Brightness is ignored by the smart plug when in appliance mode
  static Uint8List on({int brightness = 0}) {
    brightness = brightness.clamp(0, 100);
    return Uint8List.fromList([
      cmdOn,
      0,
      0,
      0,
      0,
      brightness,
      0,
      0,
      0,
    ]);
  }

  /// Creates a packet to turn a smart plug off
  static Uint8List off() {
    return Uint8List.fromList([cmdOff, 0, 0, 0]);
  }

  /// Creates a packet to set the mode of a smart plug
  /// [isAppliance] defaults to true, indicating the smart plug is attached to a high power device
  /// that does not support dimming (good for appliances, non-dimmable lights, etc.)
  static Uint8List setMode({bool isAppliance = true}) {
    final mode = isAppliance ? 0 : 1;
    return Uint8List.fromList([cmdModeSet, mode]);
  }

  /// Creates a packet to set the clock of a smart plug
  /// Smart plugs track their own system time for use with schedules
  static Uint8List setClock(DateTime time) {
    final yearBytes = time.year.toBytes(2);
    final weekday = ((time.weekday + 1) % 7) + 1;
    return Uint8List.fromList([
      cmdClockSet,
      yearBytes[0],
      yearBytes[1],
      time.month,
      time.day,
      weekday,
      time.hour,
      time.minute,
      time.second,
    ]);
  }

  /// Creates a packet to poll the current system time on a smart plug
  static Uint8List getClock() {
    return Uint8List.fromList([cmdClockGet]);
  }

  /// Produces a DateTime object from a get clock packet response
  static DateTime parseGetClock(Uint8List response) {
    final year = response.buffer.asByteData(response.offsetInBytes + 2, 2).getUint16(0);
    return DateTime(
      year,
      response[4],
      response[5],
      response[7],
      response[8],
      response[9],
    );
  }

  /// Creates a packet to read current power consumption
  static Uint8List readPower() {
    return Uint8List.fromList([cmdPowerRead]);
  }

  /// Returns the current power consumption data from a read power packet response
  /// Returns (irms_ma, power_mw, power_factor, voltage_mv)
  static PowerReading parseReadPower(Uint8List response) {
    // Parse current (2 bytes starting at offset 2)
    final irmsMa = (response[2] | (response[3] << 8));
    
    // Parse power (3 bytes starting at offset 4) - little endian
    final powerMw = response[4] | (response[5] << 8) | (response[6] << 16);
    
    // Parse power factor (2 bytes starting at offset 7)
    final powerFactor = (response[7] | (response[8] << 8));
    
    // Parse voltage (3 bytes starting at offset 9) - little endian
    final voltageMv = response[9] | (response[10] << 8) | (response[11] << 16);
    
    return PowerReading(
      irmsMa: irmsMa,
      powerMw: powerMw,
      powerFactor: powerFactor,
      voltageMv: voltageMv,
    );
  }

  /// Creates a packet to read energy info
  static Uint8List readEnergyInfo() {
    return Uint8List.fromList([cmdEnergyReadInfo, 0]);
  }

  /// Parses energy info response
  static EnergyInfo parseReadEnergyInfo(Uint8List response) {
    final a = response[2];
    final b = response[4];
    final c = (response[5] | (response[6] << 8));
    final d = (response[7] | (response[8] << 8));
    
    return EnergyInfo(a: a, b: b, c: c, d: d);
  }

  /// Creates a packet to reset the smart plug
  static Uint8List resetPlug() {
    final packet = Uint8List(5);
    packet[0] = cmdReset;
    packet[1] = cmdReset;
    packet[2] = 0;
    final confirmReset = 22890;
    packet.buffer.asByteData(packet.offsetInBytes + 3, 2).setUint16(0, confirmReset, Endian.little);
    return packet;
  }
}

/// Extension to convert int to bytes
extension IntToBytes on int {
  Uint8List toBytes(int length) {
    final bytes = Uint8List(length);
    bytes.buffer.asByteData().setUint32(0, this, Endian.little);
    return bytes;
  }
}

/// Data class for power reading results
class PowerReading {
  final int irmsMa;      // Current in milliamps
  final int powerMw;     // Power in milliwatts
  final int powerFactor; // Power factor
  final int voltageMv;   // Voltage in millivolts

  PowerReading({
    required this.irmsMa,
    required this.powerMw,
    required this.powerFactor,
    required this.voltageMv,
  });

  /// Get power in watts
  double get powerWatts => powerMw / 1000.0;

  /// Get current in amps
  double get currentAmps => irmsMa / 1000.0;

  /// Get voltage in volts
  double get voltageVolts => voltageMv / 1000.0;

  @override
  String toString() {
    return 'PowerReading(power: ${powerWatts.toStringAsFixed(2)}W, '
           'current: ${currentAmps.toStringAsFixed(3)}A, '
           'voltage: ${voltageVolts.toStringAsFixed(1)}V, '
           'powerFactor: $powerFactor)';
  }
}

/// Data class for energy info results
class EnergyInfo {
  final int a;
  final int b;
  final int c;
  final int d;

  EnergyInfo({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  });

  @override
  String toString() {
    return 'EnergyInfo(a: $a, b: $b, c: $c, d: $d)';
  }
} 