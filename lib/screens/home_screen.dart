import 'package:flutter/material.dart';

import '../models/intake_entry.dart';
import '../models/user_profile.dart';
import '../providers/reminder_provider.dart';
import '../repositories/hydration_repository.dart';
import '../theme/app_spacing.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';
import '../utils/time_format.dart';
import '../widgets/activity_carousel.dart';
import '../widgets/capsule_nav_bar.dart';
import '../widgets/custom_amount_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_celebration.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hydration_circle.dart';
import '../widgets/quick_add_chip.dart';
import '../widgets/section_title.dart';
import 'today_activity_screen.dart';

/// Home screen: greeting, hydration circle, quick add, latest activity.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key, required this.reminderProvider});

  /// Shared reminder settings + notification coordinator.
  final ReminderProvider reminderProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HydrationRepository _repository = HydrationRepository();

  int _consumedMl = 0;
  int _goalMl = AppConstants.defaultDailyGoalMl;
  List<IntakeEntry> _entries = const [];
  UserProfile? _profile;
  bool _celebrate = false;

  double get _progress =>
      _goalMl <= 0 ? 0.0 : (_consumedMl / _goalMl).clamp(0.0, 1.0);

  int get _remainingMl => (_goalMl - _consumedMl).clamp(0, _goalMl);

  @override
  void initState() {
    super.initState();
    AppRefreshBridge.bind(_reload);
    _consumedMl = _repository.loadTodayIntake();
    _goalMl = _repository.loadDailyGoalMl();
    _entries = _repository.loadTodayEntries();
    _profile = _repository.loadUserProfile();
  }

  @override
  void dispose() {
    AppRefreshBridge.unbind(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _consumedMl = _repository.loadTodayIntake();
      _goalMl = _repository.loadDailyGoalMl();
      _entries = _repository.loadTodayEntries();
      _profile = _repository.loadUserProfile();
    });
  }

  /// Adds [amountMl], updates progress, persists via Hive, and shows undo SnackBar.
  Future<void> _addWater(int amountMl) async {
    final wasComplete = _progress >= 1.0;
    final updated = await _repository.addIntake(amountMl);

    if (!mounted) return;

    setState(() {
      _consumedMl = updated;
      _entries = _repository.loadTodayEntries();
    });

    await widget.reminderProvider.onWaterLogged();
    if (!mounted) return;

    final nowComplete = _progress >= 1.0;
    if (!wasComplete && nowComplete) {
      setState(() => _celebrate = true);
    }

    _showAddedSnackBar(amountMl);
  }

  Future<void> _addCustomWater() async {
    final amount = await CustomAmountDialog.show(context);
    if (!mounted || amount == null) return;
    await _addWater(amount);
  }

  void _showAddedSnackBar(int amountMl) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    const displayDuration = Duration(seconds: 3);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $amountMl ml'),
        duration: displayDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 88),
        dismissDirection: DismissDirection.down,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            messenger.hideCurrentSnackBar();
            _undoLastAdd();
          },
        ),
      ),
    );

    Future<void>.delayed(displayDuration, () {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
    });
  }

  Future<void> _undoLastAdd() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final result = await _repository.undoLastIntake();
    if (!mounted || result == null) return;

    setState(() {
      _consumedMl = result.newTotal;
      _entries = _repository.loadTodayEntries();
    });

    await widget.reminderProvider.onWaterLogged();
  }

  void _openTodayActivity() {
    Navigator.of(context)
        .push(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                TodayActivityScreen(entries: _entries),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppConstants.animNormal,
          ),
        )
        .then((_) {
          if (mounted) _reload();
        });
  }

  List<IntakeEntry> get _latestEntries {
    if (_entries.isEmpty) return const [];
    final newestFirst = _entries.reversed.toList();
    return newestFirst.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = _profile?.name.trim() ?? '';
    final greeting = TimeFormat.greetingWithIcon();

    return GradientBackground(
      child: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final landscape = constraints.maxWidth > constraints.maxHeight;
                final horizontal = wide
                    ? constraints.maxWidth * 0.16
                    : AppSpacing.xl;
                final circleSize =
                    (landscape
                            ? constraints.maxHeight * 0.48
                            : constraints.maxWidth * (wide ? 0.38 : 0.62))
                        .clamp(180.0, AppConstants.progressSize);

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      AppSpacing.lg,
                      horizontal,
                      CapsuleNavBar.contentBottomPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Greeting — left aligned with dynamic time icon
                          AnimatedSwitcher(
                            duration: AppConstants.animNormal,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                key: ValueKey<String>('$greeting-$name'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: textTheme.headlineMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                  if (name.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Stay hydrated today.',
                                    style: textTheme.bodyMedium,
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: landscape ? AppSpacing.lg : AppSpacing.xxxl,
                          ),
                          // Hydration Circle
                          Center(
                            child: HydrationCircle(
                              progress: _progress,
                              consumedMl: _consumedMl,
                              goalMl: _goalMl,
                              remainingMl: _remainingMl,
                              size: circleSize,
                            ),
                          ),
                          SizedBox(
                            height: landscape ? AppSpacing.xl : AppSpacing.xxxl,
                          ),
                          // Quick Add
                          QuickAddChips(
                            onAmountSelected: _addWater,
                            onCustomSelected: _addCustomWater,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // Today's Activity
                          SectionTitle(
                            title: "Today's Activity",
                            trailing: TextButton(
                              onPressed: _openTodayActivity,
                              child: const Text('See All'),
                            ),
                          ),
                          if (_latestEntries.isEmpty)
                            const EmptyState(
                              message:
                                  '💧 No water logged today. Start by adding your first drink.',
                              icon: Icons.water_drop_outlined,
                            )
                          else
                            ActivityCarousel(
                              entries: _latestEntries,
                              onCardTap: (_) => _openTodayActivity(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GoalCelebration(
            visible: _celebrate,
            onDismissed: () {
              if (mounted) setState(() => _celebrate = false);
            },
          ),
        ],
      ),
    );
  }
}
