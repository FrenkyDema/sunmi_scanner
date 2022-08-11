import 'dart:async';

import 'package:flutter/services.dart';

/// Defines if key code is sent as key up or key down event
enum KeyAction {
  /// Simulates button down on keyboard
  actionDown,

  /// Simulates button up on keyboard
  actionUp
}

/// Plugin that wraps Sunmi Android SDK for integrated barcode scanner
class SunmiScanner {
  static const MethodChannel _channel = MethodChannel('sunmi_scanner');
  static const EventChannel _eventChannel =
      EventChannel('sunmi_scanner_events');

  /// Customize the trigger key
  static void sendKeyEvent(KeyAction keyAction, int keyCode) async {
    await _channel.invokeMethod(
        'SEND_KEY_EVENT', {"key": keyAction.index, "code": keyCode});
  }

  /// Start scanning
  static void scan() async {
    await _channel.invokeMethod('SCAN');
  }

  /// Stop scanning
  static void stop() async {
    await _channel.invokeMethod('STOP');
  }

  /// Returns model number of the hardware scanner.
  /// 100 → NONE
  /// 101 → P2Lite/V2Pro/P2Pro(em1365/BSM1825)
  /// 102 → L2-newland(EM2096)
  /// 103 → L2-zabra(SE4710)
  /// 104 → L2-HoneyWell(N3601)
  /// 105 → L2-HoneyWell(N6603)
  /// 106 → L2-Zabra(SE4750)
  /// 107 → L2-Zabra(EM1350)
  static Future<int> getScannerModel() async {
    return (await _channel.invokeMethod('GET_MODEL')).toInt();
  }

  /// Calls `getScannerModel` and returns true if it's greater than 100
  static Future<bool> isScannerAvailable() async {
    var model = (await _channel.invokeMethod('GET_MODEL')).toInt();
    return (model > 100);
  }

  /// Stream for the event value
  static Stream<String>? _onBarcodeScanned;

  /// Subscribe to this stream to receive barcode as string when it's scanned.
  /// Make sure to cancel subscription when you're done.
  static Stream<String> onBarcodeScanned() {
    _onBarcodeScanned ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => event as String);
    return _onBarcodeScanned ?? const Stream<String>.empty();
  }
}
