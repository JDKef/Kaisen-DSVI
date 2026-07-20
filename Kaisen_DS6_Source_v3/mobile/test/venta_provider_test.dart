import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/models/venta.dart';
import 'package:kaisen/providers/inventario_provider.dart';
import 'package:kaisen/providers/venta_provider.dart';
import 'package:kaisen/repositories/remote_failure.dart';
import 'package:kaisen/screens/registro_venta_screen.dart';
import 'package:provider/provider.dart';

import 'support/fake_remote_repositories.dart';

void main() {
  const product = Producto(
    id: 7,
    idRemoto: 42,
    nombre: 'Cafe',
    precio: 10,
    stock: 5,
    categoria: 'Bebidas',
    codigoBarras: 'ABC',
    version: 3,
  );

  const secondProduct = Producto(
    id: 8,
    idRemoto: 99,
    nombre: 'Te',
    precio: 5,
    stock: 10,
    categoria: 'Bebidas',
    codigoBarras: 'DEF',
    version: 2,
  );

  test('barcode lookup reads the Supabase product repository', () async {
    final products = FakeProductRepository(products: [product]);
    final provider = VentaProvider(
      productRepository: products,
      saleRepository: FakeSaleRepository(),
    );

    expect((await provider.buscarProductoPorCodigo('ABC'))?.remoteId, 42);
  });

  test('quantity 1 sends 1', () async {
    final sales = FakeSaleRepository();
    final provider = VentaProvider(
      productRepository: FakeProductRepository(products: [product]),
      saleRepository: sales,
    );
    provider.agregarAlCarrito(product);

    expect(await provider.confirmarVenta(), isNull);
    expect(sales.lastItems?.single.productId, 42);
    expect(sales.lastItems?.single.quantity, 1);
  });

  test('quantity 2 shown in the cart is the quantity sent', () async {
    final sales = FakeSaleRepository();
    final provider = VentaProvider(
      productRepository: FakeProductRepository(products: [product]),
      saleRepository: sales,
    );
    provider.agregarAlCarrito(product);

    // RegistroVentaScreen passes the screen-facing local ID.
    provider.actualizarCantidad(product.id!, 2);

    expect(provider.carrito.single.cantidad, 2);
    expect(provider.cantidadArticulos, 2);
    expect(await provider.confirmarVenta(), isNull);
    expect(sales.lastItems?.single.quantity, 2);
  });

  testWidgets('pressing plus twice displays and sends quantity 3',
      (tester) async {
    final sales = FakeSaleRepository();
    final products = FakeProductRepository(products: [product]);
    final saleProvider = VentaProvider(
      productRepository: products,
      saleRepository: sales,
    );
    final inventoryProvider = InventarioProvider(repository: products);
    saleProvider.agregarAlCarrito(product);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: saleProvider),
          ChangeNotifierProvider.value(value: inventoryProvider),
        ],
        child: const MaterialApp(home: RegistroVentaScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(saleProvider.carrito.single.cantidad, 3);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar venta'));
    await tester.pumpAndSettle();

    expect(sales.lastItems?.single.quantity, 3);
  });

  test('two products preserve their individual quantities', () async {
    final sales = FakeSaleRepository();
    final provider = VentaProvider(
      productRepository:
          FakeProductRepository(products: [product, secondProduct]),
      saleRepository: sales,
    );
    provider.agregarAlCarrito(product);
    provider.agregarAlCarrito(secondProduct);
    provider.actualizarCantidad(product.id!, 2);
    provider.actualizarCantidad(secondProduct.id!, 4);

    expect(await provider.confirmarVenta(), isNull);
    expect(
      sales.lastItems
          ?.map((item) => (item.productId, item.quantity))
          .toList(),
      [(42, 2), (99, 4)],
    );
  });

  test('successful sale clears cart and refreshes history and stock', () async {
    final sales = FakeSaleRepository()
      ..history = [
        Venta(
          id: 100,
          idRemoto: 100,
          productoId: 42,
          productoNombre: 'Cafe',
          categoria: 'Bebidas',
          cantidad: 2,
          precioUnitario: 10,
          fecha: DateTime.utc(2026, 1, 1),
          sincronizada: true,
        ),
      ];
    var inventoryRefreshes = 0;
    final provider = VentaProvider(
      productRepository: FakeProductRepository(products: [product]),
      saleRepository: sales,
      refreshInventory: () async {
        inventoryRefreshes++;
      },
    );
    provider.agregarAlCarrito(product);
    provider.actualizarCantidad(product.id!, 2);

    expect(await provider.confirmarVenta(), isNull);
    expect(provider.carrito, isEmpty);
    expect(sales.lastItems?.single.productId, 42);
    expect(sales.lastItems?.single.quantity, 2);
    expect(sales.historyCalls, 1);
    expect(inventoryRefreshes, 1);
  });

  test('insufficient stock keeps the cart intact', () async {
    final sales = FakeSaleRepository()
      ..createFailure = const RemoteRepositoryException(
        RemoteFailureType.insufficientStock,
      );
    final provider = VentaProvider(
      productRepository: FakeProductRepository(products: [product]),
      saleRepository: sales,
    );
    provider.agregarAlCarrito(product);
    provider.actualizarCantidad(product.id!, 2);

    final message = await provider.confirmarVenta();

    expect(message, contains('stock'));
    expect(provider.carrito, hasLength(1));
    expect(provider.carrito.single.cantidad, 2);
  });
}
