import 'dart:async';

import 'package:flutter/services.dart';

/// Defines if key code is sent as key up or key down event
enum KeyAction {
  /// Simulates button down on keyboard
  actionDown,

  /// Simulates button up on keyboard
  actionUp,
}

/// Represents the specific hardware model of the Sunmi scanner.
enum SunmiScannerModel {
  /// No scanner hardware found.
  none,

  /// P2Lite, V2Pro, or P2Pro
  p2LiteV2ProP2Pro,

  /// L2 with Newland scanner
  l2Newland,

  /// L2 with Zebra scanner (SE4710)
  l2ZebraSe4710,

  /// L2 with HoneyWell scanner (N3601)
  l2HoneywellN3601,

  /// L2 with HoneyWell scanner (N6603)
  l2HoneywellN6603,

  /// L2 with Zebra scanner (SE4750)
  l2ZebraSe4750,

  /// L2 with Zebra scanner (EM1350)
  l2ZebraEm1350,

  /// An unknown or unsupported scanner model.
  unknown,
}

/// Represents the connection status to the native Sunmi scanner service.
enum ScannerConnectionStatus {
  /// Successfully connected to the service.
  connected,

  /// Disconnected from the service (e.g., service crashed or was unbound).
  disconnected,

  /// Failed to connect to the service.
  failedToConnect,
}

/// Plugin that wraps Sunmi Android SDK for integrated barcode scanner
class SunmiScanner {
  static const MethodChannel _channel = MethodChannel('sunmi_scanner');
  static const EventChannel _eventChannel = EventChannel(
    'sunmi_scanner_events',
  );
  static const EventChannel _connectionEventChannel = EventChannel(
    'sunmi_scanner_connection_events',
  );

  /// Binds the scanner service.
  ///
  /// This method must be called before any other scanner operations.
  /// [showToast] controls whether to display Toasts on service connection
  /// events (connected, disconnected, failed). Defaults to `true`.
  static Future<void> bindService({bool showToast = true}) async {
    await _channel.invokeMethod('bindService', {"showToast": showToast});
  }

  /// Unbinds the scanner service.
  static Future<void> unbindService() async {
    await _channel.invokeMethod('unbindService');
  }

  /// Customize the trigger key.
  ///
  /// Can throw a [PlatformException] if the service is not bound
  /// or a remote exception occurs.
  static void sendKeyEvent(KeyAction keyAction, int keyCode) async {
    await _channel.invokeMethod('SEND_KEY_EVENT', {
      "key": keyAction.index,
      "code": keyCode,
    });
  }

  /// Start scanning.
  ///
  /// Can throw a [PlatformException] if the service is not bound
  /// or a remote exception occurs.
  static void scan() async {
    await _channel.invokeMethod('SCAN');
  }

  /// Stop scanning.
  ///
  /// Can throw a [PlatformException] if the service is not bound
  /// or a remote exception occurs.
  static void stop() async {
    await _channel.invokeMethod('STOP');
  }

  /// Returns the raw model number of the hardware scanner.
  ///
  /// Consider using [getScannerModelEnum] for a more type-safe alternative.
  ///
  /// 100 → NONE
  /// 101 → P2Lite/V2Pro/P2Pro
  /// 102 → L2-newland
  /// 103 → L2-zabra(SE4710)
  /// 104 → L2-HoneyWell(N3601)
  /// 105 → L2-HoneyWell(N6603)
  /// 106 → L2-Zabra(SE4750)
  /// 107 → L2-Zabra(EM1350)
  ///
  /// Can throw a [PlatformException] if the service is not bound
  /// or a remote exception occurs.
  static Future<int> getScannerModel() async {
    return (await _channel.invokeMethod('GET_MODEL')).toInt();
  }

  /// Returns the parsed [SunmiScannerModel] enum.
  ///
  /// This is a convenience wrapper around [getScannerModel].
  static Future<SunmiScannerModel> getScannerModelEnum() async {
    final int modelCode = await getScannerModel();
    switch (modelCode) {
      case 100:
        return SunmiScannerModel.none;
      case 101:
        return SunmiScannerModel.p2LiteV2ProP2Pro;
      case 102:
        return SunmiScannerModel.l2Newland;
      case 103:
        return SunmiScannerModel.l2ZebraSe4710;
      case 104:
        return SunmiScannerModel.l2HoneywellN3601;
      case 105:
        return SunmiScannerModel.l2HoneywellN6603;
      case 106:
        return SunmiScannerModel.l2ZebraSe4750;
      case 107:
        return SunmiScannerModel.l2ZebraEm1350;
      default:
        return SunmiScannerModel.unknown;
    }
  }

  /// Calls `getScannerModel` and returns true if it's greater than 100.
  ///
  /// Can throw a [PlatformException] if the service is not bound.
  static Future<bool> isScannerAvailable() async {
    var model = await getScannerModel();
    return (model > 100);
  }

  /// Stream for the event value
  static Stream<String>? _onBarcodeScanned;

  /// Subscribe to this stream to receive barcode as string when it's scanned.
  /// Make sure to cancel subscription when you're done.
  static Stream<String> onBarcodeScanned() {
    _onBarcodeScanned ??= _eventChannel.receiveBroadcastStream().map(
      (dynamic event) => event as String,
    );
    return _onBarcodeScanned ?? const Stream<String>.empty();
  }

  /// Stream for the service connection status
  static Stream<ScannerConnectionStatus>? _onScannerStatusChanged;

  /// Subscribe to this stream to receive [ScannerConnectionStatus] events.
  /// This allows you to react to service connections, disconnections,
  /// or connection failures.
  static Stream<ScannerConnectionStatus> onScannerStatusChanged() {
    _onScannerStatusChanged ??= _connectionEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
          switch (event as String) {
            case "CONNECTED":
              return ScannerConnectionStatus.connected;
            case "DISCONNECTED":
              return ScannerConnectionStatus.disconnected;
            case "FAILED_TO_CONNECT":
              return ScannerConnectionStatus.failedToConnect;
            default:
              // This should not happen
              return ScannerConnectionStatus.disconnected;
          }
        });
    return _onScannerStatusChanged ??
        const Stream<ScannerConnectionStatus>.empty();
  }
}
