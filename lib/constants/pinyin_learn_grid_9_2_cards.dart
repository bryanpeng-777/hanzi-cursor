import 'package:flutter/material.dart';

/// Figma node 9-2 单张拼音卡片的切图映射（声母 b~l 有独立 3D 插图）。
class PinyinGrid9CardVisual {
  const PinyinGrid9CardVisual({
    required this.accentLineKey,
    required this.speakerKey,
    this.illustrationKey,
    this.letterImageKey,
  });

  final String accentLineKey;
  final String speakerKey;
  final String? illustrationKey;
  final String? letterImageKey;
}

abstract final class PinyinLearnGrid9Cards {
  static const defaultSpeakerKey = 'figma_pinyin_grid_45';
  static const defaultAccentKey = 'figma_pinyin_grid_44';

  /// 无独立切图时的底部 accent 色（与 Figma 8 卡循环一致）
  static const accentFallbackColors = [
    Color(0xFFFF8FAB),
    Color(0xFFFFB347),
    Color(0xFF7ED957),
    Color(0xFFB388FF),
    Color(0xFF64B5F6),
    Color(0xFF4DD0E1),
    Color(0xFFFF8FAB),
    Color(0xFFFFB347),
  ];

  static const Map<String, PinyinGrid9CardVisual> initials = {
    'b': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_44',
      speakerKey: 'figma_pinyin_grid_45',
      illustrationKey: 'figma_pinyin_grid_46',
    ),
    'p': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_40',
      speakerKey: 'figma_pinyin_grid_41',
      illustrationKey: 'figma_pinyin_grid_42',
      letterImageKey: 'figma_pinyin_grid_43',
    ),
    'm': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_36',
      speakerKey: 'figma_pinyin_grid_37',
      illustrationKey: 'figma_pinyin_grid_38',
      letterImageKey: 'figma_pinyin_grid_39',
    ),
    'f': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_32',
      speakerKey: 'figma_pinyin_grid_33',
      illustrationKey: 'figma_pinyin_grid_34',
      letterImageKey: 'figma_pinyin_grid_35',
    ),
    'd': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_29',
      speakerKey: 'figma_pinyin_grid_30',
      illustrationKey: 'figma_pinyin_grid_31',
    ),
    't': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_25',
      speakerKey: 'figma_pinyin_grid_26',
      illustrationKey: 'figma_pinyin_grid_27',
      letterImageKey: 'figma_pinyin_grid_28',
    ),
    'n': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_21',
      speakerKey: 'figma_pinyin_grid_22',
      illustrationKey: 'figma_pinyin_grid_23',
      letterImageKey: 'figma_pinyin_grid_24',
    ),
    'l': PinyinGrid9CardVisual(
      accentLineKey: 'figma_pinyin_grid_17',
      speakerKey: 'figma_pinyin_grid_18',
      illustrationKey: 'figma_pinyin_grid_19',
      letterImageKey: 'figma_pinyin_grid_20',
    ),
  };

  static PinyinGrid9CardVisual visualFor(String symbol, int index) {
    return initials[symbol] ??
        PinyinGrid9CardVisual(
          accentLineKey: defaultAccentKey,
          speakerKey: defaultSpeakerKey,
        );
  }

  static Color accentFallbackFor(int index) =>
      accentFallbackColors[index % accentFallbackColors.length];
}
