package com.example.app_iot

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.nio.charset.StandardCharsets
import java.util.UUID
import java.util.concurrent.Executors
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    companion object {
        private const val BLUETOOTH_CHANNEL = "app_iot/bluetooth"
        private const val RFCOMM_EVENTS_CHANNEL = "app_iot/rfcomm_events"
        private const val REQUEST_BLUETOOTH_CONNECT = 1001
        private val SPP_UUID: UUID =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val rfcommLock = Any()

    private var pendingBluetoothResult: MethodChannel.Result? = null
    private var rfcommSocket: BluetoothSocket? = null
    private var rfcommInput: InputStream? = null
    private var rfcommOutput: OutputStream? = null
    private var rfcommReaderThread: Thread? = null
    private var rfcommEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLUETOOTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBluetoothEnabled" -> result.success(isBluetoothEnabled())
                    "requestEnableBluetooth" -> requestEnableBluetooth(result)
                    "connectRfcommChannel" -> {
                        val address = call.argument<String>("address")
                        val channel = call.argument<Int>("channel") ?: 4

                        if (address.isNullOrBlank()) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Bluetooth address is required.",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        connectRfcommChannel(address, channel, result)
                    }
                    "writeRfcomm" -> {
                        val message = call.argument<String>("message")
                        writeRfcomm(message, result)
                    }
                    "disconnectRfcomm" -> disconnectRfcomm(result)
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, RFCOMM_EVENTS_CHANNEL)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                        rfcommEventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        rfcommEventSink = null
                    }
                },
            )
    }

    override fun onDestroy() {
        closeRfcommConnection(notifyDisconnect = false)
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun bluetoothAdapter(): BluetoothAdapter? {
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as? BluetoothManager
        return bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
    }

    private fun isBluetoothEnabled(): Boolean {
        val adapter = bluetoothAdapter() ?: return false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }

        return adapter.isEnabled
    }

    private fun requestEnableBluetooth(result: MethodChannel.Result) {
        val adapter = bluetoothAdapter()

        if (adapter == null) {
            result.error("UNAVAILABLE", "Bluetooth is not supported on this device.", null)
            return
        }

        if (adapter.isEnabled) {
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingBluetoothResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.BLUETOOTH_CONNECT),
                REQUEST_BLUETOOTH_CONNECT,
            )
            return
        }

        startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
        result.success(true)
    }

    private fun connectRfcommChannel(
        address: String,
        channel: Int,
        result: MethodChannel.Result,
    ) {
        val adapter = bluetoothAdapter()

        if (adapter == null) {
            result.error("UNAVAILABLE", "Bluetooth is not supported on this device.", null)
            return
        }

        if (!hasBluetoothConnectPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Bluetooth connect permission was denied.",
                null,
            )
            return
        }

        if (!adapter.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled.", null)
            return
        }

        ioExecutor.execute {
            closeRfcommConnection(notifyDisconnect = false)

            try {
                runCatching { adapter.cancelDiscovery() }

                val device = adapter.getRemoteDevice(address)
                val socket = connectWithFallback(device, channel)
                val input = socket.inputStream
                val output = socket.outputStream

                synchronized(rfcommLock) {
                    rfcommSocket = socket
                    rfcommInput = input
                    rfcommOutput = output
                }

                startRfcommReader(socket, input)
                postSuccess(result, true)
            } catch (error: Throwable) {
                closeRfcommConnection(notifyDisconnect = false)
                postError(
                    result,
                    "RFCOMM_CONNECT_FAILED",
                    error.message ?: "Unable to connect RFCOMM socket.",
                )
            }
        }
    }

    private fun connectWithFallback(device: BluetoothDevice, channel: Int): BluetoothSocket {
        val attempts = listOf(
            { createChannelSocket(device, channel) },
            { device.createRfcommSocketToServiceRecord(SPP_UUID) },
            { device.createInsecureRfcommSocketToServiceRecord(SPP_UUID) },
        )

        var lastError: Throwable? = null

        for (factory in attempts) {
            var socket: BluetoothSocket? = null
            try {
                socket = factory.invoke()
                socket.connect()
                return socket
            } catch (error: Throwable) {
                lastError = error
                runCatching { socket?.close() }
            }
        }

        throw IOException(lastError?.message ?: "Unable to connect RFCOMM socket.")
    }

    private fun createChannelSocket(device: BluetoothDevice, channel: Int): BluetoothSocket {
        val method = device.javaClass.getMethod(
            "createRfcommSocket",
            Int::class.javaPrimitiveType,
        )

        val socket = method.invoke(device, channel)
        require(socket is BluetoothSocket) {
            "RFCOMM reflection did not return a BluetoothSocket."
        }

        return socket
    }

    private fun startRfcommReader(socket: BluetoothSocket, input: InputStream) {
        synchronized(rfcommLock) {
            if (Thread.currentThread() != rfcommReaderThread) {
                rfcommReaderThread?.interrupt()
            }

            rfcommReaderThread = thread(
                start = true,
                name = "RfcommReader",
            ) {
                val buffer = ByteArray(1024)

                try {
                    while (!Thread.currentThread().isInterrupted) {
                        val count = input.read(buffer)

                        if (count < 0) {
                            break
                        }

                        if (count == 0) {
                            continue
                        }

                        val payload = String(buffer, 0, count, StandardCharsets.UTF_8)
                        postRfcommEvent(mapOf("type" to "data", "data" to payload))
                    }

                    postRfcommEvent(mapOf("type" to "disconnected"))
                } catch (error: IOException) {
                    if (!Thread.currentThread().isInterrupted) {
                        postRfcommEvent(
                            mapOf(
                                "type" to "error",
                                "message" to (error.message ?: "RFCOMM connection lost."),
                            ),
                        )
                    }
                } finally {
                    closeRfcommConnection(notifyDisconnect = false)
                    runCatching { socket.close() }
                }
            }
        }
    }

    private fun writeRfcomm(message: String?, result: MethodChannel.Result) {
        if (message == null) {
            result.error("INVALID_ARGUMENT", "Message is required.", null)
            return
        }

        val output = synchronized(rfcommLock) { rfcommOutput }
        if (output == null) {
            result.error("NOT_CONNECTED", "RFCOMM socket is not connected.", null)
            return
        }

        ioExecutor.execute {
            try {
                output.write(message.toByteArray(StandardCharsets.UTF_8))
                output.flush()
                postSuccess(result, true)
            } catch (error: Throwable) {
                postError(
                    result,
                    "WRITE_FAILED",
                    error.message ?: "Unable to write RFCOMM payload.",
                )
            }
        }
    }

    private fun disconnectRfcomm(result: MethodChannel.Result) {
        ioExecutor.execute {
            closeRfcommConnection(notifyDisconnect = true)
            postSuccess(result, true)
        }
    }

    private fun closeRfcommConnection(notifyDisconnect: Boolean) {
        val socket: BluetoothSocket?
        val input: InputStream?
        val output: OutputStream?
        val reader: Thread?

        synchronized(rfcommLock) {
            socket = rfcommSocket
            input = rfcommInput
            output = rfcommOutput
            reader = rfcommReaderThread

            rfcommSocket = null
            rfcommInput = null
            rfcommOutput = null
            rfcommReaderThread = null
        }

        if (Thread.currentThread() != reader) {
            reader?.interrupt()
        }

        runCatching { input?.close() }
        runCatching { output?.close() }
        runCatching { socket?.close() }

        if (notifyDisconnect) {
            postRfcommEvent(mapOf("type" to "disconnected"))
        }
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED
    }

    private fun postRfcommEvent(event: Map<String, Any>) {
        mainHandler.post {
            rfcommEventSink?.success(event)
        }
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post { result.error(code, message, null) }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != REQUEST_BLUETOOTH_CONNECT) return

        val result = pendingBluetoothResult ?: return
        pendingBluetoothResult = null

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            result.error(
                "PERMISSION_DENIED",
                "Bluetooth connect permission was denied.",
                null,
            )
            return
        }

        requestEnableBluetooth(result)
    }
}
