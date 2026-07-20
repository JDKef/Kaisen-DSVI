import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/repositories/business_context.dart';
import 'package:kaisen/repositories/pending_sale_store.dart';
import 'package:kaisen/repositories/remote_failure.dart';
import 'package:kaisen/repositories/sale_repository.dart';

void main() {
  test('RPC JSON preserves every requested quantity and field name', () {
    final payload = saleItemsToRpcJson(const [
      SaleItemRequest(productId: 42, quantity: 1),
      SaleItemRequest(productId: 7, quantity: 2),
      SaleItemRequest(productId: 99, quantity: 3),
    ]);

    expect(payload, [
      {'product_id': 42, 'cantidad': 1},
      {'product_id': 7, 'cantidad': 2},
      {'product_id': 99, 'cantidad': 3},
    ]);
    expect(payload[1]['cantidad'], isNot(1));
    expect(payload[2]['cantidad'], isNot(1));
  });

  test('sale_history maps one remote row to one Venta line', () async {
    final gateway = _RecordingSaleGateway()
      ..historyRows = [
        {
          'id': 501,
          'business_id': 'business-1',
          'sale_id': 50,
          'producto_id': 42,
          'producto_nombre': 'Cafe',
          'categoria': 'Bebidas',
          'cantidad': 2,
          'precio_unitario': '12.50',
          'total': '25.00',
          'fecha': '2026-07-16T12:00:00Z',
          'seller_id': 'user-1',
          'client_operation_id':
              '00000000-0000-4000-8000-000000000001',
          'created_at': '2026-07-16T12:00:00Z',
        },
      ];
    final repository = SupabaseSaleRepository(
      gateway: gateway,
      businessContext: _StaticBusinessContext(),
      pendingSaleStore: _MemoryPendingSaleStore(),
    );

    final history = await repository.loadHistory();

    expect(history, hasLength(1));
    expect(history.single.id, 501);
    expect(history.single.productoId, 42);
    expect(history.single.total, 25);
    expect(history.single.sincronizada, isTrue);
  });

  test('uncertain retry reuses operation ID and exact remote payload', () async {
    final gateway = _RecordingSaleGateway()
      ..failures.add(
        const RemoteRepositoryException(RemoteFailureType.noConnection),
      );
    final store = _MemoryPendingSaleStore();
    final repository = SupabaseSaleRepository(
      gateway: gateway,
      businessContext: _StaticBusinessContext(),
      pendingSaleStore: store,
      operationIdGenerator: () => '00000000-0000-4000-8000-000000000001',
    );
    const items = [
      SaleItemRequest(productId: 42, quantity: 2),
      SaleItemRequest(productId: 7, quantity: 1),
    ];

    await expectLater(
      repository.createSale(items),
      throwsA(isA<RemoteRepositoryException>()),
    );
    final replay = await repository.createSale(items);

    expect(gateway.operationIds, [
      '00000000-0000-4000-8000-000000000001',
      '00000000-0000-4000-8000-000000000001',
    ]);
    expect(gateway.calls.first.first.toRpcJson(), {
      'product_id': 42,
      'cantidad': 2,
    });
    expect(replay.replayed, isTrue);
    expect(store.entries, isEmpty);
  });

  test('a different cart receives a different operation ID', () async {
    final generated = <String>[
      '00000000-0000-4000-8000-000000000001',
      '00000000-0000-4000-8000-000000000002',
    ];
    final gateway = _RecordingSaleGateway()
      ..failures.add(
        const RemoteRepositoryException(RemoteFailureType.noConnection),
      )
      ..failures.add(
        const RemoteRepositoryException(RemoteFailureType.noConnection),
      );
    final repository = SupabaseSaleRepository(
      gateway: gateway,
      businessContext: _StaticBusinessContext(),
      pendingSaleStore: _MemoryPendingSaleStore(),
      operationIdGenerator: () => generated.removeAt(0),
    );

    for (final items in const [
      [SaleItemRequest(productId: 42, quantity: 1)],
      [SaleItemRequest(productId: 42, quantity: 2)],
    ]) {
      await expectLater(
        repository.createSale(items),
        throwsA(isA<RemoteRepositoryException>()),
      );
    }

    expect(gateway.operationIds.toSet(), hasLength(2));
  });
}

class _StaticBusinessContext implements BusinessContext {
  @override
  Future<String> currentBusinessId() async => 'business-1';
}

class _MemoryPendingSaleStore implements PendingSaleStore {
  final Map<String, String> entries = {};

  @override
  Future<String?> operationIdFor(String fingerprint) async =>
      entries[fingerprint];

  @override
  Future<void> save(String fingerprint, String operationId) async {
    entries[fingerprint] = operationId;
  }

  @override
  Future<void> remove(String fingerprint) async {
    entries.remove(fingerprint);
  }
}

class _RecordingSaleGateway implements SaleGateway {
  final List<Object> failures = [];
  final List<String> operationIds = [];
  final List<List<SaleItemRequest>> calls = [];
  List<Map<String, dynamic>> historyRows = [];

  @override
  Future<Map<String, dynamic>> createSale({
    required String businessId,
    required String operationId,
    required List<SaleItemRequest> items,
  }) async {
    operationIds.add(operationId);
    calls.add(List.of(items));
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return {
      'sale_id': 90,
      'item_ids': [901, 902],
      'replayed': operationIds.length > 1,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> loadHistory(String businessId) async =>
      historyRows;
}
