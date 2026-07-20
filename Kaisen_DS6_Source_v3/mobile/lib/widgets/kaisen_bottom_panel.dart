import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_shadows.dart';
import '../theme/kaisen_spacing.dart';

class KaisenBottomPanel extends StatelessWidget {
  const KaisenBottomPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KaisenSpacing.space5),
    this.safeArea = true,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool safeArea;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (safeArea) {
      content = SafeArea(top: false, child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: KaisenColors.surfaceHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KaisenRadius.floating),
        ),
        border: const Border(top: BorderSide(color: KaisenColors.subtleBorder)),
        boxShadow: elevated ? KaisenShadows.floating : null,
      ),
      child: content,
    );
  }
}
