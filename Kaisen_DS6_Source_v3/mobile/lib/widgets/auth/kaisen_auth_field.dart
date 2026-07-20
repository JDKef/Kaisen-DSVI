import 'package:flutter/material.dart';

import '../../theme/kaisen_radius.dart';
import '../../theme/kaisen_spacing.dart';
import 'kaisen_auth_tokens.dart';

class KaisenAuthField extends StatelessWidget {
  const KaisenAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.onToggleVisibility,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final visibilityControl = onToggleVisibility == null
        ? null
        : IconButton(
            onPressed: onToggleVisibility,
            tooltip: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
            constraints: const BoxConstraints.tightFor(
              width: KaisenSpacing.minimumTouchTarget,
              height: KaisenSpacing.minimumTouchTarget,
            ),
            padding: EdgeInsets.zero,
            iconSize: 20,
            color: KaisenAuthTokens.sheetSecondary,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          );

    return TextFormField(
      key: key,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      cursorColor: KaisenAuthTokens.fieldBorderFocused,
      style: const TextStyle(
        color: KaisenAuthTokens.sheetText,
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: KaisenAuthTokens.field,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 56),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KaisenSpacing.space4,
          vertical: 17,
        ),
        prefixIcon: Icon(icon, size: 20),
        prefixIconColor: KaisenAuthTokens.sheetSecondary,
        suffixIcon: visibilityControl,
        suffixIconColor: KaisenAuthTokens.sheetSecondary,
        labelStyle: const TextStyle(
          color: KaisenAuthTokens.sheetSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: KaisenAuthTokens.sheetText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          color: KaisenAuthTokens.danger,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w600,
        ),
        border: _border(KaisenAuthTokens.fieldBorder),
        enabledBorder: _border(KaisenAuthTokens.fieldBorder),
        focusedBorder: _border(KaisenAuthTokens.fieldBorderFocused, width: 1.5),
        errorBorder: _border(KaisenAuthTokens.danger),
        focusedErrorBorder: _border(KaisenAuthTokens.danger, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(KaisenRadius.control),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
