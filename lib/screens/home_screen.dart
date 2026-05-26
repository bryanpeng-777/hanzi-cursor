import 'package:flutter/material.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: HanziBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: HanziBottomNavBar.defaultItems,
      ),
    );
  }
}
