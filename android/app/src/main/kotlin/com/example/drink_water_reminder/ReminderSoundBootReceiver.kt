package com.example.drink_water_reminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Restores companion reminder-sound alarms after device reboot.
 *
 * flutter_local_notifications restores the visible notifications; this
 * receiver restores the looping ringtone schedule that pairs with them.
 */
class ReminderSoundBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        Log.i(TAG, "Boot/replace event — restoring companion sound alarms")
        try {
            ReminderSoundScheduler.restoreAfterBoot(context.applicationContext)
        } catch (error: Exception) {
            Log.e(TAG, "Boot restore failed", error)
        }
    }

    companion object {
        private const val TAG = "ReminderSoundBoot"
    }
}
