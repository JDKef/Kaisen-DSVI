import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kaisen_auth_tokens.dart';

enum KaisenInventoryHeroVariant { storageStack, zoneModules }

class KaisenInventoryHero extends StatefulWidget {
  const KaisenInventoryHero({
    super.key,
    this.variant = KaisenInventoryHeroVariant.storageStack,
    this.compact = false,
  });

  final KaisenInventoryHeroVariant variant;
  final bool compact;

  @override
  State<KaisenInventoryHero> createState() => _KaisenInventoryHeroState();
}

class _KaisenInventoryHeroState extends State<KaisenInventoryHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0.58, end: 1).animate(curve);
    _position = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Representación operativa de módulos de inventario',
      image: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _position,
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('kaisen-inventory-hero-painter'),
                painter: _InventoryHeroPainter(
                  variant: widget.variant,
                  compact: widget.compact,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryHeroPainter extends CustomPainter {
  const _InventoryHeroPainter({required this.variant, required this.compact});

  final KaisenInventoryHeroVariant variant;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(size.width / 360, size.height / 170);
    final drawingWidth = 360 * scale;
    final drawingHeight = 170 * scale;
    final origin = Offset(
      (size.width - drawingWidth) / 2,
      (size.height - drawingHeight) / 2,
    );

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    _drawOperationalPath(canvas);
    if (variant == KaisenInventoryHeroVariant.storageStack) {
      _drawStorageStack(canvas);
    } else {
      _drawZoneModules(canvas);
    }
    _drawAnnotations(canvas);

    canvas.restore();
  }

  void _drawOperationalPath(Canvas canvas) {
    final path = Path()
      ..moveTo(16, 137)
      ..lineTo(72, 137)
      ..lineTo(105, 119)
      ..lineTo(193, 119)
      ..lineTo(228, 138)
      ..lineTo(343, 138);
    canvas.drawPath(
      path,
      Paint()
        ..color = KaisenAuthTokens.heroLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    for (final point in const [
      Offset(16, 137),
      Offset(105, 119),
      Offset(228, 138),
      Offset(343, 138),
    ]) {
      canvas.drawCircle(
        point,
        2,
        Paint()..color = KaisenAuthTokens.heroMuted.withValues(alpha: 0.72),
      );
    }
  }

  void _drawStorageStack(Canvas canvas) {
    _drawPlatform(canvas, const Offset(44, 107), 116, 34);
    _drawModule(canvas, const Offset(57, 73), 92, 42, 14, label: 'A-12');
    _drawModule(canvas, const Offset(64, 43), 78, 35, 12, label: 'SKU-04');
    _drawBarcode(canvas, const Offset(78, 86), 29, 14);

    _drawPlatform(canvas, const Offset(188, 117), 126, 34);
    _drawModule(canvas, const Offset(203, 72), 96, 49, 15, label: 'Z-03');
    _drawModule(canvas, const Offset(220, 48), 63, 30, 11, label: '128 uds');
    _drawBarcode(canvas, const Offset(219, 91), 34, 15);
    _drawAccentBeacon(canvas, const Offset(302, 104));
  }

  void _drawZoneModules(Canvas canvas) {
    _drawPlatform(canvas, const Offset(50, 110), 262, 38);
    _drawModule(canvas, const Offset(63, 72), 64, 42, 13, label: 'A-01');
    _drawModule(canvas, const Offset(140, 61), 73, 50, 14, label: 'B-08');
    _drawModule(canvas, const Offset(226, 78), 64, 38, 12, label: 'C-14');
    _drawBarcode(canvas, const Offset(76, 88), 24, 13);
    _drawBarcode(canvas, const Offset(158, 82), 27, 15);
    _drawBarcode(canvas, const Offset(239, 91), 23, 12);
    _drawAccentBeacon(canvas, const Offset(215, 113));
  }

  void _drawPlatform(Canvas canvas, Offset origin, double width, double depth) {
    final top = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + width, origin.dy)
      ..lineTo(origin.dx + width - depth, origin.dy + depth * 0.48)
      ..lineTo(origin.dx - depth, origin.dy + depth * 0.48)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFF243029));
    canvas.drawPath(
      top,
      Paint()
        ..color = KaisenAuthTokens.heroLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _drawModule(
    Canvas canvas,
    Offset origin,
    double width,
    double height,
    double depth, {
    required String label,
  }) {
    final front = Rect.fromLTWH(origin.dx, origin.dy, width, height);
    final top = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + depth, origin.dy - depth * 0.48)
      ..lineTo(origin.dx + width + depth, origin.dy - depth * 0.48)
      ..lineTo(origin.dx + width, origin.dy)
      ..close();
    final side = Path()
      ..moveTo(origin.dx + width, origin.dy)
      ..lineTo(origin.dx + width + depth, origin.dy - depth * 0.48)
      ..lineTo(origin.dx + width + depth, origin.dy + height - depth * 0.48)
      ..lineTo(origin.dx + width, origin.dy + height)
      ..close();

    canvas.drawRect(front, Paint()..color = KaisenAuthTokens.heroModule);
    canvas.drawPath(top, Paint()..color = KaisenAuthTokens.heroModuleHigh);
    canvas.drawPath(side, Paint()..color = const Color(0xFF18211C));

    final outline = Paint()
      ..color = KaisenAuthTokens.heroLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawRect(front, outline);
    canvas.drawPath(top, outline);
    canvas.drawPath(side, outline);
    canvas.drawLine(
      Offset(origin.dx + 9, origin.dy + height - 10),
      Offset(origin.dx + width - 9, origin.dy + height - 10),
      Paint()
        ..color = KaisenAuthTokens.heroLine
        ..strokeWidth = 0.6,
    );
    _drawText(
      canvas,
      label,
      Offset(origin.dx + 8, origin.dy + 7),
      color: KaisenAuthTokens.heroMuted,
      size: 6.5,
      weight: FontWeight.w600,
      spacing: 0.7,
    );
  }

  void _drawBarcode(Canvas canvas, Offset origin, double width, double height) {
    final widths = <double>[1, 2, 1, 1, 2, 1, 2, 1];
    var x = origin.dx;
    for (var index = 0; index < widths.length; index++) {
      final lineWidth = widths[index];
      if (x > origin.dx + width) break;
      canvas.drawRect(
        Rect.fromLTWH(x, origin.dy, lineWidth, height - (index.isOdd ? 2 : 0)),
        Paint()..color = KaisenAuthTokens.heroMuted.withValues(alpha: 0.62),
      );
      x += lineWidth + 2;
    }
  }

  void _drawAccentBeacon(Canvas canvas, Offset center) {
    final illumination = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x52B8F23A), Color(0x00B8F23A)],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, illumination);
    canvas.drawCircle(center, 3.2, Paint()..color = KaisenAuthTokens.accent);
    canvas.drawCircle(
      center,
      6.2,
      Paint()
        ..color = KaisenAuthTokens.accent.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawAnnotations(Canvas canvas) {
    _drawText(
      canvas,
      variant == KaisenInventoryHeroVariant.storageStack
          ? 'ALMACÉN / 03'
          : 'ZONAS / ACTIVAS',
      const Offset(18, 151),
      color: KaisenAuthTokens.heroMuted,
      size: 6,
      weight: FontWeight.w700,
      spacing: 1,
    );
    _drawText(
      canvas,
      compact ? 'SINCRONIZADO' : 'TRAZABILIDAD ACTIVA',
      const Offset(251, 151),
      color: KaisenAuthTokens.heroMuted,
      size: 5.8,
      weight: FontWeight.w600,
      spacing: 0.8,
    );
  }

  void _drawText(
    Canvas canvas,
    String value,
    Offset offset, {
    required Color color,
    required double size,
    required FontWeight weight,
    required double spacing,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _InventoryHeroPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.compact != compact;
  }
}
