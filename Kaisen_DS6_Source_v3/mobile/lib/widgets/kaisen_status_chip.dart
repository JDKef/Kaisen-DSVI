import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';

enum KaisenStatus { neutral, positive, warning, critical }

class KaisenStatusChip extends StatelessWidget {
  const KaisenStatusChip({
    super.key,
    required this.label,
    this.status = KaisenStatus.neutral,
    this.icon,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final KaisenStatus status;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  Color get _accentColor {
    return switch (status) {
      KaisenStatus.neutral => KaisenColors.textSecondary,
      KaisenStatus.positive => KaisenColors.accent,
      KaisenStatus.warning => KaisenColors.warning,
      KaisenStatus.critical => KaisenColors.danger,
    };
  }

  Color get _backgroundColor {
    if (selected) return KaisenColors.accentMuted;
    return switch (status) {
      KaisenStatus.neutral => KaisenColors.surfaceHigh,
      KaisenStatus.positive => KaisenColors.accentSurface,
      KaisenStatus.warning => KaisenColors.warningSurface,
      KaisenStatus.critical => KaisenColors.dangerSurface,
    };
  }

  Color get _borderColor {
    if (selected) return KaisenColors.accentBorder;
    return switch (status) {
      KaisenStatus.neutral => KaisenColors.subtleBorder,
      KaisenStatus.positive => KaisenColors.accentBorder,
      KaisenStatus.warning => KaisenColors.warningBorder,
      KaisenStatus.critical => KaisenColors.dangerBorder,
    };
  }

  IconData? get _defaultIcon {
    if (icon != null) return icon;
    return switch (status) {
      KaisenStatus.neutral => null,
      KaisenStatus.positive => Icons.check_circle_outline,
      KaisenStatus.warning => Icons.warning_amber_rounded,
      KaisenStatus.critical => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = _defaultIcon;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: KaisenColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KaisenRadius.pill),
          child: Ink(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(KaisenRadius.pill),
              border: Border.all(color: _borderColor),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KaisenSpacing.space3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (resolvedIcon != null) ...[
                      Icon(resolvedIcon, size: 18, color: _accentColor),
                      const SizedBox(width: KaisenSpacing.space2),
                    ],
                    Text(
                      label,
                      style: KaisenTypography.label.copyWith(
                        color: selected ? KaisenColors.accent : _accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
