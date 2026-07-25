import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Consistent section header with optional trailing action.
class SectionTitle extends StatelessWidget {
  /// Creates a section title.
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  /// Section headline.
  final String title;

  /// Optional supporting copy.
  final String? subtitle;

  /// Optional trailing control (e.g. See All).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ?trailing,          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
