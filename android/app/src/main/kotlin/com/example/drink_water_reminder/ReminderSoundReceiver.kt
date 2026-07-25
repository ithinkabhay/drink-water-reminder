package com.example.drink_water_reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * Fires at the same time as a hydration reminder and starts
 * [ReminderSoundService] so audio can loop for ~10 seconds.
 *
 * Uses [goAsync] + a short wake lock so the process stays alive long enough
 * to promote the foreground service.
 */
class ReminderSoundReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_PLAY) return

        val uriString = intent.getStringExtra(EXTRA_URI)
        if (uriString.isNullOrBlank()) {
            Log.w(TAG, "Missing uri — ignoring sound alarm")
            return
        }

        val durationMs = intent.getLongExtra(EXTRA_DURATION_MS, 10_000L)
        val requestCode = intent.getIntExtra(EXTRA_REQUEST_CODE, -1)
        Log.i(
            TAG,
            "Sound alarm fired requestCode=$requestCode durationMs=$durationMs",
        )

        val pending = goAsync()
        val appContext = context.applicationContext
        val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "drink_water_reminder:SoundReceiver",
        ).apply {
            setReferenceCounted(false)
            acquire(8_000L)
        }

        try {
            ReminderSoundService.start(appContext, uriString, durationMs)
        } catch (error: Exception) {
            Log.e(TAG, "Failed to start ReminderSoundService", error)
        } finally {
            try {
                if (wakeLock.isHeld) wakeLock.release()
            } catch (_: Exception) {
            }
            pending.finish()
        }
    }

    companion object {
        private const val TAG = "ReminderSoundReceiver"
        const val ACTION_PLAY = "com.example.drink_water_reminder.PLAY_REMINDER_SOUND"
        const val EXTRA_URI = "uri"
        const val EXTRA_DURATION_MS = "durationMs"
        const val EXTRA_REQUEST_CODE = "requestCode"
    }
}
