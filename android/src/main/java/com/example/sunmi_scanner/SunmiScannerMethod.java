package com.example.sunmi_scanner;

import android.app.Service;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteException;
import android.view.KeyEvent;
import android.widget.Toast;
import com.sunmi.scanner.IScanInterface;

/**
 * The type Sunmi scanner method.
 */
public class SunmiScannerMethod {
    private static final String SERVICE＿PACKAGE = "com.sunmi.scanner";
    private static final String SERVICE＿ACTION = "com.sunmi.scanner.IScanInterface";
    private IScanInterface scannerService;
    private final ServiceConnection connService;
    private final Context _context;


    /**
     * Instantiates a new Sunmi scanner method.
     *
     * @param _context the context
     */
    public SunmiScannerMethod(Context _context) {
        this._context = _context;
        connService = new ServiceConnection() {

            @Override
            public void onServiceConnected(ComponentName name, IBinder service) {
                scannerService = IScanInterface.Stub.asInterface(service);
                if (scannerService != null) {
                    new Thread(() -> {
                        Looper.prepare();
                        Toast.makeText(
                                _context,
                                "Connected to Sunmi scanner service",
                                Toast.LENGTH_LONG
                        ).show();
                        Looper.loop();
                        Looper.myLooper().quitSafely();
                    }).start();


                } else {
                    new Thread(() -> {
                        Toast.makeText(
                                _context,
                                "Failed to connect to Sunmi scanner service",
                                Toast.LENGTH_LONG
                        ).show();
                        Looper.loop();
                        Looper.myLooper().quitSafely();
                    }).start();
                }
            }

            @Override
            public void onServiceDisconnected(ComponentName name) {
                scannerService = null;
                new Thread(() -> {
                    Looper.prepare();
                    Toast.makeText(
                            _context,
                            "Sunmi code service disconnected " + this.hashCode(),
                            Toast.LENGTH_LONG
                    ).show();
                    Looper.loop();
                    Looper.myLooper().quitSafely();
                }).start();
            }
        };
    }


    /**
     * Connect scanner service.
     */
    public void connectScannerService() {
        Intent intent = new Intent();
        intent.setPackage(SERVICE＿PACKAGE);
        intent.setAction(SERVICE＿ACTION);
        _context.getApplicationContext().bindService(intent, connService, Service.BIND_AUTO_CREATE);
    }

    /**
     * Disconnect scanner service.
     */
    public void disconnectScannerService() {
        if (scannerService != null) {
            _context.getApplicationContext().unbindService(connService);
            scannerService = null;
        }
    }


    /**
     * Send key event.
     *
     * @param key the key
     */
    public void sendKeyEvent(KeyEvent key) {
        if (scannerService == null) return;
        try {
            scannerService.sendKeyEvent(key);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }


    /**
     * Scan.
     */
    public void scan() {
        if (scannerService == null) return;
        try {
            scannerService.scan();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    /**
     * Stop.
     */
    public void stop() {
        if (scannerService == null) return;
        try {
            scannerService.stop();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    /**
     * Gets scanner model.
     *
     * @return the scanner model
     */
    public int getScannerModel() {
        if (scannerService == null) return 0;
        try {
            return scannerService.getScannerModel();
        } catch (RemoteException e) {
            e.printStackTrace();
        }
        return 0;
    }
}
