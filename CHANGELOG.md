# CHANGELOG

## 0.0.7

* **BREAKING CHANGE:** You must now call `SunmiScanner.bindService()` before using any scanner methods.
* Added `SunmiScanner.bindService()` and `SunmiScanner.unbindService()` for manual control over the service lifecycle.
* The service connection toast is now optional and can be disabled via `bindService(showToast: false)`.
* Improved error handling. Methods now throw a `PlatformException` if the service is not bound or a `RemoteException` occurs.
* Added a new stream `SunmiScanner.onScannerStatusChanged()` to monitor the service connection status (`ScannerConnectionStatus`).
* Added `SunmiScannerModel` enum and `SunmiScanner.getScannerModelEnum()` method for type-safe model identification.

## 0.0.6

Update github repo

## 0.0.5

Documentation & Dependencies update

## 0.0.4

Documentation & Refactoring

## 0.0.3

Update pubspec

## 0.0.2

Update minSdkVersion -> 16

## 0.0.1

Implementation of basic functions, management of scanner calls