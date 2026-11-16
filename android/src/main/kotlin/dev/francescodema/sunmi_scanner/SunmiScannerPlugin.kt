package dev.francescodema.sunmi_scanner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbManager
import android.os.RemoteException
import android.util.Log
import android.view.KeyEvent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/**
 * The Sunmi scanner plugin.
 */
class SunmiScannerPlugin : FlutterPlugin, MethodCallHandler, StreamHandler {
    private var scannerServiceReceiver: BroadcastReceiver? = null
    private var sunmiScannerMethod: SunmiScannerMethod? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private var connectionEventChannel: EventChannel? = null
    private var connectionEventSink: EventSink? = null
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "sunmi_scanner")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "sunmi_scanner_events")
        connectionEventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "sunmi_scanner_connection_events")

        eventChannel?.setStreamHandler(this)
        methodChannel?.setMethodCallHandler(this)

        connectionEventChannel?.setStreamHandler(object : StreamHandler {
            override fun onListen(arguments: Any?, events: EventSink?) {
                connectionEventSink = events
                sunmiScannerMethod?.setConnectionEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                connectionEventSink = null
                sunmiScannerMethod?.setConnectionEventSink(null)
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Method called: ${call.method}")

        if (call.method == "bindService") {
            val showToast = call.argument<Boolean>("showToast") ?: true
            if (sunmiScannerMethod == null) {
                sunmiScannerMethod = SunmiScannerMethod(requireNotNull(context), showToast).also {
                    if (connectionEventSink != null) {
                        it.setConnectionEventSink(connectionEventSink)
                    }
                }
            }
            sunmiScannerMethod?.connectScannerService()
            result.success(null)
            return
        }

        if (call.method == "unbindService") {
            sunmiScannerMethod?.disconnectScannerService()
            sunmiScannerMethod = null
            result.success(null)
            return
        }

        // The USB scanner methods talk to Android and to the Sunmi scanner
        // service through broadcasts: they do not need bindService().
        if (call.method == "GET_USB_DEVICES") {
            val ctx = context ?: return notAttached(result)
            val manager = ctx.getSystemService(Context.USB_SERVICE) as? UsbManager
            val devices = manager?.deviceList?.values.orEmpty().map {
                mapOf(
                    "name" to it.productName,
                    "vendorId" to it.vendorId,
                    "productId" to it.productId,
                )
            }
            result.success(devices)
            return
        }

        if (call.method == "SET_USB_SCANNER_OUTPUT") {
            val name = call.argument<String>("name")
            val pid = call.argument<Int>("pid")
            val vid = call.argument<Int>("vid")
            val type = call.argument<Int>("type")
            if (name == null || pid == null || vid == null || type == null) {
                result.error(
                    "INVALID_ARGUMENT",
                    "Arguments 'name', 'pid', 'vid' and 'type' must not be null.",
                    null
                )
                return
            }
            val ctx = context ?: return notAttached(result)
            // Sunmi "Barcode Scanner User Guide": the scanner service keeps
            // the output mode of each USB scanner (0 keyboard, 1 KeyEvent,
            // 2 broadcast, 3 fill at once).
            val intent = Intent(ACTION_BAR_DEVICES_SETTING)
                .setPackage(SCANNER_SERVICE_PACKAGE)
                .putExtra("name", name)
                .putExtra("pid", pid)
                .putExtra("vid", vid)
                .putExtra("type", type)
                .putExtra("toast", call.argument<Boolean>("toast") ?: false)
            ctx.sendBroadcast(intent)
            result.success(null)
            return
        }

        val scannerMethod = sunmiScannerMethod
        if (scannerMethod == null) {
            result.error("NOT_BOUND", "Scanner service is not bound. Call bindService() first.", null)
            return
        }

        try {
            when (call.method) {
                "SCAN" -> {
                    scannerMethod.scan()
                    result.success(null)
                }

                "STOP" -> {
                    scannerMethod.stop()
                    result.success(null)
                }

                "GET_MODEL" -> {
                    result.success(scannerMethod.getScannerModel())
                }

                "SEND_KEY_EVENT" -> {
                    val action = call.argument<Int>("key")
                    val code = call.argument<Int>("code")

                    if (action == null || code == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "Arguments 'key' and 'code' must not be null.",
                            null
                        )
                        return
                    }

                    scannerMethod.sendKeyEvent(KeyEvent(action, code))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (e: RemoteException) {
            Log.e(TAG, "Remote exception during method call: ${call.method}", e)
            result.error("SERVICE_ERROR", "A remote exception occurred: ${e.message}", e.toString())
        }
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        val receiver = createScannerServiceReceiver(events)
        scannerServiceReceiver = receiver

        // Use ContextCompat to securely register the receiver and handle the RECEIVER_EXPORTED lint warning natively
        context?.let {
            ContextCompat.registerReceiver(
                it,
                receiver,
                IntentFilter("com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED"),
                ContextCompat.RECEIVER_EXPORTED
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        scannerServiceReceiver?.let { receiver ->
            try {
                context?.unregisterReceiver(receiver)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to unregister scanner service receiver", e)
            }
            scannerServiceReceiver = null
        }
    }

    private fun createScannerServiceReceiver(events: EventSink?): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val data = intent.getStringExtra("data")
                if (!data.isNullOrEmpty()) events?.success(data)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onCancel(null)
        sunmiScannerMethod?.disconnectScannerService()
        sunmiScannerMethod = null
        context = null
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        connectionEventChannel?.setStreamHandler(null)
        connectionEventChannel = null
    }

    private fun notAttached(result: MethodChannel.Result) {
        result.error("NOT_ATTACHED", "The plugin is not attached to a Flutter engine.", null)
    }

    private companion object {
        const val TAG = "SunmiScannerPlugin"
        const val SCANNER_SERVICE_PACKAGE = "com.sunmi.scanner"
        const val ACTION_BAR_DEVICES_SETTING = "com.sunmi.scanner.ACTION_BAR_DEVICES_SETTING"
    }
}
