import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'codia/pinyin_learn_detail_codia_page.dart';

/// Codia 原稿 — 拼音学习详情模态（Figma node 4-2，2324×1164）
///
/// 布局与用户提供的 [PinyinLearnDetailCodiaPage] 完全一致，供与正式详情模态对比。
class PinyinLearnDetailCodiaTestScreen extends StatelessWidget {
  const PinyinLearnDetailCodiaTestScreen({super.key});

  static const double designW = 2324;
  static const double designH = 1164;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / designW;
              final scaledH = designH * scale;
              final canvas = SizedBox(
                width: constraints.maxWidth,
                height: scaledH,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: designW,
                    height: designH,
                    child: const PinyinLearnDetailCodiaPage(),
                  ),
                ),
              );

              if (scaledH > constraints.maxHeight + 0.5) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: canvas,
                );
              }
              return Center(child: canvas);
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
                  color: const Color(0xFF214B8C).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Codia 原稿 · 详情模态 4-2',
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
