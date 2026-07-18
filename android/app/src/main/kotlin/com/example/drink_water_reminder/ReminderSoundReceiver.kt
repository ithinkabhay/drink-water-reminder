package com.example.drink_water_reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Fires at the same time as a hydration reminder and plays the ringtone
 * for ~10 seconds (notification channel sounds only ring once).
 */
class ReminderSoundReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_PLAY) return
        val uriString = intent.getStringExtra(EXTRA_URI) ?: return
        val durationMs = intent.getLongExtra(EXTRA_DURATION_MS, 10_000L)
        try {
            ReminderSoundPlayer.play(context, Uri.parse(uriString), durationMs)
        } catch (_: Exception) {
        }
    }

    companion object {
        const val ACTION_PLAY = "com.example.drink_water_reminder.PLAY_REMINDER_SOUND"
        const val EXTRA_URI = "uri"
        const val EXTRA_DURATION_MS = "durationMs"
        const val EXTRA_REQUEST_CODE = "requestCode"
    }
}
