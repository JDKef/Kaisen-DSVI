import 'package:flutter/foundation.dart';

import '../models/item_carrito.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../repositories/product_repository.dart';
import '../repositories/remote_failure.dart';
import '../repositories/sale_repository.dart';

class VentaProvider extends ChangeNotifier {
  VentaProvider({
    SaleRepository? saleRepository,
    ProductRepository? productRepository,
    Future<void> Function()? refreshInventory,
  })  : _saleRepository = saleRepository ?? SupabaseSaleRepository(),
        _productRepository = productRepository ?? SupabaseProductRepository(),
        _refreshInventory = refreshInventory;

  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;
  final Future<void> Function()? _refreshInventory;

  List<Venta> _historial = [];
  bool _cargando = false;
  String? _errorMessage;
  String? _categoriaHistorial;
  bool _ordenarPorMonto = false;

  final List<ItemCarrito> _carrito = [];

  List<Venta> get historial => _historial;
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);
  double get totalCarrito =>
      _carrito.fold(0, (suma, item) => suma + item.subtotal);
  int get cantidadArticulos =>
      _carrito.fold(0, (suma, item) => suma + item.cantidad);
  double get gananciaTotal =>
      _historial.fold(0.0, (suma, venta) => suma + venta.total);

  String? get categoriaHistorial => _categoriaHistorial;
  bool get ordenarPorMonto => _ordenarPorMonto;

  List<String> get categoriasHistorial =>
      _historial.map((v) => v.categoria).toSet().toList()..sort();

  List<Venta> get historialFiltrado {
    var lista = _categoriaHistorial == null
        ? _historial
        : _historial.where((v) => v.categoria == _categoriaHistorial).toList();

    lista = List.of(lista);
    if (_ordenarPorMonto) {
      lista.sort((a, b) => b.total.compareTo(a.total));
    } else {
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    return lista;
  }

  void filtrarHistorialPorCategoria(String? categoria) {
    _categoriaHistorial = categoria;
    notifyListeners();
  }

  void ordenarHistorialPorMonto(bool activar) {
    _ordenarPorMonto = activar;
    notifyListeners();
  }

  Future<void> cargarHistorial() async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _historial = await _saleRepository.loadHistory();
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<Producto?> buscarProductoPorCodigo(String codigoBarras) async {
    _errorMessage = null;
    try {
      return await _productRepository.findByBarcode(codigoBarras);
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
      notifyListeners();
      return null;
    }
  }

  String? agregarAlCarrito(Producto producto) {
    final productId = producto.remoteId;
    if (productId == null || !producto.activo) {
      return RemoteFailureType.productUnavailable.userMessage;
    }

    final index = _carrito.indexWhere(
      (item) => item.producto.remoteId == productId,
    );
    if (index == -1) {
      if (producto.stock <= 0) {
        return '${producto.nombre} no tiene stock disponible.';
      }
      _carrito.add(ItemCarrito(producto: producto, cantidad: 1));
      notifyListeners();
      return null;
    }

    final actual = _carrito[index];
    if (actual.cantidad + 1 > producto.stock) {
      return 'No hay mas stock disponible de ${producto.nombre}.';
    }
    _carrito[index] = actual.copyWith(cantidad: actual.cantidad + 1);
    notifyListeners();
    return null;
  }

  void actualizarCantidad(int productoId, int nuevaCantidad) {
    final index = _cartIndexForProduct(productoId);
    if (index == -1) return;

    if (nuevaCantidad <= 0) {
      _carrito.removeAt(index);
    } else {
      final tope = _carrito[index].producto.stock;
      _carrito[index] = _carrito[index].copyWith(
        cantidad: nuevaCantidad > tope ? tope : nuevaCantidad,
      );
    }
    notifyListeners();
  }

  void quitarDelCarrito(int productoId) {
    _carrito.removeWhere(
      (item) =>
          item.producto.id == productoId ||
          item.producto.remoteId == productoId,
    );
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    notifyListeners();
  }

  Future<String?> confirmarVenta() async {
    if (_carrito.isEmpty) return 'El carrito esta vacio.';

    final items = <SaleItemRequest>[];
    for (final item in _carrito) {
      final remoteId = item.producto.remoteId;
      if (remoteId == null) {
        return RemoteFailureType.productUnavailable.userMessage;
      }
      items.add(
        SaleItemRequest(productId: remoteId, quantity: item.cantidad),
      );
    }

    try {
      await _saleRepository.createSale(items);
      _carrito.clear();
      notifyListeners();
      await cargarHistorial();
      await _refreshInventory?.call();
      return null;
    } catch (error) {
      final message = mapRemoteFailure(error).userMessage;
      _errorMessage = message;
      notifyListeners();
      return message;
    }
  }

  int _cartIndexForProduct(int productId) {
    return _carrito.indexWhere(
      (item) =>
          item.producto.id == productId ||
          item.producto.remoteId == productId,
    );
  }
}
