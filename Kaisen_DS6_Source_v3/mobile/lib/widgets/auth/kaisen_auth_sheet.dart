import 'package:flutter/material.dart';

import '../../theme/kaisen_spacing.dart';
import 'kaisen_auth_tokens.dart';

class KaisenAuthSheet extends StatelessWidget {
  const KaisenAuthSheet({super.key, required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = compact
        ? KaisenSpacing.space5
        : KaisenSpacing.space6;
    final topPadding = compact ? KaisenSpacing.space5 : 28.0;
    final bottomPadding = KaisenSpacing.space5 + bottomInset;

    return Container(
      key: const ValueKey('kaisen-auth-sheet'),
      decoration: const BoxDecoration(
        color: KaisenAuthTokens.sheet,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: KaisenAuthTokens.shadow,
            blurRadius: 26,
            offset: Offset(0, -8),
            spreadRadius: -10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumContentHeight =
              (constraints.maxHeight - topPadding - bottomPadding)
                  .clamp(0.0, double.infinity)
                  .toDouble();

          return SingleChildScrollView(
            key: const ValueKey('kaisen-auth-sheet-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumContentHeight),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: KaisenAuthTokens.sheetText),
                child: IconTheme.merge(
                  data: const IconThemeData(
                    color: KaisenAuthTokens.sheetSecondary,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
