// 开发调试专用 — T002 skeleton（S5）；S6 接入 HanziBottomNavBar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockLandscape();
  runApp(const ProviderScope(child: T002PlaygroundApp()));
}

class T002PlaygroundApp extends StatelessWidget {
  const T002PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppOrientation.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'T002 Playground',
        theme: ThemeData(
          scaffoldBackgroundColor: HanziDesignSpec.surfaceWarm,
          useMaterial3: true,
        ),
        home: const T002Playground(),
      ),
    );
  }
}

class T002Playground extends StatelessWidget {
  const T002Playground({super.key});

  static const _acceptanceCriteria = [
    '[ ] 4 Tab 切换正常',
    '[ ] 底栏视觉符合 design_spec',
    '[ ] T002 单测通过',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T002: 主壳层 + 底部 Tab 导航'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Playground skeleton — S6 接入 Tab 导航'),
            const SizedBox(height: 12),
            ..._acceptanceCriteria.map(Text.new),
          ],
        ),
      ),
    );
  }
}
