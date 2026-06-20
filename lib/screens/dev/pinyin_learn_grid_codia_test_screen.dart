import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'codia/pinyin_learn_grid_codia_page.dart';

/// Codia 原稿 — 拼音学习网格主界面（Figma node 9-2，1536×1024）
///
/// 布局与用户提供的 [PinyinLearnGridCodiaPage] 完全一致，仅将 `images/*` 映射到
/// `assets/figma_ui/*`，供与正式 [PinyinLearnScreen] 对比。
class PinyinLearnGridCodiaTestScreen extends StatelessWidget {
  const PinyinLearnGridCodiaTestScreen({super.key});

  static const double designW = 1536;
  static const double designH = 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final scaledH =
                  designH * constraints.maxWidth / designW;
              final canvas = SizedBox(
                width: constraints.maxWidth,
                height: scaledH,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: designW,
                    height: designH,
                    child: const PinyinLearnGridCodiaPage(),
                  ),
                ),
              );

              if (scaledH > constraints.maxHeight + 0.5) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: canvas,
                );
              }
              return Align(alignment: Alignment.topCenter, child: canvas);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  tooltip: '返回',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0BAEB9).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Codia 原稿 · 学习网格 9-2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
