import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';

class KaisenLoadingIndicator extends StatelessWidget {
  const KaisenLoadingIndicator({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color = KaisenColors.textSecondary,
    this.semanticLabel,
  });

  final double size;
  final double strokeWidth;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(color: color, strokeWidth: strokeWidth),
    );

    if (semanticLabel == null) return indicator;

    return Semantics(label: semanticLabel, child: indicator);
  }
}
