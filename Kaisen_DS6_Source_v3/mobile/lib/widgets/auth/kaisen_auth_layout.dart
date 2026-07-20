import 'package:flutter/material.dart';

import '../../theme/kaisen_spacing.dart';
import '../kaisen_logo_mark.dart';
import 'kaisen_auth_sheet.dart';
import 'kaisen_auth_tokens.dart';
import 'kaisen_inventory_hero.dart';
import 'kaisen_operational_label.dart';

class KaisenAuthLayout extends StatelessWidget {
  const KaisenAuthLayout({
    super.key,
    required this.sheetChild,
    required this.heroVariant,
    this.registration = false,
  });

  final Widget sheetChild;
  final KaisenInventoryHeroVariant heroVariant;
  final bool registration;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardVisible = media.viewInsets.bottom > 0;

    return DecoratedBox(
      key: const ValueKey('kaisen-auth-background'),
      decoration: const BoxDecoration(
        color: KaisenAuthTokens.heroBackground,
        gradient: RadialGradient(
          center: Alignment(0.72, -0.82),
          radius: 1.12,
          colors: [
            KaisenAuthTokens.heroBackgroundHigh,
            KaisenAuthTokens.heroBackground,
          ],
          stops: [0, 0.72],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final compact =
                keyboardVisible || landscape || constraints.maxHeight < 610;
            final normalRatio = registration ? 0.40 : 0.43;
            final heroHeight = compact
                ? (landscape ? 92.0 : 112.0)
                : constraints.maxHeight * normalRatio;
            final overlap = compact ? 12.0 : 18.0;
            final sheetTop = (heroHeight - overlap).clamp(
              78.0,
              constraints.maxHeight - 180,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const ValueKey('kaisen-auth-hero-zone'),
                    height: heroHeight,
                    width: double.infinity,
                    child: _HeroContent(compact: compact, variant: heroVariant),
                  ),
                ),
                Positioned(
                  top: sheetTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: KaisenAuthSheet(
                    compact: compact,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: sheetChild,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.compact, required this.variant});

  final bool compact;
  final KaisenInventoryHeroVariant variant;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KaisenSpacing.space6,
          vertical: KaisenSpacing.space2,
        ),
        child: Row(
          children: [
            const _Wordmark(compact: true),
            const SizedBox(width: KaisenSpacing.space4),
            const Expanded(
              child: Text(
                'Sistema operativo de inventario',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: KaisenAuthTokens.heroMuted,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KaisenSpacing.space6,
        KaisenSpacing.space4,
        KaisenSpacing.space6,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KaisenOperationalLabel(),
          const SizedBox(height: KaisenSpacing.space2),
          const _Wordmark(),
          const SizedBox(height: KaisenSpacing.space1),
          const Text(
            'Sistema operativo de inventario',
            style: TextStyle(
              color: KaisenAuthTokens.heroMuted,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: KaisenSpacing.space2),
          Expanded(child: KaisenInventoryHero(variant: variant)),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const KaisenLogoMark(size: 48),
        const SizedBox(width: KaisenSpacing.space2),
        Text(
          'Kaisen',
          style: TextStyle(
            color: const Color(0xFFF1F2EC),
            fontSize: compact ? 24 : 30,
            height: compact ? 28 / 24 : 34 / 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}
