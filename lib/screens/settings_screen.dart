import 'package:flutter/material.dart';

import '../models/reminder_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Screen for configuring drink reminder notifications.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Holds editable reminder settings and persists changes on update.
class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();

  late ReminderSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _storage.loadReminderSettings();
  }

  /// Saves [updated] settings and reschedules notifications immediately.
  Future<void> _updateSettings(ReminderSettings updated) async {
    setState(() => _settings = updated);
    await _storage.saveReminderSettings(updated);
    await _notifications.reschedule(updated);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.startTime,
    );
    if (picked == null) return;

    await _updateSettings(
      _settings.copyWith(
        startHour: picked.hour,
        startMinute: picked.minute,
      ),
    );
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.endTime,
    );
    if (picked == null) return;

    await _updateSettings(
      _settings.copyWith(
        endHour: picked.hour,
        endMinute: picked.minute,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _intervalLabel(int minutes) {
    if (minutes == 30) return '30 min';
    if (minutes == 60) return '1 hour';
    return '2 hours';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SwitchListTile(
                title: Text(
                  'Enable reminders',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Get notified to drink water'),
                value: _settings.enabled,
                onChanged: (value) => _updateSettings(
                  _settings.copyWith(enabled: value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder interval',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<int>(
                    segments: [
                      for (final minutes
                          in AppConstants.reminderIntervalsMinutes)
                        ButtonSegment<int>(
                          value: minutes,
                          label: Text(_intervalLabel(minutes)),
                        ),
                    ],
                    selected: {_settings.intervalMinutes},
                    onSelectionChanged: _settings.enabled
                        ? (selection) => _updateSettings(
                              _settings.copyWith(
                                intervalMinutes: selection.first,
                              ),
                            )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    enabled: _settings.enabled,
                    title: const Text('Start time'),
                    subtitle: Text(_formatTime(_settings.startTime)),
                    trailing: Icon(
                      Icons.access_time_rounded,
                      color: colorScheme.primary,
                    ),
                    onTap: _settings.enabled ? _pickStartTime : null,
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  ListTile(
                    enabled: _settings.enabled,
                    title: const Text('End time'),
                    subtitle: Text(_formatTime(_settings.endTime)),
                    trailing: Icon(
                      Icons.access_time_rounded,
                      color: colorScheme.primary,
                    ),
                    onTap: _settings.enabled ? _pickEndTime : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Text(
                'Reminders are sent between the start and end times at the '
                'selected interval, even when the app is closed.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
