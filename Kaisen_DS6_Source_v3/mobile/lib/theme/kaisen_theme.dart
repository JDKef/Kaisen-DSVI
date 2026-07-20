import 'package:flutter/material.dart';

import 'kaisen_colors.dart';
import 'kaisen_radius.dart';
import 'kaisen_spacing.dart';
import 'kaisen_typography.dart';

final class KaisenTheme {
  KaisenTheme._();

  static final ThemeData dark = _buildTheme();

  static ThemeData _buildTheme() {
    final colorScheme = ColorScheme.dark(
      primary: KaisenColors.accent,
      onPrimary: KaisenColors.background,
      secondary: KaisenColors.success,
      onSecondary: KaisenColors.background,
      tertiary: KaisenColors.warning,
      onTertiary: KaisenColors.background,
      surface: KaisenColors.surface,
      onSurface: KaisenColors.textPrimary,
      onSurfaceVariant: KaisenColors.textSecondary,
      error: KaisenColors.danger,
      onError: KaisenColors.background,
      outline: KaisenColors.strongBorder,
      outlineVariant: KaisenColors.subtleBorder,
      surfaceTint: KaisenColors.transparent,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KaisenRadius.control),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: KaisenColors.background,
      canvasColor: KaisenColors.background,
      cardColor: KaisenColors.surface,
      shadowColor: KaisenColors.shadowTint,
      textTheme: KaisenTypography.textTheme.apply(
        bodyColor: KaisenColors.textPrimary,
        displayColor: KaisenColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KaisenColors.backgroundElevated,
        foregroundColor: KaisenColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: KaisenColors.transparent,
        toolbarHeight: KaisenSpacing.appBarHeight,
        titleTextStyle: KaisenTypography.sectionTitle.copyWith(
          color: KaisenColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: KaisenColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KaisenSpacing.space4,
          vertical: 11,
        ),
        labelStyle: KaisenTypography.body.copyWith(
          color: KaisenColors.textSecondary,
        ),
        floatingLabelStyle: KaisenTypography.label.copyWith(
          color: KaisenColors.accent,
        ),
        hintStyle: KaisenTypography.body.copyWith(
          color: KaisenColors.textMuted,
        ),
        prefixIconColor: KaisenColors.textSecondary,
        suffixIconColor: KaisenColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          borderSide: const BorderSide(color: KaisenColors.subtleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          borderSide: const BorderSide(color: KaisenColors.subtleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          borderSide: const BorderSide(color: KaisenColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          borderSide: const BorderSide(color: KaisenColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          borderSide: const BorderSide(color: KaisenColors.danger, width: 1.5),
        ),
        errorStyle: KaisenTypography.caption.copyWith(
          color: KaisenColors.danger,
        ),
        constraints: const BoxConstraints(
          minHeight: KaisenSpacing.minimumTouchTarget,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, KaisenSpacing.controlHeight),
          ),
          padding: WidgetStateProperty.all(KaisenSpacing.controlPadding),
          shape: WidgetStateProperty.all(controlShape),
          textStyle: WidgetStateProperty.all(KaisenTypography.label),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return KaisenColors.surfaceHigh;
            }
            if (states.contains(WidgetState.pressed)) {
              return KaisenColors.accentPressed;
            }
            return KaisenColors.accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? KaisenColors.textDisabled
                : KaisenColors.background,
          ),
          overlayColor: WidgetStateProperty.all(
            KaisenColors.pressedOverlayDark,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, KaisenSpacing.controlHeight),
          ),
          padding: WidgetStateProperty.all(KaisenSpacing.controlPadding),
          shape: WidgetStateProperty.all(controlShape),
          textStyle: WidgetStateProperty.all(KaisenTypography.label),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? KaisenColors.textDisabled
                : KaisenColors.textPrimary,
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? KaisenColors.textDisabled
                  : states.contains(WidgetState.focused)
                  ? KaisenColors.accent
                  : KaisenColors.subtleBorder,
              width: states.contains(WidgetState.focused) ? 1.5 : 1,
            ),
          ),
          overlayColor: WidgetStateProperty.all(KaisenColors.surfaceHigh),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(
            const Size(0, KaisenSpacing.controlHeight),
          ),
          padding: WidgetStateProperty.all(KaisenSpacing.controlPadding),
          textStyle: WidgetStateProperty.all(KaisenTypography.label),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? KaisenColors.textDisabled
                : KaisenColors.textPrimary,
          ),
          overlayColor: WidgetStateProperty.all(KaisenColors.surfaceHigh),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KaisenColors.surfaceHigh,
        selectedColor: KaisenColors.accentMuted,
        disabledColor: KaisenColors.backgroundElevated,
        side: const BorderSide(color: KaisenColors.subtleBorder),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: KaisenSpacing.space3),
        labelStyle: KaisenTypography.label.copyWith(
          color: KaisenColors.textSecondary,
        ),
        secondaryLabelStyle: KaisenTypography.label.copyWith(
          color: KaisenColors.accent,
        ),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KaisenColors.surfaceHigh,
        contentTextStyle: KaisenTypography.body.copyWith(
          color: KaisenColors.textPrimary,
        ),
        actionTextColor: KaisenColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.panel),
        ),
        elevation: 6,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KaisenColors.accent,
        linearTrackColor: KaisenColors.subtleBorder,
        circularTrackColor: KaisenColors.subtleBorder,
      ),
      dividerTheme: const DividerThemeData(
        color: KaisenColors.subtleBorder,
        thickness: 0.5,
        space: KaisenSpacing.space4,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: KaisenColors.textSecondary,
        textColor: KaisenColors.textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KaisenSpacing.space4,
        ),
        minVerticalPadding: KaisenSpacing.space3,
        titleTextStyle: KaisenTypography.bodyLarge.copyWith(
          color: KaisenColors.textPrimary,
        ),
        subtitleTextStyle: KaisenTypography.body.copyWith(
          color: KaisenColors.textSecondary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KaisenColors.accent,
        foregroundColor: KaisenColors.background,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      iconTheme: const IconThemeData(color: KaisenColors.textSecondary),
      primaryIconTheme: const IconThemeData(color: KaisenColors.textPrimary),
      cardTheme: CardThemeData(
        color: KaisenColors.surface,
        surfaceTintColor: KaisenColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.panel),
          side: const BorderSide(color: KaisenColors.subtleBorder),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}
