enum RemoteFailureType {
  noConnection,
  insufficientStock,
  productUnavailable,
  duplicateBarcode,
  staleVersion,
  idempotencyConflict,
  unexpected,
}

extension RemoteFailureMessages on RemoteFailureType {
  String get userMessage => switch (this) {
        RemoteFailureType.noConnection =>
          'Sin conexión. Verifica tu internet e intenta de nuevo.',
        RemoteFailureType.insufficientStock =>
          'No hay stock suficiente para completar la venta.',
        RemoteFailureType.productUnavailable =>
          'Uno de los productos ya no está disponible.',
        RemoteFailureType.duplicateBarcode =>
          'Ya existe un producto activo con ese código de barras.',
        RemoteFailureType.staleVersion =>
          'El producto cambió en otro dispositivo. Actualiza e intenta de nuevo.',
        RemoteFailureType.idempotencyConflict =>
          'La operación pendiente no coincide con el carrito actual.',
        RemoteFailureType.unexpected =>
          'No se pudo completar la operación remota. Intenta de nuevo.',
      };
}

class RemoteRepositoryException implements Exception {
  const RemoteRepositoryException(this.type);

  final RemoteFailureType type;

  String get userMessage => type.userMessage;

  bool get isDefiniteSaleRejection => switch (type) {
        RemoteFailureType.insufficientStock => true,
        RemoteFailureType.productUnavailable => true,
        RemoteFailureType.idempotencyConflict => true,
        _ => false,
      };

  @override
  String toString() => 'RemoteRepositoryException(${type.name})';
}

RemoteRepositoryException mapRemoteFailure(Object error) {
  if (error is RemoteRepositoryException) return error;

  final details = error.toString().toLowerCase();

  if (_containsAny(details, [
    'client operation id was used with a different payload',
    'idempotency',
  ])) {
    return const RemoteRepositoryException(
      RemoteFailureType.idempotencyConflict,
    );
  }

  if (_containsAny(details, [
    'product version conflict',
    'stale version',
  ])) {
    return const RemoteRepositoryException(RemoteFailureType.staleVersion);
  }

  if (_containsAny(details, [
    'active product barcode already exists',
    'duplicate barcode',
    'products_active_barcode_uidx',
  ]) ||
      (details.contains('23505') && details.contains('barcode'))) {
    return const RemoteRepositoryException(
      RemoteFailureType.duplicateBarcode,
    );
  }

  if (_containsAny(details, [
    'insufficient product stock',
    'insufficient stock',
    'p0004',
  ])) {
    return const RemoteRepositoryException(
      RemoteFailureType.insufficientStock,
    );
  }

  if (_containsAny(details, [
    'product not found',
    'archived products',
    'already archived',
    'p0002',
  ])) {
    return const RemoteRepositoryException(
      RemoteFailureType.productUnavailable,
    );
  }

  if (_containsAny(details, [
    'network',
    'connection',
    'failed host lookup',
    'socket',
    'timed out',
    'timeout',
    'fetch failed',
    'clientexception',
    'xmlhttprequest error',
  ])) {
    return const RemoteRepositoryException(RemoteFailureType.noConnection);
  }

  return const RemoteRepositoryException(RemoteFailureType.unexpected);
}

bool _containsAny(String value, List<String> fragments) {
  return fragments.any(value.contains);
}
