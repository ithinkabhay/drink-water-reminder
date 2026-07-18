import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Material 3 dialog for entering a custom daily water goal.
///
/// Accepts numeric input only, enforces
/// [AppConstants.minDailyGoalMl]–[AppConstants.maxDailyGoalMl], and shows
/// validation errors before confirming.
class CustomGoalDialog extends StatefulWidget {
  /// Creates a custom goal dialog seeded with [initialGoalMl].
  const CustomGoalDialog({
    super.key,
    required this.initialGoalMl,
  });

  /// Value shown when the dialog opens.
  final int initialGoalMl;

  /// Presents the dialog and returns the confirmed goal, or `null` if cancelled.
  static Future<int?> show(
    BuildContext context, {
    required int initialGoalMl,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => CustomGoalDialog(initialGoalMl: initialGoalMl),
    );
  }

  @override
  State<CustomGoalDialog> createState() => _CustomGoalDialogState();
}

class _CustomGoalDialogState extends State<CustomGoalDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialGoalMl}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a goal';
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      return 'Enter a whole number in milliliters';
    }
    if (value < AppConstants.minDailyGoalMl) {
      return 'Minimum goal is ${AppConstants.minDailyGoalMl} ml';
    }
    if (value > AppConstants.maxDailyGoalMl) {
      return 'Maximum goal is ${AppConstants.maxDailyGoalMl} ml';
    }
    return null;
  }

  void _onChanged(String _) {
    if (_errorText == null) return;
    setState(() => _errorText = _validate(_controller.text));
  }

  void _submit() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.edit_outlined),
      title: const Text('Custom Goal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Daily goal',
          hintText: '${AppConstants.defaultDailyGoalMl}',
          suffixText: 'ml',
          errorText: _errorText,
          border: const OutlineInputBorder(),
        ),
        onChanged: _onChanged,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
