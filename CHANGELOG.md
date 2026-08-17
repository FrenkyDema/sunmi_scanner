# CHANGELOG

## 0.0.8

* Migrates the Android implementation from Java to Kotlin, compiled with AGP's built-in Kotlin
  support (no longer applies the Kotlin Gradle Plugin), for compatibility with AGP 9+.
* Updates the minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Updates the example app to AGP 9.0.1, Gradle 9.1.0, and `android.builtInKotlin=true`.

## 0.0.7

* **BREAKING CHANGE:** You must now call `SunmiScanner.bindService()` before using any scanner
  methods.
* Added `SunmiScanner.bindService()` and `SunmiScanner.unbindService()` for manual control over the
  service lifecycle.
* The service connection toast is now optional and can be disabled via
  `bindService(showToast: false)`.
* Improved error handling. Methods now throw a `PlatformException` if the service is not bound or a
  `RemoteException` occurs.
* Added a new stream `SunmiScanner.onScannerStatusChanged()` to monitor the service connection
  status (`ScannerConnectionStatus`).
* Added `SunmiScannerModel` enum and `SunmiScanner.getScannerModelEnum()` method for type-safe model
  identification.
* Make `isScannerAvailable()` return false when the platform channel throws, instead of propagating
    the exception.
* Adjust Android scanner integration (receiver export flag; attempt to start the scanner service
  before binding).
* Bump example lockfile SDK/dependency versions and update GitHub Actions workflow action versions.
* Updated some Gradle config by the flutter migrator.
* Better logs

## 0.0.6

Update GitHub repo

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