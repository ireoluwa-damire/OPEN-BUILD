package com.example.sumi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.os.Build
import android.os.StatFs

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sumi/device")
            .setMethodCallHandler { call, result ->
                if (call.method != "capabilities") {
                    result.notImplemented()
                } else {
                    val activity = getSystemService(ACTIVITY_SERVICE) as ActivityManager
                    val memory = ActivityManager.MemoryInfo()
                    activity.getMemoryInfo(memory)
                    result.success(mapOf(
                        "abis" to Build.SUPPORTED_ABIS.toList(),
                        "ram_total_bytes" to memory.totalMem,
                        "ram_available_bytes" to memory.availMem,
                        "low_ram" to activity.isLowRamDevice,
                        "storage_free_bytes" to StatFs(filesDir.absolutePath).availableBytes
                    ))
                }
            }
    }
}
