import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Material 3 dialog for entering a custom quick-add water amount.
///
/// Accepts numeric input only, enforces
/// [AppConstants.minCustomAmountMl]–[AppConstants.maxCustomAmountMl], and
/// closes after a successful save.
class CustomAmountDialog extends StatefulWidget {
  /// Creates a custom amount dialog.
  const CustomAmountDialog({super.key});

  /// Presents the dialog and returns the confirmed amount, or `null` if cancelled.
  static Future<int?> show(BuildContext context) {
    return showDialog<int>(
      context: context,
      builder: (_) => const CustomAmountDialog(),
    );
  }

  @override
  State<CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<CustomAmountDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Please enter an amount';
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      return 'Enter a whole number in milliliters';
    }
    if (value < AppConstants.minCustomAmountMl) {
      return 'Minimum amount is ${AppConstants.minCustomAmountMl} ml';
    }
    if (value > AppConstants.maxCustomAmountMl) {
      return 'Maximum amount is ${AppConstants.maxCustomAmountMl} ml';
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
      icon: const Icon(Icons.water_drop_outlined),
      title: const Text('Custom Amount'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Amount',
          hintText: '250',
          suffixText: 'ml',
          errorText: _errorText,
          helperText:
              '${AppConstants.minCustomAmountMl}–${AppConstants.maxCustomAmountMl} ml',
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
