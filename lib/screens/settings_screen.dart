import 'package:flutter/material.dart';

import '../models/reminder_settings.dart';
import '../providers/reminder_provider.dart';
import '../services/ringtone_picker_service.dart';
import '../utils/constants.dart';
import '../utils/time_format.dart';
import '../widgets/custom_amount_dialog.dart';
import '../widgets/custom_interval_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Complete Reminder Settings screen for the smart hydration assistant.
class SettingsScreen extends StatefulWidget {
  /// Creates the reminder settings screen.
  const SettingsScreen({
    super.key,
    required this.reminderProvider,
  });

  /// Shared reminder state and scheduling coordinator.
  final ReminderProvider reminderProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ReminderProvider get _provider => widget.reminderProvider;

  ReminderSettings get _settings => _provider.settings;

  @override
  void dispose() {
    RingtonePickerService.stopPreview();
    super.dispose();
  }

  Future<void> _update(ReminderSettings updated) =>
      _provider.updateSettings(updated);

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.startTime,
    );
    if (picked == null) return;

    await _update(
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

    await _update(
      _settings.copyWith(
        endHour: picked.hour,
        endMinute: picked.minute,
      ),
    );
  }

  Future<void> _onIntervalSelected(int value) async {
    if (value == AppConstants.customIntervalSentinel) {
      final minutes = await CustomIntervalDialog.show(
        context,
        initialMinutes: _settings.isCustomInterval
            ? _settings.intervalMinutes
            : null,
      );
      if (minutes == null || !mounted) return;
      final error = await _provider.setCustomIntervalMinutes(minutes);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    await _provider.setIntervalMinutes(value);
  }

  Future<void> _onQuickAddSelected(int value) async {
    if (value == AppConstants.customIntervalSentinel) {
      final amount = await CustomAmountDialog.show(context);
      if (amount == null || !mounted) return;
      await _update(_settings.copyWith(defaultQuickAddMl: amount));
      return;
    }
    await _update(_settings.copyWith(defaultQuickAddMl: value));
  }

  Future<void> _pickRingtone() async {
    if (!RingtonePickerService.isSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ringtone picker is only available on Android'),
        ),
      );
      return;
    }

    final picked = await RingtonePickerService.pick(
      existingUri: _settings.customRingtoneUri,
    );
    if (!mounted || picked == null) return;

    await _update(
      _settings.copyWith(
        soundEnabled: true,
        customRingtoneUri: picked.uri,
        customRingtoneTitle: picked.title,
      ),
    );

    // Preview for ~10 seconds so the user can confirm the choice.
    await RingtonePickerService.preview(
      picked.uri,
      durationMs: AppConstants.notificationAlertDurationMs,
    );
  }

  Future<void> _clearRingtone() async {
    await RingtonePickerService.stopPreview();
    await _update(_settings.copyWith(clearCustomRingtone: true));
  }

  int get _selectedIntervalValue {
    if (_settings.isCustomInterval) {
      return AppConstants.customIntervalSentinel;
    }
    return _settings.intervalMinutes;
  }

  int get _selectedQuickAddValue {
    if (AppConstants.quickAddAmountsMl.contains(_settings.defaultQuickAddMl)) {
      return _settings.defaultQuickAddMl;
    }
    return AppConstants.customIntervalSentinel;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final settings = _provider.settings;
        final enabled = settings.enabled;

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Reminder Settings'),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SwitchListTile(
                    title: Text(
                      'Enable reminders',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Smart hydration assistant alerts'),
                    value: settings.enabled,
                    onChanged: (value) => _update(
                      settings.copyWith(enabled: value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Reminder Interval'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final minutes
                          in AppConstants.reminderIntervalPresetsMinutes)
                        ListTile(
                          enabled: enabled,
                          title: Text(AppConstants.intervalLabel(minutes)),
                          trailing: _selectedIntervalValue == minutes
                              ? Icon(Icons.check_rounded,
                                  color: colorScheme.primary)
                              : null,
                          onTap: enabled
                              ? () => _onIntervalSelected(minutes)
                              : null,
                        ),
                      ListTile(
                        enabled: enabled,
                        title: const Text('Custom Interval'),
                        subtitle: settings.isCustomInterval
                            ? Text(
                                AppConstants.intervalLabel(
                                  settings.intervalMinutes,
                                ),
                              )
                            : const Text('Choose your own minutes'),
                        trailing: _selectedIntervalValue ==
                                AppConstants.customIntervalSentinel
                            ? Icon(Icons.check_rounded,
                                color: colorScheme.primary)
                            : Icon(Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant),
                        onTap: enabled
                            ? () => _onIntervalSelected(
                                  AppConstants.customIntervalSentinel,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Active Window'),
                const SizedBox(height: 8),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        enabled: enabled,
                        title: const Text('Reminder Start Time'),
                        subtitle: Text(TimeFormat.timeOfDay(settings.startTime)),
                        trailing: Icon(
                          Icons.access_time_rounded,
                          color: colorScheme.primary,
                        ),
                        onTap: enabled ? _pickStartTime : null,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      ListTile(
                        enabled: enabled,
                        title: const Text('Reminder End Time'),
                        subtitle: Text(TimeFormat.timeOfDay(settings.endTime)),
                        trailing: Icon(
                          Icons.access_time_rounded,
                          color: colorScheme.primary,
                        ),
                        onTap: enabled ? _pickEndTime : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Alert Style'),
                const SizedBox(height: 8),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Notification Sound'),
                        subtitle: const Text(
                          'Play for about 10 seconds when a reminder fires',
                        ),
                        value: settings.soundEnabled,
                        onChanged: enabled
                            ? (value) => _update(
                                  settings.copyWith(soundEnabled: value),
                                )
                            : null,
                      ),
                      ListTile(
                        enabled: enabled && settings.soundEnabled,
                        title: const Text('Reminder ringtone'),
                        subtitle: Text(
                          settings.customRingtoneTitle?.isNotEmpty == true
                              ? settings.customRingtoneTitle!
                              : 'Built-in water chime (tap to pick from phone)',
                        ),
                        trailing: Icon(
                          Icons.music_note_rounded,
                          color: colorScheme.primary,
                        ),
                        onTap: enabled && settings.soundEnabled
                            ? _pickRingtone
                            : null,
                      ),
                      if (settings.customRingtoneUri != null)
                        ListTile(
                          enabled: enabled,
                          title: const Text('Use built-in chime'),
                          leading: Icon(
                            Icons.restore_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: enabled ? _clearRingtone : null,
                        ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle: const Text('Repeating vibration pattern'),
                        value: settings.vibrationEnabled,
                        onChanged: enabled
                            ? (value) => _update(
                                  settings.copyWith(vibrationEnabled: value),
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Default Quick Add Amount'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final amount in AppConstants.quickAddAmountsMl)
                        ListTile(
                          title: Text('$amount ml'),
                          trailing: _selectedQuickAddValue == amount
                              ? Icon(Icons.check_rounded,
                                  color: colorScheme.primary)
                              : null,
                          onTap: () => _onQuickAddSelected(amount),
                        ),
                      ListTile(
                        title: const Text('Custom'),
                        subtitle: !AppConstants.quickAddAmountsMl
                                .contains(settings.defaultQuickAddMl)
                            ? Text('${settings.defaultQuickAddMl} ml')
                            : const Text('Enter your own amount'),
                        trailing: _selectedQuickAddValue ==
                                AppConstants.customIntervalSentinel
                            ? Icon(Icons.check_rounded,
                                color: colorScheme.primary)
                            : Icon(Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant),
                        onTap: () => _onQuickAddSelected(
                              AppConstants.customIntervalSentinel,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Smart Behavior'),
                const SizedBox(height: 8),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Stop after daily goal'),
                        subtitle: const Text(
                          'Cancel remaining reminders once the goal is met; '
                          'resume tomorrow',
                        ),
                        value: settings.stopAfterGoalCompleted,
                        onChanged: enabled
                            ? (value) => _update(
                                  settings.copyWith(
                                    stopAfterGoalCompleted: value,
                                  ),
                                )
                            : null,
                      ),
                      SwitchListTile(
                        title: const Text('Skip if recently logged'),
                        subtitle: Text(
                          'After you log water, wait '
                          '${settings.intervalMinutes} minutes '
                          '(your reminder interval) before the next alert',
                        ),
                        value: settings.skipIfRecentlyLogged,
                        onChanged: enabled
                            ? (value) => _update(
                                  settings.copyWith(
                                    skipIfRecentlyLogged: value,
                                  ),
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Text(
                    'Reminders use high-priority notifications with '
                    '✅ Drank Water and ⏰ Remind Me Later actions. Schedules '
                    'restore automatically after app restarts and device reboots.',
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
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
