import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import 'business_context.dart';
import 'remote_failure.dart';

abstract interface class ProductRepository {
  Future<List<Producto>> listActiveProducts({
    String search = '',
    String? category,
  });

  Future<Producto?> findByBarcode(String barcode);

  Future<Producto> createProduct(Producto product);

  Future<Producto> updateProduct(Producto product);

  Future<Producto> archiveProduct(Producto product);
}

abstract interface class ProductGateway {
  Future<List<Map<String, dynamic>>> listActiveProducts({
    required String businessId,
    required String search,
    required String? category,
  });

  Future<Map<String, dynamic>?> findByBarcode({
    required String businessId,
    required String barcode,
  });

  Future<Map<String, dynamic>> invokeRpc(
    String functionName,
    Map<String, dynamic> parameters,
  );
}

class SupabaseProductGateway implements ProductGateway {
  SupabaseProductGateway({SupabaseClient? client}) : _clientOverride = client;

  static const _columns =
      'id, business_id, nombre, precio, stock, categoria, '
      'codigo_barras, activo, version, created_at, updated_at';

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> listActiveProducts({
    required String businessId,
    required String search,
    required String? category,
  }) async {
    var query = _client
        .from('products')
        .select(_columns)
        .eq('business_id', businessId)
        .eq('activo', true);

    if (search.trim().isNotEmpty) {
      query = query.ilike('nombre', '%${search.trim()}%');
    }
    if (category != null && category.trim().isNotEmpty) {
      query = query.eq('categoria', category.trim());
    }

    final rows = await query.order('nombre');
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> findByBarcode({
    required String businessId,
    required String barcode,
  }) async {
    final row = await _client
        .from('products')
        .select(_columns)
        .eq('business_id', businessId)
        .eq('activo', true)
        .eq('codigo_barras', barcode.trim())
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> invokeRpc(
    String functionName,
    Map<String, dynamic> parameters,
  ) async {
    final response = await _client.rpc(functionName, params: parameters);
    return _singleRow(response);
  }

  Map<String, dynamic> _singleRow(Object? response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.length == 1 && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw StateError('Remote product RPC returned an invalid result.');
  }
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository({
    ProductGateway? gateway,
    BusinessContext? businessContext,
  })  : _gateway = gateway ?? SupabaseProductGateway(),
        _businessContext = businessContext ?? SupabaseBusinessContext();

  final ProductGateway _gateway;
  final BusinessContext _businessContext;

  @override
  Future<List<Producto>> listActiveProducts({
    String search = '',
    String? category,
  }) async {
    try {
      final businessId = await _businessContext.currentBusinessId();
      final rows = await _gateway.listActiveProducts(
        businessId: businessId,
        search: search,
        category: category,
      );
      return rows.map(Producto.fromRemoteMap).toList();
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  @override
  Future<Producto?> findByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;

    try {
      final businessId = await _businessContext.currentBusinessId();
      final row = await _gateway.findByBarcode(
        businessId: businessId,
        barcode: normalized,
      );
      return row == null ? null : Producto.fromRemoteMap(row);
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  @override
  Future<Producto> createProduct(Producto product) async {
    try {
      final businessId = await _businessContext.currentBusinessId();
      final row = await _gateway.invokeRpc('create_product', {
        'p_business_id': businessId,
        'p_nombre': product.nombre,
        'p_precio': product.precio,
        'p_stock': product.stock,
        'p_categoria': product.categoria,
        'p_codigo_barras': _normalizedBarcode(product.codigoBarras),
      });
      return Producto.fromRemoteMap(row);
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  @override
  Future<Producto> updateProduct(Producto product) async {
    final remoteId = product.remoteId;
    if (remoteId == null) {
      throw const RemoteRepositoryException(
        RemoteFailureType.productUnavailable,
      );
    }
    if (product.version <= 0) {
      throw const RemoteRepositoryException(RemoteFailureType.staleVersion);
    }

    try {
      final row = await _gateway.invokeRpc('update_product', {
        'p_product_id': remoteId,
        'p_expected_version': product.version,
        'p_nombre': product.nombre,
        'p_precio': product.precio,
        'p_stock': product.stock,
        'p_categoria': product.categoria,
        'p_codigo_barras': _normalizedBarcode(product.codigoBarras),
      });
      return Producto.fromRemoteMap(row);
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  @override
  Future<Producto> archiveProduct(Producto product) async {
    final remoteId = product.remoteId;
    if (remoteId == null) {
      throw const RemoteRepositoryException(
        RemoteFailureType.productUnavailable,
      );
    }

    try {
      final row = await _gateway.invokeRpc('archive_product', {
        'p_product_id': remoteId,
        'p_expected_version': product.version,
      });
      return Producto.fromRemoteMap(row);
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  String? _normalizedBarcode(String? barcode) {
    final normalized = barcode?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
