import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Result of picking a system ringtone on Android.
class PickedRingtone {
  /// Creates a picked ringtone descriptor.
  const PickedRingtone({required this.uri, required this.title});

  /// Content URI playable by Android notifications.
  final String uri;

  /// Human-readable ringtone title.
  final String title;
}

/// Thin bridge to the Android ringtone picker / 10s alert player.
class RingtonePickerService {
  /// Private constructor — static API only.
  const RingtonePickerService._();

  static const MethodChannel _channel = MethodChannel(
    'drink_water_reminder/ringtone',
  );

  /// Whether the native ringtone picker is available on this platform.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens the system ringtone picker. Returns `null` if cancelled.
  static Future<PickedRingtone?> pick({String? existingUri}) async {
    if (!isSupported) return null;
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'pickRingtone',
        <String, Object?>{'existingUri': existingUri},
      );
      if (result == null) return null;
      final uri = result['uri'] as String?;
      final title = result['title'] as String?;
      if (uri == null || uri.isEmpty) return null;
      return PickedRingtone(
        uri: uri,
        title: (title == null || title.isEmpty) ? 'Custom ringtone' : title,
      );
    } on PlatformException catch (error) {
      debugPrint('Ringtone pick failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Plays [uri] looping for about [durationMs] (Settings preview).
  static Future<void> preview(
    String uri, {
    int durationMs = AppConstants.notificationAlertDurationMs,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('previewRingtone', <String, Object?>{
        'uri': uri,
        'durationMs': durationMs,
      });
    } catch (error) {
      debugPrint('Ringtone preview failed: $error');
    }
  }

  /// Stops an in-progress preview / alert sound, if any.
  static Future<void> stopPreview() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('stopPreview');
    } catch (_) {}
  }

  /// URI of the bundled water chime raw resource.
  static Future<String?> builtinSoundUri() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('builtinSoundUri');
    } catch (_) {
      return null;
    }
  }

  /// Schedules a looping ringtone alarm at [triggerAt] (companion to a notif).
  static Future<void> scheduleAlertSound({
    required DateTime triggerAt,
    required String uri,
    required int notificationId,
    int durationMs = AppConstants.notificationAlertDurationMs,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('scheduleAlertSound', <String, Object?>{
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'uri': uri,
        'durationMs': durationMs,
        'notificationId': notificationId,
      });
    } catch (error) {
      debugPrint('Schedule alert sound failed: $error');
    }
  }

  /// Cancels every pending 10s ringtone alarm and stops playback.
  static Future<void> cancelAllAlertSounds() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelAllAlertSounds');
    } catch (_) {}
  }
}
