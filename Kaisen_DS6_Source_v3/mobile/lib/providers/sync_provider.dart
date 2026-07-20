import 'package:flutter/foundation.dart';

import 'inventario_provider.dart';
import 'venta_provider.dart';

class SyncResultado {
  const SyncResultado({
    required this.productosSubidos,
    required this.productosActualizados,
    required this.productosDescargados,
    required this.ventasSubidas,
    required this.ventasDescargadas,
  });

  final int productosSubidos;
  final int productosActualizados;
  final int productosDescargados;
  final int ventasSubidas;
  final int ventasDescargadas;

  int get total =>
      productosSubidos +
      productosActualizados +
      productosDescargados +
      ventasSubidas +
      ventasDescargadas;
}

class SyncProvider extends ChangeNotifier {
  SyncProvider({
    required InventarioProvider inventarioProvider,
    required VentaProvider ventaProvider,
  })  : _inventarioProvider = inventarioProvider,
        _ventaProvider = ventaProvider;

  final InventarioProvider _inventarioProvider;
  final VentaProvider _ventaProvider;

  bool _sincronizando = false;
  String? _errorMessage;
  SyncResultado? _ultimoResultado;

  bool get sincronizando => _sincronizando;
  String? get errorMessage => _errorMessage;
  SyncResultado? get ultimoResultado => _ultimoResultado;

  Future<SyncResultado?> sincronizar() async {
    _sincronizando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventarioProvider.cargarProductos();
      if (_inventarioProvider.errorMessage != null) {
        _errorMessage = _inventarioProvider.errorMessage;
        return null;
      }

      await _ventaProvider.cargarHistorial();
      if (_ventaProvider.errorMessage != null) {
        _errorMessage = _ventaProvider.errorMessage;
        return null;
      }

      const resultado = SyncResultado(
        productosSubidos: 0,
        productosActualizados: 0,
        productosDescargados: 0,
        ventasSubidas: 0,
        ventasDescargadas: 0,
      );
      _ultimoResultado = resultado;
      return resultado;
    } catch (_) {
      _errorMessage =
          'No se pudo actualizar la informacion desde el servidor.';
      return null;
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }
}
