package com.example.drink_water_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.net.Uri

/**
 * Schedules exact alarms that trigger [ReminderSoundReceiver] so reminder
 * audio can loop for a full duration instead of a one-shot notification beep.
 */
object ReminderSoundScheduler {
    private const val PREFS = "reminder_sound_alarms"
    private const val KEY_IDS = "request_codes"
    private const val BASE_REQUEST_CODE = 710_000

    fun schedule(
        context: Context,
        requestCode: Int,
        triggerAtMillis: Long,
        uri: String,
        durationMs: Long,
    ) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = pendingIntent(appContext, requestCode, uri, durationMs)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pending,
                )
            } else {
                @Suppress("DEPRECATION")
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
            }
            rememberId(appContext, requestCode)
        } catch (_: Exception) {
            try {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pending,
                )
                rememberId(appContext, requestCode)
            } catch (_: Exception) {
            }
        }
    }

    fun cancelAll(context: Context) {
        val appContext = context.applicationContext
        val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(KEY_IDS, emptySet())?.toSet().orEmpty()
        for (idString in ids) {
            val code = idString.toIntOrNull() ?: continue
            val pending = pendingIntent(appContext, code, "", 10_000L)
            alarmManager.cancel(pending)
            pending.cancel()
        }
        prefs.edit().remove(KEY_IDS).apply()
        ReminderSoundPlayer.stop()
    }

    fun builtinSoundUri(context: Context): String {
        return Uri.parse(
            "android.resource://${context.packageName}/raw/water_chime",
        ).toString()
    }

    private fun pendingIntent(
        context: Context,
        requestCode: Int,
        uri: String,
        durationMs: Long,
    ): PendingIntent {
        val intent = Intent(context, ReminderSoundReceiver::class.java).apply {
            action = ReminderSoundReceiver.ACTION_PLAY
            putExtra(ReminderSoundReceiver.EXTRA_URI, uri)
            putExtra(ReminderSoundReceiver.EXTRA_DURATION_MS, durationMs)
            putExtra(ReminderSoundReceiver.EXTRA_REQUEST_CODE, requestCode)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun rememberId(context: Context, requestCode: Int) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val next = prefs.getStringSet(KEY_IDS, emptySet())?.toMutableSet() ?: mutableSetOf()
        next.add(requestCode.toString())
        prefs.edit().putStringSet(KEY_IDS, next).apply()
    }

    fun requestCodeForNotification(notificationId: Int): Int = BASE_REQUEST_CODE + notificationId
}
