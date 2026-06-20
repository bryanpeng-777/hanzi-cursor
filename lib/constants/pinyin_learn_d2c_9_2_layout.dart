/// Figma node 9-2 布局常量 — 由 tdesign-d2c `figma.html` 提取（1536×1024）
abstract final class PinyinLearnD2c92Layout {
  static const canvasW = 1536.0;
  static const canvasH = 1024.0;

  // ── 顶栏 ──────────────────────────────────────────────────────
  static const headerH = 158.0;
  static const backLeft = 42.0;
  static const backTop = 33.0;
  static const backW = 87.0;
  static const backH = 90.0;

  static const titleDecoLeft = 133.0;
  static const titleDecoTop = 12.0;
  static const titleDecoSmallLeft = 391.0;
  static const titleDecoSmallTop = 75.0;
  static const headerDecoLeft = 1094.0;
  static const headerDecoTop = 34.0;

  static const tabInitialsLeft = 543.0;
  static const tabInitialsTop = 62.0;
  static const tabInitialsW = 222.0;
  static const tabInitialsH = 86.0;

  static const tabFinalsLeft = 769.0;
  static const tabFinalsTop = 62.0;
  static const tabFinalsW = 216.0;
  static const tabFinalsH = 88.0;

  static const avatarLeft = 1386.0;
  static const avatarTop = 16.0;
  static const avatarSize = 123.0;

  // ── 主内容区（Groups @ top:168）────────────────────────────────
  static const contentTop = 168.0;
  static const panelLeft = 115.0;
  static const panelTop = contentTop - 11; // 157
  static const panelW = 1290.0;
  static const panelH = 826.0;

  /// 首行卡片 top（相对 contentTop + 14）
  static const gridLeft = 163.0;
  static const gridTop = contentTop + 14; // 182
  static const gridW = 1210.0;
  static const gridH = 656.0; // 覆盖两行卡片区

  static const sideDecoLeft = 1404.0;
  static const sideDecoTop = contentTop + 382; // 550

  static const mascotLeft = 99.0;
  static const mascotTop = contentTop + 655; // 823

  // ── 底部进度条 ────────────────────────────────────────────────
  static const statsLeft = 95.0;
  static const statsTop = contentTop + 673 - 7; // 834
  static const statsW = 1302.0;
  static const statsH = 152.0;

  /// 单卡参考尺寸（d2c 首行 b 卡）
  static const cardW = 289.0;
  static const cardH = 311.0;
  static const gridCrossAxisCount = 4;
  static const gridMainSpacing = 16.0;
  static const gridCrossSpacing = 16.0;
}
