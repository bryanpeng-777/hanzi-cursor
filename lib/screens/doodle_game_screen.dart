import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/doodle_d2c_layout.dart';
import '../constants/doodle_ui_assets.dart';
import '../data/doodle_templates.dart';
import '../design/hanzi_design_spec.dart';
import '../providers/learning_provider.dart';
import '../utils/doodle_image_export.dart';
import '../widgets/doodle/doodle_drawing_canvas.dart';

/// 涂鸦填色 — Figma node 8-2
class DoodleGameScreen extends ConsumerStatefulWidget {
  const DoodleGameScreen({super.key});

  @override
  ConsumerState<DoodleGameScreen> createState() => _DoodleGameScreenState();
}

class _DoodleGameScreenState extends ConsumerState<DoodleGameScreen> {
  final _random = Random();
  final _exportKey = GlobalKey();

  late DoodleTemplate _template;
  int _colorIndex = 3;
  int _brushIndex = 1;
  bool _isEraser = false;
  List<DoodleStroke> _strokes = [];

  @override
  void initState() {
    super.initState();
    _template = DoodleTemplate.random(_random);
  }

  void _nextTemplate() {
    setState(() {
      DoodleTemplate next;
      do {
        next = DoodleTemplate.random(_random);
      } while (next == _template && DoodleTemplate.values.length > 1);
      _template = next;
      _strokes = [];
      _isEraser = false;
    });
  }

  void _clearCanvas() {
    setState(() => _strokes = []);
  }

  Future<void> _saveImage() async {
    final image = await captureDoodleCanvas(_exportKey);
    if (image == null || !mounted) {
      _showSnack('保存失败，请重试');
      return;
    }
    final ts = DateTime.now();
    final name =
        '涂鸦_${_template.label}_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}_${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}${ts.second.toString().padLeft(2, '0')}.png';
    final path = await exportDoodlePng(image: image, fileName: name);
    image.dispose();
    if (!mounted) return;
    _showSnack(path != null ? '已开始保存/分享' : '保存失败，请重试');
  }

