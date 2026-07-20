import 'package:flutter/material.dart';

class KaisenLogoMark extends StatelessWidget {
  const KaisenLogoMark({super.key, this.size = 56});

  static const assetPath = 'assets/branding/kaisen_logo_mark.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticLabel: 'Kaisen',
        errorBuilder: (context, error, stackTrace) {
          return Semantics(
            label: 'Kaisen',
            child: ExcludeSemantics(
              child: Icon(
                Icons.inventory_2_outlined,
                size: size * 0.58,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
