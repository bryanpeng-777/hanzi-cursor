import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/hanzi_data.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_quiz_screen.dart';

class HanziQuizLevelScreen extends StatelessWidget {
  const HanziQuizLevelScreen({super.key});

  int get _maxLevel =>
      allHanzi.map((h) => h.level).reduce((a, b) => a > b ? a : b);

  static const _levelThemes = <int, _LevelTheme>{
    1: _LevelTheme('数字&基础', '一二三人口手…', '🔢'),
    2: _LevelTheme('大小&五行', '大小火水木土', '🔥'),
    3: _LevelTheme('天地&日常', '天地心书鱼花', '🌍'),
    4: _LevelTheme('动物', '猫狗鸟虫马牛…', '🐾'),
    5: _LevelTheme('颜色', '红黄蓝绿白黑', '🎨'),
    6: _LevelTheme('食物', '饭米面包果菜', '🍚'),
    7: _LevelTheme('身体', '头耳鼻足发眼', '👁️'),
    8: _LevelTheme('家庭', '爸妈哥姐弟妹', '👨‍👩‍👧‍👦'),
    9: _LevelTheme('方位', '上下左右前后', '⬆️'),
    10: _LevelTheme('自然', '风雨雪云雷电', '🌧️'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '选择关卡 ✏️',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<LearningProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _maxLevel,
            itemBuilder: (context, index) {
              final level = index + 1;
              final isUnlocked = provider.isHanziLevelUnlocked(level);
              final isPassed = provider.isHanziLevelPassed(level);
              final bestScore = provider.getHanziQuizBestScore(level);
              final theme = _levelThemes[level] ??
                  _LevelTheme('第$level关', '', '📖');
              final hanziCount = getHanziByLevel(level).length;

              return _LevelCard(
                level: level,
                theme: theme,
                hanziCount: hanziCount,
                isUnlocked: isUnlocked,
                isPassed: isPassed,
                bestScore: bestScore,
                index: index,
                onTap: isUnlocked
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HanziQuizScreen(level: level),
                          ),
                        )
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🔒 请先通过第${level - 1}关测验来解锁',
                              style: const TextStyle(fontSize: 15),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelTheme {
  final String name;
  final String preview;
  final String emoji;
  const _LevelTheme(this.name, this.preview, this.emoji);
}

class _LevelCard extends StatelessWidget {
  final int level;
  final _LevelTheme theme;
  final int hanziCount;
  final bool isUnlocked;
  final bool isPassed;
  final int bestScore;
  final int index;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.theme,
    required this.hanziCount,
    required this.isUnlocked,
    required this.isPassed,
    required this.bestScore,
    required this.index,
    required this.onTap,
  });

  Color get _levelColor => AppColors.getLevelColor(level);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isPassed
                ? Border.all(color: AppTheme.primaryGreen, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 关卡色块
              Container(
                width: 72,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _levelColor,
                      _levelColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isUnlocked ? theme.emoji : '🔒',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '第$level关',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 主体信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (isPassed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '已通关',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUnlocked
                          ? '${theme.preview}  ·  $hanziCount 个汉字'
                          : '通过第${level - 1}关测验后解锁',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isUnlocked && bestScore > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '最高 $bestScore%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧箭头或锁
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isUnlocked
                    ? Icon(Icons.arrow_forward_ios_rounded,
                        color: _levelColor, size: 18)
                    : Icon(Icons.lock_outline,
                        color: Colors.grey[400], size: 20),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn()
        .slideX(begin: 0.1);
  }
}
