import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../providers/auth_provider.dart';
import '../providers/inventario_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/venta_provider.dart';
import '../theme/kaisen_colors.dart';
import '../theme/kaisen_gradients.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';
import '../widgets/kaisen_error_state.dart';
import '../widgets/kaisen_loading_indicator.dart';
import '../widgets/kaisen_page_background.dart';
import '../widgets/kaisen_primary_button.dart';
import '../widgets/kaisen_section_header.dart';
import '../widgets/kaisen_status_chip.dart';
import '../widgets/kaisen_surface.dart';
import '../widgets/producto_card.dart';
import 'catalogo_screen.dart';
import 'historial_ventas_screen.dart';
import 'producto_detalle_screen.dart';
import 'registro_venta_screen.dart';

abstract final class _DashboardPalette {
  static const Color background = Color(0xFF111513);
  static const Color elevated = Color(0xFF171D1A);
  static const Color surface = Color(0xFF202723);
  static const Color hero = Color(0xFFEEEFE9);
  static const Color heroText = Color(0xFF121713);
  static const Color heroSecondary = Color(0xFF4E5751);
  static const Color textPrimary = Color(0xFFF3F4EF);
  static const Color textSecondary = Color(0xFFAAB1AC);
  static const Color accent = Color(0xFFB8F23A);
  static const Color subtleBorder = Color(0x12FFFFFF);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final entranceCurve = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(entranceCurve);
    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarProductos();
      context.read<VentaProvider>().cargarHistorial();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _sincronizar() async {
    final sync = context.read<SyncProvider>();
    final resultado = await sync.sincronizar();

    if (!mounted) return;

    if (resultado == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error al sincronizar'),
          content: SingleChildScrollView(
            child: Text(sync.errorMessage ?? 'No se pudo sincronizar.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    final inventario = context.read<InventarioProvider>();
    final venta = context.read<VentaProvider>();
    await inventario.cargarProductos();
    await venta.cargarHistorial();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado.total == 0
              ? 'Ya estaba todo sincronizado.'
              : 'Sincronizado: ${resultado.productosSubidos} productos nuevos, '
                    '${resultado.productosActualizados} actualizados, '
                    '${resultado.productosDescargados} descargados, '
                    '${resultado.ventasSubidas} ventas subidas, '
                    '${resultado.ventasDescargadas} ventas descargadas.',
        ),
      ),
    );
  }

