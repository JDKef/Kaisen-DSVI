import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/producto.dart';

/// Cliente de la API REST en PHP (ver `kaisen_api` en XAMPP).
///
/// Usa localhost + `adb reverse tcp:80 tcp:80`: mientras el teléfono esté
/// conectado por USB con depuración activada, el tráfico a "localhost" en el
/// teléfono se redirige automáticamente al "localhost" de la PC. Esto evita
/// depender de la red WiFi (útil en redes públicas con aislamiento de
/// clientes, como esta). Si más adelante se prueba por WiFi en una red sin
/// esa restricción, cambia esto por la IP local de la PC (ver `ipconfig`).
class ApiService {
  static const String baseUrl = 'http://localhost/kaisen_api';

  static const _timeout = Duration(seconds: 8);

  Future<List<Map<String, dynamic>>> listarProductos() async {
    final res = await http
        .get(Uri.parse('$baseUrl/productos.php'))
        .timeout(_timeout);
    _verificarRespuesta(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// Busca en el servidor un producto con este código de barras. Se usa
  /// antes de crear uno "nuevo" al sincronizar, para no duplicarlo si ya
  /// existe (por ejemplo, tras reinstalar la app y perder el vínculo local).
  Future<Map<String, dynamic>?> buscarProductoPorCodigo(String codigoBarras) async {
    final res = await http
        .get(Uri.parse('$baseUrl/productos.php?codigo=${Uri.encodeQueryComponent(codigoBarras)}'))
        .timeout(_timeout);
    _verificarRespuesta(res);
    if (res.body == 'null') return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<int> crearProducto(Producto producto) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/productos.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(producto.toApiJson()),
        )
        .timeout(_timeout);
    _verificarRespuesta(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return int.parse(body['id'].toString());
  }

  Future<void> actualizarProducto(Producto producto) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl/productos.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(producto.toApiJson()),
        )
        .timeout(_timeout);
    _verificarRespuesta(res);
  }

  Future<List<Map<String, dynamic>>> listarVentas() async {
    final res = await http.get(Uri.parse('$baseUrl/ventas.php')).timeout(_timeout);
    _verificarRespuesta(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// Registra el carrito completo y retorna los IDs remotos asignados,
  /// en el mismo orden que [payload]. Cada mapa debe traer el `producto_id`
  /// ya resuelto al id remoto correspondiente (ver [Venta.toApiJson]).
  Future<List<int>> registrarVentas(List<Map<String, dynamic>> payload) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/ventas.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    _verificarRespuesta(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['ids'] as List).map((id) => int.parse(id.toString())).toList();
  }

  void _verificarRespuesta(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('La API respondió con error ${res.statusCode}.');
    }
  }
}
