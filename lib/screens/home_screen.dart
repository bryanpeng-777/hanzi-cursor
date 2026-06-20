import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/hanzi_design_spec.dart';
import '../design/hanzi_shared_widgets.dart';
import 'game_screen.dart';
import 'learn_screen.dart';
import 'pinyin_screen.dart';
import 'vocabulary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    PinyinScreen(),
    LearnScreen(),
    GameScreen(),
    VocabularyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HanziDesignSpec.surfaceWarm,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          if (_currentIndex == 0)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 6,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    elevation: 2,
                    borderRadius: BorderRadius.circular(20),
                    child: TextButton.icon(
                      key: const Key('hanzi-screenshot-preview-entry'),
                      onPressed: () => context.push('/pinyin-screenshot-preview'),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('截图预览'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF42BAC4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    elevation: 2,
                    borderRadius: BorderRadius.circular(20),
                    child: TextButton.icon(
                      key: const Key('hanzi-pinyin-codia-test-entry'),
                      onPressed: () => context.push('/pinyin-hub-codia-test'),
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: const Text('Codia 对比'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2C91F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: HanziBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: HanziBottomNavBar.defaultItems,
      ),
    );
  }
}
