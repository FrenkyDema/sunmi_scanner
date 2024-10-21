import 'package:flutter/material.dart';
import 'package:sunmi_scanner/sunmi_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
    SunmiScanner.onBarcodeScanned().listen((event) {
      _setScannedValue(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text("scanning: ${scannedValue ?? ""}"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
