import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';

class KaisenEmptyState extends StatelessWidget {
  const KaisenEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.padding = const EdgeInsets.all(KaisenSpacing.space6),
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: KaisenColors.surfaceHigh,
              borderRadius: BorderRadius.circular(KaisenRadius.large),
            ),
            child: Icon(icon, size: 32, color: KaisenColors.textMuted),
          ),
          const SizedBox(height: KaisenSpacing.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KaisenTypography.sectionTitle.copyWith(
              color: KaisenColors.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: KaisenSpacing.space2),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: KaisenTypography.body.copyWith(
                color: KaisenColors.textSecondary,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: KaisenSpacing.space5),
            action!,
          ],
        ],
      ),
    );
  }
}
