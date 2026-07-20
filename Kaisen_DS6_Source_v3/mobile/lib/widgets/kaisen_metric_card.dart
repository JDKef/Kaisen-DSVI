import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';
import 'kaisen_surface.dart';

class KaisenMetricCard extends StatelessWidget {
  const KaisenMetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accentColor = KaisenColors.accent,
    this.onTap,
    this.semanticsLabel,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final panel = KaisenSurface(
      radius: KaisenRadius.floating,
      tone: KaisenSurfaceTone.elevated,
      borderColor: KaisenColors.subtleBorder,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: KaisenSpacing.space7,
                height: KaisenSpacing.space7,
                decoration: BoxDecoration(
                  color: KaisenColors.surface,
                  borderRadius: BorderRadius.circular(KaisenRadius.small),
                ),
                child: Icon(icon, size: 22, color: KaisenColors.textSecondary),
              ),
              if (onTap != null) ...[
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: KaisenColors.textMuted,
                ),
              ],
            ],
          ),
          const SizedBox(height: KaisenSpacing.space3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KaisenTypography.operationalMetric.copyWith(
              color: accentColor,
            ),
          ),
          const SizedBox(height: KaisenSpacing.space1),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KaisenTypography.caption.copyWith(
              color: KaisenColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    final semanticPanel = Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      child: panel,
    );

    if (onTap == null) return semanticPanel;

    return Material(
      color: KaisenColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(KaisenRadius.floating),
        onTap: onTap,
        child: semanticPanel,
      ),
    );
  }
}
