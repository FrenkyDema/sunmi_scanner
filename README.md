# sunmi_scanner

A Flutter plugin that wraps the Sunmi Android SDK for the integrated barcode scanner.

**IMPORTANT: THIS PACKAGE WILL WORK ONLY ON ANDROID!**

---

## Features

* **Manual Service Control:** Manually bind and unbind from the Sunmi scanner service.
* **Optional Toasts:** Disable the native "Service connected/disconnected" toasts.
* **Barcode Events:** Listen to a stream of barcode scan events.
* **Connection Status:** Listen to a stream of service connection status changes (`connected`,
  `disconnected`, `failedToConnect`).
* **Type-Safe Models:** Get the hardware scanner model as a `SunmiScannerModel` enum.
* **Error Handling:** Methods throw a `PlatformException` if the service is not bound or another
  error occurs.
* **Scanner Control:** Programmatically start (`scan()`) and stop (`stop()`) the scanner.
* **USB Scanners:** List the attached USB devices (`getUsbDevices()`) and set how a USB barcode
  scanner delivers its data (`setUsbScannerOutput()`), for example broadcast only.

## Installation

```bash
flutter pub add sunmi_scanner
```

## Usage

### 1. Bind the Service

You **must** call `SunmiScanner.bindService()` before using any other method. A good place to do
this is in your `initState`.

You must also call `SunmiScanner.unbindService()` in your `dispose` method to clean up the
connection.

### 2. Listen to Streams and Call Methods

Once bound, you can listen to streams and call methods like `scan()`.

### 3. USB Barcode Scanners

Terminals with a USB scanner (for example the SUNMI FLEX 3) deliver the scans as key events by
default, so `onBarcodeScanned()` receives nothing. Switch the scanner to broadcast output once; the
Sunmi scanner service keeps the setting:

```dart
final devices = await SunmiScanner.getUsbDevices();
for (final device in devices) {
  // The scanner of the SUNMI FLEX 3: "SM-2D PRODUCT DEFHID+KBW", VID 0x324F.
  if (device.name.contains('SM-2D')) {
    await SunmiScanner.setUsbScannerOutput(device, SunmiScannerOutput.broadcast);
  }
}
```

The scanned data arrives with the suffix the scanner adds (often a trailing newline): trim it if
you need the bare code. These two methods do not need `bindService()`.

On the SUNMI FLEX 3 the base peripherals (scanner, printer, USB Ethernet) are detached while a
USB cable connects the terminal to a computer: use `adb` over Wi-Fi to debug the scanner.

### Full Example

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_scanner/sunmi_scanner.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _scannedValue = '---';
  SunmiScannerModel? _scannerModel;
  ScannerConnectionStatus _status = ScannerConnectionStatus.disconnected;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _bindScanner();
    _listenToStreams();
  }

  void _listenToStreams() {
    _scanSubscription = SunmiScanner.onBarcodeScanned().listen((event) {
      setState(() {
        _scannedValue = event;
      });
    });

    _statusSubscription = SunmiScanner.onScannerStatusChanged().listen((status) {
      setState(() {
        _status = status;
      });
    });
  }

  Future<void> _bindScanner() async {
    try {
      // Bind the service.
      // You can also pass showToast: false to hide connection Toasts.
      await SunmiScanner.bindService(showToast: true);

      // Get scanner model
      final SunmiScannerModel model = await SunmiScanner.getScannerModelEnum();
      setState(() {
        _scannerModel = model;
      });
    } on PlatformException catch (e) {
      print("Failed to bind scanner: ${e.message}");
    }
  }

  @override
  void dispose() {
    // Unbind the service and cancel subscriptions
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    SunmiScanner.unbindService();
    super.dispose();
  }

  void _triggerScan() {
    try {
      SunmiScanner.scan();
    } on PlatformException catch (e) {
      print("Failed to scan: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sunmi Scanner Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Connection Status: ${_status.name}'),
              Text('Scanner Model: ${_scannerModel?.name ?? 'Unknown'}'),
              SizedBox(height: 20),
              Text(
                'Scanned Value:',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              Text(
                _scannedValue,
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _triggerScan,
                child: Text("Trigger Scan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Tested Devices

```
Sunmi L2ks
SunMi P3H
SUNMI L2s PRO
SUNMI FLEX 3 (USB scanner)
```