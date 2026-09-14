package com.legendstudy.app

import android.app.Activity
import android.app.AutomaticZenRule
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.service.notification.Condition
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/** Only our rule/activation lease is touched. Never writes the global filter/policy. */
class StudyFocusBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val prefs = activity.getSharedPreferences("study-focus-v1", Context.MODE_PRIVATE)
    private val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val config = ComponentName(activity, StudyFocusSettingsActivity::class.java)
    private val condition = Uri.parse("condition://com.legendstudy.app/study-focus")
    private val supported get() = Build.VERSION.SDK_INT >= 29
    private val permitted get() = supported && manager.isNotificationPolicyAccessGranted

    init {
        MethodChannel(messenger, "com.legendstudy.app/focus").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(mapOf("capability" to if (supported) "ownedRule" else "manualAndroid", "permission" to permitted))
                    "readPreference" -> result.success(prefs.getString("preference", "ask"))
                    "writePreference" -> {
                        val value = call.arguments as String
                        require(value in listOf("ask", "always", "disabled"))
                        check(prefs.edit().putString("preference", value).commit())
                        result.success(null)
                    }
                    "requestPermission" -> {
                        if (supported && !permitted) activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        result.success(null) // Never waits for a settings result.
                    }
                    "activate" -> result.success(activate(call.arguments as String))
                    "reconcile" -> { reconcile(call.arguments as? String); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: SecurityException) {
                if (call.method == "activate") result.success("denied")
                else result.error("FOCUS_UNAVAILABLE", "Focus unavailable", null)
            } catch (_: Exception) { result.error("FOCUS_UNAVAILABLE", "Focus unavailable", null) }
        }
    }
    private fun currentDraft(session: String): JSONObject? {
        // Verify the durable timer still exists before an activation can take effect.
        val file = File(activity.filesDir, "study-state-v1.json")
        val owners = JSONObject(file.readText()).getJSONObject("owners")
        for (owner in owners.keys()) {
            val draft = owners.getJSONObject(owner).optJSONObject("draft") ?: continue
            if (draft.optString("id") == session && draft.optString("phase") in listOf("running", "paused") && draft.isNull("frozen")) return draft
        }
        return null
    }
    private fun ownedRuleId(): String? {
        if (!permitted) return null
        val id = prefs.getString("rule", null) ?: return null
        val rule = manager.getAutomaticZenRule(id) ?: return null
        // Defense against metadata mismatch; getAutomaticZenRule also enforces ownership.
        return if (rule.configurationActivity == config && rule.conditionId == condition) id else null
    }
    @Suppress("DEPRECATION")
    private fun activate(session: String): String {
        if (!supported) return "unsupported"
        if (!permitted) return "denied"
        val draft = currentDraft(session) ?: return "inactive"
        val expires = draft.getLong("started") + 86400000L
        if (System.currentTimeMillis() >= expires) return "inactive"
        var id = ownedRuleId()
        if (id == null) {
            val rule = AutomaticZenRule("레전드스터디 공부", null, config, condition, null,
                NotificationManager.INTERRUPTION_FILTER_PRIORITY, true)
            id = manager.addAutomaticZenRule(rule) ?: return "failed"
            if (!prefs.edit().putString("rule", id).commit()) {
                manager.removeAutomaticZenRule(id) // Only the just-created, still inactive rule.
                return "failed"
            }
        }
        val rule = manager.getAutomaticZenRule(id) ?: return "failed"
        if (!rule.isEnabled) return "inactive" // Never override a user-disabled rule.
        if (prefs.getString("session", null) == session) return "requested"
        reconcile(null) // End only a prior activation lease, never any global DND.
        check(prefs.edit().putString("session", session).putLong("expires", expires).commit())
        manager.setAutomaticZenRuleState(id, Condition(condition, "공부 중", Condition.STATE_TRUE))
        return "requested" // Request is not proof of effective global DND; user overrides win.
    }
    private fun reconcile(session: String?) {
        val lease = prefs.getString("session", null) ?: return
        val valid = session != null && FocusLeasePolicy.retain(lease, session,
            prefs.getLong("expires", 0), System.currentTimeMillis()) && currentDraft(session) != null
        if (valid) return // Pause/resume do not re-activate or clear a user override.
        if (!permitted) throw SecurityException("Owned cleanup deferred") // Retain metadata for re-grant.
        val id = ownedRuleId()
        if (id != null) manager.setAutomaticZenRuleState(id, Condition(condition, "공부 종료", Condition.STATE_FALSE))
        check(prefs.edit().remove("session").remove("expires").commit())
    }
}

internal object FocusLeasePolicy {
    fun retain(lease: String, current: String?, expires: Long, now: Long): Boolean =
        lease == current && now < expires
}
