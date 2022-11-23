# sunmi_scanner

A packae for support sunmi scanners

## Important

**THIS PACKAGE WILL WORK ONLY IN ANDROID!**

---

## Class Name

```dart
SunmiScanner
```

## Example

```dart
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
```

## Installation

```bash
flutter pub add sunmi_scanner
```

## Tested Devices

```bash
Sunmi L2ks
```
