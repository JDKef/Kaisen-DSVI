import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/providers/inventario_provider.dart';
import 'package:kaisen/repositories/product_repository.dart';
import 'package:kaisen/repositories/remote_failure.dart';
import 'package:kaisen/screens/catalogo_screen.dart';
import 'package:kaisen/screens/producto_detalle_screen.dart';
import 'package:kaisen/theme/kaisen_colors.dart';
import 'package:kaisen/theme/kaisen_theme.dart';
import 'package:kaisen/widgets/kaisen_page_background.dart';
import 'package:kaisen/widgets/kaisen_status_chip.dart';
import 'package:provider/provider.dart';

import 'support/fake_remote_repositories.dart';

void main() {
  testWidgets('Catalog presents products with operational stock hierarchy', (
    WidgetTester tester,
  ) async {
    final harness = _InventoryHarness.withProducts();
    addTearDown(harness.dispose);
    await harness.pump(tester, home: const CatalogoScreen());

    expect(find.text('Catálogo de inventario'), findsOneWidget);
    expect(find.text('3 productos visibles'), findsOneWidget);
    expect(find.text('Buscar producto...'), findsOneWidget);
    expect(find.byType(KaisenStatusChip), findsNWidgets(3));
    expect(find.byType(BackdropFilter), findsNothing);

    expect(find.text('Guantes'), findsOneWidget);
    expect(find.text('Tornillos'), findsOneWidget);
    expect(find.text('Adhesivo'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
    expect(find.text('\$2.00'), findsOneWidget);
    expect(find.text('\$5.00'), findsOneWidget);

    final healthy = tester.widget<Text>(find.text('Disponible'));
    final lowStock = tester.widget<Text>(find.text('Stock bajo'));
    final outOfStock = tester.widget<Text>(find.text('Sin stock'));
    expect(healthy.style?.color, KaisenColors.textSecondary);
    expect(lowStock.style?.color, KaisenColors.warning);
    expect(outOfStock.style?.color, KaisenColors.danger);

    final healthyValue = tester.widget<Text>(find.text('18'));
    expect(healthyValue.style?.fontSize, 24);
    expect(healthyValue.style?.color, KaisenColors.textPrimary);

    final addAction = find.widgetWithText(
      FloatingActionButton,
      'Nuevo producto',
    );
    expect(addAction, findsOneWidget);
    expect(tester.getSize(addAction).height, greaterThanOrEqualTo(44));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final page = tester.widget<KaisenPageBackground>(
      find.byType(KaisenPageBackground),
    );
    expect(scaffold.backgroundColor, const Color(0xFF111513));
    expect(page.backgroundColor, scaffold.backgroundColor);
  });

  testWidgets('Catalog preserves search, clear, and category filtering', (
    WidgetTester tester,
  ) async {
    final harness = _InventoryHarness.withProducts();
    addTearDown(harness.dispose);
    await harness.pump(tester, home: const CatalogoScreen());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Buscar producto...'),
      'Guantes',
    );
    await tester.pumpAndSettle();

    expect(find.text('Guantes'), findsNWidgets(2));
    expect(find.text('Tornillos'), findsNothing);
    expect(find.byTooltip('Limpiar búsqueda'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Tornillos'), findsOneWidget);

    final hardwareCategory = find.descendant(
      of: find.byType(KaisenStatusChip),
      matching: find.text('Ferretería'),
    );
    await tester.tap(hardwareCategory);
    await tester.pumpAndSettle();

    expect(find.text('Guantes'), findsNothing);
    expect(find.text('Tornillos'), findsOneWidget);
    expect(find.text('Adhesivo'), findsOneWidget);
    expect(harness.provider.categoriaSeleccionada, 'Ferretería');
    expect(harness.fakeRepository.listCalls, greaterThanOrEqualTo(4));
  });

  testWidgets('Catalog preserves edit and create navigation paths', (
    WidgetTester tester,
  ) async {
    final harness = _InventoryHarness.withProducts();
    addTearDown(harness.dispose);
    await harness.pump(tester, home: const CatalogoScreen());

    await tester.tap(find.text('Guantes'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductoDetalleScreen), findsOneWidget);
    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.text('Modo edición'), findsOneWidget);
    expect(_fieldText(tester, 'Nombre'), 'Guantes');

    Navigator.of(tester.element(find.byType(ProductoDetalleScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo producto'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductoDetalleScreen), findsOneWidget);
    expect(find.text('Nuevo producto'), findsOneWidget);
    expect(find.text('Modo creación'), findsOneWidget);
  });

  testWidgets('Catalog exposes polished loading, empty, and error states', (
    WidgetTester tester,
  ) async {
    final pendingRepository = _PendingProductRepository();
    final pendingHarness = _InventoryHarness(pendingRepository);
    addTearDown(pendingHarness.dispose);
    await pendingHarness.pump(
      tester,
      home: const CatalogoScreen(),
      settle: false,
    );

    expect(find.bySemanticsLabel('Cargando productos'), findsOneWidget);
    pendingRepository.complete(const <Producto>[]);
    await tester.pumpAndSettle();
    expect(find.text('No hay productos que coincidan.'), findsOneWidget);

    final errorRepository = FakeProductRepository()
      ..listFailure = const RemoteRepositoryException(
        RemoteFailureType.noConnection,
      );
    final errorHarness = _InventoryHarness(errorRepository);
    addTearDown(errorHarness.dispose);
    await errorHarness.pump(tester, home: const CatalogoScreen());

    expect(find.text('No se pudo cargar el catálogo'), findsOneWidget);
    expect(
      find.text('Sin conexión. Verifica tu internet e intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets(
    'Product form has the required sections and unchanged validators',
    (WidgetTester tester) async {
      final harness = _InventoryHarness(FakeProductRepository());
      addTearDown(harness.dispose);
      await harness.pump(tester, home: const ProductoDetalleScreen());

      expect(find.text('Información'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Identificación'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Precio'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Stock inicial'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Categoría'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Código de barras (opcional)'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Crear producto'));
      await tester.tap(find.text('Crear producto'));
      await tester.pump();

      expect(find.text('Requerido'), findsNWidgets(2));
      expect(find.text('Precio inválido'), findsOneWidget);
      expect(find.text('Stock inválido'), findsOneWidget);
      for (final field in find.byType(TextFormField).evaluate()) {
        expect(
          tester.getSize(find.byWidget(field.widget)).height,
          greaterThanOrEqualTo(44),
        );
      }
    },
  );

  testWidgets('Barcode prefill and create flow remain unchanged', (
    WidgetTester tester,
  ) async {
    final repository = FakeProductRepository();
    final harness = _InventoryHarness(repository);
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      home: const _DetailLauncher(
        detail: ProductoDetalleScreen(codigoBarrasInicial: 'ABC-123'),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'Código de barras (opcional)'), 'ABC-123');

    await _fillProductForm(tester);
    await tester.ensureVisible(find.text('Crear producto'));
    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(repository.lastCreated?.nombre, 'Producto nuevo');
    expect(repository.lastCreated?.precio, 12.5);
    expect(repository.lastCreated?.stock, 7);
    expect(repository.lastCreated?.categoria, 'Operaciones');
    expect(repository.lastCreated?.codigoBarras, 'ABC-123');
    expect(find.text('Pantalla de origen'), findsOneWidget);
  });

  testWidgets('Edit flow preserves update values and remote identity', (
    WidgetTester tester,
  ) async {
    final repository = FakeProductRepository(
      products: const [_editableProduct],
    );
    final harness = _InventoryHarness(repository);
    addTearDown(harness.dispose);
    await harness.provider.cargarProductos();
    await harness.pump(
      tester,
      home: const _DetailLauncher(
        detail: ProductoDetalleScreen(producto: _editableProduct),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Guantes reforzados',
    );
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdated?.nombre, 'Guantes reforzados');
    expect(repository.lastUpdated?.idRemoto, 42);
    expect(repository.lastUpdated?.version, 9);
    expect(find.text('Pantalla de origen'), findsOneWidget);
  });

  testWidgets('Edit mode keeps archive as a deliberate destructive action', (
    WidgetTester tester,
  ) async {
    final repository = FakeProductRepository(
      products: const [_editableProduct],
    );
    final harness = _InventoryHarness(repository);
    addTearDown(harness.dispose);
    await harness.provider.cargarProductos();
    await harness.pump(
      tester,
      home: const _DetailLauncher(
        detail: ProductoDetalleScreen(producto: _editableProduct),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eliminar producto'));

    final destructive = find.widgetWithText(
      OutlinedButton,
      'Eliminar producto',
    );
    expect(destructive, findsOneWidget);
    expect(tester.getSize(destructive).height, greaterThanOrEqualTo(44));

    await tester.tap(destructive);
    await tester.pumpAndSettle();
    expect(find.text('Eliminar producto'), findsNWidgets(2));
    expect(find.text('¿Seguro que deseas eliminar "Guantes"?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.lastArchived, isNull);

    await tester.ensureVisible(find.text('Eliminar producto'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Eliminar producto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repository.lastArchived?.idRemoto, 42);
    expect(find.text('Pantalla de origen'), findsOneWidget);
  });

  testWidgets('Save action preserves loading and repository errors', (
    WidgetTester tester,
  ) async {
    final deferredRepository = _DeferredCreateRepository();
    final deferredHarness = _InventoryHarness(deferredRepository);
    addTearDown(deferredHarness.dispose);
    await deferredHarness.pump(
      tester,
      home: const _DetailLauncher(detail: ProductoDetalleScreen()),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await _fillProductForm(tester, barcode: 'LOAD-1');
    await tester.ensureVisible(find.text('Crear producto'));
    await tester.tap(find.text('Crear producto'));
    await tester.pump();

    expect(find.bySemanticsLabel('Guardando producto'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    deferredRepository.completeCreate();
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de origen'), findsOneWidget);

    final errorRepository = FakeProductRepository()
      ..createFailure = const RemoteRepositoryException(
        RemoteFailureType.duplicateBarcode,
      );
    final errorHarness = _InventoryHarness(errorRepository);
    addTearDown(errorHarness.dispose);
    await errorHarness.pump(
      tester,
      home: const _DetailLauncher(detail: ProductoDetalleScreen()),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await _fillProductForm(tester, barcode: 'DUPLICATE');
    await tester.ensureVisible(find.text('Crear producto'));
    await tester.tap(find.text('Crear producto'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe un producto activo con ese código de barras.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byType(ProductoDetalleScreen), findsOneWidget);
  });

  testWidgets('Catalog and detail avoid overflow on a small Android viewport', (
    WidgetTester tester,
  ) async {
    final harness = _InventoryHarness.withProducts();
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      home: const CatalogoScreen(),
      size: const Size(320, 568),
      textScale: 1.3,
      viewInsets: const EdgeInsets.only(bottom: 220),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Guantes'));
    await tester.tap(find.text('Guantes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.byType(ProductoDetalleScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(44),
    );
  });
}

const _editableProduct = Producto(
  id: 42,
  idRemoto: 42,
  nombre: 'Guantes',
  precio: 8,
  stock: 18,
  categoria: 'Operaciones',
  codigoBarras: 'G-42',
  version: 9,
);

class _InventoryHarness {
  _InventoryHarness(this.repository)
    : provider = InventarioProvider(repository: repository);

  factory _InventoryHarness.withProducts() {
    return _InventoryHarness(
      FakeProductRepository(
        products: const [
          _editableProduct,
          Producto(
            id: 2,
            idRemoto: 2,
            nombre: 'Tornillos',
            precio: 2,
            stock: 4,
            categoria: 'Ferretería',
          ),
          Producto(
            id: 3,
            idRemoto: 3,
            nombre: 'Adhesivo',
            precio: 5,
            stock: 0,
            categoria: 'Ferretería',
          ),
        ],
      ),
    );
  }

  final ProductRepository repository;
  final InventarioProvider provider;

  FakeProductRepository get fakeRepository =>
      repository as FakeProductRepository;

  Future<void> pump(
    WidgetTester tester, {
    required Widget home,
    Size size = const Size(390, 844),
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<InventarioProvider>.value(
        value: provider,
        child: MaterialApp(
          key: ValueKey<InventarioProvider>(provider),
          theme: KaisenTheme.dark,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(textScale),
                viewInsets: viewInsets,
              ),
              child: child!,
            );
          },
          home: home,
        ),
      ),
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  void dispose() => provider.dispose();
}

class _DetailLauncher extends StatelessWidget {
  const _DetailLauncher({required this.detail});

  final ProductoDetalleScreen detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pantalla de origen'),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => detail)),
              child: const Text('Abrir detalle'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _fillProductForm(
  WidgetTester tester, {
  String barcode = '',
}) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nombre'),
    'Producto nuevo',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Precio'), '12.50');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Categoría'),
    'Operaciones',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Stock inicial'),
    '7',
  );
  if (barcode.isNotEmpty) {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de barras (opcional)'),
      barcode,
    );
  }
}

String _fieldText(WidgetTester tester, String label) {
  final field = find.widgetWithText(TextFormField, label);
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

class _PendingProductRepository implements ProductRepository {
  final Completer<List<Producto>> _products = Completer<List<Producto>>();

  void complete(List<Producto> products) => _products.complete(products);

  @override
  Future<List<Producto>> listActiveProducts({
    String search = '',
    String? category,
  }) => _products.future;

  @override
  Future<Producto> archiveProduct(Producto product) =>
      throw UnimplementedError();

  @override
  Future<Producto> createProduct(Producto product) =>
      throw UnimplementedError();

  @override
  Future<Producto?> findByBarcode(String barcode) => throw UnimplementedError();

  @override
  Future<Producto> updateProduct(Producto product) =>
      throw UnimplementedError();
}

class _DeferredCreateRepository extends FakeProductRepository {
  final Completer<Producto> _created = Completer<Producto>();

  @override
  Future<Producto> createProduct(Producto product) {
    lastCreated = product;
    return _created.future;
  }

  void completeCreate() {
    final product = lastCreated!;
    final created = product.copyWith(id: 1, idRemoto: 1);
    products = [created];
    _created.complete(created);
  }
}
