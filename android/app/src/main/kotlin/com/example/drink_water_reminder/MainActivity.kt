package com.example.drink_water_reminder

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pickRequestCode = 9911
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(ReminderSoundPlugin())

        // Picker needs an Activity result callback — keep it on the Activity.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ReminderSoundPlugin.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickRingtone" -> {
                    if (pendingPickResult != null) {
                        result.error("busy", "Ringtone picker already open", null)
                        return@setMethodCallHandler
                    }
                    pendingPickResult = result
                    val existing = call.argument<String>("existingUri")
                    openRingtonePicker(existing)
                }
                else -> {
                    // Defer preview / schedule / cancel to the plugin handler.
                    // Re-registering the same channel replaces the plugin handler,
                    // so forward those methods here too.
                    handleSharedRingtoneMethods(call, result)
                }
            }
        }
    }

    private fun handleSharedRingtoneMethods(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "previewRingtone" -> {
                val uri = call.argument<String>("uri")
                val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 10_000L
                if (uri.isNullOrBlank()) {
                    result.error("invalid", "Missing ringtone uri", null)
                    return
                }
                ReminderSoundPlayer.play(this, Uri.parse(uri), durationMs)
                result.success(null)
            }
            "stopPreview" -> {
                ReminderSoundPlayer.stop()
                result.success(null)
            }
            "scheduleAlertSound" -> {
                val triggerAt = call.argument<Number>("triggerAtMillis")?.toLong()
                val uri = call.argument<String>("uri")
                val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 10_000L
                val notificationId = call.argument<Number>("notificationId")?.toInt() ?: 0
                if (triggerAt == null || uri.isNullOrBlank()) {
                    result.error("invalid", "Missing triggerAtMillis or uri", null)
                    return
                }
                ReminderSoundScheduler.schedule(
                    this,
                    ReminderSoundScheduler.requestCodeForNotification(notificationId),
                    triggerAt,
                    uri,
                    durationMs,
                )
                result.success(null)
            }
            "cancelAllAlertSounds" -> {
                ReminderSoundScheduler.cancelAll(this)
                result.success(null)
            }
            "builtinSoundUri" -> {
                result.success(ReminderSoundScheduler.builtinSoundUri(this))
            }
            else -> result.notImplemented()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        // Do not stop ReminderSoundPlayer here — Activity recreation / process
        // teardown would cut the ~10s looping reminder sound short (~1s beep).
        super.onDestroy()
    }

    private fun openRingtonePicker(existingUri: String?) {
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_NOTIFICATION or RingtoneManager.TYPE_ALARM or
                    RingtoneManager.TYPE_RINGTONE,
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select reminder sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            if (!existingUri.isNullOrBlank()) {
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                    Uri.parse(existingUri),
                )
            }
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, pickRequestCode)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return

        val result = pendingPickResult
        pendingPickResult = null
        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data.getParcelableExtra(
                RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                Uri::class.java,
            )
        } else {
            @Suppress("DEPRECATION")
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }

        if (uri == null) {
            result.success(null)
            return
        }

        // Persist URI read permission when the system grants it.
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: Exception) {
            // Many ringtone URIs are not persistable — ignore.
        }

        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
                ?: "Custom ringtone"
        } catch (_: Exception) {
            "Custom ringtone"
        }

        result.success(
            mapOf(
                "uri" to uri.toString(),
                "title" to title,
            ),
        )
    }
}
