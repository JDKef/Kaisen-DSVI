import 'package:kaisen/models/producto.dart';
import 'package:kaisen/models/venta.dart';
import 'package:kaisen/repositories/product_repository.dart';
import 'package:kaisen/repositories/sale_repository.dart';

class FakeProductRepository implements ProductRepository {
  FakeProductRepository({List<Producto>? products})
      : products = products ?? <Producto>[];

  List<Producto> products;
  Object? listFailure;
  Object? createFailure;
  Object? updateFailure;
  Object? archiveFailure;
  Producto? lastCreated;
  Producto? lastUpdated;
  Producto? lastArchived;
  int listCalls = 0;

  @override
  Future<List<Producto>> listActiveProducts({
    String search = '',
    String? category,
  }) async {
    listCalls++;
    if (listFailure != null) throw listFailure!;
    return products
        .where((product) =>
            product.activo &&
            (search.isEmpty || product.nombre.contains(search)) &&
            (category == null || product.categoria == category))
        .toList();
  }

  @override
  Future<Producto?> findByBarcode(String barcode) async {
    for (final product in products) {
      if (product.activo && product.codigoBarras == barcode.trim()) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<Producto> createProduct(Producto product) async {
    lastCreated = product;
    if (createFailure != null) throw createFailure!;
    final created = product.copyWith(
      id: products.length + 1,
      idRemoto: products.length + 1,
    );
    products = [...products, created];
    return created;
  }

  @override
  Future<Producto> updateProduct(Producto product) async {
    lastUpdated = product;
    if (updateFailure != null) throw updateFailure!;
    final updated = product.copyWith(version: product.version + 1);
    products = products
        .map((current) => current.remoteId == product.remoteId
            ? updated
            : current)
        .toList();
    return updated;
  }

  @override
  Future<Producto> archiveProduct(Producto product) async {
    lastArchived = product;
    if (archiveFailure != null) throw archiveFailure!;
    final archived = product.copyWith(
      activo: false,
      version: product.version + 1,
    );
    products = products
        .map((current) => current.remoteId == product.remoteId
            ? archived
            : current)
        .toList();
    return archived;
  }
}

class FakeSaleRepository implements SaleRepository {
  List<Venta> history = <Venta>[];
  Object? createFailure;
  Object? historyFailure;
  List<SaleItemRequest>? lastItems;
  int createCalls = 0;
  int historyCalls = 0;

  @override
  Future<SaleReceipt> createSale(List<SaleItemRequest> items) async {
    createCalls++;
    lastItems = List.of(items);
    if (createFailure != null) throw createFailure!;
    return const SaleReceipt(
      saleId: 10,
      itemIds: [100],
      replayed: false,
      operationId: '00000000-0000-4000-8000-000000000001',
    );
  }

  @override
  Future<List<Venta>> loadHistory() async {
    historyCalls++;
    if (historyFailure != null) throw historyFailure!;
    return List.of(history);
  }
}
