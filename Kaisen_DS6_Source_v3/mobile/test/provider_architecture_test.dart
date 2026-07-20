import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product and sale providers do not invoke legacy data services', () {
    const providerFiles = [
      'lib/providers/inventario_provider.dart',
      'lib/providers/venta_provider.dart',
      'lib/providers/sync_provider.dart',
    ];

    for (final path in providerFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('DatabaseService')), reason: path);
      expect(source, isNot(contains('ApiService')), reason: path);
      expect(source, isNot(contains('database_service.dart')), reason: path);
      expect(source, isNot(contains('api_service.dart')), reason: path);
    }
  });
}
