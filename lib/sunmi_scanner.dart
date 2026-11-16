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

/// A USB device attached to the terminal, as Android lists it.
///
/// Pass it to [SunmiScanner.setUsbScannerOutput] to choose how a USB
/// barcode scanner delivers its data.
class SunmiUsbDevice {
  /// Creates a USB device description.
  const SunmiUsbDevice({
    required this.name,
    required this.vendorId,
    required this.productId,
  });

  /// The product name the device reports (empty when it reports none).
  final String name;

  /// The USB vendor id (VID).
  final int vendorId;

  /// The USB product id (PID).
  final int productId;

  @override
  String toString() =>
      'SunmiUsbDevice($name, vid: 0x${vendorId.toRadixString(16)}, '
      'pid: 0x${productId.toRadixString(16)})';
}

/// How a USB barcode scanner delivers what it reads, as in the Sunmi
/// "Barcode Scanner User Guide" (`com.sunmi.scanner.ACTION_BAR_DEVICES_SETTING`).
enum SunmiScannerOutput {
  /// The device is treated as a plain keyboard, not as a scanner.
  keyboard(0),

  /// Key events, typed into the focused input field.
  keyEvent(1),

  /// Broadcast only: [SunmiScanner.onBarcodeScanned] receives the data and
  /// nothing is typed into input fields.
  broadcast(2),

  /// The whole code is filled into the focused input field at once
  /// (Sunmi scanner service 1.0.18 or newer).
  fillAtOnce(3);

  const SunmiScannerOutput(this.code);

  /// The `type` value the Sunmi scanner service expects.
  final int code;
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
  /// Returns false if the scanner service is unavailable or not bound.
  static Future<bool> isScannerAvailable() async {
    try {
      var model = await getScannerModel();
      return (model > 100);
    } on PlatformException {
      return false;
    }
  }

  /// Lists the USB devices attached to the terminal.
  ///
  /// It does not need [bindService]. Use it to find the USB barcode scanner
  /// to pass to [setUsbScannerOutput].
  static Future<List<SunmiUsbDevice>> getUsbDevices() async {
    final List<Object?>? devices = await _channel.invokeListMethod<Object?>(
      'GET_USB_DEVICES',
    );
    return [
      for (final Object? device in devices ?? const <Object?>[])
        if (device is Map)
          SunmiUsbDevice(
            name: device['name'] as String? ?? '',
            vendorId: device['vendorId'] as int,
            productId: device['productId'] as int,
          ),
    ];
  }

  /// Sets how the USB barcode scanner [device] delivers what it reads.
  ///
  /// With [SunmiScannerOutput.broadcast], scans arrive only through
  /// [onBarcodeScanned]. The Sunmi scanner service keeps the setting, so it
  /// survives restarts. It does not need [bindService]. [showToast] makes the
  /// service show a debugging toast.
  static Future<void> setUsbScannerOutput(
    SunmiUsbDevice device,
    SunmiScannerOutput output, {
    bool showToast = false,
  }) async {
    await _channel.invokeMethod('SET_USB_SCANNER_OUTPUT', {
      'name': device.name,
      'pid': device.productId,
      'vid': device.vendorId,
      'type': output.code,
      'toast': showToast,
    });
  }

  /// Stream for the event value
  static Stream<String>? _onBarcodeScanned;

  /// Subscribe to this stream to receive barcode as string when it's scanned.
  /// Make sure to cancel subscription when you're done.
  ///
  /// Events without data are skipped. The data is passed as the scanner
  /// sends it, with any suffix (for example a trailing newline) it is
  /// configured to add.
  static Stream<String> onBarcodeScanned() {
    _onBarcodeScanned ??= _eventChannel
        .receiveBroadcastStream()
        .where((dynamic event) => event is String && event.isNotEmpty)
        .cast<String>();
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
