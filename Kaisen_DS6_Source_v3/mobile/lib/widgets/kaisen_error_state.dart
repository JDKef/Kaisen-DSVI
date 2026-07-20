import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';
import 'kaisen_surface.dart';

class KaisenErrorState extends StatelessWidget {
  const KaisenErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return KaisenSurface(
      color: KaisenColors.redSurface,
      borderColor: KaisenColors.redBorder,
      radius: KaisenRadius.floating,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: KaisenColors.red400, size: 24),
              const SizedBox(width: KaisenSpacing.space3),
              Expanded(
                child: Text(
                  title,
                  style: KaisenTypography.sectionTitle.copyWith(
                    color: KaisenColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KaisenSpacing.space3),
          Text(
            message,
            style: KaisenTypography.body.copyWith(
              color: KaisenColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: KaisenSpacing.space4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