  Future<void> _complete() async {
    final learned = ref.read(learningNotifierProvider).learnedCharacters;
    if (learned.isNotEmpty) {
      final char = learned[_random.nextInt(learned.length)];
      await ref.read(learningNotifierProvider.notifier).addStars(char.character, 1);
    }
    if (mounted) _showSnack('画得真棒！+1 星星');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HanziDesignSpec.surfaceWarm,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: DoodleD2cLayout.canvasW,
                height: DoodleD2cLayout.canvasH,
                child: Stack(
                  clipBehavior: Clip.none,
                  key: const Key('hanzi-doodle-game-landscape'),
                  children: [
                    Positioned.fill(
                      child: FigmaUiImage(
                        configKey: DoodleUiAssets.canvasBackdrop,
                        description: '涂鸦页海滨背景',
                        fit: BoxFit.cover,
                      ),
                    ),
                    _buildHeader(context),
                    _buildLineArtPanel(),
                    _buildColoringPanel(),
                    _buildToolbar(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      left: 0,
      top: DoodleD2cLayout.headerTop,
      width: DoodleD2cLayout.canvasW,
      height: DoodleD2cLayout.headerH,
      child: Stack(
        children: [
          Positioned.fill(
            child: FigmaUiImage(
              configKey: DoodleUiAssets.headerBg,
              description: '顶栏背景',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.backLeft,
            top: DoodleD2cLayout.backTop,
            width: DoodleD2cLayout.backSize,
            height: DoodleD2cLayout.backSize,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: FigmaUiImage(
                configKey: DoodleUiAssets.backBtn,
                description: '返回',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.titleLeft,
            top: DoodleD2cLayout.titleTop,
            child: Text(
              '涂鸦填色',
              style: GoogleFonts.notoSansSc(
                fontSize: 75,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D6ECF),
                height: 91 / 75,
              ),
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.btnNextLeft,
            top: DoodleD2cLayout.btnNextTop,
            width: DoodleD2cLayout.btnNextW,
            height: DoodleD2cLayout.btnNextH,
            child: Material(
              color: const Color(0xFFFBFBFB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(35),
                side: const BorderSide(color: Color(0xFFE0E7EC)),
              ),
              child: InkWell(
                onTap: _nextTemplate,
                borderRadius: BorderRadius.circular(35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FigmaUiImage(
                      configKey: DoodleUiAssets.btnRefreshIcon,
                      description: '换一张',
                      width: 45,
                      height: 47,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '换一张',
                      style: GoogleFonts.notoSansSc(
                        fontSize: 37,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF368FF6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineArtPanel() {
    return Positioned(
      left: DoodleD2cLayout.lineArtLeft,
      top: DoodleD2cLayout.lineArtTop,
      width: DoodleD2cLayout.lineArtW,
      height: DoodleD2cLayout.lineArtH,
      child: Stack(
        children: [
          Positioned.fill(
            child: FigmaUiImage(
              configKey: DoodleUiAssets.panelLineartBg,
              description: '线稿面板背景',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 148,
            top: 18,
            child: Text(
              '线稿参考',
              style: GoogleFonts.notoSansSc(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDFEDFC),
              ),
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.lineArtBirdLeft,
            top: DoodleD2cLayout.lineArtBirdTop,
            width: DoodleD2cLayout.lineArtBirdW,
            height: DoodleD2cLayout.lineArtBirdH,
            child: DoodleLineArtReference(template: _template),
          ),
        ],
      ),
    );
  }

  Widget _buildColoringPanel() {
    return Positioned(
      left: DoodleD2cLayout.coloringLeft,
      top: DoodleD2cLayout.coloringTop,
      width: DoodleD2cLayout.coloringW,
      height: DoodleD2cLayout.coloringH,
      child: Stack(
        children: [
          Positioned.fill(
            child: FigmaUiImage(
              configKey: DoodleUiAssets.panelColoringBg,
              description: '涂色面板背景',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 321,
            top: 1,
            width: 257,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FigmaUiImage(
                  configKey: DoodleUiAssets.labelMyColoringBg,
                  description: '我的涂色标签背景',
                  fit: BoxFit.fill,
                ),
                Text(
                  '我的涂色',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE4EFFC),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.canvasInnerLeft,
            top: DoodleD2cLayout.canvasInnerTop,
            width: DoodleD2cLayout.canvasInnerW,
            height: DoodleD2cLayout.canvasInnerH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RepaintBoundary(
                key: _exportKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.white),
                    if (_template.usesFigmaAsset)
                      Opacity(
                        opacity: 0.35,
                        child: FigmaUiImage(
                          configKey: DoodleUiAssets.birdLineart,
                          description: '小鸟线稿引导',
                          fit: BoxFit.contain,
                        ),
                      ),
                    DoodleDrawingCanvas(
                      template: _template,
                      selectedColorIndex: _colorIndex,
                      brushIndex: _brushIndex,
                      isEraser: _isEraser,
                      strokes: _strokes,
                      onStrokesChanged: (s) => setState(() => _strokes = s),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      left: 0,
      bottom: 0,
      width: DoodleD2cLayout.canvasW,
      height: DoodleD2cLayout.toolbarH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: DoodleD2cLayout.toolbarBgLeft,
            bottom: 28,
            width: DoodleD2cLayout.toolbarBgW,
            height: DoodleD2cLayout.toolbarBgH,
            child: FigmaUiImage(
              configKey: DoodleUiAssets.toolbarBg,
              description: '工具栏背景',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: DoodleD2cLayout.toolbarInnerLeft,
            bottom: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...List.generate(DoodleUiAssets.colorKeys.length, (i) {
                  final selected = !_isEraser && _colorIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _colorIndex = i;
                        _isEraser = false;
                      }),
                      child: Container(
                        decoration: selected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: HanziDesignSpec.accentLearn, width: 4),
                              )
                            : null,
                        padding: const EdgeInsets.all(2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: FigmaUiImage(
                            configKey: DoodleUiAssets.colorKeys[i],
                            description: '调色盘',
                            width: 77,
                            height: 77,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 24),
                ...List.generate(DoodleUiAssets.brushKeys.length, (i) {
                  final selected = _brushIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _brushIndex = i),
                      child: Opacity(
                        opacity: selected ? 1 : 0.55,
                        child: FigmaUiImage(
                          configKey: DoodleUiAssets.brushKeys[i],
                          description: '笔刷',
                          width: 67,
                          height: 81,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 16),
                _toolBtn(DoodleUiAssets.eraser, '橡皮', () => setState(() => _isEraser = true), 95, 118),
                _toolBtn(DoodleUiAssets.clear, '清空', _clearCanvas, 96, 118),
                _toolBtn(DoodleUiAssets.save, '保存', _saveImage, 96, 118),
                _toolBtn(DoodleUiAssets.done, '完成', _complete, 123, 123),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(
    String key,
    String desc,
    VoidCallback onTap,
    double w,
    double h,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: FigmaUiImage(
          configKey: key,
          description: desc,
          width: w,
          height: h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
