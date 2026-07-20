import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../repositories/product_repository.dart';
import '../repositories/remote_failure.dart';

class InventarioProvider extends ChangeNotifier {
  InventarioProvider({ProductRepository? repository})
      : _repository = repository ?? SupabaseProductRepository();

  final ProductRepository _repository;

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _errorMessage;
  String _busqueda = '';
  String? _categoriaSeleccionada;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get errorMessage => _errorMessage;
  String get busqueda => _busqueda;
  String? get categoriaSeleccionada => _categoriaSeleccionada;

  List<String> get categorias =>
      _productos.map((p) => p.categoria).toSet().toList()..sort();

  List<Producto> get productosStockBajo =>
      _productos.where((p) => p.stockBajo).toList();

  Future<void> cargarProductos() async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _productos = await _repository.listActiveProducts(
        search: _busqueda,
        category: _categoriaSeleccionada,
      );
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> buscar(String texto) async {
    _busqueda = texto;
    await cargarProductos();
  }

  Future<void> filtrarPorCategoria(String? categoria) async {
    _categoriaSeleccionada = categoria;
    await cargarProductos();
  }

  Future<bool> crearProducto(Producto producto) async {
    _errorMessage = null;
    try {
      await _repository.createProduct(producto);
      await cargarProductos();
      return true;
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarProducto(Producto producto) async {
    _errorMessage = null;
    try {
      final actual = _findLoadedProduct(producto.id ?? producto.idRemoto);
      final productWithRemoteIdentity = producto.copyWith(
        id: actual?.id ?? producto.id,
        idRemoto: actual?.idRemoto ?? producto.idRemoto,
        version: actual?.version ?? producto.version,
        activo: actual?.activo ?? producto.activo,
      );
      await _repository.updateProduct(productWithRemoteIdentity);
      await cargarProductos();
      return true;
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarProducto(int id) async {
    _errorMessage = null;
    try {
      final producto = _findLoadedProduct(id);
      if (producto == null) {
        throw const RemoteRepositoryException(
          RemoteFailureType.productUnavailable,
        );
      }
      await _repository.archiveProduct(producto);
      await cargarProductos();
      return true;
    } catch (error) {
      _errorMessage = mapRemoteFailure(error).userMessage;
      notifyListeners();
      return false;
    }
  }

  Producto? _findLoadedProduct(int? id) {
    if (id == null) return null;
    for (final product in _productos) {
      if (product.id == id || product.idRemoto == id) return product;
    }
    return null;
  }
}
