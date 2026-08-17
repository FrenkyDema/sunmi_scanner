package dev.francescodema.sunmi_scanner

import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.os.RemoteException
import android.util.Log
import android.view.KeyEvent
import android.widget.Toast
import com.sunmi.scanner.IScanInterface
import io.flutter.plugin.common.EventChannel

/**
 * Handles the connection to the Sunmi scanner service and forwards commands to it.
 *
 * @param context   the context
 * @param showToast whether to display Toasts on service connection events
 */
class SunmiScannerMethod(
    private val context: Context,
    private val showToast: Boolean
) {
    private var scannerService: IScanInterface? = null
    private var connectionEventSink: EventChannel.EventSink? = null

    private val connService: ServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            scannerService = IScanInterface.Stub.asInterface(service)
            if (scannerService != null) {
                if (showToast) {
                    Toast.makeText(
                        context,
                        "Connected to Sunmi scanner service",
                        Toast.LENGTH_LONG
                    ).show()
                }
                connectionEventSink?.success("CONNECTED")
            } else {
                if (showToast) {
                    Toast.makeText(
                        context,
                        "Failed to connect to Sunmi scanner service",
                        Toast.LENGTH_LONG
                    ).show()
                }
                connectionEventSink?.success("FAILED_TO_CONNECT")
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            scannerService = null
            if (showToast) {
                Toast.makeText(
                    context,
                    "Sunmi code service disconnected",
                    Toast.LENGTH_LONG
                ).show()
            }
            connectionEventSink?.success("DISCONNECTED")
        }
    }

    /**
     * Sets the event sink for broadcasting connection status.
     *
     * @param sink The EventSink from the EventChannel.
     */
    fun setConnectionEventSink(sink: EventChannel.EventSink?) {
        connectionEventSink = sink
    }

    /**
     * Connect scanner service.
     */
    fun connectScannerService() {
        val intent = Intent()
        intent.setPackage(SERVICE_PACKAGE)
        intent.action = SERVICE_ACTION
        try {
            context.applicationContext.startService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start scanner service", e)
        }
        context.applicationContext.bindService(intent, connService, Service.BIND_AUTO_CREATE)
    }

    /**
     * Disconnect scanner service.
     */
    fun disconnectScannerService() {
        if (scannerService != null) {
            try {
                context.applicationContext.unbindService(connService)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to unbind scanner service", e)
            }
            scannerService = null
        }
    }

    /**
     * Send key event.
     *
     * @param key the key
     * @throws RemoteException if service is not bound or remote call fails
     */
    @Throws(RemoteException::class)
    fun sendKeyEvent(key: KeyEvent) {
        val service = scannerService
            ?: throw RemoteException("Scanner service is not connected.")
        try {
            service.sendKeyEvent(key)
        } catch (e: RemoteException) {
            Log.e(TAG, "RemoteException while sending key event", e)
            throw e
        }
    }

    /**
     * Scan.
     *
     * @throws RemoteException if service is not bound or remote call fails
     */
    @Throws(RemoteException::class)
    fun scan() {
        val service = scannerService
            ?: throw RemoteException("Scanner service is not connected.")
        try {
            service.scan()
        } catch (e: RemoteException) {
            Log.e(TAG, "RemoteException while calling scan()", e)
            throw e
        }
    }

    /**
     * Stop.
     *
     * @throws RemoteException if service is not bound or remote call fails
     */
    @Throws(RemoteException::class)
    fun stop() {
        val service = scannerService
            ?: throw RemoteException("Scanner service is not connected.")
        try {
            service.stop()
        } catch (e: RemoteException) {
            Log.e(TAG, "RemoteException while calling stop()", e)
            throw e
        }
    }

    /**
     * Gets scanner model.
     *
     * @return the scanner model
     * @throws RemoteException if service is not bound or remote call fails
     */
    @Throws(RemoteException::class)
    fun getScannerModel(): Int {
        val service = scannerService
            ?: throw RemoteException("Scanner service is not connected.")
        try {
            return service.scannerModel
        } catch (e: RemoteException) {
            Log.e(TAG, "RemoteException while getting scanner model", e)
            throw e
        }
    }

    private companion object {
        const val TAG = "SunmiScannerMethod"
        const val SERVICE_PACKAGE = "com.sunmi.scanner"
        const val SERVICE_ACTION = "com.sunmi.scanner.IScanInterface"
    }
}
