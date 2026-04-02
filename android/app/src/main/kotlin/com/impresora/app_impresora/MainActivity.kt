package com.impresora.app_impresora

import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.impresora.app_impresora/bluetooth"
    private val BLUETOOTH_REQUEST_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> {
                    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                    val isEnabled = bluetoothAdapter?.isEnabled ?: false
                    result.success(isEnabled)
                }
                "enableBluetooth" -> {
                    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                    if (bluetoothAdapter != null && !bluetoothAdapter.isEnabled) {
                        val enableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                        startActivityForResult(enableIntent, BLUETOOTH_REQUEST_CODE)
                        result.success(true)
                    } else {
                        result.success(bluetoothAdapter?.isEnabled ?: false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == BLUETOOTH_REQUEST_CODE) {
            // El usuario decidió sobre el bluetooth
            debug("Bluetooth enable dialog closed")
        }
    }

    private fun debug(message: String) {
        android.util.Log.d("BluetoothPlugin", message)
    }
}