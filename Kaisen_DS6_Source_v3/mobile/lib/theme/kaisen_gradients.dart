import 'package:flutter/material.dart';

import 'kaisen_colors.dart';

abstract final class KaisenGradients {
  static const Gradient atmospheric = RadialGradient(
    center: Alignment(0.76, -0.88),
    radius: 1.15,
    colors: <Color>[
      KaisenColors.atmosphericWarm,
      KaisenColors.atmosphericHigh,
      KaisenColors.transparent,
    ],
    stops: <double>[0, 0.34, 0.78],
  );

  static const Gradient atmosphericLower = RadialGradient(
    center: Alignment(-0.92, 0.82),
    radius: 1.05,
    colors: <Color>[KaisenColors.atmosphericSurface, KaisenColors.transparent],
    stops: <double>[0, 0.72],
  );

  static const Gradient dashboardAtmospheric = RadialGradient(
    center: Alignment(0.76, -0.88),
    radius: 1.15,
    colors: <Color>[
      Color(0x0DEEEFE9),
      Color(0x38202723),
      KaisenColors.transparent,
    ],
    stops: <double>[0, 0.34, 0.78],
  );

  static const Gradient dashboardAtmosphericLower = RadialGradient(
    center: Alignment(-0.92, 0.82),
    radius: 1.05,
    colors: <Color>[Color(0x2E202723), KaisenColors.transparent],
    stops: <double>[0, 0.72],
  );

  static const Gradient graphiteWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[KaisenColors.backgroundElevated, KaisenColors.background],
  );

  static const Gradient primaryAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[KaisenColors.acid400, KaisenColors.accent],
  );

  static const Gradient warningHalo = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.2,
    colors: <Color>[
      KaisenColors.warningSurface,
      Color(0x00F3B64A),
      KaisenColors.surface,
    ],
    stops: <double>[0, 0.42, 1],
  );

  static const Gradient surfaceSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      KaisenColors.surfaceSheenStart,
      KaisenColors.surfaceSheenEnd,
    ],
  );

  static const Gradient lightSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[KaisenColors.textPrimary, KaisenColors.surfaceLight],
  );
}
