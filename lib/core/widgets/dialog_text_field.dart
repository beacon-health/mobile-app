import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Compact outlined text field used by the facility request and correction
/// dialogs, so both forms stay visually identical.
class DialogTextField extends StatelessWidget {
  const DialogTextField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(labelText: label, isDense: true),
        style: Theme.of(context).textTheme.bodyMedium,
        validator: validator,
      ),
    );
  }
}
