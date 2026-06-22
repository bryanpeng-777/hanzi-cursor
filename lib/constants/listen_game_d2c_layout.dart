/// Figma node 1-2 布局常量 — 听音选字（1536×1024 → 812×375 横屏）
abstract final class ListenGameD2cLayout {
  static const figmaCanvasW = 1536.0;
  static const figmaCanvasH = 1024.0;
  static const canvasW = 812.0;
  static const canvasH = 375.0;

  static const scaleX = canvasW / figmaCanvasW;
  static const scaleY = canvasH / figmaCanvasH;

  static double sx(double v) => v * scaleX;
  static double sy(double v) => v * scaleY;

  static const headerH = 103.0;
  static const backBtnSize = 80.0;
  static const progressPillW = 230.0;
  static const progressPillH = 81.0;

  static const audioPanelW = 690.0;
  static const audioPanelH = 767.0;
  static const playBtnSize = 275.0;

  static const optionCardRadius = 32.0;
  static const optionBorderSelected = 6.0;
  static const optionBorderDefault = 2.0;

  static const colorTitle = 0xFFDCF0FA;
  static const colorProgressPill = 0xFF1A7FD1;
  static const colorProgressText = 0xFFDBF0F9;
  static const colorPinyin = 0xFFF4FBFA;
  static const colorHint = 0xFFC7EBE5;
  static const colorCardBg = 0xFFFDFDFD;
  static const colorCardBorder = 0xFFF5EFE1;
  static const colorSelectedBorder = 0xFF5CC26D;
  static const colorCharText = 0xFF323438;
}
