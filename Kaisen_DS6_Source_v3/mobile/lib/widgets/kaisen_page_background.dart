import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_gradients.dart';

class KaisenPageBackground extends StatelessWidget {
  const KaisenPageBackground({
    super.key,
    required this.child,
    this.safeArea = false,
    this.backgroundColor = KaisenColors.background,
    this.primaryGradient = KaisenGradients.atmospheric,
    this.secondaryGradient = KaisenGradients.atmosphericLower,
  });

  final Widget child;
  final bool safeArea;
  final Color backgroundColor;
  final Gradient primaryGradient;
  final Gradient secondaryGradient;

  @override
  Widget build(BuildContext context) {
    final content = safeArea ? SafeArea(child: child) : child;

    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: primaryGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: secondaryGradient),
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }
}
