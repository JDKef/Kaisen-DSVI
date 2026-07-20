import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/theme/kaisen_colors.dart';
import 'package:kaisen/theme/kaisen_gradients.dart';
import 'package:kaisen/theme/kaisen_spacing.dart';
import 'package:kaisen/theme/kaisen_theme.dart';
import 'package:kaisen/widgets/kaisen_bottom_panel.dart';
import 'package:kaisen/widgets/kaisen_empty_state.dart';
import 'package:kaisen/widgets/kaisen_error_state.dart';
import 'package:kaisen/widgets/kaisen_loading_indicator.dart';
import 'package:kaisen/widgets/kaisen_metric_card.dart';
import 'package:kaisen/widgets/kaisen_page_background.dart';
import 'package:kaisen/widgets/kaisen_primary_button.dart';
import 'package:kaisen/widgets/kaisen_secondary_button.dart';
import 'package:kaisen/widgets/kaisen_status_chip.dart';
import 'package:kaisen/widgets/kaisen_surface.dart';
import 'package:kaisen/widgets/kaisen_text_field.dart';
import 'package:kaisen/widgets/producto_card.dart';

Widget themed(Widget child) {
  return MaterialApp(
    theme: KaisenTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  test('Kaisen calibrated color tokens keep exact role values', () {
    expect(KaisenColors.background, const Color(0xFF111613));
    expect(KaisenColors.backgroundElevated, const Color(0xFF161D19));
    expect(KaisenColors.surface, const Color(0xFF1C2621));
    expect(KaisenColors.surfaceHigh, const Color(0xFF25312B));
    expect(KaisenColors.surfaceLight, const Color(0xFFECEEE8));
    expect(KaisenColors.textPrimary, const Color(0xFFF4F4EE));
    expect(KaisenColors.textSecondary, const Color(0xFFABB3AD));
    expect(KaisenColors.accent, const Color(0xFFB9F541));
    expect(KaisenColors.accentMuted, const Color(0xFF28351D));
    expect(KaisenColors.success, const Color(0xFF55D58C));
    expect(KaisenColors.warning, const Color(0xFFF3B64A));
    expect(KaisenColors.danger, const Color(0xFFFF675F));
    expect(KaisenColors.subtleBorder, const Color(0x14FFFFFF));
  });

  testWidgets('Kaisen buttons use the shared theme and touch target', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      themed(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KaisenPrimaryButton(label: 'Primary', onPressed: () {}),
            KaisenSecondaryButton(label: 'Secondary', onPressed: () {}),
          ],
        ),
      ),
    );

    final primary = find.byType(FilledButton);
    final secondary = find.byType(OutlinedButton);

    expect(tester.getSize(primary).height, KaisenSpacing.controlHeight);
    expect(tester.getSize(secondary).height, KaisenSpacing.controlHeight);
    expect(
      Theme.of(tester.element(primary)).colorScheme.primary,
      KaisenColors.accent,
    );
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
  });

  testWidgets('Kaisen text field keeps its label and minimum height', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      themed(
        const KaisenTextField(
          labelText: 'Usuario',
          hintText: 'Escribe tu usuario',
        ),
      ),
    );

    final field = find.byType(TextFormField);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Escribe tu usuario'), findsOneWidget);
    expect(tester.getSize(field).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(field).height, lessThan(48));
  });

  testWidgets('Kaisen background and loading indicator use shared primitives', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KaisenTheme.dark,
        home: const KaisenPageBackground(
          child: KaisenLoadingIndicator(semanticLabel: 'Cargando'),
        ),
      ),
    );

    final background = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox).first,
    );
    final decoration = background.decoration as BoxDecoration;

    expect(decoration.gradient, KaisenGradients.atmospheric);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient ==
                KaisenGradients.atmosphericLower,
      ),
      findsOneWidget,
    );
    expect(find.byType(KaisenLoadingIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Kaisen light surface provides a warm hero-panel treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      themed(const KaisenSurface.light(child: Text('Hero panel'))),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(KaisenSurface),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    final textContext = tester.element(find.text('Hero panel'));

    expect(decoration.gradient, KaisenGradients.lightSurface);
    expect(
      DefaultTextStyle.of(textContext).style.color,
      KaisenColors.lightTextPrimary,
    );
  });

  testWidgets('Kaisen status chip exposes selection and a 44 pixel target', (
    WidgetTester tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        themed(
          const KaisenStatusChip(
            label: 'Stock bajo',
            status: KaisenStatus.warning,
            selected: true,
          ),
        ),
      );

      final chip = find.byType(KaisenStatusChip);
      final semantics = tester.getSemantics(chip);

      expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('Kaisen metric and state widgets render shared content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      themed(
        SingleChildScrollView(
          child: Column(
            children: [
              const KaisenMetricCard(
                value: '24',
                label: 'Productos activos',
                icon: Icons.inventory_2_outlined,
              ),
              const KaisenEmptyState(
                title: 'Sin productos',
                message: 'No hay datos para mostrar.',
              ),
              KaisenErrorState(
                title: 'No se pudo cargar',
                message: 'Intenta de nuevo.',
                onRetry: () {},
              ),
              const KaisenBottomPanel(safeArea: false, child: Text('Panel')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('24'), findsOneWidget);
    expect(find.text('Productos activos'), findsOneWidget);
    expect(find.text('Sin productos'), findsOneWidget);
    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Inventory visuals use neutral icons and semantic stock colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      themed(
        const ProductoCard(
          producto: Producto(
            nombre: 'Guantes',
            precio: 12,
            stock: 3,
            categoria: 'Operaciones',
          ),
        ),
      ),
    );

    final inventoryIcon = tester.widget<Icon>(
      find.byIcon(Icons.inventory_2_outlined),
    );
    final stockLabel = tester.widget<Text>(find.text('Stock: 3'));

    expect(inventoryIcon.color, KaisenColors.textSecondary);
    expect(stockLabel.style?.color, KaisenColors.warning);
  });
}
