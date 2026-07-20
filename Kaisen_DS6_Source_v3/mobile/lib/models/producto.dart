class Producto {
  final int? id;
  final int? idRemoto;
  final String nombre;
  final double precio;
  final int stock;
  final String categoria;
  final String? codigoBarras;
  final bool activo;
  final int version;

  const Producto({
    this.id,
    this.idRemoto,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.categoria,
    this.codigoBarras,
    this.activo = true,
    this.version = 1,
  });

  Producto copyWith({
    int? id,
    int? idRemoto,
    String? nombre,
    double? precio,
    int? stock,
    String? categoria,
    String? codigoBarras,
    bool? activo,
    int? version,
  }) {
    return Producto(
      id: id ?? this.id,
      idRemoto: idRemoto ?? this.idRemoto,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      activo: activo ?? this.activo,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_remoto': idRemoto,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'codigo_barras': codigoBarras,
      'activo': activo ? 1 : 0,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      idRemoto: map['id_remoto'] as int?,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      stock: map['stock'] as int,
      categoria: map['categoria'] as String,
      codigoBarras: map['codigo_barras'] as String?,
      activo: (map['activo'] as int) == 1,
    );
  }

  factory Producto.fromRemoteMap(Map<String, dynamic> map) {
    final remoteId = _asInt(map['id']);
    return Producto(
      id: remoteId,
      idRemoto: remoteId,
      nombre: map['nombre'] as String,
      precio: _asDouble(map['precio']),
      stock: _asInt(map['stock']),
      categoria: map['categoria'] as String,
      codigoBarras: map['codigo_barras'] as String?,
      activo: map['activo'] as bool? ?? true,
      version: _asInt(map['version']),
    );
  }

  /// Cuerpo JSON para crear/actualizar este producto en la API remota.
  Map<String, dynamic> toApiJson() {
    return {
      if (idRemoto != null) 'id': idRemoto,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'codigo_barras': codigoBarras,
    };
  }

  bool get stockBajo => stock <= 5;

  int? get remoteId => idRemoto ?? id;

  static int _asInt(Object? value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }
}
