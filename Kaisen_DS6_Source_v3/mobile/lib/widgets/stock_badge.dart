import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_typography.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock, required this.stockBajo});

  final int stock;
  final bool stockBajo;

  @override
  Widget build(BuildContext context) {
    final (color, backgroundColor, borderColor) = switch ((stock, stockBajo)) {
      (0, _) => (
        KaisenColors.danger,
        KaisenColors.dangerSurface,
        KaisenColors.dangerBorder,
      ),
      (_, true) => (
        KaisenColors.warning,
        KaisenColors.warningSurface,
        KaisenColors.warningBorder,
      ),
      _ => (
        KaisenColors.accent,
        KaisenColors.accentSurface,
        KaisenColors.accentBorder,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(KaisenRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        'Stock: $stock',
        style: KaisenTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
