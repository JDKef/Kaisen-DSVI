import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/venta.dart';
import '../providers/venta_provider.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  static const routeName = '/historial-ventas';

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentaProvider>().cargarHistorial();
    });
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final venta = context.watch<VentaProvider>();
    final historial = venta.historialFiltrado;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de ventas')),
      body: venta.cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: venta.cargarHistorial,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ganancias totales', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${venta.gananciaTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${venta.historial.length} venta(s) registrada(s) en total',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (venta.categoriasHistorial.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: const Text('Todas'),
                              selected: venta.categoriaHistorial == null,
                              onSelected: (_) => venta.filtrarHistorialPorCategoria(null),
                            ),
                          ),
                          for (final categoria in venta.categoriasHistorial)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(categoria),
                                selected: venta.categoriaHistorial == categoria,
                                onSelected: (_) => venta.filtrarHistorialPorCategoria(categoria),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        const Text('Ordenar:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Recientes'),
                          selected: !venta.ordenarPorMonto,
                          onSelected: (_) => venta.ordenarHistorialPorMonto(false),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Monto más alto'),
                          selected: venta.ordenarPorMonto,
                          onSelected: (_) => venta.ordenarHistorialPorMonto(true),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: historial.isEmpty
                        ? Center(
                            child: Text(
                              venta.historial.isEmpty
                                  ? 'Todavía no hay ventas registradas.'
                                  : 'No hay ventas en esta categoría.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: historial.length,
                            itemBuilder: (context, index) =>
                                _VentaTile(venta: historial[index], formatearFecha: _formatearFecha),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VentaTile extends StatelessWidget {
  const _VentaTile({required this.venta, required this.formatearFecha});

  final Venta venta;
  final String Function(DateTime) formatearFecha;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.receipt_long, color: Colors.green),
        ),
        title: Text(venta.productoNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${venta.categoria} · ${venta.cantidad} x \$${venta.precioUnitario.toStringAsFixed(2)} · ${formatearFecha(venta.fecha)}',
        ),
        trailing: Text(
          '\$${venta.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
