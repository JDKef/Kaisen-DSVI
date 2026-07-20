import 'package:flutter/material.dart';

import '../../theme/kaisen_radius.dart';
import '../../theme/kaisen_spacing.dart';
import '../kaisen_loading_indicator.dart';
import 'kaisen_auth_tokens.dart';

class KaisenAuthPrimaryButton extends StatelessWidget {
  const KaisenAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.loadingLabel,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? loadingLabel;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (busy || states.contains(WidgetState.disabled)) {
              return KaisenAuthTokens.accentDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return KaisenAuthTokens.accentPressed;
            }
            return KaisenAuthTokens.accent;
          }),
          foregroundColor: WidgetStateProperty.all(KaisenAuthTokens.sheetText),
          overlayColor: WidgetStateProperty.all(
            KaisenAuthTokens.sheetText.withValues(alpha: 0.08),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KaisenRadius.control),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: KaisenSpacing.space4),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        child: busy
            ? KaisenLoadingIndicator(
                size: 20,
                color: KaisenAuthTokens.sheetText,
                semanticLabel: loadingLabel ?? 'Cargando',
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Center(child: Text(label)),
                  if (showArrow)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                ],
              ),
      ),
    );
  }
}
