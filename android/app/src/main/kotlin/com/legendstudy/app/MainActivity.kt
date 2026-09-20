package com.legendstudy.app

import android.os.SystemClock
import android.provider.Settings
import android.util.AtomicFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var mockNotifications: MockNotificationBridge? = null
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        mockNotifications?.permissionResult(requestCode)
    }
    companion object {
        // Without boot metadata, continuity is proven only within this process.
        private val processClockIdentity = "process:" + UUID.randomUUID().toString()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.legendstudy.app/info")
            .setMethodCallHandler { call, result ->
                if (call.method != "version") { result.notImplemented() } else {
                    try {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val build = if (android.os.Build.VERSION.SDK_INT >= 28) info.longVersionCode else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        result.success(mapOf("version" to info.versionName, "build" to build.toString()))
                    } catch (_: Exception) { result.error("unavailable", "App information unavailable", null) }
                }
            }
        mockNotifications = MockNotificationBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        StudyFocusBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        val store = AtomicFile(File(filesDir, "study-state-v1.json"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.legendstudy.app/study")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "clock" -> {
                            val boot = try { Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT).toString() }
                                catch (_: Exception) { processClockIdentity }
                            result.success(mapOf("utcMs" to System.currentTimeMillis(),
                                "elapsedMs" to SystemClock.elapsedRealtime(), "boot" to boot))
                        }
                        "read" -> result.success(if (store.baseFile.exists() || File(store.baseFile.path + ".bak").exists())
                            store.openRead().bufferedReader().use { it.readText() } else null)
                        "write" -> {
                            val output = store.startWrite()
                            try {
                                output.write((call.arguments as String).toByteArray(Charsets.UTF_8))
                                store.finishWrite(output)
                            } catch (e: Exception) { store.failWrite(output); throw e }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) { result.error("STUDY_LOCAL_IO", "Local study operation failed", null) }
            }
    }
}
