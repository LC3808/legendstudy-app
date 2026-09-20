package com.legendstudy.app

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.util.AtomicFile
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/** One device timer, one replaceable inexact reminder. No timer/account mutations. */
class MockNotificationBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private var permissionResult: MethodChannel.Result? = null
    init {
        MethodChannel(messenger, "com.legendstudy.app/mock-notification").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "request" -> {
                        if (Build.VERSION.SDK_INT >= 33 && activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (permissionResult != null) result.success(false) else {
                                permissionResult = result
                                activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 807)
                            }
                        } else result.success(allowed(activity))
                    }
                    "replace" -> {
                        val alarm = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        alarm.cancel(pending(activity))
                        (activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(807)
                        val session = call.argument<String>("session")
                        val ms = call.argument<Number>("remainingMs")?.toLong() ?: 0L
                        activity.getSharedPreferences("mock-alert", 0).edit().putString("session", session).commit()
                        if (session != null && ms > 0 && allowed(activity)) {
                            val at = SystemClock.elapsedRealtime() + ms.coerceAtMost(43200000)
                            if (Build.VERSION.SDK_INT >= 23) alarm.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending(activity))
                            else alarm.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending(activity))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("MOCK_ALERT", "Reminder unavailable", null) }
        }
    }
    fun permissionResult(requestCode: Int) {
        if (requestCode == 807) { permissionResult?.success(allowed(activity)); permissionResult = null }
    }
    companion object {
        fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(context, 807,
            Intent(context, MockReminderReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun allowed(context: Context): Boolean {
            if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return Build.VERSION.SDK_INT < 24 || manager.areNotificationsEnabled()
        }
    }
}

class MockReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (!MockNotificationBridge.allowed(context)) return
            val session = context.getSharedPreferences("mock-alert", 0).getString("session", null) ?: return
            val file = AtomicFile(File(context.filesDir, "study-state-v1.json"))
            val root = JSONObject(file.openRead().bufferedReader().use { it.readText() })
            val owners = root.getJSONObject("owners")
            val active = owners.keys().asSequence().any { owner ->
                val d = owners.getJSONObject(owner).optJSONObject("draft")
                d != null && d.optString("id") == session && (d.optString("phase") == "running" && d.isNull("frozen") || d.optString("frozen") == "planElapsed") && d.optJSONObject("mock")?.optBoolean("notify") == true
            }
            if (!active) return
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel("mock-end", "모의고사 종료", NotificationManager.IMPORTANCE_DEFAULT))
            val launch = PendingIntent.getActivity(context, 807, Intent(context, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "mock-end") else Notification.Builder(context)
            manager.notify(807, builder.setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle("레전드스터디+")
                .setContentText("모의고사 시간이 종료됐어요.").setContentIntent(launch).setAutoCancel(true).build())
        } catch (_: Exception) { /* Best effort; no payloads or credentials logged. */ }
    }
}
