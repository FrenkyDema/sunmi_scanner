package dev.francescodema.sunmi_scanner

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify

/**
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */
class SunmiScannerPluginTest {
    @Test
    fun onMethodCall_withoutBoundService_returnsNotBoundError() {
        val plugin = SunmiScannerPlugin()

        val call = MethodCall("SCAN", null)
        val mockResult = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(
            "NOT_BOUND",
            "Scanner service is not bound. Call bindService() first.",
            null
        )
    }

    @Test
    fun onMethodCall_unbindServiceWithoutBind_succeeds() {
        val plugin = SunmiScannerPlugin()

        val call = MethodCall("unbindService", null)
        val mockResult = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(null)
    }
    @Test
    fun onMethodCall_getUsbDevicesWithoutEngine_returnsNotAttachedError() {
        val plugin = SunmiScannerPlugin()

        val call = MethodCall("GET_USB_DEVICES", null)
        val mockResult = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(
            "NOT_ATTACHED",
            "The plugin is not attached to a Flutter engine.",
            null
        )
    }

    @Test
    fun onMethodCall_setUsbScannerOutputWithoutType_returnsInvalidArgument() {
        val plugin = SunmiScannerPlugin()

        val call = MethodCall(
            "SET_USB_SCANNER_OUTPUT",
            mapOf("name" to "SM-2D PRODUCT DEFHID+KBW", "pid" to 275, "vid" to 12879)
        )
        val mockResult = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(
            "INVALID_ARGUMENT",
            "Arguments 'name', 'pid', 'vid' and 'type' must not be null.",
            null
        )
    }

    @Test
    fun onMethodCall_setUsbScannerOutputWithoutEngine_returnsNotAttachedError() {
        val plugin = SunmiScannerPlugin()

        val call = MethodCall(
            "SET_USB_SCANNER_OUTPUT",
            mapOf(
                "name" to "SM-2D PRODUCT DEFHID+KBW",
                "pid" to 275,
                "vid" to 12879,
                "type" to 2,
                "toast" to false
            )
        )
        val mockResult = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(
            "NOT_ATTACHED",
            "The plugin is not attached to a Flutter engine.",
            null
        )
    }
}
