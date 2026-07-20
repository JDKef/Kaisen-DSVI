import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/producto.dart';
import 'package:kaisen/repositories/business_context.dart';
import 'package:kaisen/repositories/product_repository.dart';

void main() {
  test('Producto maps remote bigint identity and version consistently', () {
    final product = Producto.fromRemoteMap(_remoteProduct());

    expect(product.id, 42);
    expect(product.idRemoto, 42);
    expect(product.remoteId, 42);
    expect(product.version, 7);
    expect(product.precio, 12.5);
  });

  test('update_product sends the deployed expected_version signature', () async {
    final gateway = _RecordingProductGateway();
    final repository = SupabaseProductRepository(
      gateway: gateway,
      businessContext: _StaticBusinessContext(),
    );

    await repository.updateProduct(
      const Producto(
        id: 42,
        idRemoto: 42,
        nombre: 'Cafe',
        precio: 12.5,
        stock: 8,
        categoria: 'Bebidas',
        codigoBarras: 'ABC',
        version: 7,
      ),
    );

    expect(gateway.functionName, 'update_product');
    expect(gateway.parameters, {
      'p_product_id': 42,
      'p_expected_version': 7,
      'p_nombre': 'Cafe',
      'p_precio': 12.5,
      'p_stock': 8,
      'p_categoria': 'Bebidas',
      'p_codigo_barras': 'ABC',
    });
  });

  test('archive_product sends the current remote identity and version', () async {
    final gateway = _RecordingProductGateway();
    final repository = SupabaseProductRepository(
      gateway: gateway,
      businessContext: _StaticBusinessContext(),
    );

    await repository.archiveProduct(
      const Producto(
        id: 42,
        idRemoto: 42,
        nombre: 'Cafe',
        precio: 12.5,
        stock: 8,
        categoria: 'Bebidas',
        version: 7,
      ),
    );

    expect(gateway.functionName, 'archive_product');
    expect(gateway.parameters, {
      'p_product_id': 42,
      'p_expected_version': 7,
    });
  });
}

Map<String, dynamic> _remoteProduct() => {
      'id': 42,
      'business_id': 'business-1',
      'nombre': 'Cafe',
      'precio': '12.50',
      'stock': 8,
      'categoria': 'Bebidas',
      'codigo_barras': 'ABC',
      'activo': true,
      'version': 7,
    };

class _StaticBusinessContext implements BusinessContext {
  @override
  Future<String> currentBusinessId() async => 'business-1';
}

class _RecordingProductGateway implements ProductGateway {
  String? functionName;
  Map<String, dynamic>? parameters;

  @override
  Future<Map<String, dynamic>> invokeRpc(
    String functionName,
    Map<String, dynamic> parameters,
  ) async {
    this.functionName = functionName;
    this.parameters = parameters;
    return _remoteProduct();
  }

  @override
  Future<Map<String, dynamic>?> findByBarcode({
    required String businessId,
    required String barcode,
  }) async => null;

  @override
  Future<List<Map<String, dynamic>>> listActiveProducts({
    required String businessId,
    required String search,
    required String? category,
  }) async => [];
}
