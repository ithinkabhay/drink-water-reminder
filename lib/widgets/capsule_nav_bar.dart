import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';

/// Destination for [CapsuleNavBar].
class CapsuleNavItem {
  /// Creates a nav destination.
  const CapsuleNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Text shown only when this item is selected.
  final String label;

  /// Icon for the unselected state.
  final IconData icon;

  /// Icon for the selected state.
  final IconData selectedIcon;
}

/// Floating pill navigation — only the capsule paints a background.
///
/// The bar wraps its content (not a full-width rectangle). Selected tabs show
/// a blue pill with icon + label; unselected tabs show icon only.
class CapsuleNavBar extends StatelessWidget {
  /// Creates a floating capsule navigation bar.
  const CapsuleNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  /// Tab destinations (typically 3–5).
  final List<CapsuleNavItem> items;

  /// Currently selected tab index.
  final int selectedIndex;

  /// Called when the user taps a destination.
  final ValueChanged<int> onItemSelected;

  static const double _capsuleHeight = 60;
  static const double _horizontalInset = 24;
  static const double _bottomGap = 10;
  static const double _itemGap = 4;

  /// Scroll-view padding that keeps the final item above the floating capsule.
  static const double contentBottomPadding =
      _capsuleHeight + _bottomGap + AppSpacing.xl;

  /// Outer horizontal inset used when positioning the bar.
  static double get horizontalMargin => _horizontalInset;

  /// Outer vertical inset above the system safe-area.
  static double get verticalMargin => _bottomGap;

  /// Bar height (excluding margins / safe area).
  static double get barHeight => _capsuleHeight;

  /// Total bottom clearance so page content clears the floating bar.
  static double contentClearance(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return _capsuleHeight + _bottomGap * 2 + bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final surface = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceLight;
    final unselectedColor = colorScheme.onSurfaceVariant;
    final maxWidth = MediaQuery.sizeOf(context).width - (_horizontalInset * 2);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: _bottomGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface.withValues(alpha: isDark ? 0.94 : 0.97),
              borderRadius: AppRadius.capsuleAll,
              border: Border.all(
                color: colorScheme.outline.withValues(
                  alpha: isDark ? 0.16 : 0.08,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 6,
              ),
              child: AnimatedSize(
                duration: AppConstants.animNormal,
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(width: _itemGap),
                        _CapsuleNavTile(
                          item: items[i],
                          selected: i == selectedIndex,
                          unselectedColor: unselectedColor,
                          onTap: () => onItemSelected(i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleNavTile extends StatelessWidget {
  const _CapsuleNavTile({
    required this.item,
    required this.selected,
    required this.unselectedColor,
    required this.onTap,
  });

  final CapsuleNavItem item;
  final bool selected;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconColor = selected ? Colors.white : unselectedColor;
    final iconData = selected ? item.selectedIcon : item.icon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const StadiumBorder(),
        splashColor: AppColors.primary.withValues(alpha: 0.14),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: AppConstants.animNormal,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 14 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.capsuleAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppConstants.animFast,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  iconData,
                  key: ValueKey<String>('${item.label}-$selected'),
                  size: 22,
                  color: iconColor,
                ),
              ),
              AnimatedSize(
                duration: AppConstants.animNormal,
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
