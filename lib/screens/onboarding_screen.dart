import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../providers/reminder_provider.dart';
import '../repositories/hydration_repository.dart';
import '../utils/constants.dart';
import '../utils/water_goal_calculator.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';

/// First-launch multi-step onboarding that collects profile data and a goal.
class OnboardingScreen extends StatefulWidget {
  /// Creates the onboarding experience.
  const OnboardingScreen({
    super.key,
    required this.reminderProvider,
  });

  /// Shared reminder coordinator passed through to [HomeScreen].
  final ReminderProvider reminderProvider;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final HydrationRepository _repository = HydrationRepository();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  int _pageIndex = 0;
  Gender? _gender;
  int? _recommendedGoalMl;
  bool _saving = false;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  UserProfile? _buildProfile() {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (name.isEmpty || age == null || weight == null || height == null) {
      return null;
    }
    if (age < AppConstants.minAge || age > AppConstants.maxAge) return null;
    if (weight < AppConstants.minWeightKg ||
        weight > AppConstants.maxWeightKg) {
      return null;
    }
    if (height < AppConstants.minHeightCm ||
        height > AppConstants.maxHeightCm) {
      return null;
    }

    return UserProfile(
      name: name,
      age: age,
      weightKg: weight,
      heightCm: height,
      gender: _gender,
    );
  }

  bool _validateCurrentPage() {
    switch (_pageIndex) {
      case 0:
        return true;
      case 1:
        if (_nameController.text.trim().isEmpty) {
          _showMessage('Please enter your name.');
          return false;
        }
        return true;
      case 2:
        final profile = _buildProfile();
        if (profile == null) {
          _showMessage('Please enter a valid age, weight, and height.');
          return false;
        }
        return true;
      case 3:
        final goal = int.tryParse(_goalController.text.trim());
        if (goal == null ||
            goal < AppConstants.minDailyGoalMl ||
            goal > AppConstants.maxDailyGoalMl) {
          _showMessage(
            'Choose a goal between ${AppConstants.minDailyGoalMl} and '
            '${AppConstants.maxDailyGoalMl} ml.',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _goNext() async {
    if (!_validateCurrentPage()) return;

    if (_pageIndex == 2) {
      final profile = _buildProfile()!;
      final recommended = WaterGoalCalculator.recommendedDailyGoalMl(profile);
      _recommendedGoalMl = recommended;
      _goalController.text = recommended.toString();
    }

    if (_pageIndex >= _pageCount - 1) {
      await _finish();
      return;
    }

    setState(() => _pageIndex += 1);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_pageIndex == 0) return;
    setState(() => _pageIndex -= 1);
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final profile = _buildProfile();
    final goal = int.tryParse(_goalController.text.trim());
    if (profile == null || goal == null) {
      _showMessage('Please complete your profile details.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.completeOnboarding(
        profile: profile,
        dailyGoalMl: goal,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomeScreen(reminderProvider: widget.reminderProvider),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 420),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _pageIndex > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: _pageIndex > 0 ? _goBack : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (_pageIndex + 1) / _pageCount,
                          minHeight: 6,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _WelcomeStep(textTheme: textTheme, colorScheme: colorScheme),
                    _NameStep(
                      controller: _nameController,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    _BodyMetricsStep(
                      ageController: _ageController,
                      weightController: _weightController,
                      heightController: _heightController,
                      gender: _gender,
                      onGenderChanged: (value) => setState(() => _gender = value),
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    _GoalStep(
                      goalController: _goalController,
                      recommendedGoalMl: _recommendedGoalMl,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton(
                  onPressed: _saving ? null : _goNext,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          _pageIndex == _pageCount - 1
                              ? 'Get started'
                              : 'Continue',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.textTheme,
    required this.colorScheme,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            Icons.water_drop_rounded,
            size: 72,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to ${AppConstants.brandName}',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tell us a little about yourself so we can personalize your '
            'daily water goal and keep you refreshed.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.textTheme,
    required this.colorScheme,
  });

  final TextEditingController controller;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'What should we call you?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your name appears in daily greetings on the home screen.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          GlassCard(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsStep extends StatelessWidget {
  const _BodyMetricsStep({
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.gender,
    required this.onGenderChanged,
    required this.textTheme,
    required this.colorScheme,
  });

  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your body metrics',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use these to recommend a daily water target. Gender is optional.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                _MetricField(
                  controller: ageController,
                  label: 'Age',
                  suffix: 'years',
                  keyboardType: TextInputType.number,
                ),
                const Divider(height: 1),
                _MetricField(
                  controller: weightController,
                  label: 'Weight',
                  suffix: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const Divider(height: 1),
                _MetricField(
                  controller: heightController,
                  label: 'Height',
                  suffix: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gender (optional)',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in <(Gender?, String)>[
                (null, 'Skip'),
                (Gender.male, 'Male'),
                (Gender.female, 'Female'),
                (Gender.other, 'Other'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: gender == option.$1,
                  onSelected: (_) => onGenderChanged(option.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: InputBorder.none,
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.goalController,
    required this.recommendedGoalMl,
    required this.textTheme,
    required this.colorScheme,
  });

  final TextEditingController goalController;
  final int? recommendedGoalMl;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your daily water goal',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We calculated a recommendation from your profile. '
            'Feel free to customize it.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (recommendedGoalMl != null) ...[
            GlassCard(
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recommended: $recommendedGoalMl ml',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      goalController.text = recommendedGoalMl.toString();
                    },
                    child: const Text('Use'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GlassCard(
            child: TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Daily goal',
                suffixText: 'ml',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in AppConstants.quickDailyGoalOptionsMl)
                ActionChip(
                  label: Text('$preset ml'),
                  onPressed: () => goalController.text = preset.toString(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
