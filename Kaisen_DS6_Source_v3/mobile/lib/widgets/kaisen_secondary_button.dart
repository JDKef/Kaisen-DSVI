import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_spacing.dart';
import 'kaisen_loading_indicator.dart';

class KaisenSecondaryButton extends StatelessWidget {
  const KaisenSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.fullWidth = true,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (busy) {
      content = KaisenLoadingIndicator(
        color: KaisenColors.textSecondary,
        semanticLabel: loadingLabel ?? 'Cargando',
      );
    } else if (icon == null) {
      content = Text(label);
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: KaisenSpacing.space2),
          Text(label),
        ],
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: KaisenSpacing.controlHeight,
      child: OutlinedButton(onPressed: busy ? null : onPressed, child: content),
    );
  }
}
