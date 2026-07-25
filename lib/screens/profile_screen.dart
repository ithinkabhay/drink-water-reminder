import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/hydration_stats.dart';
import '../models/user_profile.dart';
import '../providers/reminder_provider.dart';
import '../repositories/hydration_repository.dart';
import '../services/hydration_history_service.dart';
import '../theme/app_spacing.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';
import '../widgets/capsule_nav_bar.dart';
import '../widgets/custom_interval_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/premium_bottom_sheet.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/section_title.dart';

/// Premium personal account page with avatar, details, and achievements.
class ProfileScreen extends StatefulWidget {
  /// Creates the profile screen.
  const ProfileScreen({super.key, this.reminderProvider});

  /// Optional reminder coordinator used after goal / interval changes.
  final ReminderProvider? reminderProvider;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final HydrationRepository _repository = HydrationRepository();
  final HydrationHistoryService _history = HydrationHistoryService();

  UserProfile? _profile;
  String? _avatarPath;
  int _goalMl = AppConstants.defaultDailyGoalMl;
  int _reminderIntervalMinutes = 45;
  int _consumedMl = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  double _completionRate = 0;

  @override
  void initState() {
    super.initState();
    AppRefreshBridge.bind(_reload);
    _reload();
  }

  @override
  void dispose() {
    AppRefreshBridge.unbind(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final stats = _history.loadStats(HistoryPeriod.month);
    final history = _repository.loadHistoryMap();
    final goal = _repository.loadDailyGoalMl();
    var met = 0;
    var counted = 0;
    for (final entry in history.entries) {
      if (entry.value <= 0) continue;
      counted++;
      if (entry.value >= goal) met++;
    }

    setState(() {
      _profile = _repository.loadUserProfile();
      _avatarPath = _validAvatarPath(_repository.loadProfileAvatarPath());
      _goalMl = goal;
      _reminderIntervalMinutes = _repository
          .loadReminderSettings()
          .intervalMinutes;
      _consumedMl = _repository.loadTodayIntake();
      _currentStreak = _repository.loadCurrentStreak();
      _longestStreak = stats.longestStreak;
      _completionRate = counted == 0 ? 0 : met / counted;
    });
  }

  String? _validAvatarPath(String? path) {
    if (path == null || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
  }

  String _genderLabel(Gender? gender) {
    return switch (gender) {
      Gender.male => 'Male',
      Gender.female => 'Female',
      Gender.other => 'Other',
      null => 'Not set',
    };
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  Future<void> _ensureProfile() async {
    if (_profile != null) return;
    final blank = const UserProfile(
      name: '',
      age: 25,
      weightKg: 70,
      heightCm: 170,
    );
    await _repository.saveUserProfile(blank);
    _profile = blank;
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await ProfilePhotoService.pickAndPersist();
      if (path == null || !mounted) return;
      await _repository.saveProfileAvatarPath(path);
      AppRefreshBridge.notify();
      if (!mounted) return;
      setState(() => _avatarPath = path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not update photo')));
    }
  }

  Future<void> _editName() async {
    await _ensureProfile();
    if (!mounted) return;
    final value = await EditTextSheet.show(
      context: context,
      title: 'Edit Name',
      subtitle: 'How should we greet you?',
      label: 'Name',
      initialValue: _profile?.name ?? '',
      textCapitalization: TextCapitalization.words,
      validator: ProfileValidators.name,
    );
    if (value == null || !mounted) return;
    await _repository.saveUserProfile(_profile!.copyWith(name: value));
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editAge() async {
    await _ensureProfile();
    if (!mounted) return;
    final value = await EditTextSheet.show(
      context: context,
      title: 'Edit Age',
      label: 'Age',
      suffixText: 'years',
      initialValue: _profile == null ? '' : '${_profile!.age}',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: ProfileValidators.age,
    );
    if (value == null || !mounted) return;
    await _repository.saveUserProfile(
      _profile!.copyWith(age: int.parse(value)),
    );
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editWeight() async {
    await _ensureProfile();
    if (!mounted) return;
    final value = await EditTextSheet.show(
      context: context,
      title: 'Edit Weight',
      label: 'Weight',
      suffixText: 'kg',
      initialValue: _profile == null ? '' : _formatNumber(_profile!.weightKg),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: ProfileValidators.weight,
    );
    if (value == null || !mounted) return;
    await _repository.saveUserProfile(
      _profile!.copyWith(weightKg: double.parse(value)),
    );
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editHeight() async {
    await _ensureProfile();
    if (!mounted) return;
    final value = await EditTextSheet.show(
      context: context,
      title: 'Edit Height',
      label: 'Height',
      suffixText: 'cm',
      initialValue: _profile == null ? '' : _formatNumber(_profile!.heightCm),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: ProfileValidators.height,
    );
    if (value == null || !mounted) return;
    await _repository.saveUserProfile(
      _profile!.copyWith(heightCm: double.parse(value)),
    );
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editGender() async {
    await _ensureProfile();
    if (!mounted) return;

    Gender? selected = _profile?.gender;
    final confirmed = await PremiumBottomSheet.show<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            return PremiumBottomSheet(
              title: 'Gender',
              subtitle: 'Used for personalized goal tips',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in <(Gender?, String)>[
                    (null, 'Not set'),
                    (Gender.male, 'Male'),
                    (Gender.female, 'Female'),
                    (Gender.other, 'Other'),
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.$2),
                      trailing: selected == option.$1
                          ? Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setSheetState(() => selected = option.$1);
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _repository.saveUserProfile(
      selected == null
          ? _profile!.copyWith(clearGender: true)
          : _profile!.copyWith(gender: selected),
    );
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editGoal() async {
    final value = await EditTextSheet.show(
      context: context,
      title: 'Daily Goal',
      subtitle: 'How much water do you want each day?',
      label: 'Goal',
      suffixText: 'ml',
      initialValue: '$_goalMl',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: ProfileValidators.goal,
    );
    if (value == null || !mounted) return;
    await _repository.saveDailyGoalMl(int.parse(value));
    await widget.reminderProvider?.onWaterLogged();
    AppRefreshBridge.notify();
    _reload();
  }

  Future<void> _editInterval() async {
    final settings = _repository.loadReminderSettings();
    final presets = AppConstants.reminderIntervalPresetsMinutes;
    final options = <(int, String)>[
      for (final m in presets) (m, AppConstants.intervalLabel(m)),
      (AppConstants.customIntervalSentinel, 'Custom'),
    ];

    final selected = presets.contains(settings.intervalMinutes)
        ? settings.intervalMinutes
        : AppConstants.customIntervalSentinel;

    final picked = await EditChoiceSheet.show<int>(
      context: context,
      title: 'Reminder Interval',
      subtitle: 'How often should we nudge you?',
      selected: selected,
      options: options,
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
      final provider = widget.reminderProvider;
      if (provider != null) {
        final error = await provider.setCustomIntervalMinutes(minutes);
        if (error != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      } else {
        await _repository.saveReminderSettings(
          settings.copyWith(intervalMinutes: minutes),
        );
      }
    } else {
      final provider = widget.reminderProvider;
      if (provider != null) {
        await provider.setIntervalMinutes(picked);
      } else {
        await _repository.saveReminderSettings(
          settings.copyWith(intervalMinutes: picked),
        );
      }
    }

    AppRefreshBridge.notify();
    _reload();
  }

  String get _todayGoalLabel {
    final pct = _goalMl <= 0
        ? 0
        : ((_consumedMl / _goalMl) * 100).clamp(0, 100).round();
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = _profile?.name.trim().isNotEmpty == true
        ? _profile!.name.trim()
        : 'Your name';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final horizontal = wide
                  ? constraints.maxWidth * 0.16
                  : AppSpacing.xl;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.lg,
                  horizontal,
                  CapsuleNavBar.contentBottomPadding,
                ),
                children: [
                  // ── Header ──────────────────────────────────────────
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: ProfileAvatar(
                      name: name,
                      imagePath: _avatarPath,
                      onEditPhoto: _pickPhoto,
                      radius: 58,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    name,
                    style: textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Stay hydrated every day 💧',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: OutlinedButton(
                      onPressed: _editName,
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Personal Information ────────────────────────────
                  const SectionTitle(title: 'Personal Information'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        ProfileDetailTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Name',
                          value: name,
                          onTap: _editName,
                        ),
                        ProfileDetailTile(
                          icon: Icons.cake_outlined,
                          title: 'Age',
                          value: _profile == null
                              ? '—'
                              : '${_profile!.age} years',
                          onTap: _editAge,
                        ),
                        ProfileDetailTile(
                          icon: Icons.monitor_weight_outlined,
                          title: 'Weight',
                          value: _profile == null
                              ? '—'
                              : '${_formatNumber(_profile!.weightKg)} kg',
                          onTap: _editWeight,
                        ),
                        ProfileDetailTile(
                          icon: Icons.height_rounded,
                          title: 'Height',
                          value: _profile == null
                              ? '—'
                              : '${_formatNumber(_profile!.heightCm)} cm',
                          onTap: _editHeight,
                        ),
                        ProfileDetailTile(
                          icon: Icons.wc_rounded,
                          title: 'Gender',
                          value: _genderLabel(_profile?.gender),
                          onTap: _editGender,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Hydration Preferences ───────────────────────────
                  const SectionTitle(title: 'Hydration Preferences'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        ProfileDetailTile(
                          icon: Icons.flag_outlined,
                          title: 'Daily Goal',
                          value: '$_goalMl ml',
                          onTap: _editGoal,
                        ),
                        ProfileDetailTile(
                          icon: Icons.timer_outlined,
                          title: 'Reminder Interval',
                          value: AppConstants.intervalLabel(
                            _reminderIntervalMinutes,
                          ),
                          onTap: _editInterval,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Achievements ────────────────────────────────────
                  const SectionTitle(title: 'Achievements'),
                  Row(
                    children: [
                      Expanded(
                        child: AchievementCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Current Streak',
                          value: _currentStreak == 1
                              ? '1 day'
                              : '$_currentStreak days',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AchievementCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'Longest Streak',
                          value: _longestStreak == 1
                              ? '1 day'
                              : '$_longestStreak days',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AchievementCard(
                          icon: Icons.water_drop_outlined,
                          label: "Today's Goal",
                          value: _todayGoalLabel,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AchievementCard(
                          icon: Icons.insights_rounded,
                          label: 'Completion Rate',
                          value: '${(_completionRate * 100).round()}%',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
