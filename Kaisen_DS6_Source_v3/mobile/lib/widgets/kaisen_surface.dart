import 'package:flutter/material.dart';

import '../theme/kaisen_colors.dart';
import '../theme/kaisen_gradients.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_shadows.dart';
import '../theme/kaisen_spacing.dart';

enum KaisenSurfaceTone { standard, elevated, light }

class KaisenSurface extends StatelessWidget {
  const KaisenSurface({
    super.key,
    required this.child,
    this.padding = KaisenSpacing.panelPadding,
    this.margin,
    this.color,
    this.borderColor = KaisenColors.subtleBorder,
    this.borderWidth = 1,
    this.radius = KaisenRadius.panel,
    this.tone = KaisenSurfaceTone.standard,
    this.elevated = false,
    this.translucent = false,
    this.showSheen = false,
  });

  const KaisenSurface.light({
    super.key,
    required this.child,
    this.padding = KaisenSpacing.floatingPanelPadding,
    this.margin,
    this.color,
    this.borderColor = KaisenColors.lightSurfaceBorder,
    this.borderWidth = 1,
    this.radius = KaisenRadius.floating,
    this.elevated = true,
    this.showSheen = false,
  }) : tone = KaisenSurfaceTone.light,
       translucent = false;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final KaisenSurfaceTone tone;
  final bool elevated;
  final bool translucent;
  final bool showSheen;

  @override
  Widget build(BuildContext context) {
    final resolvedTone = tone == KaisenSurfaceTone.standard && elevated
        ? KaisenSurfaceTone.elevated
        : tone;
    final isLight = resolvedTone == KaisenSurfaceTone.light;
    final resolvedColor =
        color ??
        (translucent
            ? KaisenColors.surfaceTranslucent
            : switch (resolvedTone) {
                KaisenSurfaceTone.standard => KaisenColors.surface,
                KaisenSurfaceTone.elevated => KaisenColors.surfaceHigh,
                KaisenSurfaceTone.light => KaisenColors.surfaceLight,
              });
    final border = borderColor == null || borderWidth <= 0
        ? null
        : Border.all(color: borderColor!, width: borderWidth);
    final decoration = BoxDecoration(
      color: isLight && color == null ? null : resolvedColor,
      gradient: isLight && color == null ? KaisenGradients.lightSurface : null,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: elevated ? KaisenShadows.soft : null,
    );

    Widget content = Padding(padding: padding, child: child);
    if (isLight) {
      content = DefaultTextStyle.merge(
        style: const TextStyle(color: KaisenColors.lightTextPrimary),
        child: IconTheme.merge(
          data: const IconThemeData(color: KaisenColors.lightTextSecondary),
          child: content,
        ),
      );
    }

    final decoratedContent = showSheen
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: KaisenGradients.surfaceSheen,
                      ),
                    ),
                  ),
                ),
                content,
              ],
            ),
          )
        : content;

    return Container(
      margin: margin,
      decoration: decoration,
      child: decoratedContent,
    );
  }
}
