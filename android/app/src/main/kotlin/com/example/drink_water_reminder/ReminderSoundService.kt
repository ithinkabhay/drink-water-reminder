package com.example.drink_water_reminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

/**
 * Foreground service that keeps the process alive while the reminder
 * ringtone loops for the configured duration (~10 seconds).
 *
 * A plain [BroadcastReceiver] can be killed after [BroadcastReceiver.onReceive]
 * returns, which truncates playback to roughly a one-shot beep.
 */
class ReminderSoundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var stopRunnable: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action != ACTION_PLAY) {
            stopSelf(startId)
            return START_NOT_STICKY
        }

        val uriString = intent.getStringExtra(EXTRA_URI)
        if (uriString.isNullOrBlank()) {
            Log.w(TAG, "Missing sound uri — stopping service")
            stopSelf(startId)
            return START_NOT_STICKY
        }

        val durationMs = intent
            .getLongExtra(EXTRA_DURATION_MS, 10_000L)
            .coerceIn(1_000L, 15_000L)

        try {
            ensureChannel()
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            Log.i(TAG, "Playing reminder sound for ${durationMs}ms uri=$uriString")
            ReminderSoundPlayer.play(applicationContext, Uri.parse(uriString), durationMs)

            stopRunnable?.let { handler.removeCallbacks(it) }
            val stop = Runnable {
                Log.i(TAG, "Sound duration elapsed — stopping service")
                ReminderSoundPlayer.stop()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf(startId)
            }
            stopRunnable = stop
            handler.postDelayed(stop, durationMs + 250L)
        } catch (error: Exception) {
            Log.e(TAG, "Failed to start reminder sound service", error)
            ReminderSoundPlayer.stop()
            stopSelf(startId)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopRunnable?.let { handler.removeCallbacks(it) }
        stopRunnable = null
        // Do not stop the player here if another start is racing; play() resets.
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reminder sound",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps reminder audio playing briefly"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Waterly")
            .setContentText("Playing hydration reminder…")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    companion object {
        private const val TAG = "ReminderSoundService"
        private const val CHANNEL_ID = "reminder_sound_playback"
        private const val NOTIFICATION_ID = 710999

        const val ACTION_PLAY = "com.example.drink_water_reminder.PLAY_REMINDER_SOUND_SERVICE"
        const val EXTRA_URI = "uri"
        const val EXTRA_DURATION_MS = "durationMs"

        fun start(context: Context, uri: String, durationMs: Long) {
            val intent = Intent(context, ReminderSoundService::class.java).apply {
                action = ACTION_PLAY
                putExtra(EXTRA_URI, uri)
                putExtra(EXTRA_DURATION_MS, durationMs)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (error: Exception) {
                Log.e(TAG, "startForegroundService failed — falling back to direct play", error)
                ReminderSoundPlayer.play(context, Uri.parse(uri), durationMs)
            }
        }
    }
}
