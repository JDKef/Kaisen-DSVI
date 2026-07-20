import 'package:flutter/material.dart';

import 'kaisen_colors.dart';

abstract final class KaisenShadows {
  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(
      color: KaisenColors.shadowSoft,
      blurRadius: 22,
      offset: Offset(0, 9),
      spreadRadius: -5,
    ),
  ];

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: KaisenColors.shadowFloat,
      blurRadius: 34,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> focus = <BoxShadow>[
    BoxShadow(color: KaisenColors.focusGlow, blurRadius: 0, spreadRadius: 2),
  ];

  static const List<BoxShadow> criticalFocus = <BoxShadow>[
    BoxShadow(
      color: KaisenColors.criticalFocusGlow,
      blurRadius: 0,
      spreadRadius: 2,
    ),
  ];
}
