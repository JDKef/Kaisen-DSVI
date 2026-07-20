import 'package:flutter/material.dart';

import 'kaisen_auth_tokens.dart';

class KaisenOperationalLabel extends StatelessWidget {
  const KaisenOperationalLabel({super.key, this.label = 'Control operativo'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Text(
          label,
          style: const TextStyle(
            color: KaisenAuthTokens.heroMuted,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.35,
          ),
        ),
      ),
    );
  }
}
