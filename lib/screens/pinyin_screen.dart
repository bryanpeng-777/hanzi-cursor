import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'pinyin_learn_screen.dart';
import 'pinyin_exercise_screen.dart';

class PinyinScreen extends StatefulWidget {
  const PinyinScreen({super.key});

  @override
  State<PinyinScreen> createState() => _PinyinScreenState();
}

class _PinyinScreenState extends State<PinyinScreen>
    with TickerProviderStateMixin {
  Timer? _mascotTimer;
  Timer? _speechHideTimer;
  bool _showSpeech = false;

  late AnimationController _bobController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _mascotTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _showMascotSpeech();
    });
  }

  @override
  void dispose() {
    _mascotTimer?.cancel();
    _speechHideTimer?.cancel();
    _bobController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _showMascotSpeech() {
    setState(() => _showSpeech = true);
    _waveController.repeat(reverse: true);
    _speechHideTimer?.cancel();
    _speechHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _hideMascotSpeech();
    });
  }

  void _hideMascotSpeech() {
    setState(() => _showSpeech = false);
    _waveController.stop();
    _waveController.reset();
  }

  void _onMascotTap() {
    if (_showSpeech) {
      _hideMascotSpeech();
    } else {
      _showMascotSpeech();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, _) {
        final mistakeCount = provider.pinyinMistakes.length;
        return SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    _buildLearnCard(context),
                    const SizedBox(height: 16),
                    _buildExerciseCard(context),
                    const SizedBox(height: 16),
                    _buildMistakeCard(context, mistakeCount),
                    const SizedBox(height: 24),
                    _buildTip(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 20,
                child: _buildMascot(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMascot() {
    return GestureDetector(
      onTap: _onMascotTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showSpeech)
            Container(
              margin: const EdgeInsets.only(bottom: 10, right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 190),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '小朋友，今天我们要认识哪个拼音朋友呢？🎵',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 250.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 450.ms,
                ),
          AnimatedBuilder(
            animation: Listenable.merge([_bobController, _waveController]),
            builder: (context, child) {
              final bobOffset = _bobController.value * -6.0;
              final waveAngle =
                  _showSpeech ? (_waveController.value - 0.5) * 0.5 : 0.0;
              return Transform.translate(
                offset: Offset(0, bobOffset),
                child: Transform.rotate(
                  angle: waveAngle,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF2BB5AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐿️', style: TextStyle(fontSize: 34)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '探索乐园 🔤',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 28,
              ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(height: 4),
        Text(
          '学好拼音，读好汉字！',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[600]),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildLearnCard(BuildContext context) {
    return _EntryCard(
      emoji: '📚',
      title: '拼音学习',
      subtitle: '认识声母·韵母·四声',
      gradient: const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFF4ECDC4),
      badge: null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PinyinLearnScreen()),
      ),
      delay: 0,
    );
  }

  Widget _buildExerciseCard(BuildContext context) {
    return _EntryCard(
      emoji: '✏️',
      title: '拼音测验',
      subtitle: '声母识别·10 题挑战',
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: AppTheme.primaryOrange,
      badge: null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const PinyinExerciseScreen(mistakeMode: false)),
      ),
      delay: 100,
    );
  }

  Widget _buildMistakeCard(BuildContext context, int mistakeCount) {
    final hasMistakes = mistakeCount > 0;
    return _TreasureChestCard(
      hasMistakes: hasMistakes,
      mistakeCount: mistakeCount,
      onTap: hasMistakes
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const PinyinExerciseScreen(mistakeMode: true)),
              )
          : () => _showEmptyChestDialog(context),
      delay: 200,
    );
  }

  void _showEmptyChestDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64))
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
              const SizedBox(height: 16),
              Text(
                '太棒了！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '你的错题怪兽都被消灭啦！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('继续加油 💪',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ).animate().scale(
            begin: const Offset(0.85, 0.85),
            curve: Curves.elasticOut,
            duration: 450.ms,
          ),
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryYellow.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '先学习声母和韵母，再做测验！答错的声母会自动加入错题集。',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}

// ───────────────────────── 宝箱卡片 ──────────────────────────

class _TreasureChestCard extends StatefulWidget {
  final bool hasMistakes;
  final int mistakeCount;
  final VoidCallback onTap;
  final int delay;

  const _TreasureChestCard({
    required this.hasMistakes,
    required this.mistakeCount,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_TreasureChestCard> createState() => _TreasureChestCardState();
}

class _TreasureChestCardState extends State<_TreasureChestCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.hasMistakes) {
      _pulseController.repeat(reverse: true);
    }

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_TreasureChestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasMistakes && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasMistakes) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final gradient = widget.hasMistakes
        ? const LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final shadowColor =
        widget.hasMistakes ? const Color(0xFFFF8C00) : Colors.grey;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _tapScale]),
        builder: (context, child) {
          final glowOpacity = widget.hasMistakes
              ? 0.3 + _pulseController.value * 0.35
              : 0.25;
          final chestScale = 1.0 + (widget.hasMistakes
              ? _pulseController.value * 0.06
              : 0.0);

          return Transform.scale(
            scale: _tapScale.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 发光光晕（有错题时）
                if (widget.hasMistakes)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withOpacity(glowOpacity),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      Transform.scale(
                        scale: chestScale,
                        child: Text(
                          widget.hasMistakes ? '📦' : '🔒',
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '错题宝箱',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.hasMistakes
                                  ? '宝箱里藏着 ${widget.mistakeCount} 个错题，快来攻克！'
                                  : '宝箱已上锁，暂无错题怪兽 ✨',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(
                          widget.hasMistakes
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.lock_outline_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // 错题数量角标
                if (widget.hasMistakes)
                  Positioned(
                    top: -8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Text(
                        '${widget.mistakeCount}',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ).animate(delay: widget.delay.ms).fadeIn().scale(
        begin: const Offset(0.94, 0.94));
  }
}

// ───────────────────────── 通用入口卡片（Spring 点击动效）──────────────────────────

class _EntryCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color shadowColor;
  final String? badge;
  final VoidCallback? onTap;
  final int delay;

  const _EntryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.shadowColor,
    required this.badge,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Opacity(
          opacity: widget.onTap == null ? 0.6 : 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Text(widget.emoji,
                        style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onTap != null)
                      const Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white70, size: 18),
                      ),
                  ],
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: -8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(delay: widget.delay.ms).fadeIn().scale(
        begin: const Offset(0.94, 0.94));
  }
}
