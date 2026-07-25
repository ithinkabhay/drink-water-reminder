import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reminder_settings.dart';
import '../providers/reminder_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/hydration_repository.dart';
import '../services/ringtone_picker_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';
import '../utils/time_format.dart';
import '../widgets/capsule_nav_bar.dart';
import '../widgets/custom_interval_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/premium_bottom_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/settings_tile.dart';

/// Settings organized into Notifications, Appearance, Data, and General.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    super.key,
    required this.reminderProvider,
    required this.themeProvider,
  });

  /// Shared reminder state and scheduling coordinator.
  final ReminderProvider reminderProvider;

  /// Theme preference controller.
  final ThemeProvider themeProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HydrationRepository _repository = HydrationRepository();

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
      _settings.copyWith(startHour: picked.hour, startMinute: picked.minute),
    );
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.endTime,
    );
    if (picked == null) return;

    await _update(
      _settings.copyWith(endHour: picked.hour, endMinute: picked.minute),
    );
  }

  Future<void> _editInterval() async {
    final settings = _settings;
    final presets = AppConstants.reminderIntervalPresetsMinutes;
    final selected = presets.contains(settings.intervalMinutes)
        ? settings.intervalMinutes
        : AppConstants.customIntervalSentinel;

    final picked = await EditChoiceSheet.show<int>(
      context: context,
      title: 'Reminder Interval',
      subtitle: 'How often should we nudge you?',
      selected: selected,
      options: [
        for (final m in presets) (m, AppConstants.intervalLabel(m)),
        (AppConstants.customIntervalSentinel, 'Custom'),
      ],
    );
    if (picked == null || !mounted) return;

    if (picked == AppConstants.customIntervalSentinel) {
      final minutes = await CustomIntervalDialog.show(
        context,
        initialMinutes: settings.isCustomInterval
            ? settings.intervalMinutes
            : null,
      );
      if (minutes == null || !mounted) return;
      final error = await _provider.setCustomIntervalMinutes(minutes);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    await _provider.setIntervalMinutes(picked);
  }

  Future<void> _editTheme() async {
    final picked = await EditChoiceSheet.show<ThemeMode>(
      context: context,
      title: 'Theme',
      subtitle: 'Choose how Waterly looks',
      selected: widget.themeProvider.themeMode,
      options: const [
        (ThemeMode.system, 'System'),
        (ThemeMode.light, 'Light'),
        (ThemeMode.dark, 'Dark'),
      ],
    );
    if (picked == null || !mounted) return;
    await widget.themeProvider.setThemeMode(picked);
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

    await RingtonePickerService.preview(
      picked.uri,
      durationMs: AppConstants.notificationAlertDurationMs,
    );
  }

  Future<void> _exportData() async {
    final data = _repository.exportData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Export copied to clipboard')));
  }

  Future<void> _backupData() async {
    await _exportData();
  }

  Future<void> _restoreData() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim();
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty — copy a backup first'),
        ),
      );
      return;
    }

    Map<String, dynamic> decoded;
    try {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is! Map) throw const FormatException('Not a map');
      decoded = Map<String, dynamic>.from(parsed);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard does not contain valid backup JSON'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces local hydration logs, goal, and profile '
          'from the clipboard backup. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.importData(decoded);
      await _provider.onWaterLogged();
      AppRefreshBridge.notify();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup restored')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not restore backup')));
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await PremiumBottomSheet.show<void>(
      context: context,
      builder: (context) => const PremiumBottomSheet(
        title: 'Privacy Policy',
        child: Text(
          'Waterly stores your hydration logs, profile details, and reminder '
          'preferences only on this device using local storage.\n\n'
          'No account is required. Data is not uploaded to external servers '
          'by the app. Export and backup create a local copy you control.\n\n'
          'Notification scheduling uses your device’s system notification '
          'services and optional ringtone selection on Android.',
        ),
      ),
    );
  }

  Future<void> _showAbout() async {
    await PremiumBottomSheet.show<void>(
      context: context,
      builder: (context) => PremiumBottomSheet(
        title: AppConstants.brandName,
        subtitle: AppConstants.tagline,
        child: const Text(
          'A calm hydration companion with smart reminders, '
          'daily goals, and personal insights.',
        ),
      ),
    );
  }

  Future<void> _resetData() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
          'Clear today’s intake and history, or wipe everything '
          'including profile and settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'hydration'),
            child: const Text('Clear logs'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: Text(
              'Reset all',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'hydration') {
      await _repository.resetHydrationData();
      await _provider.onWaterLogged();
      AppRefreshBridge.notify();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hydration logs cleared')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
          'This removes profile, settings, history, and onboarding. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset all',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _repository.resetAllData();
    await _provider.updateSettings(ReminderSettings.defaults());
    await widget.themeProvider.setThemeMode(ThemeMode.system);
    AppRefreshBridge.notify();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data reset. Restart the app.')),
    );
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  Widget _groupedCard({required List<Widget> children}) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.mediumAll,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md + 24 + AppSpacing.sm,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([_provider, widget.themeProvider]),
      builder: (context, _) {
        final settings = _provider.settings;
        final enabled = settings.enabled;
        final isDark = widget.themeProvider.themeMode == ThemeMode.dark;

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  CapsuleNavBar.contentBottomPadding,
                ),
                children: [
                  Text('Settings', style: textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Reminders, appearance, and data',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Notifications ───────────────────────────────────
                  const SectionTitle(title: 'Notifications'),
                  _groupedCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                        title: 'Enable Reminders',
                        subtitle: 'Hydration alerts on a schedule',
                        trailing: Switch.adaptive(
                          value: settings.enabled,
                          onChanged: (value) =>
                              _update(settings.copyWith(enabled: value)),
                        ),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: 'Reminder Interval',
                        subtitle: AppConstants.intervalLabel(
                          settings.intervalMinutes,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: enabled ? _editInterval : null,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.music_note_outlined),
                        title: 'Reminder Sound',
                        subtitle: settings.soundEnabled
                            ? (settings.customRingtoneTitle?.isNotEmpty == true
                                  ? settings.customRingtoneTitle!
                                  : 'Built-in water chime')
                            : 'Off',
                        trailing: Switch.adaptive(
                          value: settings.soundEnabled,
                          onChanged: enabled
                              ? (value) => _update(
                                  settings.copyWith(soundEnabled: value),
                                )
                              : null,
                        ),
                        onTap: enabled && settings.soundEnabled
                            ? _pickRingtone
                            : null,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.vibration_rounded),
                        title: 'Vibration',
                        subtitle: 'Repeating vibration pattern',
                        trailing: Switch.adaptive(
                          value: settings.vibrationEnabled,
                          onChanged: enabled
                              ? (value) => _update(
                                  settings.copyWith(vibrationEnabled: value),
                                )
                              : null,
                        ),
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.wb_sunny_outlined),
                        title: 'Start Time',
                        subtitle: TimeFormat.timeOfDay(settings.startTime),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: enabled ? _pickStartTime : null,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.nights_stay_outlined),
                        title: 'End Time',
                        subtitle: TimeFormat.timeOfDay(settings.endTime),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: enabled ? _pickEndTime : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Appearance ──────────────────────────────────────
                  const SectionTitle(title: 'Appearance'),
                  _groupedCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: 'Theme',
                        subtitle: _themeLabel(widget.themeProvider.themeMode),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _editTheme,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.dark_mode_outlined),
                        title: 'Dark Mode',
                        subtitle: isDark ? 'On' : 'Off',
                        trailing: Switch.adaptive(
                          value: isDark,
                          onChanged: (value) =>
                              widget.themeProvider.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Data ────────────────────────────────────────────
                  const SectionTitle(title: 'Data'),
                  _groupedCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.ios_share_rounded),
                        title: 'Export Data',
                        subtitle: 'Copy JSON to clipboard',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _exportData,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: 'Backup',
                        subtitle: 'Create a local snapshot',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _backupData,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.restore_rounded),
                        title: 'Restore',
                        subtitle: 'Import from clipboard backup',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _restoreData,
                      ),
                      SettingsTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: colorScheme.error,
                        ),
                        title: 'Reset Data',
                        subtitle: 'Clear logs or wipe everything',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.error,
                        ),
                        destructive: true,
                        onTap: _resetData,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── General ─────────────────────────────────────────
                  const SectionTitle(title: 'General'),
                  _groupedCard(
                    children: [
                      SettingsTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: 'Privacy Policy',
                        subtitle: 'How your data stays on device',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _showPrivacyPolicy,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: 'About',
                        subtitle: AppConstants.tagline,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _showAbout,
                      ),
                      SettingsTile(
                        leading: const Icon(Icons.tag_rounded),
                        title: 'Version',
                        subtitle: '1.0.0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
