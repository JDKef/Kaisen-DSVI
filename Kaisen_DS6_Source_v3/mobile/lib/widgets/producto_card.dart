import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/kaisen_colors.dart';
import '../theme/kaisen_spacing.dart';
import 'stock_badge.dart';

class ProductoCard extends StatelessWidget {
  const ProductoCard({super.key, required this.producto, this.onTap});

  final Producto producto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: KaisenSpacing.space3,
        vertical: KaisenSpacing.space1,
      ),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: KaisenColors.surfaceHigh,
          child: Icon(
            Icons.inventory_2_outlined,
            color: KaisenColors.textSecondary,
          ),
        ),
        title: Text(
          producto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${producto.categoria} · \$${producto.precio.toStringAsFixed(2)}',
        ),
        trailing: StockBadge(
          stock: producto.stock,
          stockBajo: producto.stockBajo,
        ),
      ),
    );
  }
}
