import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/pinyin_figma_assets.dart';
import '../../providers/learning_provider.dart';

/// Codia 导出原稿 1536×1024，保留 right/bottom 锚点定位，供与正式 [PinyinScreen] 对比。
class PinyinHubCodiaTestScreen extends ConsumerWidget {
  const PinyinHubCodiaTestScreen({super.key});

  static const double _designW = 1536;
  static const double _designH = 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(learningNotifierProvider).totalStars;
    final mistakeCount =
        ref.watch(learningNotifierProvider).pinyinMistakes.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final scaledH =
                  _designH * constraints.maxWidth / _designW;
              final hub = SizedBox(
                width: constraints.maxWidth,
                height: scaledH,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: _designW,
                    height: _designH,
                    child: _CodiaCanvas(
                      points: points,
                      mistakeCount: mistakeCount,
                      onLearn: () => context.push('/pinyin-learn'),
                      onQuiz: () => context.push('/pinyin-exercise'),
                      onMistake: mistakeCount > 0
                          ? () => context.push(
                                '/pinyin-exercise',
                                extra: {'mistakeMode': true},
                              )
                          : null,
                    ),
                  ),
                ),
              );

              if (scaledH > constraints.maxHeight + 0.5) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: hub,
                );
              }
              return Align(alignment: Alignment.topCenter, child: hub);
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
        ],
      ),
    );
  }
}

class _CodiaCanvas extends StatelessWidget {
  const _CodiaCanvas({
    required this.points,
    required this.mistakeCount,
    required this.onLearn,
    required this.onQuiz,
    required this.onMistake,
  });

  final int points;
  final int mistakeCount;
  final VoidCallback onLearn;
  final VoidCallback onQuiz;
  final VoidCallback? onMistake;

