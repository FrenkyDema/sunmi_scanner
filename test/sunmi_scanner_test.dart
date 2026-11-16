import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunmi_scanner/sunmi_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('sunmi_scanner');
  final List<MethodCall> log = <MethodCall>[];
  Object? response;

  setUp(() {
    log.clear();
    response = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          log.add(call);
          final Object? currentResponse = response;
          if (currentResponse is PlatformException) {
            throw currentResponse;
          }
          return currentResponse;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('service binding', () {
    test('bindService shows toast by default', () async {
      await SunmiScanner.bindService();

      expect(log, hasLength(1));
      expect(log.single.method, 'bindService');
      expect(log.single.arguments, {'showToast': true});
    });

    test('bindService forwards showToast: false', () async {
      await SunmiScanner.bindService(showToast: false);

      expect(log.single.method, 'bindService');
      expect(log.single.arguments, {'showToast': false});
    });

    test('unbindService invokes the channel', () async {
      await SunmiScanner.unbindService();

      expect(log.single.method, 'unbindService');
      expect(log.single.arguments, isNull);
    });
  });

  group('scanner commands', () {
    test('scan invokes SCAN', () async {
      SunmiScanner.scan();
      await Future<void>.delayed(Duration.zero);

      expect(log.single.method, 'SCAN');
    });

    test('stop invokes STOP', () async {
      SunmiScanner.stop();
      await Future<void>.delayed(Duration.zero);

      expect(log.single.method, 'STOP');
    });

    test('sendKeyEvent forwards action index and key code', () async {
      SunmiScanner.sendKeyEvent(KeyAction.actionUp, 42);
      await Future<void>.delayed(Duration.zero);

      expect(log.single.method, 'SEND_KEY_EVENT');
      expect(log.single.arguments, {
        'key': KeyAction.actionUp.index,
        'code': 42,
      });
    });
  });

  group('scanner model', () {
    test('getScannerModel returns the raw model code', () async {
      response = 101;

      expect(await SunmiScanner.getScannerModel(), 101);
      expect(log.single.method, 'GET_MODEL');
    });

    test('getScannerModelEnum maps every known model code', () async {
      const Map<int, SunmiScannerModel> expected = {
        100: SunmiScannerModel.none,
        101: SunmiScannerModel.p2LiteV2ProP2Pro,
        102: SunmiScannerModel.l2Newland,
        103: SunmiScannerModel.l2ZebraSe4710,
        104: SunmiScannerModel.l2HoneywellN3601,
        105: SunmiScannerModel.l2HoneywellN6603,
        106: SunmiScannerModel.l2ZebraSe4750,
        107: SunmiScannerModel.l2ZebraEm1350,
        999: SunmiScannerModel.unknown,
      };

      for (final MapEntry<int, SunmiScannerModel> entry in expected.entries) {
        response = entry.key;
        expect(
          await SunmiScanner.getScannerModelEnum(),
          entry.value,
          reason: 'model code ${entry.key}',
        );
      }
    });

    test('isScannerAvailable is true for a real scanner', () async {
      response = 101;

      expect(await SunmiScanner.isScannerAvailable(), isTrue);
    });

    test('isScannerAvailable is false when no scanner is present', () async {
      response = 100;

      expect(await SunmiScanner.isScannerAvailable(), isFalse);
    });

    test('isScannerAvailable is false when the channel throws', () async {
      response = PlatformException(
        code: 'NOT_BOUND',
        message: 'Scanner service is not bound. Call bindService() first.',
      );

      expect(await SunmiScanner.isScannerAvailable(), isFalse);
    });
  });

  group('usb scanners', () {
    test('getUsbDevices reads name, vendor and product ids', () async {
      response = <Object?>[
        <Object?, Object?>{
          'name': 'SM-2D PRODUCT DEFHID+KBW',
          'vendorId': 0x324F,
          'productId': 0x0113,
        },
        <Object?, Object?>{'name': null, 'vendorId': 0x0424, 'productId': 1},
      ];

      final List<SunmiUsbDevice> devices = await SunmiScanner.getUsbDevices();

      expect(log.single.method, 'GET_USB_DEVICES');
      expect(devices, hasLength(2));
      expect(devices.first.name, 'SM-2D PRODUCT DEFHID+KBW');
      expect(devices.first.vendorId, 0x324F);
      expect(devices.first.productId, 0x0113);
      expect(devices.last.name, '');
    });

    test('getUsbDevices is empty when the platform returns nothing', () async {
      response = null;

      expect(await SunmiScanner.getUsbDevices(), isEmpty);
    });

    test(
      'setUsbScannerOutput forwards the device and the output code',
      () async {
        const SunmiUsbDevice reader = SunmiUsbDevice(
          name: 'SM-2D PRODUCT DEFHID+KBW',
          vendorId: 0x324F,
          productId: 0x0113,
        );

        await SunmiScanner.setUsbScannerOutput(
          reader,
          SunmiScannerOutput.broadcast,
        );

        expect(log.single.method, 'SET_USB_SCANNER_OUTPUT');
        expect(log.single.arguments, {
          'name': 'SM-2D PRODUCT DEFHID+KBW',
          'pid': 0x0113,
          'vid': 0x324F,
          'type': 2,
          'toast': false,
        });
      },
    );

    test('every output has the code of the Sunmi guide', () {
      expect(SunmiScannerOutput.keyboard.code, 0);
      expect(SunmiScannerOutput.keyEvent.code, 1);
      expect(SunmiScannerOutput.broadcast.code, 2);
      expect(SunmiScannerOutput.fillAtOnce.code, 3);
    });
  });

  group('event streams', () {
    // onBarcodeScanned() caches its stream, and a closed broadcast stream
    // cannot be listened to again: every barcode case lives in this test.
    test('onBarcodeScanned emits barcodes and skips empty events', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            const EventChannel('sunmi_scanner_events'),
            MockStreamHandler.inline(
              onListen: (Object? arguments, MockStreamHandlerEventSink events) {
                events.success('4006381333931');
                events.success(null);
                events.success('');
                events.success('U-527845\n');
                events.endOfStream();
              },
            ),
          );

      expect(await SunmiScanner.onBarcodeScanned().toList(), [
        '4006381333931',
        'U-527845\n',
      ]);
    });

    test('onScannerStatusChanged maps native status strings', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            const EventChannel('sunmi_scanner_connection_events'),
            MockStreamHandler.inline(
              onListen: (Object? arguments, MockStreamHandlerEventSink events) {
                events.success('CONNECTED');
                events.success('DISCONNECTED');
                events.success('FAILED_TO_CONNECT');
                events.success('SOMETHING_UNEXPECTED');
                events.endOfStream();
              },
            ),
          );

      expect(await SunmiScanner.onScannerStatusChanged().take(4).toList(), [
        ScannerConnectionStatus.connected,
        ScannerConnectionStatus.disconnected,
        ScannerConnectionStatus.failedToConnect,
        ScannerConnectionStatus.disconnected,
      ]);
    });
  });
}
