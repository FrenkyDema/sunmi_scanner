# sunmi_scanner

A Flutter plugin that wraps the Sunmi Android SDK for the integrated barcode scanner.

**IMPORTANT: THIS PACKAGE WILL WORK ONLY ON ANDROID!**

---

## Features

* **Manual Service Control:** Manually bind and unbind from the Sunmi scanner service.
* **Optional Toasts:** Disable the native "Service connected/disconnected" toasts.
* **Barcode Events:** Listen to a stream of barcode scan events.
* **Connection Status:** Listen to a stream of service connection status changes (`connected`, `disconnected`, `failedToConnect`).
* **Type-Safe Models:** Get the hardware scanner model as a `SunmiScannerModel` enum.
* **Error Handling:** Methods throw a `PlatformException` if the service is not bound or another error occurs.
* **Scanner Control:** Programmatically start (`scan()`) and stop (`stop()`) the scanner.

## Usage

### 1. Bind the Service

You **must** call `SunmiScanner.bindService()` before using any other method. A good place to do this is in your `initState`.

You must also call `SunmiScanner.unbindService()` in your `dispose` method to clean up the connection.

### 2. Listen to Streams and Call Methods

Once bound, you can listen to streams and call methods like `scan()`.

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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _scannedValue,
                style: Theme.of(context).textTheme.headlineMedium,
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