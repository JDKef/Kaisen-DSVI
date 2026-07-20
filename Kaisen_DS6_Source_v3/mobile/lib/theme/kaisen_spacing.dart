import 'package:flutter/material.dart';

abstract final class KaisenSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double space10 = 64;

  static const double minimumTouchTarget = 44;
  static const double controlHeight = minimumTouchTarget;
  static const double appBarHeight = 56;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: space5,
  );
  static const EdgeInsets panelPadding = EdgeInsets.all(space5);
  static const EdgeInsets floatingPanelPadding = EdgeInsets.all(space6);
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(
    horizontal: space4,
  );
}
