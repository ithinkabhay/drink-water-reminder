import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Material 3 dialog for entering a custom reminder interval in minutes.
class CustomIntervalDialog extends StatefulWidget {
  /// Creates a custom interval dialog.
  const CustomIntervalDialog({
    super.key,
    this.initialMinutes,
  });

  /// Prefills the field when editing an existing custom interval.
  final int? initialMinutes;

  /// Presents the dialog and returns the confirmed minutes, or `null`.
  static Future<int?> show(BuildContext context, {int? initialMinutes}) {
    return showDialog<int>(
      context: context,
      builder: (_) => CustomIntervalDialog(initialMinutes: initialMinutes),
    );
  }

  @override
  State<CustomIntervalDialog> createState() => _CustomIntervalDialogState();
}

class _CustomIntervalDialogState extends State<CustomIntervalDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMinutes;
    _controller = TextEditingController(
      text: initial != null &&
              !AppConstants.reminderIntervalPresetsMinutes.contains(initial)
          ? '$initial'
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Please enter an interval';
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      return 'Enter a whole number in minutes';
    }
    if (value < AppConstants.minCustomIntervalMinutes) {
      return 'Minimum is ${AppConstants.minCustomIntervalMinutes} minutes';
    }
    if (value > AppConstants.maxCustomIntervalMinutes) {
      return 'Maximum is ${AppConstants.maxCustomIntervalMinutes} minutes';
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
      icon: const Icon(Icons.timer_outlined),
      title: const Text('Custom Interval'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Interval',
          hintText: '45',
          suffixText: 'Minutes',
          errorText: _errorText,
          helperText:
              '${AppConstants.minCustomIntervalMinutes}–${AppConstants.maxCustomIntervalMinutes} minutes',
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
