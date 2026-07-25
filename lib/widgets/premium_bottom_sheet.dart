import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';

/// Shared premium modal bottom sheet shell (32px radius, blur, handle).
class PremiumBottomSheet extends StatelessWidget {
  /// Creates sheet content wrapped in the shared chrome.
  const PremiumBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  /// Sheet body below the optional title block.
  final Widget child;

  /// Optional headline.
  final String? title;

  /// Optional supporting copy under [title].
  final String? subtitle;

  /// Presents [builder] inside the shared sheet chrome.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      showDragHandle: false,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: AppRadius.sheetTop,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: AppRadius.sheetTop,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: AnimatedPadding(
              duration: AppConstants.animFast,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl + safeBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.35),
                        borderRadius: AppRadius.capsuleAll,
                      ),
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(title!, style: textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ] else
                    const SizedBox(height: AppSpacing.md),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text field edit sheet with Save action.
class EditTextSheet extends StatefulWidget {
  /// Creates a text edit sheet.
  const EditTextSheet({
    super.key,
    required this.title,
    required this.initialValue,
    this.subtitle,
    this.label,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final String title;
  final String? subtitle;
  final String initialValue;
  final String? label;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? validator;
  final TextCapitalization textCapitalization;

  /// Shows the sheet and returns the trimmed value, or `null` if cancelled.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String initialValue,
    String? subtitle,
    String? label,
    String? suffixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return PremiumBottomSheet.show<String>(
      context: context,
      builder: (context) => EditTextSheet(
        title: title,
        subtitle: subtitle,
        initialValue: initialValue,
        label: label,
        suffixText: suffixText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textCapitalization: textCapitalization,
      ),
    );
  }

  @override
  State<EditTextSheet> createState() => _EditTextSheetState();
}

class _EditTextSheetState extends State<EditTextSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: widget.label,
              suffixText: widget.suffixText,
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Single-select option sheet.
class EditChoiceSheet<T> extends StatelessWidget {
  /// Creates a choice sheet.
  const EditChoiceSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<(T value, String label)> options;
  final T selected;

  /// Shows the sheet and returns the selected value, or `null` if cancelled.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<(T value, String label)> options,
    required T selected,
    String? subtitle,
  }) {
    return PremiumBottomSheet.show<T>(
      context: context,
      builder: (context) => EditChoiceSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PremiumBottomSheet(
      title: title,
      subtitle: subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.$2),
              trailing: selected == option.$1
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(option.$1);
              },
            ),
        ],
      ),
    );
  }
}
