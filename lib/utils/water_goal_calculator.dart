import '../models/user_profile.dart';
import 'constants.dart';

/// Calculates a recommended daily water goal from a [UserProfile].
///
/// Uses a weight-based baseline with light adjustments for gender and age,
/// then clamps to the app's allowed daily-goal range.
class WaterGoalCalculator {
  /// Private constructor — this class is not meant to be instantiated.
  const WaterGoalCalculator._();

  /// Milliliters per kilogram baseline when gender is unknown.
  static const double _mlPerKgDefault = 33;

  /// Milliliters per kilogram for male profiles.
  static const double _mlPerKgMale = 35;

  /// Milliliters per kilogram for female profiles.
  static const double _mlPerKgFemale = 31;

  /// Milliliters per kilogram for other / non-binary profiles.
  static const double _mlPerKgOther = 33;

  /// Recommended daily intake in milliliters for [profile].
  static int recommendedDailyGoalMl(UserProfile profile) {
    final mlPerKg = switch (profile.gender) {
      Gender.male => _mlPerKgMale,
      Gender.female => _mlPerKgFemale,
      Gender.other => _mlPerKgOther,
      null => _mlPerKgDefault,
    };

    var goal = profile.weightKg * mlPerKg;

    // Slightly lower needs are common for older adults.
    if (profile.age >= 55) {
      goal *= 0.95;
    } else if (profile.age < 18) {
      goal *= 0.9;
    }

    // Round to nearest 50 ml for a clean, editable target.
    final rounded = ((goal / 50).round() * 50).toInt();

    return rounded.clamp(
      AppConstants.minDailyGoalMl,
      AppConstants.maxDailyGoalMl,
    );
  }
}
