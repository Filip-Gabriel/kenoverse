import 'package:flutter/material.dart';
import 'package:kenoverse/functionality/theme/theme_extensions.dart';

/// A consistent header for form sections with an icon and label.
class FormSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const FormSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colorScheme.primary),
          context.gapSM,
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pre-styled TextField using the app's design system tokens.
class KenoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final int? maxLines;
  final Function(String)? onChanged;

  const KenoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: context.radiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: context.radiusMD,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: context.radiusMD,
          borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
