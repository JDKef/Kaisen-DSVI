import 'package:flutter/material.dart';

abstract final class KaisenTypography {
  static const TextStyle display = TextStyle(
    fontSize: 36,
    height: 40 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );

  static const TextStyle operationalMetric = TextStyle(
    fontSize: 32,
    height: 36 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle microLabel = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static final TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: operationalMetric,
    headlineLarge: screenTitle,
    titleLarge: sectionTitle,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    labelLarge: label,
    labelMedium: caption,
    labelSmall: microLabel,
  );
}
