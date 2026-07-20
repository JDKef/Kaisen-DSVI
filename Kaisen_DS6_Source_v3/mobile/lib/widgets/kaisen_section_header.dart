import 'package:flutter/material.dart';

import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';

class KaisenSectionHeader extends StatelessWidget {
  const KaisenSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(
      bottom: KaisenSpacing.space2,
    ),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: KaisenTypography.sectionTitle,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
