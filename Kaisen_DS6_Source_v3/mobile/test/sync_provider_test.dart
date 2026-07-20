import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/providers/inventario_provider.dart';
import 'package:kaisen/providers/sync_provider.dart';
import 'package:kaisen/providers/venta_provider.dart';

import 'support/fake_remote_repositories.dart';

void main() {
  test('sync button only refreshes remote inventory and history', () async {
    final products = FakeProductRepository();
    final sales = FakeSaleRepository();
    final inventoryProvider = InventarioProvider(repository: products);
    final saleProvider = VentaProvider(
      productRepository: products,
      saleRepository: sales,
    );
    final syncProvider = SyncProvider(
      inventarioProvider: inventoryProvider,
      ventaProvider: saleProvider,
    );

    final result = await syncProvider.sincronizar();

    expect(result, isNotNull);
    expect(result?.total, 0);
    expect(products.listCalls, 1);
    expect(sales.historyCalls, 1);
  });
}
