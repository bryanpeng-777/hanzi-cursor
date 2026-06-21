import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 涂鸦线稿模板
enum DoodleTemplate {
  bird('小鸟', usesFigmaAsset: true),
  car('汽车', usesFigmaAsset: false),
  flower('花朵', usesFigmaAsset: false),
  fish('小鱼', usesFigmaAsset: false),
  house('房子', usesFigmaAsset: false),
  butterfly('蝴蝶', usesFigmaAsset: false);

  const DoodleTemplate(this.label, {required this.usesFigmaAsset});

  final String label;
  final bool usesFigmaAsset;

  static DoodleTemplate random([math.Random? random]) {
    final r = random ?? math.Random();
    return DoodleTemplate.values[r.nextInt(DoodleTemplate.values.length)];
  }

  CustomPainter lineArtPainter() => DoodleLineArtPainter(this);
}

/// 程序化线稿（除小鸟外）
class DoodleLineArtPainter extends CustomPainter {
  DoodleLineArtPainter(this.template, {this.strokeColor = Colors.black, this.strokeWidth = 3.0});

  final DoodleTemplate template;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (template) {
      case DoodleTemplate.bird:
        break;
      case DoodleTemplate.car:
        _drawCar(canvas, size, paint);
      case DoodleTemplate.flower:
        _drawFlower(canvas, size, paint);
      case DoodleTemplate.fish:
        _drawFish(canvas, size, paint);
      case DoodleTemplate.house:
        _drawHouse(canvas, size, paint);
      case DoodleTemplate.butterfly:
        _drawButterfly(canvas, size, paint);
    }
  }

  void _drawCar(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.8, h * 0.28),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(body, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.28, w * 0.44, h * 0.22),
        Radius.circular(h * 0.06),
      ),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.28, h * 0.78), w * 0.09, paint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.78), w * 0.09, paint);
  }

  void _drawFlower(Canvas canvas, Size size, Paint paint) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final r = size.width * 0.12;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a) * r * 1.6, math.sin(a) * r * 1.6),
        r * 0.55,
        paint,
      );
    }
    canvas.drawCircle(c, r * 0.5, paint);
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.55),
      Offset(size.width / 2, size.height * 0.88),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, size.height * 0.72),
        width: size.width * 0.2,
        height: size.height * 0.15,
      ),
      0,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.58, size.height * 0.72),
        width: size.width * 0.2,
        height: size.height * 0.15,
      ),
      0,
      math.pi,
      false,
      paint,
    );
  }

  void _drawFish(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.2,
        size.width * 0.78,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.8,
        size.width * 0.15,
        size.height * 0.5,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.68),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.45), 4, paint..style = PaintingStyle.fill);
  }

  void _drawHouse(Canvas canvas, Size size, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.22, size.height * 0.42, size.width * 0.56, size.height * 0.42),
      paint,
    );
    final roof = Path()
      ..moveTo(size.width * 0.12, size.height * 0.44)
      ..lineTo(size.width * 0.5, size.height * 0.18)
      ..lineTo(size.width * 0.88, size.height * 0.44);
    canvas.drawPath(roof, paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.58, size.width * 0.16, size.height * 0.26),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.5, size.width * 0.12, size.height * 0.12),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.5, size.width * 0.12, size.height * 0.12),
      paint,
    );
  }

  void _drawButterfly(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height * 0.48;
    canvas.drawLine(Offset(cx, size.height * 0.22), Offset(cx, size.height * 0.78), paint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - size.width * 0.18, cy - size.height * 0.08), width: size.width * 0.32, height: size.height * 0.22),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + size.width * 0.18, cy - size.height * 0.08), width: size.width * 0.32, height: size.height * 0.22),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - size.width * 0.14, cy + size.height * 0.12), width: size.width * 0.22, height: size.height * 0.16),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + size.width * 0.14, cy + size.height * 0.12), width: size.width * 0.22, height: size.height * 0.16),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DoodleLineArtPainter oldDelegate) =>
      oldDelegate.template != template ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// 用户笔触
class DoodleStroke {
  DoodleStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
}

/// 对应调色盘索引的实际填色
const doodlePaletteColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFF9F43),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFF9B59B6),
  Color(0xFFFF6A88),
  Color(0xFF8B6914),
];

const doodleBrushWidths = [4.0, 12.0, 24.0];
