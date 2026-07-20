import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/models/venta.dart';
import 'package:kaisen/providers/auth_provider.dart';
import 'package:kaisen/providers/inventario_provider.dart';
import 'package:kaisen/providers/sync_provider.dart';
import 'package:kaisen/providers/venta_provider.dart';
import 'package:kaisen/repositories/product_repository.dart';
import 'package:kaisen/repositories/remote_failure.dart';
import 'package:kaisen/screens/catalogo_screen.dart';
import 'package:kaisen/screens/dashboard_screen.dart';
import 'package:kaisen/screens/historial_ventas_screen.dart';
import 'package:kaisen/screens/producto_detalle_screen.dart';
import 'package:kaisen/screens/registro_venta_screen.dart';
import 'package:kaisen/services/auth_repository.dart';
import 'package:kaisen/theme/kaisen_gradients.dart';
import 'package:kaisen/theme/kaisen_theme.dart';
import 'package:kaisen/widgets/kaisen_page_background.dart';
import 'package:kaisen/widgets/kaisen_primary_button.dart';
import 'package:kaisen/widgets/kaisen_surface.dart';
import 'package:provider/provider.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_remote_repositories.dart';

void main() {
  testWidgets('Dashboard renders the operational hierarchy and live metrics', (
    WidgetTester tester,
  ) async {
    final harness = _DashboardHarness.withOperationalData();
    addTearDown(harness.dispose);

    await harness.pump(tester);

    expect(find.byType(KaisenPageBackground), findsOneWidget);
    expect(
      tester
          .widgetList<KaisenSurface>(find.byType(KaisenSurface))
          .any((surface) => surface.tone == KaisenSurfaceTone.light),
      isTrue,
    );
    expect(find.text('Hola, Usuario de prueba'), findsOneWidget);
    expect(find.text('Estado del inventario'), findsOneWidget);
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.text('Productos activos'), findsOneWidget);
    expect(find.text('Stock bajo'), findsOneWidget);
    expect(find.text('Ganancias totales'), findsOneWidget);
    expect(find.text(r'$10.00'), findsOneWidget);
    expect(find.text('Registrar venta'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsOneWidget);
    expect(find.text('Ver ventas'), findsOneWidget);
    expect(find.text('Productos con poco stock'), findsOneWidget);
    expect(find.text('Tornillos'), findsOneWidget);
    expect(find.text('Adhesivo'), findsOneWidget);
    expect(find.text('Guantes'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(find.byType(KaisenPrimaryButton), findsOneWidget);
    expect(find.byTooltip('Sincronizar con el servidor'), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);

    final heroSurface = find
        .ancestor(
          of: find.text('Estado del inventario'),
          matching: find.byType(KaisenSurface),
        )
        .first;
    expect(tester.getSize(heroSurface).height, lessThanOrEqualTo(180));
    expect(
      tester.getSize(find.byTooltip('Sincronizar con el servidor')),
      const Size.square(44),
    );
    expect(tester.getSize(find.byIcon(Icons.logout)), const Size.square(18));

    final inventoryIcons = tester.widgetList<Icon>(
      find.byIcon(Icons.inventory_2_outlined),
    );
    expect(inventoryIcons, isNotEmpty);
    for (final icon in inventoryIcons) {
      expect(icon.color, isNot(Colors.indigo));
      expect(icon.color, isNot(Colors.blue));
    }
  });

  testWidgets('Dashboard keeps every existing navigation path', (
    WidgetTester tester,
  ) async {
    final harness = _DashboardHarness.withOperationalData();
    addTearDown(harness.dispose);
    await harness.pump(tester, size: const Size(800, 900));

    await _openAndReturn(
      tester,
      find.text('Registrar venta'),
      find.byType(RegistroVentaScreen),
    );
    await _openAndReturn(
      tester,
      find.text('Catálogo'),
      find.byType(CatalogoScreen),
    );
    await _openAndReturn(
      tester,
      find.text('Nuevo producto'),
      find.byType(ProductoDetalleScreen),
    );
    await _openAndReturn(
      tester,
      find.text('Ver ventas'),
      find.byType(HistorialVentasScreen),
    );
    await _openAndReturn(
      tester,
      find.text(r'$10.00'),
      find.byType(HistorialVentasScreen),
    );
  });

  testWidgets('Dashboard background remains stable after route return', (
    WidgetTester tester,
  ) async {
    final harness = _DashboardHarness.withOperationalData();
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final initial = _dashboardBackgroundSnapshot(tester);
    expect(initial.scaffoldColor, const Color(0xFF111513));
    expect(initial.pageColor, initial.scaffoldColor);
    expect(initial.primaryGradient, KaisenGradients.dashboardAtmospheric);
    expect(
      initial.secondaryGradient,
      KaisenGradients.dashboardAtmosphericLower,
    );
    final page = tester.widget<KaisenPageBackground>(
      find.byType(KaisenPageBackground),
    );
    expect(page.child, isA<RefreshIndicator>());

    final dashboardContext = tester.element(find.byType(DashboardScreen));
    unawaited(
      Navigator.of(dashboardContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Ruta temporal')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ruta temporal'), findsOneWidget);

    Navigator.of(tester.element(find.text('Ruta temporal'))).pop();
    await tester.pump(const Duration(milliseconds: 120));

    final duringReturn = _dashboardBackgroundSnapshot(
      tester,
      skipOffstage: false,
    );
    expect(duringReturn, initial);

    await tester.pumpAndSettle();
    expect(_dashboardBackgroundSnapshot(tester), initial);
  });

  testWidgets('Dashboard preserves remote refresh and logout actions', (
    WidgetTester tester,
  ) async {
    final harness = _DashboardHarness.withOperationalData();
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(harness.productRepository.listCalls, 1);
    expect(harness.saleRepository.historyCalls, 1);

    await tester.tap(find.byTooltip('Sincronizar con el servidor'));
    await tester.pumpAndSettle();

    expect(harness.productRepository.listCalls, 3);
    expect(harness.saleRepository.historyCalls, 3);
    expect(find.text('Ya estaba todo sincronizado.'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(harness.authRepository.logoutCalls, 1);
  });

  testWidgets('Dashboard exposes loading, empty, and inventory error states', (
    WidgetTester tester,
  ) async {
    final pendingRepository = _PendingProductRepository();
    final loadingHarness = _DashboardHarness(
      productRepository: pendingRepository,
      saleRepository: FakeSaleRepository(),
    );
    addTearDown(loadingHarness.dispose);

    await loadingHarness.pump(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Actualizando inventario...'), findsOneWidget);

    pendingRepository.complete(const []);
    await tester.pumpAndSettle();

    expect(
      find.text('Todo el inventario tiene stock saludable.'),
      findsOneWidget,
    );

    final failureRepository = FakeProductRepository()
      ..listFailure = const RemoteRepositoryException(
        RemoteFailureType.noConnection,
      );
    final errorHarness = _DashboardHarness(
      productRepository: failureRepository,
      saleRepository: FakeSaleRepository(),
    );
    addTearDown(errorHarness.dispose);

    await errorHarness.pump(tester);

    expect(find.text('No se pudo cargar el inventario'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Dashboard avoids overflow on a small Android-sized viewport', (
    WidgetTester tester,
  ) async {
    final harness = _DashboardHarness.withOperationalData();
    addTearDown(harness.dispose);

    await harness.pump(
      tester,
      size: const Size(320, 568),
      textScaler: const TextScaler.linear(1.3),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();

    expect(find.text('Registrar venta'), findsOneWidget);
    expect(find.text('Productos con poco stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openAndReturn(
  WidgetTester tester,
  Finder action,
  Finder destination,
) async {
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(destination, findsOneWidget);

  Navigator.of(tester.element(destination)).pop();
  await tester.pumpAndSettle();
}

({
  Color? scaffoldColor,
  Color pageColor,
  Gradient primaryGradient,
  Gradient secondaryGradient,
})
_dashboardBackgroundSnapshot(WidgetTester tester, {bool skipOffstage = true}) {
  final pageFinder = find.byType(
    KaisenPageBackground,
    skipOffstage: skipOffstage,
  );
  final scaffoldFinder = find.ancestor(
    of: pageFinder,
    matching: find.byType(Scaffold, skipOffstage: skipOffstage),
  );
  final page = tester.widget<KaisenPageBackground>(pageFinder);
  final scaffold = tester.widget<Scaffold>(scaffoldFinder.first);

  return (
    scaffoldColor: scaffold.backgroundColor,
    pageColor: page.backgroundColor,
    primaryGradient: page.primaryGradient,
    secondaryGradient: page.secondaryGradient,
  );
}

class _DashboardHarness {
  _DashboardHarness({
    required ProductRepository productRepository,
    required this.saleRepository,
  }) : productRepository = productRepository is FakeProductRepository
           ? productRepository
           : FakeProductRepository(),
       _productRepository = productRepository,
       authRepository = FakeAuthRepository(
         session: const AuthSession(userId: 'test-user-id'),
       ) {
    auth = AuthProvider(repository: authRepository);
    inventario = InventarioProvider(repository: _productRepository);
    venta = VentaProvider(
      saleRepository: saleRepository,
      productRepository: _productRepository,
      refreshInventory: inventario.cargarProductos,
    );
    sync = SyncProvider(inventarioProvider: inventario, ventaProvider: venta);
  }

  factory _DashboardHarness.withOperationalData() {
    final productRepository = FakeProductRepository(
      products: const [
        Producto(
          id: 1,
          idRemoto: 1,
          nombre: 'Guantes',
          precio: 8,
          stock: 18,
          categoria: 'Operaciones',
        ),
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
    );
    final saleRepository = FakeSaleRepository()
      ..history = [
        Venta(
          id: 1,
          idRemoto: 1,
          productoId: 3,
          productoNombre: 'Adhesivo',
          categoria: 'Ferretería',
          cantidad: 2,
          precioUnitario: 5,
          fecha: DateTime(2026, 7, 16),
          sincronizada: true,
        ),
      ];
    return _DashboardHarness(
      productRepository: productRepository,
      saleRepository: saleRepository,
    );
  }

  final ProductRepository _productRepository;
  final FakeProductRepository productRepository;
  final FakeSaleRepository saleRepository;
  final FakeAuthRepository authRepository;
  late final AuthProvider auth;
  late final InventarioProvider inventario;
  late final VentaProvider venta;
  late final SyncProvider sync;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<InventarioProvider>.value(value: inventario),
          ChangeNotifierProvider<VentaProvider>.value(value: venta),
          ChangeNotifierProvider<SyncProvider>.value(value: sync),
        ],
        child: MaterialApp(
          theme: KaisenTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: DashboardScreen(key: ValueKey(_productRepository)),
        ),
      ),
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> dispose() async {
    sync.dispose();
    venta.dispose();
    inventario.dispose();
    auth.dispose();
    await authRepository.close();
  }
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
  Future<Producto> archiveProduct(Producto product) {
    throw UnimplementedError();
  }

  @override
  Future<Producto> createProduct(Producto product) {
    throw UnimplementedError();
  }

  @override
  Future<Producto?> findByBarcode(String barcode) {
    throw UnimplementedError();
  }

  @override
  Future<Producto> updateProduct(Producto product) {
    throw UnimplementedError();
  }
}
