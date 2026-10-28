import 'package:flutter/material.dart';

/// Shared form field (DRY): one place for text-field behaviour across the
/// item, need, request, review, report and profile forms. Styling comes from
/// the app's InputDecorationTheme in lib/config/theme.dart.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Multi-line fields keep the label at the top, next to the hint.
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
