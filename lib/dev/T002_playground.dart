// 开发调试专用 — T002 主壳层 + 底部 Tab 导航验收

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/design/hanzi_shared_widgets.dart';
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

class T002Playground extends StatefulWidget {
  const T002Playground({super.key});

  static const _acceptanceCriteria = [
    '[ ] 4 Tab 切换正常（内容区随 Tab 变化）',
    '[ ] 底栏视觉符合 design_spec（浅蓝选中底 + headerBlue 标签）',
    '[ ] T002 单测通过',
  ];

  @override
  State<T002Playground> createState() => _T002PlaygroundState();
}

class _T002PlaygroundState extends State<T002Playground> {
  int _index = 0;

  static const _tabTitles = ['拼音 Hub', '识字 Hub', '游戏大厅', '我的学习'];
  static const _tabColors = [
    HanziDesignSpec.headerBlue,
    HanziDesignSpec.accentLearn,
    HanziDesignSpec.accentQuiz,
    HanziDesignSpec.accentMistake,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T002: 主壳层 + 底部 Tab 导航'),
        backgroundColor: HanziDesignSpec.headerBlue.withValues(alpha: 0.15),
        foregroundColor: HanziDesignSpec.titleInk,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.all(12.w),
            color: Colors.amber.shade50,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('验收标准', style: HanziDesignSpec.cardTitleStyle),
                  SizedBox(height: 8.h),
                  ...T002Playground._acceptanceCriteria.map(Text.new),
                ],
              ),
            ),
          ),
          Expanded(
            child: HanziLandscapeScaffold(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              body: HanziSurfaceCard(
                shadowColor: _tabColors[_index],
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tab, size: 48.sp, color: _tabColors[_index]),
                      SizedBox(height: 12.h),
                      Text(
                        _tabTitles[_index],
                        style: HanziDesignSpec.hubTitleStyle.copyWith(
                          color: _tabColors[_index],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '当前 Tab index = $_index',
                        style: HanziDesignSpec.hubSubtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: HanziBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: HanziBottomNavBar.defaultItems,
      ),
    );
  }
}
