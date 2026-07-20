import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_carrito.dart';
import '../providers/inventario_provider.dart';
import '../providers/venta_provider.dart';
import 'producto_detalle_screen.dart';
import 'scanner_screen.dart';

class RegistroVentaScreen extends StatefulWidget {
  const RegistroVentaScreen({super.key});

  static const routeName = '/registro-venta';

  @override
  State<RegistroVentaScreen> createState() => _RegistroVentaScreenState();
}

class _RegistroVentaScreenState extends State<RegistroVentaScreen> {
  bool _buscando = false;
  bool _confirmando = false;
  String? _codigoNoEncontrado;

  Future<void> _escanear() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (codigo == null || !mounted) return;

    setState(() {
      _buscando = true;
      _codigoNoEncontrado = null;
    });

    final venta = context.read<VentaProvider>();
    final producto = await venta.buscarProductoPorCodigo(codigo);

    if (!mounted) return;

    if (producto == null) {
      setState(() {
        _buscando = false;
        _codigoNoEncontrado = codigo;
      });
      return;
    }

    final error = venta.agregarAlCarrito(producto);
    setState(() => _buscando = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmarVenta() async {
    setState(() => _confirmando = true);

    final venta = context.read<VentaProvider>();
    final totalArticulos = venta.cantidadArticulos;
    final total = venta.totalCarrito;
    final error = await venta.confirmarVenta();

    if (!mounted) return;
    setState(() => _confirmando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    await context.read<InventarioProvider>().cargarProductos();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venta registrada: $totalArticulos artículo(s) por \$${total.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venta = context.watch<VentaProvider>();
    final carrito = venta.carrito;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de venta'),
        actions: [
          if (carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              tooltip: 'Vaciar carrito',
              onPressed: venta.limpiarCarrito,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(carrito.isEmpty ? 'Escanear producto' : 'Escanear otro producto'),
                onPressed: _buscando ? null : _escanear,
              ),
            ),
            if (_buscando) const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(),
            ),
            if (_codigoNoEncontrado != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProductoNoEncontrado(codigo: _codigoNoEncontrado!),
              ),
            Expanded(
              child: carrito.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Tu carrito está vacío.\nEscanea un producto para comenzar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: carrito.length,
                      itemBuilder: (context, index) => _ItemCarritoTile(item: carrito[index]),
                    ),
            ),
            if (carrito.isNotEmpty)
              _ResumenCarrito(
                total: venta.totalCarrito,
                confirmando: _confirmando,
                onConfirmar: _confirmarVenta,
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemCarritoTile extends StatelessWidget {
  const _ItemCarritoTile({required this.item});

  final ItemCarrito item;

  @override
  Widget build(BuildContext context) {
    final venta = context.read<VentaProvider>();
    final producto = item.producto;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '\$${producto.precio.toStringAsFixed(2)} c/u · Subtotal \$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => venta.actualizarCantidad(producto.id!, item.cantidad - 1),
            ),
            Text('${item.cantidad}', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: item.cantidad < producto.stock
                  ? () => venta.actualizarCantidad(producto.id!, item.cantidad + 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => venta.quitarDelCarrito(producto.id!),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCarrito extends StatelessWidget {
  const _ResumenCarrito({
    required this.total,
    required this.confirmando,
    required this.onConfirmar,
  });

  final double total;
  final bool confirmando;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: confirmando ? null : onConfirmar,
            child: confirmando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}

class _ProductoNoEncontrado extends StatelessWidget {
  const _ProductoNoEncontrado({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se encontró ningún producto con ese código.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Código: $codigo', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Crear producto con este código'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductoDetalleScreen(codigoBarrasInicial: codigo),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
