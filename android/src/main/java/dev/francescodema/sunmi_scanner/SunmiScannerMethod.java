package dev.francescodema.sunmi_scanner;

import android.app.Service;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.RemoteException;
import android.view.KeyEvent;
import android.widget.Toast;

import com.sunmi.scanner.IScanInterface;

import io.flutter.plugin.common.EventChannel;

/**
 * The type Sunmi scanner method.
 */
public class SunmiScannerMethod {
    private static final String SERVICE_PACKAGE = "com.sunmi.scanner";
    private static final String SERVICE_ACTION = "com.sunmi.scanner.IScanInterface";
    private IScanInterface scannerService;
    private final ServiceConnection connService;
    private final Context _context;
    private final boolean _showToast;
    private EventChannel.EventSink connectionEventSink;


    /**
     * Instantiates a new Sunmi scanner method.
     *
     * @param _context  the context
     * @param showToast whether to display Toasts on service connection events
     */
    public SunmiScannerMethod(Context _context, boolean showToast) {
        this._context = _context;
        this._showToast = showToast;
        connService = new ServiceConnection() {

            @Override
            public void onServiceConnected(ComponentName name, IBinder service) {
                scannerService = IScanInterface.Stub.asInterface(service);
                if (scannerService != null) {
                    if (_showToast) {
                        Toast.makeText(
                                _context,
                                "Connected to Sunmi scanner service",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                    if (connectionEventSink != null) {
                        connectionEventSink.success("CONNECTED");
                    }
                } else {
                    if (_showToast) {
                        Toast.makeText(
                                _context,
                                "Failed to connect to Sunmi scanner service",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                    if (connectionEventSink != null) {
                        connectionEventSink.success("FAILED_TO_CONNECT");
                    }
                }
            }

            @Override
            public void onServiceDisconnected(ComponentName name) {
                scannerService = null;
                if (_showToast) {
                    Toast.makeText(
                            _context,
                            "Sunmi code service disconnected",
                            Toast.LENGTH_LONG
                    ).show();
                }
                if (connectionEventSink != null) {
                    connectionEventSink.success("DISCONNECTED");
                }
            }
        };
    }

    /**
     * Sets the event sink for broadcasting connection status.
     *
     * @param sink The EventSink from the EventChannel.
     */
    public void setConnectionEventSink(EventChannel.EventSink sink) {
        this.connectionEventSink = sink;
    }


    /**
     * Connect scanner service.
     */
    public void connectScannerService() {
        Intent intent = new Intent();
        intent.setPackage(SERVICE_PACKAGE);
        intent.setAction(SERVICE_ACTION);
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
     * @throws RemoteException if service is not bound or remote call fails
     */
    public void sendKeyEvent(KeyEvent key) throws RemoteException {
        if (scannerService == null) {
            throw new RemoteException("Scanner service is not connected.");
        }
        try {
            scannerService.sendKeyEvent(key);
        } catch (RemoteException e) {
            e.printStackTrace();
            throw e;
        }
    }


    /**
     * Scan.
     *
     * @throws RemoteException if service is not bound or remote call fails
     */
    public void scan() throws RemoteException {
        if (scannerService == null) {
            throw new RemoteException("Scanner service is not connected.");
        }
        try {
            scannerService.scan();
        } catch (RemoteException e) {
            e.printStackTrace();
            throw e;
        }
    }

    /**
     * Stop.
     *
     * @throws RemoteException if service is not bound or remote call fails
     */
    public void stop() throws RemoteException {
        if (scannerService == null) {
            throw new RemoteException("Scanner service is not connected.");
        }
        try {
            scannerService.stop();
        } catch (RemoteException e) {
            e.printStackTrace();
            throw e;
        }
    }

    /**
     * Gets scanner model.
     *
     * @return the scanner model
     * @throws RemoteException if service is not bound or remote call fails
     */
    public int getScannerModel() throws RemoteException {
        if (scannerService == null) {
            throw new RemoteException("Scanner service is not connected.");
        }
        try {
            return scannerService.getScannerModel();
        } catch (RemoteException e) {
            e.printStackTrace();
            throw e;
        }
    }
}