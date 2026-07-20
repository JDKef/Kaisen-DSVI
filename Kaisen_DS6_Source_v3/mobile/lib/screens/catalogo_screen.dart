import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../theme/kaisen_colors.dart';
import '../theme/kaisen_gradients.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';
import '../widgets/kaisen_empty_state.dart';
import '../widgets/kaisen_error_state.dart';
import '../widgets/kaisen_page_background.dart';
import '../widgets/kaisen_status_chip.dart';
import '../widgets/kaisen_text_field.dart';
import 'producto_detalle_screen.dart';

const _catalogBackground = Color(0xFF111513);
const _catalogElevated = Color(0xFF171D1A);
const _catalogSurface = Color(0xFF202723);
const _catalogBorder = Color(0x12FFFFFF);

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  static const routeName = '/catalogo';

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventario = context.watch<InventarioProvider>();
    final visibleProducts = inventario.productos.length;
    final productSummary = visibleProducts == 1
        ? '1 producto visible'
        : '$visibleProducts productos visibles';

    return Scaffold(
      backgroundColor: _catalogBackground,
      appBar: AppBar(
        backgroundColor: _catalogBackground,
        surfaceTintColor: KaisenColors.transparent,
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Catálogo de inventario',
              style: KaisenTypography.screenTitle.copyWith(
                color: KaisenColors.textPrimary,
                fontSize: 25,
              ),
            ),
            const SizedBox(height: KaisenSpacing.space1),
            Text(
              productSummary,
              style: KaisenTypography.caption.copyWith(
                color: KaisenColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: KaisenPageBackground(
        backgroundColor: _catalogBackground,
        primaryGradient: KaisenGradients.dashboardAtmospheric,
        secondaryGradient: KaisenGradients.dashboardAtmosphericLower,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KaisenSpacing.space5,
                  KaisenSpacing.space2,
                  KaisenSpacing.space5,
                  KaisenSpacing.space3,
                ),
                child: Semantics(
                  textField: true,
                  label: 'Buscar producto',
                  child: KaisenTextField(
                    controller: _busquedaController,
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _busquedaController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _busquedaController.clear();
                              context.read<InventarioProvider>().buscar('');
                            },
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                    textInputAction: TextInputAction.search,
                    onChanged: (texto) =>
                        context.read<InventarioProvider>().buscar(texto),
                  ),
                ),
              ),
              if (inventario.categorias.isNotEmpty) ...[
                SizedBox(
                  height: KaisenSpacing.minimumTouchTarget,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: KaisenSpacing.space5,
                    ),
                    itemCount: inventario.categorias.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: KaisenSpacing.space2),
                    itemBuilder: (context, index) {
                      final category = index == 0
                          ? null
                          : inventario.categorias[index - 1];
                      final selected =
                          inventario.categoriaSeleccionada == category;
                      return KaisenStatusChip(
                        label: category ?? 'Todas',
                        selected: selected,
                        onTap: () => context
                            .read<InventarioProvider>()
                            .filtrarPorCategoria(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: KaisenSpacing.space3),
              ],
              Expanded(child: _buildInventoryContent(inventario)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProductoDetalleScreen(),
            ),
          );
        },
        tooltip: 'Nuevo producto',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.control),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo producto'),
      ),
    );
  }

  Widget _buildInventoryContent(InventarioProvider inventario) {
    if (inventario.cargando) return const _CatalogLoadingState();

    final error = inventario.errorMessage;
    if (error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KaisenSpacing.space5),
          child: KaisenErrorState(
            title: 'No se pudo cargar el catálogo',
            message: error,
            onRetry: inventario.cargarProductos,
          ),
        ),
      );
    }

    if (inventario.productos.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: KaisenEmptyState(
            title: 'No hay productos que coincidan.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: KaisenColors.accent,
      backgroundColor: _catalogSurface,
      onRefresh: inventario.cargarProductos,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          KaisenSpacing.space5,
          KaisenSpacing.space1,
          KaisenSpacing.space5,
          96,
        ),
        itemCount: inventario.productos.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: KaisenSpacing.space3),
        itemBuilder: (context, index) {
          final producto = inventario.productos[index];
          return _CatalogProductCard(
            producto: producto,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductoDetalleScreen(producto: producto),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CatalogProductCard extends StatelessWidget {
  const _CatalogProductCard({required this.producto, required this.onTap});

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stock = _StockPresentation.forProduct(producto);

    return Semantics(
      button: true,
      label:
          '${producto.nombre}, ${producto.categoria}, '
          'precio ${producto.precio.toStringAsFixed(2)}, '
          'stock ${producto.stock}, ${stock.label}',
      child: ExcludeSemantics(
        child: Material(
          color: KaisenColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KaisenRadius.panel),
            child: Ink(
              padding: const EdgeInsets.all(KaisenSpacing.space4),
              decoration: BoxDecoration(
                color: _catalogSurface,
                borderRadius: BorderRadius.circular(KaisenRadius.panel),
                border: Border.all(color: _catalogBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: KaisenTypography.sectionTitle.copyWith(
                                color: KaisenColors.textPrimary,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: KaisenSpacing.space1),
                            Text(
                              producto.categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KaisenTypography.body.copyWith(
                                color: KaisenColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KaisenSpacing.space4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Precio',
                            style: KaisenTypography.microLabel.copyWith(
                              color: KaisenColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: KaisenSpacing.space1),
                          Text(
                            '\$${producto.precio.toStringAsFixed(2)}',
                            style: KaisenTypography.sectionTitle.copyWith(
                              color: KaisenColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: KaisenSpacing.space3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KaisenSpacing.space3,
                      vertical: KaisenSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: stock.background,
                      borderRadius: BorderRadius.circular(KaisenRadius.control),
                      border: Border.all(color: stock.border),
                    ),
                    child: Row(
                      children: [
                        Icon(stock.icon, size: 18, color: stock.color),
                        const SizedBox(width: KaisenSpacing.space2),
                        Expanded(
                          child: Text(
                            stock.label,
                            style: KaisenTypography.label.copyWith(
                              color: stock.color,
                            ),
                          ),
                        ),
                        Text(
                          '${producto.stock}',
                          style: KaisenTypography.operationalMetric.copyWith(
                            color: stock.valueColor,
                            fontSize: 24,
                            height: 28 / 24,
                          ),
                        ),
                        const SizedBox(width: KaisenSpacing.space1),
                        Text(
                          'unid.',
                          style: KaisenTypography.caption.copyWith(
                            color: KaisenColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: KaisenSpacing.space2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: KaisenColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockPresentation {
  const _StockPresentation({
    required this.label,
    required this.icon,
    required this.color,
    required this.valueColor,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color valueColor;
  final Color background;
  final Color border;

  factory _StockPresentation.forProduct(Producto product) {
    if (product.stock <= 0) {
      return const _StockPresentation(
        label: 'Sin stock',
        icon: Icons.error_outline_rounded,
        color: KaisenColors.danger,
        valueColor: KaisenColors.danger,
        background: KaisenColors.dangerSurface,
        border: KaisenColors.dangerBorder,
      );
    }
    if (product.stockBajo) {
      return const _StockPresentation(
        label: 'Stock bajo',
        icon: Icons.warning_amber_rounded,
        color: KaisenColors.warning,
        valueColor: KaisenColors.warning,
        background: KaisenColors.warningSurface,
        border: KaisenColors.warningBorder,
      );
    }
    return const _StockPresentation(
      label: 'Disponible',
      icon: Icons.inventory_2_outlined,
      color: KaisenColors.textSecondary,
      valueColor: KaisenColors.textPrimary,
      background: _catalogElevated,
      border: _catalogBorder,
    );
  }
}

class _CatalogLoadingState extends StatelessWidget {
  const _CatalogLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando productos',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          KaisenSpacing.space5,
          KaisenSpacing.space1,
          KaisenSpacing.space5,
          KaisenSpacing.space5,
        ),
        itemCount: 3,
        separatorBuilder: (_, _) =>
            const SizedBox(height: KaisenSpacing.space3),
        itemBuilder: (_, _) => const _CatalogLoadingCard(),
      ),
    );
  }
}

class _CatalogLoadingCard extends StatelessWidget {
  const _CatalogLoadingCard();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(KaisenSpacing.space4),
        decoration: BoxDecoration(
          color: _catalogSurface,
          borderRadius: BorderRadius.circular(KaisenRadius.panel),
          border: Border.all(color: _catalogBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 156,
              height: 16,
              decoration: BoxDecoration(
                color: KaisenColors.surfaceHigh,
                borderRadius: BorderRadius.circular(KaisenRadius.small),
              ),
            ),
            const SizedBox(height: KaisenSpacing.space2),
            Container(
              width: 92,
              height: 12,
              decoration: BoxDecoration(
                color: _catalogElevated,
                borderRadius: BorderRadius.circular(KaisenRadius.small),
              ),
            ),
            const Spacer(),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: _catalogElevated,
                borderRadius: BorderRadius.circular(KaisenRadius.control),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
