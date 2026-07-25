import 'package:flutter/material.dart';

import '../providers/reminder_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../widgets/capsule_nav_bar.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Root shell with a floating capsule bottom navigation (4 tabs).
///
/// Only the selected destination shows its label.
class MainShell extends StatefulWidget {
  /// Creates the main tab shell.
  const MainShell({
    super.key,
    required this.reminderProvider,
    required this.themeProvider,
    this.initialIndex = 0,
  });

  /// Shared reminder settings + notification coordinator.
  final ReminderProvider reminderProvider;

  /// Theme preference controller.
  final ThemeProvider themeProvider;

  /// Starting tab index.
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  static const _destinations = <CapsuleNavItem>[
    CapsuleNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    CapsuleNavItem(
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    CapsuleNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
    CapsuleNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  void _onTabSelected(int value) {
    if (value == _index) return;
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(reminderProvider: widget.reminderProvider),
      const InsightsScreen(),
      ProfileScreen(reminderProvider: widget.reminderProvider),
      SettingsScreen(
        reminderProvider: widget.reminderProvider,
        themeProvider: widget.themeProvider,
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: AppConstants.animNormal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset =
                  Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_index),
              child: pages[_index],
            ),
          ),
          // Constrain the overlay to its intrinsic height. An Align here would
          // expand the navigation layer and create a full-width bottom strip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CapsuleNavBar(
              items: _destinations,
              selectedIndex: _index,
              onItemSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
