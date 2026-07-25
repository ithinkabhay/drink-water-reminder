import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Transparent custom app bar that respects the safe area.
class CustomAppBar extends StatelessWidget {
  /// Creates a custom app bar.
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  /// Primary title on the left.
  final Widget title;

  /// Optional supporting line under [title].
  final Widget? subtitle;

  /// Optional trailing action icons.
  final List<Widget> actions;

  /// Optional leading widget (replaces title block when set with [title]).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: leading ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                  ],
                ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
        ],
      ),
    );
  }
}
