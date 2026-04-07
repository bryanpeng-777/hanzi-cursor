import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class StrokeAnimationWidget extends StatefulWidget {
  final String character;

  const StrokeAnimationWidget({super.key, required this.character});

  @override
  State<StrokeAnimationWidget> createState() => _StrokeAnimationWidgetState();
}

class _StrokeAnimationWidgetState extends State<StrokeAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    setState(() => _isAnimating = true);
    _controller.reset();
    _controller.forward().then((_) {
      setState(() => _isAnimating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _playAnimation,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 米字格
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _GridPainter(),
                ),
                // 汉字显示
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _isAnimating
                          ? _controller.value
                          : 1.0,
                      child: Text(
                        widget.character,
                        style: TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: _isAnimating
                              ? AppTheme.primaryOrange
                              : const Color(0xFF333333),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isAnimating ? '✨ 笔画动画中...' : '👆 点击查看笔画',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ).animate(target: _isAnimating ? 1 : 0).tint(color: AppTheme.primaryOrange),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // 横线
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    // 竖线
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // 斜线
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
