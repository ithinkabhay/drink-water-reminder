import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../repositories/hydration_repository.dart';
import '../utils/constants.dart';
import '../utils/water_goal_calculator.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Screen for viewing and editing the user's profile and daily goal.
class ProfileScreen extends StatefulWidget {
  /// Creates the profile editor.
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final HydrationRepository _repository = HydrationRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _goalController;

  Gender? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = _repository.loadUserProfile();
    final goal = _repository.loadDailyGoalMl();

    _nameController = TextEditingController(text: profile?.name ?? '');
    _ageController = TextEditingController(
      text: profile == null ? '' : '${profile.age}',
    );
    _weightController = TextEditingController(
      text: profile == null ? '' : _formatNumber(profile.weightKg),
    );
    _heightController = TextEditingController(
      text: profile == null ? '' : _formatNumber(profile.heightCm),
    );
    _goalController = TextEditingController(text: '$goal');
    _gender = profile?.gender;
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      weightKg: double.parse(_weightController.text.trim()),
      heightCm: double.parse(_heightController.text.trim()),
      gender: _gender,
    );
    final goal = int.parse(_goalController.text.trim());

    setState(() => _saving = true);
    try {
      await _repository.saveUserProfile(profile);
      await _repository.saveDailyGoalMl(goal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyRecommendedGoal() {
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final name = _nameController.text.trim();

    if (age == null || weight == null || height == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in name, age, weight, and height first.'),
        ),
      );
      return;
    }

    final recommended = WaterGoalCalculator.recommendedDailyGoalMl(
      UserProfile(
        name: name,
        age: age,
        weightKg: weight,
        heightCm: height,
        gender: _gender,
      ),
    );
    setState(() => _goalController.text = recommended.toString());
  }

  String? _requiredName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    if (age == null) return 'Enter a valid age';
    if (age < AppConstants.minAge || age > AppConstants.maxAge) {
      return 'Age must be ${AppConstants.minAge}–${AppConstants.maxAge}';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    final weight = double.tryParse(value?.trim() ?? '');
    if (weight == null) return 'Enter a valid weight';
    if (weight < AppConstants.minWeightKg ||
        weight > AppConstants.maxWeightKg) {
      return 'Weight must be ${AppConstants.minWeightKg.toInt()}–'
          '${AppConstants.maxWeightKg.toInt()} kg';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    final height = double.tryParse(value?.trim() ?? '');
    if (height == null) return 'Enter a valid height';
    if (height < AppConstants.minHeightCm ||
        height > AppConstants.maxHeightCm) {
      return 'Height must be ${AppConstants.minHeightCm.toInt()}–'
          '${AppConstants.maxHeightCm.toInt()} cm';
    }
    return null;
  }

  String? _validateGoal(String? value) {
    final goal = int.tryParse(value?.trim() ?? '');
    if (goal == null) return 'Enter a valid goal';
    if (goal < AppConstants.minDailyGoalMl ||
        goal > AppConstants.maxDailyGoalMl) {
      return 'Goal must be ${AppConstants.minDailyGoalMl}–'
          '${AppConstants.maxDailyGoalMl} ml';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      validator: _requiredName,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: _validateAge,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        suffixText: 'years',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: _validateWeight,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'kg',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 1),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: _validateHeight,
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        suffixText: 'cm',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gender (optional)',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in <(Gender?, String)>[
                    (null, 'Not set'),
                    (Gender.male, 'Male'),
                    (Gender.female, 'Female'),
                    (Gender.other, 'Other'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: _gender == option.$1,
                      onSelected: (_) => setState(() => _gender = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: _validateGoal,
                      decoration: const InputDecoration(
                        labelText: 'Daily goal',
                        suffixText: 'ml',
                        border: InputBorder.none,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _applyRecommendedGoal,
                        icon: Icon(
                          Icons.auto_awesome_rounded,
                          color: colorScheme.primary,
                        ),
                        label: const Text('Use recommended goal'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
