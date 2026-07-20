class Usuario {
  final int? id;
  final String nombreUsuario;
  final String? passwordHash;
  final String? authUserId;
  final String? nombreUsuarioNormalizado;

  const Usuario({
    this.id,
    required this.nombreUsuario,
    this.passwordHash,
    this.authUserId,
    this.nombreUsuarioNormalizado,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'nombre_usuario': nombreUsuario,
    };
    // Campo conservado para compatibilidad con la tabla SQLite heredada.
    // El flujo nuevo de Supabase nunca lo calcula ni lo persiste.
    if (passwordHash != null) map['password_hash'] = passwordHash;
    return map;
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      nombreUsuario: map['nombre_usuario'] as String,
      passwordHash: map['password_hash'] as String?,
    );
  }

  factory Usuario.fromProfileMap(Map<String, dynamic> map) {
    return Usuario(
      nombreUsuario: map['username'] as String,
      authUserId: map['id'] as String,
      nombreUsuarioNormalizado: map['username_normalized'] as String,
    );
  }
}