  void _abrirRegistroVenta() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistroVentaScreen()));
  }

  void _abrirCatalogo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CatalogoScreen()));
  }

  void _abrirNuevoProducto() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProductoDetalleScreen()));
  }

  void _abrirHistorial() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistorialVentasScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inventario = context.watch<InventarioProvider>();
    final sync = context.watch<SyncProvider>();
    final venta = context.watch<VentaProvider>();
    final stockBajo = inventario.productosStockBajo;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final dashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardHeader(
          username: auth.usuarioActual?.nombreUsuario ?? '',
          syncing: sync.sincronizando,
          onSync: sync.sincronizando ? null : _sincronizar,
          onLogout: auth.cerrarSesion,
        ),
        const SizedBox(height: KaisenSpacing.space5),
        _InventoryHealthPanel(
          products: inventario.productos.length,
          lowStock: stockBajo.length,
          outOfStock: stockBajo.where((product) => product.stock <= 0).length,
          loading: inventario.cargando,
          hasError: inventario.errorMessage != null,
        ),
        const SizedBox(height: KaisenSpacing.space4),
        _SecondaryMetrics(
          products: inventario.productos.length,
          lowStock: stockBajo.length,
          earnings: venta.gananciaTotal,
          salesLoading: venta.cargando,
          salesError: venta.errorMessage != null,
          onEarningsTap: _abrirHistorial,
        ),
        if (!venta.cargando && venta.errorMessage != null) ...[
          const SizedBox(height: KaisenSpacing.space4),
          KaisenErrorState(
            title: 'No se pudieron cargar las ventas',
            message: venta.errorMessage!,
            onRetry: venta.cargarHistorial,
          ),
        ],
        const SizedBox(height: KaisenSpacing.space7),
        const KaisenSectionHeader(title: 'Accesos rápidos'),
        const SizedBox(height: KaisenSpacing.space1),
        _DashboardActions(
          onRegisterSale: _abrirRegistroVenta,
          onCatalog: _abrirCatalogo,
          onNewProduct: _abrirNuevoProducto,
          onSalesHistory: _abrirHistorial,
        ),
        const SizedBox(height: KaisenSpacing.space7),
        KaisenSectionHeader(
          title: 'Productos con poco stock',
          trailing: stockBajo.isEmpty
              ? null
              : KaisenStatusChip(
                  label: '${stockBajo.length} pendientes',
                  status: KaisenStatus.warning,
                ),
        ),
        const SizedBox(height: KaisenSpacing.space1),
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: _buildAttentionState(inventario, stockBajo),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: _DashboardPalette.background,
      body: KaisenPageBackground(
        safeArea: true,
        backgroundColor: _DashboardPalette.background,
        primaryGradient: KaisenGradients.dashboardAtmospheric,
        secondaryGradient: KaisenGradients.dashboardAtmosphericLower,
        child: RefreshIndicator(
          color: _DashboardPalette.accent,
          backgroundColor: _DashboardPalette.surface,
          onRefresh: inventario.cargarProductos,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              KaisenSpacing.space5,
              KaisenSpacing.space3,
              KaisenSpacing.space5,
              KaisenSpacing.space7,
            ),
            children: [
              if (reduceMotion)
                dashboardContent
              else
                SlideTransition(
                  position: _slideAnimation,
                  child: dashboardContent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttentionState(
    InventarioProvider inventario,
    List<Producto> stockBajo,
  ) {
    if (inventario.cargando) {
      return const _AttentionLoadingState(key: ValueKey('attention-loading'));
    }

    if (inventario.errorMessage != null) {
      return KaisenErrorState(
        key: const ValueKey('attention-error'),
        title: 'No se pudo cargar el inventario',
        message: inventario.errorMessage!,
        onRetry: inventario.cargarProductos,
      );
    }

    if (stockBajo.isEmpty) {
      return const _HealthyInventoryState(key: ValueKey('attention-empty'));
    }

    return Column(
      key: const ValueKey('attention-products'),
      children: [
        for (final producto in stockBajo)
          ProductoCard(
            producto: producto,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductoDetalleScreen(producto: producto),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.username,
    required this.syncing,
    required this.onSync,
    required this.onLogout,
  });

  final String username;
  final bool syncing;
  final VoidCallback? onSync;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro de operaciones',
                style: KaisenTypography.microLabel.copyWith(
                  color: _DashboardPalette.textSecondary,
                ),
              ),
              const SizedBox(height: KaisenSpacing.space1),
              Text(
                'Hola, $username',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KaisenTypography.screenTitle.copyWith(
                  color: _DashboardPalette.textPrimary,
                  fontSize: 24,
                  height: 28 / 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: KaisenSpacing.space3),
        _HeaderAction(
          tooltip: 'Sincronizar con el servidor',
          onTap: onSync,
          child: syncing
              ? const KaisenLoadingIndicator(
                  size: 16,
                  color: _DashboardPalette.textSecondary,
                )
              : const Icon(
                  Icons.sync,
                  size: 18,
                  color: _DashboardPalette.textSecondary,
                ),
        ),
        const SizedBox(width: KaisenSpacing.space2),
        _HeaderAction(
          tooltip: 'Cerrar sesión',
          onTap: onLogout,
          child: const Icon(
            Icons.logout,
            size: 18,
            color: _DashboardPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: tooltip,
        child: SizedBox.square(
          dimension: KaisenSpacing.minimumTouchTarget,
          child: Material(
            color: KaisenColors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(KaisenRadius.control),
              child: Center(
                child: Ink(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: onTap == null
                        ? _DashboardPalette.elevated
                        : _DashboardPalette.surface,
                    borderRadius: BorderRadius.circular(KaisenRadius.small),
                  ),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _InventoryHealth {
  loading,
  unavailable,
  empty,
  healthy,
  warning,
  critical,
}

class _InventoryHealthPanel extends StatelessWidget {
  const _InventoryHealthPanel({
    required this.products,
    required this.lowStock,
    required this.outOfStock,
    required this.loading,
    required this.hasError,
  });

  final int products;
  final int lowStock;
  final int outOfStock;
  final bool loading;
  final bool hasError;

  _InventoryHealth get _health {
    if (loading) return _InventoryHealth.loading;
    if (hasError) return _InventoryHealth.unavailable;
    if (products == 0) return _InventoryHealth.empty;
    if (outOfStock > 0) return _InventoryHealth.critical;
    if (lowStock > 0) return _InventoryHealth.warning;
    return _InventoryHealth.healthy;
  }

  int get _healthyProducts => (products - lowStock).clamp(0, products);

  @override
  Widget build(BuildContext context) {
    final health = _health;
    final presentation = _HealthPresentation.forState(
      health,
      lowStock: lowStock,
      outOfStock: outOfStock,
    );
    final value = switch (health) {
      _InventoryHealth.loading || _InventoryHealth.unavailable => '—',
      _ => '$_healthyProducts',
    };
    final totalLabel = products == 1
        ? 'de 1 producto activo'
        : 'de $products productos activos';

    return Semantics(
      container: true,
      label:
          'Estado del inventario. ${presentation.label}. '
          '$value $totalLabel.',
      child: KaisenSurface.light(
        color: _DashboardPalette.hero,
        padding: const EdgeInsets.symmetric(
          horizontal: KaisenSpacing.space3,
          vertical: 10,
        ),
        showSheen: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScaler = MediaQuery.textScalerOf(context);
            final compactHeading =
                constraints.maxWidth < 280 || textScaler.scale(1) > 1.3;
            final title = Text(
              'Estado del inventario',
              style: KaisenTypography.label.copyWith(
                color: _DashboardPalette.heroSecondary,
              ),
            );
            final indicator = _HealthIndicator(presentation: presentation);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compactHeading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: KaisenSpacing.space2),
                      indicator,
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: KaisenSpacing.space2),
                      indicator,
                    ],
                  ),
                const SizedBox(height: KaisenSpacing.space2),
                _HealthValueBlock(value: value, totalLabel: totalLabel),
                const SizedBox(height: KaisenSpacing.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KaisenSpacing.space2,
                    vertical: KaisenSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: presentation.bandColor,
                    borderRadius: BorderRadius.circular(KaisenRadius.control),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        presentation.icon,
                        size: 16,
                        color: presentation.bandForeground,
                      ),
                      const SizedBox(width: KaisenSpacing.space2),
                      Expanded(
                        child: Text(
                          presentation.message,
                          style: KaisenTypography.caption.copyWith(
                            color: presentation.bandForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HealthValueBlock extends StatelessWidget {
  const _HealthValueBlock({required this.value, required this.totalLabel});

  final String value;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: KaisenTypography.display.copyWith(
              color: _DashboardPalette.heroText,
              fontSize: 40,
              height: 44 / 40,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: KaisenSpacing.space1),
        Text(
          totalLabel,
          style: KaisenTypography.body.copyWith(
            color: _DashboardPalette.heroSecondary,
          ),
        ),
      ],
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.presentation});

  final _HealthPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KaisenSpacing.space2,
        vertical: KaisenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: _DashboardPalette.elevated,
        borderRadius: BorderRadius.circular(KaisenRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(presentation.icon, color: presentation.color, size: 16),
          const SizedBox(width: KaisenSpacing.space1),
          Text(
            presentation.label,
            style: KaisenTypography.caption.copyWith(
              color: _DashboardPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthPresentation {
  const _HealthPresentation({
    required this.label,
    required this.message,
    required this.icon,
    required this.color,
    required this.bandColor,
    required this.bandForeground,
  });

  final String label;
  final String message;
  final IconData icon;
  final Color color;
  final Color bandColor;
  final Color bandForeground;

  factory _HealthPresentation.forState(
    _InventoryHealth state, {
    required int lowStock,
    required int outOfStock,
  }) {
    return switch (state) {
      _InventoryHealth.loading => const _HealthPresentation(
        label: 'Actualizando',
        message: 'Actualizando inventario remoto',
        icon: Icons.sync,
        color: _DashboardPalette.textSecondary,
        bandColor: _DashboardPalette.elevated,
        bandForeground: _DashboardPalette.textPrimary,
      ),
      _InventoryHealth.unavailable => const _HealthPresentation(
        label: 'Sin datos',
        message: 'No se pudo verificar el estado del inventario',
        icon: Icons.cloud_off_outlined,
        color: KaisenColors.danger,
        bandColor: KaisenColors.danger,
        bandForeground: _DashboardPalette.background,
      ),
      _InventoryHealth.empty => const _HealthPresentation(
        label: 'Sin productos',
        message: 'Aún no hay productos activos para evaluar',
        icon: Icons.inventory_2_outlined,
        color: _DashboardPalette.textSecondary,
        bandColor: _DashboardPalette.elevated,
        bandForeground: _DashboardPalette.textPrimary,
      ),
      _InventoryHealth.healthy => const _HealthPresentation(
        label: 'Saludable',
        message: 'Inventario listo para operar',
        icon: Icons.check_circle_outline,
        color: _DashboardPalette.accent,
        bandColor: KaisenColors.accentMuted,
        bandForeground: _DashboardPalette.accent,
      ),
      _InventoryHealth.warning => _HealthPresentation(
        label: 'Atención',
        message: lowStock == 1
            ? '1 producto necesita reposición'
            : '$lowStock productos necesitan reposición',
        icon: Icons.warning_amber_rounded,
        color: KaisenColors.warning,
        bandColor: KaisenColors.warning,
        bandForeground: _DashboardPalette.background,
      ),
      _InventoryHealth.critical => _HealthPresentation(
        label: 'Crítico',
        message: outOfStock == 1
            ? '1 producto está sin existencias'
            : '$outOfStock productos están sin existencias',
        icon: Icons.error_outline,
        color: KaisenColors.danger,
        bandColor: KaisenColors.danger,
        bandForeground: _DashboardPalette.background,
      ),
    };
  }
}

class _SecondaryMetrics extends StatelessWidget {
  const _SecondaryMetrics({
    required this.products,
    required this.lowStock,
    required this.earnings,
    required this.salesLoading,
    required this.salesError,
    required this.onEarningsTap,
  });

  final int products;
  final int lowStock;
  final double earnings;
  final bool salesLoading;
  final bool salesError;
  final VoidCallback onEarningsTap;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Productos activos',
        value: '$products',
        icon: Icons.inventory_2_outlined,
        valueColor: _DashboardPalette.textPrimary,
      ),
      _MetricData(
        label: 'Stock bajo',
        value: '$lowStock',
        icon: Icons.warning_amber_rounded,
        valueColor: lowStock > 0
            ? KaisenColors.warning
            : _DashboardPalette.textPrimary,
      ),
      _MetricData(
        label: 'Ganancias totales',
        value: salesLoading || salesError
            ? '—'
            : '\$${earnings.toStringAsFixed(2)}',
        icon: Icons.payments_outlined,
        valueColor: _DashboardPalette.accent,
        onTap: onEarningsTap,
      ),
    ];

    return KaisenSurface(
      color: _DashboardPalette.surface,
      borderColor: _DashboardPalette.subtleBorder,
      padding: const EdgeInsets.all(KaisenSpacing.space2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stackMetrics = constraints.maxWidth < 330 || textScale > 1.3;
          if (stackMetrics) {
            return Column(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  _MetricRailItem(data: metrics[index], horizontal: true),
                  if (index != metrics.length - 1)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(child: _MetricRailItem(data: metrics[index])),
                  if (index != metrics.length - 1)
                    const VerticalDivider(width: 1, thickness: 0.5),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  final VoidCallback? onTap;
}

class _MetricRailItem extends StatelessWidget {
  const _MetricRailItem({required this.data, this.horizontal = false});

  final _MetricData data;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final value = Text(
      data.value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: KaisenTypography.sectionTitle.copyWith(
        color: data.valueColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final label = Text(
      data.label,
      maxLines: horizontal ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: KaisenTypography.caption.copyWith(
        color: _DashboardPalette.textSecondary,
      ),
    );
    final content = horizontal
        ? Row(
            children: [
              _MetricIcon(icon: data.icon),
              const SizedBox(width: KaisenSpacing.space3),
              Expanded(child: label),
              const SizedBox(width: KaisenSpacing.space3),
              value,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricIcon(icon: data.icon),
              const SizedBox(height: KaisenSpacing.space2),
              value,
              const SizedBox(height: KaisenSpacing.space1),
              label,
            ],
          );

    return Semantics(
      button: data.onTap != null,
      label: '${data.label}: ${data.value}',
      child: Material(
        color: KaisenColors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.all(KaisenSpacing.space3),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _DashboardPalette.elevated,
        borderRadius: BorderRadius.circular(KaisenRadius.small),
      ),
      child: Icon(icon, size: 18, color: _DashboardPalette.textSecondary),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
    required this.onRegisterSale,
    required this.onCatalog,
    required this.onNewProduct,
    required this.onSalesHistory,
  });

  final VoidCallback onRegisterSale;
  final VoidCallback onCatalog;
  final VoidCallback onNewProduct;
  final VoidCallback onSalesHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final compactIcons = constraints.maxWidth < 300 || textScale > 1.2;
        final stackActions = constraints.maxWidth < 380 || textScale > 1.15;
        final catalog = _DashboardSecondaryButton(
          label: 'Catálogo',
          icon: compactIcons ? null : Icons.list_alt,
          onPressed: onCatalog,
        );
        final newProduct = _DashboardSecondaryButton(
          label: 'Nuevo producto',
          icon: compactIcons ? null : Icons.add,
          onPressed: onNewProduct,
        );
        final secondaryActions = stackActions
            ? Column(
                children: [
                  catalog,
                  const SizedBox(height: KaisenSpacing.space2),
                  newProduct,
                ],
              )
            : Row(
                children: [
                  Expanded(child: catalog),
                  const SizedBox(width: KaisenSpacing.space3),
                  Expanded(child: newProduct),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KaisenPrimaryButton(
              label: 'Registrar venta',
              icon: compactIcons ? null : Icons.point_of_sale,
              onPressed: onRegisterSale,
            ),
            const SizedBox(height: KaisenSpacing.space3),
            secondaryActions,
            const SizedBox(height: KaisenSpacing.space2),
            _DashboardSecondaryButton(
              label: 'Ver ventas',
              icon: compactIcons ? null : Icons.receipt_long,
              onPressed: onSalesHistory,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardSecondaryButton extends StatelessWidget {
  const _DashboardSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: KaisenSpacing.minimumTouchTarget,
      child: Material(
        color: _DashboardPalette.surface,
        borderRadius: BorderRadius.circular(KaisenRadius.control),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(KaisenRadius.control),
          overlayColor: WidgetStateProperty.all(const Color(0x0FFFFFFF)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KaisenSpacing.space4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: _DashboardPalette.textSecondary),
                  const SizedBox(width: KaisenSpacing.space2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KaisenTypography.label.copyWith(
                      color: _DashboardPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionLoadingState extends StatelessWidget {
  const _AttentionLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const KaisenSurface(
      color: _DashboardPalette.surface,
      borderColor: null,
      child: Row(
        children: [
          KaisenLoadingIndicator(
            color: _DashboardPalette.textSecondary,
            semanticLabel: 'Cargando inventario',
          ),
          SizedBox(width: KaisenSpacing.space3),
          Expanded(child: Text('Actualizando inventario...')),
        ],
      ),
    );
  }
}

class _HealthyInventoryState extends StatelessWidget {
  const _HealthyInventoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return KaisenSurface(
      color: _DashboardPalette.surface,
      borderColor: null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KaisenColors.accentMuted,
              borderRadius: BorderRadius.circular(KaisenRadius.control),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 22,
              color: _DashboardPalette.accent,
            ),
          ),
          const SizedBox(width: KaisenSpacing.space3),
          const Expanded(
            child: Text('Todo el inventario tiene stock saludable.'),
          ),
        ],
      ),
    );
  }
}
