import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cs_ui/cs_ui.dart';

class StarRewardWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const StarRewardWidget({super.key, required this.onComplete});

  @override
  State<StarRewardWidget> createState() => _StarRewardWidgetState();
}

class _StarRewardWidgetState extends State<StarRewardWidget> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsImage(configKey: 'img_icon_celebration', description: '庆祝', width: 80, height: 80)
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shake(),
            const SizedBox(height: 20),
            const Text(
              '太棒了！',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.5),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CsImage(
                    configKey: 'img_icon_star',
                    description: '奖励星星',
                    width: 40,
                    height: 40,
                  )
                      .animate(delay: (400 + i * 150).ms)
                      .scale(
                        begin: const Offset(0, 0),
                        curve: Curves.elasticOut,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '获得 3 颗星星！',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white70,
              ),
            ).animate(delay: 900.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
