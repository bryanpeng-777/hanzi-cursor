import 'package:flutter/widgets.dart';

class CsAssetImage extends AssetImage {
  final String configKey;
  const CsAssetImage({required this.configKey, super.bundle, super.package}) : super(configKey);
}