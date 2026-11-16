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
  List<SunmiUsbDevice> usbDevices = const [];

  void _setScannedValue(String value) {
    setState(() {
      scannedValue = value;
    });
  }

  Future<void> _loadUsbDevices() async {
    final devices = await SunmiScanner.getUsbDevices();
    setState(() {
      usbDevices = devices;
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
    _loadUsbDevices();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Text("scanning: ${scannedValue ?? ""}")),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Text('USB devices')),
                TextButton(
                  onPressed: _loadUsbDevices,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            for (final device in usbDevices)
              ListTile(
                title: Text(device.name.isEmpty ? '(no name)' : device.name),
                subtitle: Text(
                  'VID 0x${device.vendorId.toRadixString(16)} · '
                  'PID 0x${device.productId.toRadixString(16)}',
                ),
                trailing: TextButton(
                  onPressed: () => SunmiScanner.setUsbScannerOutput(
                    device,
                    SunmiScannerOutput.broadcast,
                    showToast: true,
                  ),
                  child: const Text('Broadcast output'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
