import 'dart:math' as math;
import 'dart:ui';

import 'pinyin_learn_figma_cards.dart';
import 'pinyin_learn_figma_layout.dart';

/// Figma node `1-2` 拼音卡片网格（相对 gridBg 区域，宽度不够自动换行）。
abstract final class PinyinLearnFigmaGrid {
  /// 设计稿参考列数 / 行数（用于计算默认单卡尺寸）
  static const int referenceColumns = 8;
  static const int referenceRows = 3;

  /// 网格区尺寸（Figma px，与 [PinyinLearnFigmaLayout.gridAreaW/H] 一致）
  static const double gridWidthFigma = 1218;
  static const double gridHeightFigma = 544;

  /// 网格内边距（Figma px）
  static const double padH = 6;
  static const double padV = 4;

  /// 卡片间距（Figma px，左右 / 上下）
  static const double gapH = 10;
  static const double gapV = 12;

  /// 相对默认可视格子的宽度倍数（2 = 宽一倍，放不下的自动换行）
  static const double cellWidthMultiplier = 2.0;

  /// 高度 = 原先 2 倍高度的 2/3（即默认高度的 4/3）
  static const double cellHeightMultiplier = 2.0 * (2 / 3);

  static double get _baseCellWidthFigma =>
      (gridWidthFigma - 2 * padH - (referenceColumns - 1) * gapH) /
      referenceColumns;

  static double get _baseCellHeightFigma =>
      (gridHeightFigma - 2 * padV - (referenceRows - 1) * gapV) /
      referenceRows;

  static double get cellWidthFigma => _baseCellWidthFigma * cellWidthMultiplier;

  static double get cellHeightFigma =>
      _baseCellHeightFigma * cellHeightMultiplier;

  /// 当前卡片宽度下一行能放几列（铺满可视宽度，不横向滚动）
  static int columnsPerRow() {
    final available = gridWidthFigma - 2 * padH;
    final slot = cellWidthFigma + gapH;
    return math.max(1, ((available + gapH) / slot).floor());
  }

  static int rowCountFor(int itemCount) {
    if (itemCount <= 0) return 0;
    final cols = columnsPerRow();
    return (itemCount + cols - 1) ~/ cols;
  }

  static double contentHeightFor(int itemCount) {
    final rows = rowCountFor(itemCount);
    if (rows == 0) return 0;
    return 2 * padV + rows * cellHeightFigma + (rows - 1) * gapV;
  }

  /// 按行优先索引返回逻辑画布坐标矩形（自动换行）。
  static Rect cellRect(int index) {
    final cols = columnsPerRow();
    final row = index ~/ cols;
    final col = index % cols;
    final left = padH + col * (cellWidthFigma + gapH);
    final top = padV + row * (cellHeightFigma + gapV);
    return Rect.fromLTWH(
      PinyinLearnFigmaLayout.s(left),
      PinyinLearnFigmaLayout.s(top),
      PinyinLearnFigmaLayout.s(cellWidthFigma),
      PinyinLearnFigmaLayout.s(cellHeightFigma),
    );
  }

  /// 卡片内元素相对 Figma 切图规格的缩放（适配统一格子尺寸）。
  static double innerScaleFor(PinyinLearnFigmaCardSpec spec) {
    final sx = cellWidthFigma / spec.width;
    final sy = cellHeightFigma / spec.height;
    return math.min(sx, sy);
  }

  static double innerScaleXFor(PinyinLearnFigmaCardSpec spec) =>
      cellWidthFigma / spec.width;

  static double innerScaleYFor(PinyinLearnFigmaCardSpec spec) =>
      cellHeightFigma / spec.height;
}
