import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';

/// Figma 切图 — 统一走 CsImage + default_configs
class FigmaUiImage extends StatelessWidget {
  const FigmaUiImage({
    super.key,
    required this.configKey,
    required this.description,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String configKey;
  final String description;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CsImage(
      configKey: configKey,
      description: description,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
