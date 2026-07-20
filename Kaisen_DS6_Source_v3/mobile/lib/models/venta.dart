class Venta {
  final int? id;
  final int? idRemoto;
  final int productoId;
  final String productoNombre;
  final String categoria;
  final int cantidad;
  final double precioUnitario;
  final DateTime fecha;
  final bool sincronizada;

  const Venta({
    this.id,
    this.idRemoto,
    required this.productoId,
    required this.productoNombre,
    required this.categoria,
    required this.cantidad,
    required this.precioUnitario,
    required this.fecha,
    this.sincronizada = false,
  });

  double get total => cantidad * precioUnitario;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_remoto': idRemoto,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'fecha': fecha.toIso8601String(),
      'sincronizada': sincronizada ? 1 : 0,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as int?,
      idRemoto: map['id_remoto'] as int?,
      productoId: map['producto_id'] as int,
      productoNombre: map['producto_nombre'] as String,
      categoria: (map['categoria'] as String?) ?? 'Sin categoría',
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      sincronizada: (map['sincronizada'] as int? ?? 0) == 1,
    );
  }

  factory Venta.fromRemoteMap(Map<String, dynamic> map) {
    final remoteLineId = _asInt(map['id']);
    return Venta(
      id: remoteLineId,
      idRemoto: remoteLineId,
      productoId: _asInt(map['producto_id']),
      productoNombre: map['producto_nombre'] as String,
      categoria: map['categoria'] as String,
      cantidad: _asInt(map['cantidad']),
      precioUnitario: _asDouble(map['precio_unitario']),
      fecha: DateTime.parse(map['fecha'].toString()),
      sincronizada: true,
    );
  }

  /// Cuerpo JSON para registrar esta venta en la API remota.
  Map<String, dynamic> toApiJson() {
    return {
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'fecha': fecha.toIso8601String(),
    };
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }
}
