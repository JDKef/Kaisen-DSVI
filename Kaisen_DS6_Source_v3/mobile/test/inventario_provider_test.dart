import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/providers/inventario_provider.dart';
import 'package:kaisen/repositories/remote_failure.dart';

import 'support/fake_remote_repositories.dart';

void main() {
  const remoteProduct = Producto(
    id: 42,
    idRemoto: 42,
    nombre: 'Cafe',
    precio: 10,
    stock: 4,
    categoria: 'Bebidas',
    version: 9,
  );

  test('edit preserves remote identity and uses loaded version', () async {
    final repository = FakeProductRepository(products: [remoteProduct]);
    final provider = InventarioProvider(repository: repository);
    await provider.cargarProductos();

    final result = await provider.actualizarProducto(
      const Producto(
        id: 42,
        nombre: 'Cafe premium',
        precio: 11,
        stock: 5,
        categoria: 'Bebidas',
      ),
    );

    expect(result, isTrue);
    expect(repository.lastUpdated?.idRemoto, 42);
    expect(repository.lastUpdated?.version, 9);
  });

  test('stale update does not overwrite the loaded product', () async {
    final repository = FakeProductRepository(products: [remoteProduct])
      ..updateFailure = const RemoteRepositoryException(
        RemoteFailureType.staleVersion,
      );
    final provider = InventarioProvider(repository: repository);
    await provider.cargarProductos();

    final result = await provider.actualizarProducto(
      remoteProduct.copyWith(nombre: 'Overwrite'),
    );

    expect(result, isFalse);
    expect(provider.productos.single.nombre, 'Cafe');
    expect(provider.errorMessage, contains('otro dispositivo'));
  });

  test('archive removes the product from the active remote list', () async {
    final repository = FakeProductRepository(products: [remoteProduct]);
    final provider = InventarioProvider(repository: repository);
    await provider.cargarProductos();

    expect(await provider.eliminarProducto(42), isTrue);
    expect(repository.lastArchived?.version, 9);
    expect(provider.productos, isEmpty);
  });
}
