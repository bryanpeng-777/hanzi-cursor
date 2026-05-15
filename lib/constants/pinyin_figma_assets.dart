/// Figma「拼音 Hub」节点导出切片目录：`assets/images/figma_pinyin_1_2/`
///
/// 由 design-export（tdesign-d2c / get-figma-context）拉取；文件名与 Figma 导出哈希一致。
abstract final class PinyinFigmaAssetPaths {
  static const String _dir = 'assets/images/figma_pinyin_1_2';

  /// 与 `figma.html` 首层全画布背景一致（cover）
  static const String canvasBackdrop =
      '$_dir/922183cb55fd5551ca277e9b6ec34a78.png';

  /// 其余切片可在界面中使用 `assets/images/figma_pinyin_1_2/<hash>.png`。
}
