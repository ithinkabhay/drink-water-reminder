package com.example.drink_water_reminder

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log

/**
 * Loops a ringtone/URI for a fixed duration (default 10 seconds).
 *
 * Android notification-channel sounds only play once (~1s), so reminders
 * use this companion player (hosted by [ReminderSoundService]) instead.
 */
object ReminderSoundPlayer {
    private const val TAG = "ReminderSoundPlayer"

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var stopRunnable: Runnable? = null

    @Synchronized
    fun play(context: Context, uri: Uri, durationMs: Long) {
        stop()
        val clamped = durationMs.coerceIn(1_000L, 15_000L)
        try {
            val appContext = context.applicationContext
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(appContext, uri)
                isLooping = true
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                    stop()
                    true
                }
                prepare()
                start()
            }
            mediaPlayer = player
            Log.i(TAG, "Started looping playback for ${clamped}ms uri=$uri")

            val pm = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "drink_water_reminder:ReminderSound",
            ).also {
                it.setReferenceCounted(false)
                it.acquire(clamped + 2_000L)
            }

            val stop = Runnable {
                Log.i(TAG, "Stop runnable fired after ${clamped}ms")
                stop()
            }
            stopRunnable = stop
            handler.postDelayed(stop, clamped)
        } catch (error: Exception) {
            Log.e(TAG, "Failed to play reminder sound uri=$uri", error)
            stop()
        }
    }

    @Synchronized
    fun stop() {
        stopRunnable?.let { handler.removeCallbacks(it) }
        stopRunnable = null
        try {
            mediaPlayer?.run {
                if (isPlaying) stop()
                reset()
                release()
            }
        } catch (_: Exception) {
        }
        mediaPlayer = null
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {
        }
        wakeLock = null
    }
}
