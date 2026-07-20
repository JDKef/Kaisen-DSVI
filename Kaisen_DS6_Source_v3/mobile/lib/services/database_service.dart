import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../models/venta.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'kaisen.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre_usuario TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_remoto INTEGER,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            stock INTEGER NOT NULL,
            categoria TEXT NOT NULL,
            codigo_barras TEXT,
            activo INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_remoto INTEGER,
            producto_id INTEGER NOT NULL,
            producto_nombre TEXT NOT NULL,
            categoria TEXT NOT NULL DEFAULT 'Sin categoría',
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL,
            fecha TEXT NOT NULL,
            sincronizada INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (producto_id) REFERENCES productos (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE productos ADD COLUMN id_remoto INTEGER');
          await db.execute(
            'ALTER TABLE ventas ADD COLUMN sincronizada INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE ventas ADD COLUMN categoria TEXT NOT NULL DEFAULT 'Sin categoría'",
          );
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE ventas ADD COLUMN id_remoto INTEGER');
        }
      },
    );
  }

  // ---------- Usuarios ----------

  Future<int> insertUsuario(Usuario usuario) async {
    final db = await database;
    return db.insert('usuarios', usuario.toMap()..remove('id'));
  }

  Future<Usuario?> getUsuarioByNombre(String nombreUsuario) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'nombre_usuario = ?',
      whereArgs: [nombreUsuario],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Usuario.fromMap(result.first);
  }

  // ---------- Productos ----------

  Future<int> insertProducto(Producto producto) async {
    final db = await database;
    return db.insert('productos', producto.toMap()..remove('id'));
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await database;
    return db.update(
      'productos',
      producto.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminarProducto(int id) async {
    // Baja lógica: se marca como inactivo en lugar de borrar el registro.
    final db = await database;
    return db.update(
      'productos',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Producto>> getProductos({String? busqueda, String? categoria}) async {
    final db = await database;
    final where = StringBuffer('activo = 1');
    final args = <Object?>[];

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      where.write(' AND nombre LIKE ?');
      args.add('%${busqueda.trim()}%');
    }
    if (categoria != null && categoria.trim().isNotEmpty) {
      where.write(' AND categoria = ?');
      args.add(categoria.trim());
    }

    final result = await db.query(
      'productos',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'nombre ASC',
    );
    return result.map(Producto.fromMap).toList();
  }

  Future<Producto?> getProductoPorId(int id) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id = ? AND activo = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Producto.fromMap(result.first);
  }

  /// Igual que [getProductoPorId] pero incluye productos dados de baja.
  /// Se usa para resolver el id remoto real de un producto al sincronizar
  /// una venta antigua, aunque ese producto ya no esté activo.
  Future<Producto?> getProductoPorIdIncluyendoInactivos(int id) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Producto.fromMap(result.first);
  }

  Future<Producto?> getProductoPorCodigoBarras(String codigoBarras) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'codigo_barras = ? AND activo = 1',
      whereArgs: [codigoBarras],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Producto.fromMap(result.first);
  }

  // ---------- Sincronización ----------

  Future<List<Producto>> getProductosSinSincronizar() async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id_remoto IS NULL AND activo = 1',
    );
    return result.map(Producto.fromMap).toList();
  }

  Future<List<Producto>> getProductosSincronizados() async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id_remoto IS NOT NULL AND activo = 1',
    );
    return result.map(Producto.fromMap).toList();
  }

  Future<Producto?> getProductoPorIdRemoto(int idRemoto) async {
    final db = await database;
    final result = await db.query(
      'productos',
      where: 'id_remoto = ?',
      whereArgs: [idRemoto],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Producto.fromMap(result.first);
  }

  Future<Set<int>> getIdsRemotosExistentes() async {
    final db = await database;
    final result = await db.query(
      'productos',
      columns: ['id_remoto'],
      where: 'id_remoto IS NOT NULL',
    );
    return result.map((fila) => fila['id_remoto'] as int).toSet();
  }

  Future<void> marcarProductoSincronizado(int idLocal, int idRemoto) async {
    final db = await database;
    await db.update(
      'productos',
      {'id_remoto': idRemoto},
      where: 'id = ?',
      whereArgs: [idLocal],
    );
  }

  Future<List<Venta>> getVentasSinSincronizar() async {
    final db = await database;
    final result = await db.query('ventas', where: 'sincronizada = 0');
    return result.map(Venta.fromMap).toList();
  }

  /// Marca cada venta local como sincronizada y guarda el id que le asignó
  /// el servidor, para no volver a descargarla como si fuera nueva.
  Future<void> marcarVentasSincronizadas(Map<int, int> idsLocalAIdRemoto) async {
    if (idsLocalAIdRemoto.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    idsLocalAIdRemoto.forEach((idLocal, idRemoto) {
      batch.update(
        'ventas',
        {'sincronizada': 1, 'id_remoto': idRemoto},
        where: 'id = ?',
        whereArgs: [idLocal],
      );
    });
    await batch.commit(noResult: true);
  }

  Future<Set<int>> getIdsRemotosVentasExistentes() async {
    final db = await database;
    final result = await db.query(
      'ventas',
      columns: ['id_remoto'],
      where: 'id_remoto IS NOT NULL',
    );
    return result.map((fila) => fila['id_remoto'] as int).toSet();
  }

  Future<int> insertVentaDesdeRemoto(Venta venta) async {
    final db = await database;
    return db.insert('ventas', venta.toMap()..remove('id'));
  }

  // ---------- Ventas ----------

  Future<List<Venta>> getVentas() async {
    final db = await database;
    final result = await db.query('ventas', orderBy: 'fecha DESC');
    return result.map(Venta.fromMap).toList();
  }

  /// Registra todos los ítems del carrito y descuenta el stock de cada
  /// producto de forma atómica: si algo falla, no se aplica ningún cambio.
  Future<void> registrarVentaCarrito(List<ItemCarrito> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final item in items) {
        final filas = await txn.query(
          'productos',
          where: 'id = ?',
          whereArgs: [item.producto.id],
          limit: 1,
        );
        if (filas.isEmpty) {
          throw StateError('Producto no encontrado: ${item.producto.nombre}');
        }
        final stockActual = filas.first['stock'] as int;
        if (item.cantidad > stockActual) {
          throw StateError('Stock insuficiente para ${item.producto.nombre}');
        }

        await txn.update(
          'productos',
          {'stock': stockActual - item.cantidad},
          where: 'id = ?',
          whereArgs: [item.producto.id],
        );

        final venta = Venta(
          productoId: item.producto.id!,
          productoNombre: item.producto.nombre,
          categoria: item.producto.categoria,
          cantidad: item.cantidad,
          precioUnitario: item.producto.precio,
          fecha: DateTime.now(),
        );
        await txn.insert('ventas', venta.toMap()..remove('id'));
      }
    });
  }
}
