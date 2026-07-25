import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'custom_amount_dialog.dart';
import 'premium_bottom_sheet.dart';
import 'quick_add_chip.dart';

/// Premium bottom sheet for logging water.
class AddWaterSheet extends StatelessWidget {
  /// Creates the add-water sheet content.
  const AddWaterSheet({
    super.key,
    required this.onAmountSelected,
  });

  /// Called with a chosen amount (sheet pops itself before calling).
  final ValueChanged<int> onAmountSelected;

  /// Shows the sheet and returns the selected amount, if any.
  static Future<int?> show(BuildContext context) {
    return PremiumBottomSheet.show<int>(
      context: context,
      builder: (context) => AddWaterSheet(
        onAmountSelected: (amount) {
          Navigator.of(context).pop(amount);
        },
      ),
    );
  }

  Future<void> _onCustom(BuildContext context) async {
    final amount = await CustomAmountDialog.show(context);
    if (amount == null) return;
    onAmountSelected(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PremiumBottomSheet(
      title: 'Add Water',
      subtitle: 'Choose an amount to log',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop_rounded,
            color: colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.xl),
          QuickAddAmountGrid(
            onAmountSelected: onAmountSelected,
            onCustomSelected: () => _onCustom(context),
          ),
        ],
      ),
    );
  }
}
