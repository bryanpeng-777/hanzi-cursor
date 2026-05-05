import 'package:flutter/material.dart';
import 'package:cs_ui/cs_ui.dart';
import '../utils/app_theme.dart';
import 'learn_screen.dart';
import 'game_screen.dart';
import 'vocabulary_screen.dart';
import 'pinyin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PinyinScreen(),
    const LearnScreen(),
    const GameScreen(),
    const VocabularyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _NavItem(iconKey: 'img_nav_pinyin', iconDesc: '拼音', label: '拼音', index: 0, current: _currentIndex, onTap: _onTap)),
                Expanded(child: _NavItem(iconKey: 'img_nav_learn', iconDesc: '识字', label: '识字', index: 1, current: _currentIndex, onTap: _onTap)),
                Expanded(child: _NavItem(iconKey: 'img_nav_game', iconDesc: '游戏', label: '游戏', index: 2, current: _currentIndex, onTap: _onTap)),
                Expanded(child: _NavItem(iconKey: 'img_nav_vocab', iconDesc: '我的学习', label: '我的学习', index: 3, current: _currentIndex, onTap: _onTap)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
}

class _NavItem extends StatelessWidget {
  final String iconKey;
  final String iconDesc;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({
    required this.iconKey,
    required this.iconDesc,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final iconSize = isSelected ? 28.0 : 24.0;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CsImage(
              configKey: iconKey,
              description: iconDesc,
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryOrange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
