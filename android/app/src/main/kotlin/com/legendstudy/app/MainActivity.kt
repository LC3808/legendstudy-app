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
    private var exportBytes: ByteArray? = null
    private var exportResult: MethodChannel.Result? = null
    @Deprecated("Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 9261) return
        val reply = exportResult ?: return
        val bytes = exportBytes
        exportResult = null; exportBytes = null
        try {
            val uri = data?.data
            if (resultCode != RESULT_OK || uri == null || bytes == null) { reply.success(false); return }
            checkNotNull(contentResolver.openOutputStream(uri)).use { it.write(bytes) }
            reply.success(true)
        } catch (_: Exception) { reply.error("EXPORT_FAILED", "Unable to save file", null) }
    }
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
        AnswerOcrBridge(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.legendstudy.app/export").setMethodCallHandler { call, result ->
            if (call.method != "save") { result.notImplemented(); return@setMethodCallHandler }
            if (exportResult != null) { result.error("BUSY", "A save is in progress", null); return@setMethodCallHandler }
            try {
                val args = call.arguments as Map<*, *>
                val bytes = args["bytes"] as ByteArray
                val name = args["name"] as String
                val mime = args["mime"] as String
                require(bytes.isNotEmpty() && bytes.size <= 20971520)
                require(name.matches(Regex("[a-zA-Z0-9_-]+\\.(png|pdf)")))
                require(mime == "image/png" || mime == "application/pdf")
                exportBytes = bytes; exportResult = result
                startActivityForResult(android.content.Intent(android.content.Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(android.content.Intent.CATEGORY_OPENABLE); type = mime
                    putExtra(android.content.Intent.EXTRA_TITLE, name)
                }, 9261)
            } catch (_: Exception) { exportBytes = null; exportResult = null; result.error("EXPORT_FAILED", "Unable to save file", null) }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.legendstudy.app/essay-draft")
            .setMethodCallHandler { call, result ->
                try {
                    val folder = File(filesDir, "essay-drafts").apply { mkdirs() }
                    if (call.method == "purge") {
                        val owner = call.arguments as String
                        require(owner.matches(Regex("[a-f0-9]{64}")))
                        folder.listFiles()?.filter { it.name.startsWith(owner + "_") }?.forEach { check(it.delete()) }
                        result.success(null)
                    } else {
                        val args = call.arguments
                        val key = if (args is String) args else (args as Map<*, *>)["key"] as String
                        require(key.matches(Regex("[a-f0-9]{64}_[a-f0-9]{64}")))
                        if (call.method == "readImage" || call.method == "writeImage") {
                            val image = AtomicFile(File(folder, key + ".image"))
                            if (call.method == "readImage") result.success(if (image.baseFile.exists() || File(image.baseFile.path + ".bak").exists()) image.openRead().use { it.readBytes() } else null)
                            else {
                                val bytes = (args as Map<*, *>)["value"] as ByteArray?
                                if (bytes == null) image.delete() else {
                                    require(bytes.size <= 20971520)
                                    val output = image.startWrite()
                                    try { output.write(bytes); image.finishWrite(output) } catch (e: Exception) { image.failWrite(output); throw e }
                                }
                                result.success(null)
                            }
                            return@setMethodCallHandler
                        }
                        val file = AtomicFile(File(folder, key + ".json"))
                        val old = if (file.baseFile.exists() || File(file.baseFile.path + ".bak").exists()) file.openRead().bufferedReader().use { it.readText() } else null
                        if (call.method == "read") result.success(old)
                        else if (call.method == "write") {
                            val map = args as Map<*, *>
                            val revision = if (old == null) 0 else org.json.JSONObject(old).getInt("revision")
                            check(revision == (map["expected"] as Number).toInt())
                            val value = map["value"] as String
                            require(value.length <= 250000)
                            val output = file.startWrite()
                            try { output.write(value.toByteArray(Charsets.UTF_8)); file.finishWrite(output) }
                            catch (e: Exception) { file.failWrite(output); throw e }
                            result.success(null)
                        } else result.notImplemented()
                    }
                } catch (_: Exception) { result.error("ESSAY_DRAFT_IO", "Unable to store draft", null) }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.legendstudy.app/info")
            .setMethodCallHandler { call, result ->
                if (call.method == "introCompleted") {
                    val prefs = getSharedPreferences("legendstudy-install", MODE_PRIVATE)
                    val knownInstall = File(filesDir, "study-state-v1.json").exists()
                    result.success(prefs.getBoolean("intro-v1-complete", false) || knownInstall)
                    return@setMethodCallHandler
                }
                if (call.method == "completeIntro") {
                    val saved = getSharedPreferences("legendstudy-install", MODE_PRIVATE)
                        .edit().putBoolean("intro-v1-complete", true).commit()
                    if (saved) result.success(null) else result.error("LOCAL_IO", "Unable to save introduction", null)
                    return@setMethodCallHandler
                }
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
