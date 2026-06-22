import 'dart:ui' as ui;

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../data/doodle_templates.dart';

/// 填色画板：深色线稿引导 + 用户笔触
class DoodleDrawingCanvas extends StatefulWidget {
  const DoodleDrawingCanvas({
    super.key,
    required this.template,
    required this.selectedColorIndex,
    required this.brushIndex,
    required this.isEraser,
    required this.strokes,
    required this.onStrokesChanged,
  });

  final DoodleTemplate template;
  final int selectedColorIndex;
  final int brushIndex;
  final bool isEraser;
  final List<DoodleStroke> strokes;
  final ValueChanged<List<DoodleStroke>> onStrokesChanged;

  @override
  State<DoodleDrawingCanvas> createState() => _DoodleDrawingCanvasState();
}

class _DoodleDrawingCanvasState extends State<DoodleDrawingCanvas> {
  DoodleStroke? _activeStroke;

  void _onPanStart(DragStartDetails details) {
    _activeStroke = DoodleStroke(
      points: [details.localPosition],
      color: widget.isEraser ? Colors.white : doodlePaletteColors[widget.selectedColorIndex],
      width: doodleBrushWidths[widget.brushIndex.clamp(0, doodleBrushWidths.length - 1)],
      isEraser: widget.isEraser,
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStroke == null) return;
    _activeStroke!.points.add(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStroke == null) return;
    final updated = [...widget.strokes, _activeStroke!];
    widget.onStrokesChanged(updated);
    _activeStroke = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final painterStrokes = [
      ...widget.strokes,
      if (_activeStroke != null) _activeStroke!,
    ];

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _DoodleCanvasPainter(
          template: widget.template,
          strokes: painterStrokes,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DoodleCanvasPainter extends CustomPainter {
  _DoodleCanvasPainter({
    required this.template,
    required this.strokes,
  });

  final DoodleTemplate template;
  final List<DoodleStroke> strokes;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );

    if (!template.usesFigmaAsset) {
      DoodleLineArtPainter(
        template,
        strokeColor: doodleLineArtGuideColor,
        strokeWidth: 3.0,
      ).paint(canvas, canvasSize);
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.isEraser) {
        paint
          ..color = Colors.white
          ..blendMode = BlendMode.src;
      } else {
        paint.color = stroke.color;
      }

      if (stroke.points.length < 2) {
        canvas.drawCircle(stroke.points.first, stroke.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoodleCanvasPainter oldDelegate) =>
      oldDelegate.template != template || oldDelegate.strokes != strokes;
}

/// 导出画板为 PNG 字节
Future<ui.Image?> captureDoodleCanvas(GlobalKey exportKey) async {
  final boundary = exportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  return boundary.toImage(pixelRatio: 3.0);
}

/// Figma 切图封装（与拼音学习一致）
class FigmaUiImage extends StatelessWidget {
  const FigmaUiImage({
    super.key,
    required this.configKey,
    required this.description,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String configKey;
  final String description;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CsImage(
      configKey: configKey,
      description: description,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
