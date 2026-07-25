import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';

/// Large circular avatar with optional gallery photo and edit affordance.
class ProfileAvatar extends StatelessWidget {
  /// Creates a profile avatar.
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.onEditPhoto,
    this.radius = 56,
  });

  /// Used for the placeholder initial.
  final String name;

  /// Absolute path to a local image file, if any.
  final String? imagePath;

  /// When set, shows an edit badge and handles taps.
  final VoidCallback? onEditPhoto;

  /// Avatar circle radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final display = name.trim().isEmpty ? 'W' : name.trim();
    final initial = display.substring(0, 1).toUpperCase();
    final file = imagePath != null ? File(imagePath!) : null;
    final hasImage = file != null && file.existsSync();

    return SizedBox(
      width: radius * 2 + 8,
      height: radius * 2 + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.35),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                clipBehavior: Clip.antiAlias,
                child: SizedBox.square(
                  dimension: radius * 2 - 6,
                  child: hasImage
                      ? Image.file(
                          file,
                          key: ValueKey<String>(
                            '$imagePath-${file.lastModifiedSync().millisecondsSinceEpoch}',
                          ),
                          width: radius * 2 - 6,
                          height: radius * 2 - 6,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: false,
                          errorBuilder: (context, error, stackTrace) {
                            return _AvatarPlaceholder(
                              initial: initial,
                              radius: radius,
                              color: colorScheme.primary,
                              textTheme: textTheme,
                            );
                          },
                        )
                      : _AvatarPlaceholder(
                          initial: initial,
                          radius: radius,
                          color: colorScheme.primary,
                          textTheme: textTheme,
                        ),
                ),
              ),
            ),
          ),
          if (onEditPhoto != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onEditPhoto!();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Picks a gallery image, copies it into app documents, returns the new path.
class ProfilePhotoService {
  const ProfilePhotoService._();

  static final ImagePicker _picker = ImagePicker();

  /// Opens the gallery and persists a local copy under documents.
  static Future<String?> pickAndPersist() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (picked == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dest = File(
      '${docs.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(picked.path).copy(dest.path);

    // A fresh filename prevents Flutter's image cache from showing the
    // previously selected photo. Remove older local avatar copies afterward.
    await for (final entity in docs.list()) {
      if (entity is! File || entity.path == dest.path) continue;
      final filename = entity.uri.pathSegments.last;
      if (filename == 'profile_avatar.jpg' ||
          filename.startsWith('profile_avatar_')) {
        try {
          await entity.delete();
        } catch (_) {
          // The old image may still be in use for the current frame.
        }
      }
    }
    return dest.path;
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({
    required this.initial,
    required this.radius,
    required this.color,
    required this.textTheme,
  });

  final String initial;
  final double radius;
  final Color color;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.10),
      child: Center(
        child: Text(
          initial,
          style: textTheme.headlineLarge?.copyWith(
            color: color,
            fontSize: radius * 0.7,
          ),
        ),
      ),
    );
  }
}

/// Compact achievement metric card.
class AchievementCard extends StatelessWidget {
  /// Creates an achievement metric card.
  const AchievementCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.mediumAll,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Premium profile info row: icon, title, value, chevron.
class ProfileDetailTile extends StatelessWidget {
  /// Creates a tappable profile detail row.
  const ProfileDetailTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: AppRadius.mediumAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpacing.md + 22 + AppSpacing.sm,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
      ],
    );
  }
}

/// Shared validators for profile / goal edit sheets.
class ProfileValidators {
  const ProfileValidators._();

  static String? name(String value) {
    if (value.isEmpty) return 'Name is required';
    return null;
  }

  static String? age(String value) {
    final age = int.tryParse(value);
    if (age == null) return 'Enter a valid age';
    if (age < AppConstants.minAge || age > AppConstants.maxAge) {
      return 'Age must be ${AppConstants.minAge}–${AppConstants.maxAge}';
    }
    return null;
  }

  static String? weight(String value) {
    final weight = double.tryParse(value);
    if (weight == null) return 'Enter a valid weight';
    if (weight < AppConstants.minWeightKg ||
        weight > AppConstants.maxWeightKg) {
      return 'Weight must be ${AppConstants.minWeightKg.toInt()}–'
          '${AppConstants.maxWeightKg.toInt()} kg';
    }
    return null;
  }

  static String? height(String value) {
    final height = double.tryParse(value);
    if (height == null) return 'Enter a valid height';
    if (height < AppConstants.minHeightCm ||
        height > AppConstants.maxHeightCm) {
      return 'Height must be ${AppConstants.minHeightCm.toInt()}–'
          '${AppConstants.maxHeightCm.toInt()} cm';
    }
    return null;
  }

  static String? goal(String value) {
    final goal = int.tryParse(value);
    if (goal == null) return 'Enter a valid goal';
    if (goal < AppConstants.minDailyGoalMl ||
        goal > AppConstants.maxDailyGoalMl) {
      return 'Goal must be ${AppConstants.minDailyGoalMl}–'
          '${AppConstants.maxDailyGoalMl} ml';
    }
    return null;
  }
}
