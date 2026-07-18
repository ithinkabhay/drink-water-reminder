package com.example.drink_water_reminder

import android.content.Context
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Application-context MethodChannel so ringtone scheduling works as soon as
 * the Flutter engine is attached (not only while MainActivity handles calls).
 */
class ReminderSoundPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext
        if (context == null) {
            result.error("no_context", "Plugin not attached", null)
            return
        }

        when (call.method) {
            "previewRingtone" -> {
                val uri = call.argument<String>("uri")
                val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 10_000L
                if (uri.isNullOrBlank()) {
                    result.error("invalid", "Missing ringtone uri", null)
                    return
                }
                ReminderSoundPlayer.play(context, Uri.parse(uri), durationMs)
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
                    context,
                    ReminderSoundScheduler.requestCodeForNotification(notificationId),
                    triggerAt,
                    uri,
                    durationMs,
                )
                result.success(null)
            }
            "cancelAllAlertSounds" -> {
                ReminderSoundScheduler.cancelAll(context)
                result.success(null)
            }
            "builtinSoundUri" -> {
                result.success(ReminderSoundScheduler.builtinSoundUri(context))
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "drink_water_reminder/ringtone"
    }
}
