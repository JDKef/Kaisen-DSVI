import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../providers/inventario_provider.dart';
import '../theme/kaisen_colors.dart';
import '../theme/kaisen_gradients.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../theme/kaisen_typography.dart';
import '../widgets/kaisen_page_background.dart';
import '../widgets/kaisen_primary_button.dart';
import '../widgets/kaisen_section_header.dart';
import '../widgets/kaisen_surface.dart';

const _detailBackground = Color(0xFF111513);
const _detailSurface = Color(0xFF202723);
const _detailBorder = Color(0x12FFFFFF);

class ProductoDetalleScreen extends StatefulWidget {
  const ProductoDetalleScreen({
    super.key,
    this.producto,
    this.codigoBarrasInicial,
  });

  static const routeName = '/producto-detalle';

  /// Si es null, la pantalla funciona en modo "crear producto".
  final Producto? producto;

  /// Código de barras precargado (ej. al venir de escanear un producto no encontrado).
  final String? codigoBarrasInicial;

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _precioController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _codigoBarrasController;

  bool get _esEdicion => widget.producto != null;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _precioController = TextEditingController(
      text: p?.precio.toStringAsFixed(2) ?? '',
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _categoriaController = TextEditingController(text: p?.categoria ?? '');
    _codigoBarrasController = TextEditingController(
      text: p?.codigoBarras ?? widget.codigoBarrasInicial ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _categoriaController.dispose();
    _codigoBarrasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final inventario = context.read<InventarioProvider>();
    final nuevoProducto = Producto(
      id: widget.producto?.id,
      nombre: _nombreController.text.trim(),
      precio: double.parse(_precioController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      categoria: _categoriaController.text.trim(),
      codigoBarras: _codigoBarrasController.text.trim().isEmpty
          ? null
          : _codigoBarrasController.text.trim(),
    );

    final exito = _esEdicion
        ? await inventario.actualizarProducto(nuevoProducto)
        : await inventario.crearProducto(nuevoProducto);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      Navigator.of(context).pop();
    } else {
      _showError(inventario.errorMessage ?? 'Error al guardar');
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Seguro que deseas eliminar "${widget.producto!.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: KaisenColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final inventario = context.read<InventarioProvider>();
    final exito = await inventario.eliminarProducto(widget.producto!.id!);
    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop();
    } else {
      _showError(inventario.errorMessage ?? 'Error al eliminar');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: KaisenColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.panel),
          side: const BorderSide(color: KaisenColors.dangerBorder),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: KaisenColors.danger),
            const SizedBox(width: KaisenSpacing.space3),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _detailBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
        backgroundColor: _detailBackground,
        surfaceTintColor: KaisenColors.transparent,
      ),
      body: KaisenPageBackground(
        backgroundColor: _detailBackground,
        primaryGradient: KaisenGradients.dashboardAtmospheric,
        secondaryGradient: KaisenGradients.dashboardAtmosphericLower,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? KaisenSpacing.space6
                  : KaisenSpacing.space5;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  KaisenSpacing.space3,
                  horizontalPadding,
                  KaisenSpacing.space7,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProductModeLabel(isEditing: _esEdicion),
                          const SizedBox(height: KaisenSpacing.space6),
                          _ProductFormSection(
                            title: 'Información',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nombreController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                                ),
                                const SizedBox(height: KaisenSpacing.space3),
                                TextFormField(
                                  controller: _precioController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio',
                                    prefixText: '\$ ',
                                  ),
                                  validator: (v) {
                                    final valor = double.tryParse(
                                      v?.trim() ?? '',
                                    );
                                    if (valor == null || valor < 0) {
                                      return 'Precio inválido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: KaisenSpacing.space3),
                                TextFormField(
                                  controller: _categoriaController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoría',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Requerido'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: KaisenSpacing.space6),
                          _ProductFormSection(
                            title: 'Inventario',
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Stock inicial',
                              ),
                              validator: (v) {
                                final valor = int.tryParse(v?.trim() ?? '');
                                if (valor == null || valor < 0) {
                                  return 'Stock inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: KaisenSpacing.space6),
                          _ProductFormSection(
                            title: 'Identificación',
                            child: TextFormField(
                              controller: _codigoBarrasController,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Código de barras (opcional)',
                                prefixIcon: Icon(Icons.qr_code_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: KaisenSpacing.space6),
                          KaisenPrimaryButton(
                            label: _esEdicion
                                ? 'Guardar cambios'
                                : 'Crear producto',
                            onPressed: _guardar,
                            busy: _guardando,
                            loadingLabel: 'Guardando producto',
                          ),
                          if (_esEdicion) ...[
                            const SizedBox(height: KaisenSpacing.space3),
                            SizedBox(
                              height: KaisenSpacing.minimumTouchTarget,
                              child: OutlinedButton.icon(
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(
                                    KaisenColors.danger,
                                  ),
                                  backgroundColor: WidgetStateProperty.all(
                                    KaisenColors.dangerSurface,
                                  ),
                                  side: WidgetStateProperty.all(
                                    const BorderSide(
                                      color: KaisenColors.dangerBorder,
                                    ),
                                  ),
                                ),
                                onPressed: _guardando ? null : _eliminar,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                label: const Text('Eliminar producto'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProductModeLabel extends StatelessWidget {
  const _ProductModeLabel({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: KaisenSpacing.minimumTouchTarget,
          height: KaisenSpacing.minimumTouchTarget,
          decoration: BoxDecoration(
            color: _detailSurface,
            borderRadius: BorderRadius.circular(KaisenRadius.control),
            border: Border.all(color: _detailBorder),
          ),
          alignment: Alignment.center,
          child: Icon(
            isEditing ? Icons.edit_outlined : Icons.add_box_outlined,
            size: 20,
            color: KaisenColors.textSecondary,
          ),
        ),
        const SizedBox(width: KaisenSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modo edición' : 'Modo creación',
                style: KaisenTypography.label.copyWith(
                  color: KaisenColors.textPrimary,
                ),
              ),
              const SizedBox(height: KaisenSpacing.space1),
              Text(
                isEditing
                    ? 'Actualiza la información operativa del producto.'
                    : 'Registra la información operativa del producto.',
                style: KaisenTypography.body.copyWith(
                  color: KaisenColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductFormSection extends StatelessWidget {
  const _ProductFormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KaisenSectionHeader(title: title),
        KaisenSurface(
          color: _detailSurface,
          borderColor: _detailBorder,
          radius: KaisenRadius.panel,
          padding: const EdgeInsets.all(KaisenSpacing.space4),
          child: child,
        ),
      ],
    );
  }
}
