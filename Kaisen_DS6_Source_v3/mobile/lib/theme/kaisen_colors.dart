import 'package:flutter/material.dart';

abstract final class KaisenColors {
  // Core calibrated palette.
  static const Color background = Color(0xFF111613);
  static const Color backgroundElevated = Color(0xFF161D19);
  static const Color surface = Color(0xFF1C2621);
  static const Color surfaceHigh = Color(0xFF25312B);
  static const Color surfaceLight = Color(0xFFECEEE8);

  static const Color textPrimary = Color(0xFFF4F4EE);
  static const Color textSecondary = Color(0xFFABB3AD);
  static const Color textMuted = Color(0xFF7F8A83);
  static const Color textDisabled = Color(0xFF5E6861);

  static const Color accent = Color(0xFFB9F541);
  static const Color accentMuted = Color(0xFF28351D);
  static const Color success = Color(0xFF55D58C);
  static const Color warning = Color(0xFFF3B64A);
  static const Color danger = Color(0xFFFF675F);

  static const Color subtleBorder = Color(0x14FFFFFF);
  static const Color strongBorder = Color(0x2EFFFFFF);
  static const Color lightSurfaceBorder = Color(0x1F111613);
  static const Color overlay = Color(0xCC111613);
  static const Color transparent = Color(0x00000000);

  static const Color surfaceTranslucent = Color(0xE61C2621);
  static const Color accentPressed = Color(0xFF98CE32);
  static const Color accentSurface = Color(0x1AB9F541);
  static const Color accentBorder = Color(0x52B9F541);
  static const Color accentOverlay = Color(0x29B9F541);
  static const Color pressedOverlayDark = Color(0x1F111613);

  static const Color successSurface = Color(0x1F55D58C);
  static const Color successBorder = Color(0x4D55D58C);
  static const Color warningSurface = Color(0x1FF3B64A);
  static const Color warningBorder = Color(0x4DF3B64A);
  static const Color dangerSurface = Color(0x1FFF675F);
  static const Color dangerBorder = Color(0x4DFF675F);

  static const Color lightTextPrimary = background;
  static const Color lightTextSecondary = Color(0xFF465149);
  static const Color surfaceSheenStart = Color(0x12F4F4EE);
  static const Color surfaceSheenEnd = Color(0x00F4F4EE);
  static const Color atmosphericWarm = Color(0x12ECEEE8);
  static const Color atmosphericHigh = Color(0x7025312B);
  static const Color atmosphericSurface = Color(0x521C2621);
  static const Color shadowTint = Color(0xFF090C0A);
  static const Color shadowSoft = Color(0x30090C0A);
  static const Color shadowFloat = Color(0x52090C0A);
  static const Color focusGlow = Color(0x33B9F541);
  static const Color criticalFocusGlow = Color(0x33FF675F);

  // Compatibility aliases for the Phase UI-1 component API.
  static const Color ink950 = background;
  static const Color ink900 = backgroundElevated;
  static const Color ink850 = surface;
  static const Color graphite800 = surface;
  static const Color graphite700 = surfaceHigh;
  static const Color graphiteGlass = surfaceTranslucent;
  static const Color line = subtleBorder;
  static const Color lineStrong = strongBorder;

  static const Color acid400 = Color(0xFFC8FA5D);
  static const Color acid500 = accent;
  static const Color acid700 = accentPressed;
  static const Color acidSurface = accentSurface;
  static const Color acidBorder = accentBorder;
  static const Color acidGlow = Color(0x0FB9F541);
  static const Color acidTransparent = Color(0x00B9F541);
  static const Color acidOverlay = accentOverlay;

  static const Color amber400 = warning;
  static const Color amber500 = warning;
  static const Color amberSurface = warningSurface;
  static const Color amberBorder = warningBorder;

  static const Color red400 = danger;
  static const Color red500 = danger;
  static const Color redSurface = dangerSurface;
  static const Color redBorder = dangerBorder;
}
