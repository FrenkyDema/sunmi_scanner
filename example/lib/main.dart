import 'package:flutter/material.dart';
import 'package:sunmi_scanner/sunmi_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? scannedValue;

  void _setScannedValue(String value) {
    setState(() {
      scannedValue = value;
    });
  }

  @override
  void initState() {
    super.initState();

    SunmiScanner.onScannerStatusChanged().listen((status) {
      switch (status) {
        case ScannerConnectionStatus.connected:
          debugPrint("Connected");
          break;
        case ScannerConnectionStatus.disconnected:
          debugPrint("Disconnected");
          break;
        case ScannerConnectionStatus.failedToConnect:
          debugPrint("Failed To Connect");
          break;
      }
    });

    SunmiScanner.onBarcodeScanned().listen((event) {
      _setScannedValue(event);
    });

    SunmiScanner.bindService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Center(child: Text("scanning: ${scannedValue ?? ""}"))],
          ),
        ),
      ),
    );
  }
}
