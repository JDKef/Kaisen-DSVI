import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/venta.dart';
import 'business_context.dart';
import 'pending_sale_store.dart';
import 'remote_failure.dart';

class SaleItemRequest {
  const SaleItemRequest({required this.productId, required this.quantity});

  final int productId;
  final int quantity;

  Map<String, dynamic> toRpcJson() => {
        'product_id': productId,
        'cantidad': quantity,
      };
}

class SaleReceipt {
  const SaleReceipt({
    required this.saleId,
    required this.itemIds,
    required this.replayed,
    required this.operationId,
  });

  final int saleId;
  final List<int> itemIds;
  final bool replayed;
  final String operationId;
}

abstract interface class SaleRepository {
  Future<SaleReceipt> createSale(List<SaleItemRequest> items);

  Future<List<Venta>> loadHistory();
}

abstract interface class SaleGateway {
  Future<Map<String, dynamic>> createSale({
    required String businessId,
    required String operationId,
    required List<SaleItemRequest> items,
  });

  Future<List<Map<String, dynamic>>> loadHistory(String businessId);
}

class SupabaseSaleGateway implements SaleGateway {
  SupabaseSaleGateway({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client =>
      _clientOverride ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>> createSale({
    required String businessId,
    required String operationId,
    required List<SaleItemRequest> items,
  }) async {
    final response = await _client.rpc('create_sale', params: {
      'p_business_id': businessId,
      'p_client_operation_id': operationId,
      'p_items': saleItemsToRpcJson(items),
    });
    return _singleRow(response);
  }

  @override
  Future<List<Map<String, dynamic>>> loadHistory(String businessId) async {
    final rows = await _client
        .from('sale_history')
        .select(
          'id, business_id, sale_id, producto_id, producto_nombre, categoria, '
          'cantidad, precio_unitario, total, fecha, seller_id, '
          'client_operation_id, created_at',
        )
        .eq('business_id', businessId)
        .order('fecha', ascending: false);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic> _singleRow(Object? response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.length == 1 && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw StateError('Remote sale RPC returned an invalid result.');
  }
}

class SupabaseSaleRepository implements SaleRepository {
  SupabaseSaleRepository({
    SaleGateway? gateway,
    BusinessContext? businessContext,
    PendingSaleStore? pendingSaleStore,
    String Function()? operationIdGenerator,
  })  : _gateway = gateway ?? SupabaseSaleGateway(),
        _businessContext = businessContext ?? SupabaseBusinessContext(),
        _pendingSaleStore =
            pendingSaleStore ?? SharedPreferencesPendingSaleStore(),
        _operationIdGenerator = operationIdGenerator ?? generateUuidV4;

  final SaleGateway _gateway;
  final BusinessContext _businessContext;
  final PendingSaleStore _pendingSaleStore;
  final String Function() _operationIdGenerator;

  @override
  Future<SaleReceipt> createSale(List<SaleItemRequest> items) async {
    if (items.isEmpty ||
        items.any((item) => item.productId <= 0 || item.quantity <= 0)) {
      throw const RemoteRepositoryException(
        RemoteFailureType.productUnavailable,
      );
    }

    final fingerprint = saleFingerprint(items);
    String operationId;

    try {
      operationId =
          await _pendingSaleStore.operationIdFor(fingerprint) ??
              _operationIdGenerator();
      await _pendingSaleStore.save(fingerprint, operationId);
    } catch (error) {
      throw mapRemoteFailure(error);
    }

    try {
      final businessId = await _businessContext.currentBusinessId();
      final row = await _gateway.createSale(
        businessId: businessId,
        operationId: operationId,
        items: items,
      );
      final receipt = SaleReceipt(
        saleId: _asInt(row['sale_id']),
        itemIds: (row['item_ids'] as List? ?? const [])
            .map(_asInt)
            .toList(),
        replayed: row['replayed'] as bool? ?? false,
        operationId: operationId,
      );
      await _pendingSaleStore.remove(fingerprint);
      return receipt;
    } catch (error) {
      final mapped = mapRemoteFailure(error);
      if (mapped.isDefiniteSaleRejection) {
        try {
          await _pendingSaleStore.remove(fingerprint);
        } catch (storageError) {
          throw mapRemoteFailure(storageError);
        }
      }
      throw mapped;
    }
  }

  @override
  Future<List<Venta>> loadHistory() async {
    try {
      final businessId = await _businessContext.currentBusinessId();
      final rows = await _gateway.loadHistory(businessId);
      return rows.map(Venta.fromRemoteMap).toList();
    } catch (error) {
      throw mapRemoteFailure(error);
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }
}

String saleFingerprint(List<SaleItemRequest> items) {
  final canonical = [...items]
    ..sort((left, right) => left.productId.compareTo(right.productId));
  final payload = canonical.map((item) => item.toRpcJson()).toList();
  return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
}

List<Map<String, dynamic>> saleItemsToRpcJson(
  Iterable<SaleItemRequest> items,
) {
  return items.map((item) => item.toRpcJson()).toList(growable: false);
}

String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
