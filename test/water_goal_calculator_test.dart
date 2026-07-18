import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water_reminder/models/user_profile.dart';
import 'package:drink_water_reminder/utils/water_goal_calculator.dart';

void main() {
  test('recommends a weight-based daily goal', () {
    const profile = UserProfile(
      name: 'Alex',
      age: 30,
      weightKg: 70,
      heightCm: 175,
      gender: Gender.male,
    );

    final goal = WaterGoalCalculator.recommendedDailyGoalMl(profile);
    // 70kg * 35ml = 2450 → rounds to nearest 50.
    expect(goal, 2450);
  });

  test('applies female and age adjustments', () {
    const olderFemale = UserProfile(
      name: 'Sam',
      age: 60,
      weightKg: 65,
      heightCm: 165,
      gender: Gender.female,
    );

    final goal = WaterGoalCalculator.recommendedDailyGoalMl(olderFemale);
    // 65 * 31 * 0.95 = 1914.25 → nearest 50 = 1900.
    expect(goal, 1900);
  });

  test('serializes and deserializes user profile', () {
    const original = UserProfile(
      name: 'Jordan',
      age: 25,
      weightKg: 68.5,
      heightCm: 172,
      gender: Gender.other,
    );

    final restored = UserProfile.fromJson(original.toJson());
    expect(restored.name, original.name);
    expect(restored.age, original.age);
    expect(restored.weightKg, original.weightKg);
    expect(restored.heightCm, original.heightCm);
    expect(restored.gender, original.gender);
  });
}
