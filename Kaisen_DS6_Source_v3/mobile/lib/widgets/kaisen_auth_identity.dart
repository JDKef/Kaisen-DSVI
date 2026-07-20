import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';

class KaisenAuthIdentity extends StatelessWidget {
  const KaisenAuthIdentity({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 40.0 : 44.0;
    final titleStyle = compact
        ? KaisenTypography.screenTitle
        : KaisenTypography.display;

    return Semantics(
      container: true,
      label: 'Kaisen. Gestión de inventario.',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: markSize,
              height: markSize,
              decoration: BoxDecoration(
                color: KaisenColors.surfaceHigh,
                borderRadius: BorderRadius.circular(KaisenRadius.control),
                border: Border.all(color: KaisenColors.subtleBorder),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.inventory_2_outlined,
                size: compact ? 21 : 23,
                color: KaisenColors.textPrimary,
              ),
            ),
            const SizedBox(width: KaisenSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control operativo',
                    style: KaisenTypography.microLabel.copyWith(
                      color: KaisenColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KaisenSpacing.space1),
                  Text(
                    'Kaisen',
                    style: titleStyle.copyWith(color: KaisenColors.textPrimary),
                  ),
                  const SizedBox(height: KaisenSpacing.space1),
                  Text(
                    'Gestión de inventario',
                    style:
                        (compact
                                ? KaisenTypography.body
                                : KaisenTypography.bodyLarge)
                            .copyWith(color: KaisenColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
