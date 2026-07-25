import 'package:flutter/material.dart';

/// Corner radius tokens for Waterly surfaces and controls.
class AppRadius {
  const AppRadius._();

  static const double small = 12;
  static const double medium = 20;
  static const double large = 28;
  /// Premium bottom sheets (~32px).
  static const double sheet = 32;
  static const double capsule = 999;

  static BorderRadius get smallAll => BorderRadius.circular(small);
  static BorderRadius get mediumAll => BorderRadius.circular(medium);
  static BorderRadius get largeAll => BorderRadius.circular(large);
  static BorderRadius get sheetAll => BorderRadius.circular(sheet);
  static BorderRadius get sheetTop =>
      const BorderRadius.vertical(top: Radius.circular(sheet));
  static BorderRadius get capsuleAll => BorderRadius.circular(capsule);
}
