/// Optional gender used for personalized hydration recommendations.
enum Gender {
  /// Male.
  male,

  /// Female.
  female,

  /// Other / non-binary.
  other,
}

/// Persisted user profile collected during onboarding (and editable later).
class UserProfile {
  /// Creates a user profile.
  const UserProfile({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    this.gender,
  });

  /// Display name used in greetings.
  final String name;

  /// Age in years.
  final int age;

  /// Body weight in kilograms.
  final double weightKg;

  /// Height in centimeters.
  final double heightCm;

  /// Optional gender for goal recommendations.
  final Gender? gender;

  /// Serializes this profile for Hive JSON storage.
  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'gender': gender?.name,
      };

  /// Deserializes a profile from Hive JSON.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final genderRaw = json['gender'] as String?;
    Gender? gender;
    if (genderRaw != null) {
      for (final value in Gender.values) {
        if (value.name == genderRaw) {
          gender = value;
          break;
        }
      }
    }

    return UserProfile(
      name: (json['name'] as String?)?.trim() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      gender: gender,
    );
  }

  /// Returns a copy with the given fields replaced.
  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    Gender? gender,
    bool clearGender = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }

  /// Human-readable gender label, or `null` when unset.
  String? get genderLabel {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case null:
        return null;
    }
  }
}
