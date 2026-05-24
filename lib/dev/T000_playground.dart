// 开发调试专用 — T000 横屏配置验收

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockLandscape();
  runApp(const ProviderScope(child: T000PlaygroundApp()));
}

class T000PlaygroundApp extends StatelessWidget {
  const T000PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppOrientation.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'T000 Playground',
        home: const T000Playground(),
      ),
    );
  }
}

class T000Playground extends StatelessWidget {
  const T000Playground({super.key});

  static const _acceptanceCriteria = [
    '[ ] App 仅横屏（landscapeLeft / landscapeRight）',
    '[ ] ScreenUtil designSize = 812×375',
    '[ ] 主 App 4 Tab + 子路由可打开无红屏',
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('T000: 全局横屏适配'),
        backgroundColor: Colors.teal.shade100,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '验收标准',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    ..._acceptanceCriteria.map(Text.new),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('设计稿 designSize: ${AppOrientation.designSize.width} × '
                '${AppOrientation.designSize.height}'),
            Text('当前 MediaQuery: ${media.width.toStringAsFixed(1)} × '
                '${media.height.toStringAsFixed(1)}'),
            Text('当前 orientation: $orientation'),
            SizedBox(height: 16.h),
            const Text(
              '请旋转设备：应始终保持横屏。完整链路请 flutter run 主 App 验收。',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