  static const TextStyle _plain = TextStyle(
    decoration: TextDecoration.none,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _rb(
            right: 0,
            bottom: 0,
            width: 1536,
            height: 1024,
            child: Image.asset(
              PinyinFigmaAssetPaths.canvasBackdrop,
              width: 1536,
              height: 1024,
              fit: BoxFit.cover,
            ),
          ),
          _rb(
            right: 0,
            bottom: 88,
            width: 1536,
            height: 936,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _rb(
                  right: 616,
                  bottom: 676,
                  width: 26,
                  height: 26,
                  child: Image.asset(
                    PinyinFigmaAssetPaths.decorDot,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                  ),
                ),
                _rb(
                  right: 492,
                  bottom: 737,
                  width: 31,
                  height: 79,
                  child: Image.asset(
                    PinyinFigmaAssetPaths.watermarkE,
                    width: 31,
                    height: 79,
                    fit: BoxFit.cover,
                  ),
                ),
                _rb(
                  right: 1008,
                  bottom: 736,
                  width: 32,
                  height: 79,
                  child: Image.asset(
                    PinyinFigmaAssetPaths.watermarkA,
                    width: 32,
                    height: 79,
                    fit: BoxFit.cover,
                  ),
                ),
                _rb(
                  right: 32,
                  bottom: 813,
                  width: 216,
                  height: 105,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _rb(
                        right: 1,
                        bottom: 4,
                        width: 198,
                        height: 87,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.headerBabyBg,
                          width: 198,
                          height: 87,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 79,
                        bottom: 23,
                        width: 23,
                        height: 22,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.headerBabyArrow,
                          width: 23,
                          height: 22,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 118,
                        bottom: 9,
                        width: 88,
                        height: 89,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.headerBabyAvatar,
                          width: 88,
                          height: 89,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 35,
                        bottom: 23,
                        width: 37,
                        height: 24,
                        child: Text(
                          '$points',
                          textAlign: TextAlign.left,
                          style: _plain.copyWith(
                            fontSize: 19,
                            color: const Color(0xff898a8d),
                          ),
                          maxLines: 9999,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _rb(
                        right: 49,
                        bottom: 51,
                        width: 50,
                        height: 28,
                        child: const Text(
                          '宝宝',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 24,
                            color: Color(0xff7b7c7e),
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 9999,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _rb(
                  right: 1276,
                  bottom: 818,
                  width: 235,
                  height: 102,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _rb(
                        right: 0,
                        bottom: 16,
                        width: 186,
                        height: 73,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.headerPinyinBg,
                          width: 186,
                          height: 73,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 141,
                        bottom: 4,
                        width: 87,
                        height: 92,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.headerPinyinIcon,
                          width: 87,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 52,
                        bottom: 33,
                        width: 73,
                        height: 42,
                        child: const Text(
                          '拼音',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 34,
                            color: Color(0xff2c91f1),
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 9999,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _rb(
                        right: 161,
                        bottom: 28,
                        width: 37,
                        height: 43,
                        child: const Text(
                          'a',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 57,
                            color: Color(0xffe7f2fc),
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 9999,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _rb(
                  right: 646,
                  bottom: 668,
                  width: 109,
                  height: 43,
                  child: const Text(
                    '自信开',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 36,
                      color: Color(0xff5f869d),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 9999,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _rb(
                  right: 780,
                  bottom: 667,
                  child: const Text(
                    '快乐拼读',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 36,
                      color: Color(0xff5f879d),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 9999,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _rb(
                  right: 545,
                  bottom: 721,
                  width: 434,
                  height: 116,
                  child: const Text(
                    '拼音乐园',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 107,
                      color: Color(0xff202b34),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 9999,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _rb(
            right: 0,
            bottom: 0,
            width: 1536,
            height: 740,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _rb(
                  right: 538,
                  bottom: 37,
                  width: 406,
                  height: 56,
                  child: const Text(
                    '拼得快乐，读得自信！',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: 40,
                      color: Color(0xff478edd),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 9999,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _rb(
                  right: 958,
                  bottom: 42,
                  width: 36,
                  height: 50,
                  child: Image.asset(
                    PinyinFigmaAssetPaths.sloganDecor,
                    width: 36,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                _rb(
                  right: 421,
                  bottom: 119,
                  width: 694,
                  height: 73,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _rb(
                        right: 4,
                        bottom: 4,
                        width: 685,
                        height: 63,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xfffcebe8),
                            border: Border.all(
                              color: const Color(0xffeaebf0),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                      _rb(
                        right: 616,
                        bottom: 13,
                        width: 47,
                        height: 46,
                        child: Image.asset(
                          PinyinFigmaAssetPaths.tipIcon,
                          width: 47,
                          height: 46,
                          fit: BoxFit.cover,
                        ),
                      ),
                      _rb(
                        right: 146,
                        bottom: 20,
                        width: 395,
                        height: 30,
                        child: const Text(
                          '每天坚持学习，拼音进步看得见!',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 27,
                            color: Color(0xfff67f7c),
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 9999,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _rb(
                  right: 173,
                  bottom: 204,
                  width: 304,
                  height: 513,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMistake,
                    child: Opacity(
                      opacity: onMistake != null ? 1 : 0.58,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _rb(
                            right: -1,
                            bottom: 8,
                            width: 299,
                            height: 498,
                            child: Image.asset(
                              PinyinFigmaAssetPaths.cardMistakeBg,
                              width: 299,
                              height: 498,
                              fit: BoxFit.cover,
                            ),
                          ),
                          _rb(
                            right: 108,
                            bottom: 28,
                            width: 76,
                            height: 81,
                            child: Image.asset(
                              PinyinFigmaAssetPaths.cardMistakeArrow,
                              width: 76,
                              height: 81,
                              fit: BoxFit.cover,
                            ),
                          ),
                          _rb(
                            right: 73,
                            bottom: 120,
                            width: 165,
                            height: 227,
                            child: Image.asset(
                              PinyinFigmaAssetPaths.cardMistakeIllus,
                              width: 165,
                              height: 227,
                              fit: BoxFit.cover,
                            ),
                          ),
                          _rb(
                            right: 41,
                            bottom: 375,
                            width: 208,
                            height: 30,
                            child: const Text(
                              '错题回顾，查漏补缺',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 23,
                                color: Color(0xff969698),
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _rb(
                            right: 123,
                            bottom: 419,
                            width: 122,
                            height: 47,
                            child: const Text(
                              '错题本',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 40,
                                color: Color(0xfffa748a),
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 9999,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _rb(
                  right: 483,
                  bottom: 210,
                  width: 304,
                  height: 501,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onQuiz,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _rb(
                          right: -1,
                          bottom: 1,
                          width: 304,
                          height: 499,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xfffdfcfc),
                              border: Border.all(
                                color: const Color(0xffbdddee),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(36),
                            ),
                          ),
                        ),
                        _rb(
                          right: 113,
                          bottom: 25,
                          width: 77,
                          height: 78,
                          child: Image.asset(
                            PinyinFigmaAssetPaths.cardQuizArrow,
                            width: 77,
                            height: 78,
                            fit: BoxFit.cover,
                          ),
                        ),
                        _rb(
                          right: 23,
                          bottom: 121,
                          width: 257,
                          height: 218,
                          child: CsImage(
                            configKey: 'img_card_pinyin_quiz',
                            description: '拼音测验卡插画',
                            width: 257,
                            height: 218,
                            fit: BoxFit.cover,
                          ),
                        ),
                        _rb(
                          right: 43,
                          bottom: 369,
                          width: 213,
                          height: 29,
                          child: const Text(
                            '巩固拼音，检验掌握',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 23,
                              color: Color(0xff969799),
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 9999,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _rb(
                          right: 81,
                          bottom: 411,
                          width: 175,
                          height: 51,
                          child: const Text(
                            '拼音测验',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 41,
                              color: Color(0xfffb8a25),
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 9999,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _rb(
                  right: 793,
                  bottom: 205,
                  width: 615,
                  height: 519,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onLearn,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _rb(
                          right: 3,
                          bottom: 6,
                          width: 601,
                          height: 512,
                          child: Image.asset(
                            PinyinFigmaAssetPaths.cardLearnBg,
                            width: 601,
                            height: 512,
                            fit: BoxFit.cover,
                          ),
                        ),
                        _rb(
                          right: 270,
                          bottom: 361,
                          width: 279,
                          height: 38,
                          child: const Text(
                            '系统学拼音，打好基础',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 27,
                              color: Color(0xff939395),
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 9999,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _rb(
                          right: 326,
                          bottom: 411,
                          width: 224,
                          height: 64,
                          child: const Text(
                            '开始学习',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 55,
                              color: Color(0xff2eb28a),
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 9999,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _rb({
    required double right,
    required double bottom,
    double? width,
    double? height,
    required Widget child,
  }) {
    return Positioned(
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}
