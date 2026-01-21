package dev.francescodema.sunmi_scanner;


import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.RemoteException;
import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


/**
 * The type Sunmi scanner plugin.
 */
public class SunmiScannerPlugin implements FlutterPlugin, MethodCallHandler, StreamHandler {
    private BroadcastReceiver scannerServiceReceiver;
    private SunmiScannerMethod sunmiScannerMethod;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;

    private EventChannel connectionEventChannel;
    private EventChannel.EventSink connectionEventSink;
    private Context context;

    /**
     * On attached to engine.
     *
     * @param flutterPluginBinding the flutter plugin binding
     */
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sunmi_scanner");
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sunmi_scanner_events");
        connectionEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sunmi_scanner_connection_events");

        eventChannel.setStreamHandler(this);
        methodChannel.setMethodCallHandler(this);

        connectionEventChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                connectionEventSink = events;
                if (sunmiScannerMethod != null) {
                    sunmiScannerMethod.setConnectionEventSink(connectionEventSink);
                }
            }

            @Override
            public void onCancel(Object arguments) {
                connectionEventSink = null;
                if (sunmiScannerMethod != null) {
                    sunmiScannerMethod.setConnectionEventSink(null);
                }
            }
        });
    }

    /**
     * On method call.
     *
     * @param call   the call
     * @param result the result
     */
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.wtf("Method:", call.method);

        if (call.method.equals("bindService")) {
            Boolean showToastArg = call.argument("showToast");
            boolean showToast = (showToastArg != null) ? showToastArg : true;
            if (sunmiScannerMethod == null) {
                sunmiScannerMethod = new SunmiScannerMethod(context, showToast);
                if (connectionEventSink != null) {
                    sunmiScannerMethod.setConnectionEventSink(connectionEventSink);
                }
            }
            sunmiScannerMethod.connectScannerService();
            result.success(null);
            return;
        }

        if (call.method.equals("unbindService")) {
            if (sunmiScannerMethod != null) {
                sunmiScannerMethod.disconnectScannerService();
                sunmiScannerMethod = null;
            }
            result.success(null);
            return;
        }

        if (sunmiScannerMethod == null) {
            result.error("NOT_BOUND", "Scanner service is not bound. Call bindService() first.", null);
            return;
        }

        try {
            switch (call.method) {
                case "SCAN":
                    sunmiScannerMethod.scan();
                    result.success(null);
                    break;

                case "STOP":
                    sunmiScannerMethod.stop();
                    result.success(null);
                    break;

                case "GET_MODEL":
                    int model = sunmiScannerMethod.getScannerModel();
                    result.success(model);
                    break;

                case "SEND_KEY_EVENT":
                    int action = call.argument("key");
                    int code = call.argument("code");
                    sunmiScannerMethod.sendKeyEvent(new KeyEvent(action, code));
                    result.success(null);
                    break;

                default: {
                    result.notImplemented();
                    break;
                }
            }
        } catch (RemoteException e) {
            result.error("SERVICE_ERROR", "A remote exception occurred: " + e.getMessage(), e.toString());
        }
    }


    /**
     * On listen.
     *
     * @param arguments the arguments
     * @param events    the events
     */
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    @Override
    public void onListen(Object arguments, EventSink events) {
        scannerServiceReceiver = createScannerServiceReceiver(events);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(scannerServiceReceiver, new IntentFilter("com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED"), Context.RECEIVER_NOT_EXPORTED);
        } else {
            context.registerReceiver(scannerServiceReceiver, new IntentFilter("com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED"));
        }
    }

    /**
     * On cancel.
     *
     * @param arguments the arguments
     */
    @Override
    public void onCancel(Object arguments) {
        if (scannerServiceReceiver != null) {
            try {
                context.unregisterReceiver(scannerServiceReceiver);
            } catch (Exception e) {
                e.printStackTrace();
            }
            scannerServiceReceiver = null;
        }
    }

    /**
     * Create scanner service receiver from event sink.
     *
     * @param events the event sink
     * @return BroadcastReceiver
     */
    private BroadcastReceiver createScannerServiceReceiver(final EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String data = intent.getStringExtra("data");
                events.success(data);
            }
        };
    }

    /**
     * On detached from engine.
     *
     * @param binding the binding
     */
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        onCancel(null);
        if (sunmiScannerMethod != null) {
            sunmiScannerMethod.disconnectScannerService();
            sunmiScannerMethod = null;
        }
        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        eventChannel.setStreamHandler(null);
        eventChannel = null;
        connectionEventChannel.setStreamHandler(null);
        connectionEventChannel = null;
    }
}