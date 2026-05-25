// 开发调试专用 — T001 设计系统与共享 UI 基座验收

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/design/hanzi_shared_widgets.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppOrientation.lockLandscape();
  runApp(const ProviderScope(child: T001PlaygroundApp()));
}

class T001PlaygroundApp extends StatelessWidget {
  const T001PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppOrientation.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'T001 Playground',
        theme: ThemeData(
          scaffoldBackgroundColor: HanziDesignSpec.surfaceWarm,
          useMaterial3: true,
        ),
        home: const T001Playground(),
      ),
    );
  }
}

class T001Playground extends StatelessWidget {
  const T001Playground({super.key});

  static const _acceptanceCriteria = [
    '[ ] 横屏 design_spec 已确认（812×375 token 文档 + 代码）',
    '[ ] Token Playground 可展示色板/字号/共享组件',
    '[ ] T001 单测通过',
  ];

  static const _swatches = <(String, Color)>[
    ('headerBlue', HanziDesignSpec.headerBlue),
    ('titleInk', HanziDesignSpec.titleInk),
    ('accentLearn', HanziDesignSpec.accentLearn),
    ('accentQuiz', HanziDesignSpec.accentQuiz),
    ('accentMistake', HanziDesignSpec.accentMistake),
    ('surfaceWarm', HanziDesignSpec.surfaceWarm),
  ];

  @override
  Widget build(BuildContext context) {
    return HanziLandscapeScaffold(
      appBar: AppBar(
        title: const Text('T001: 设计系统与共享 UI 基座'),
        backgroundColor: HanziDesignSpec.headerBlue.withValues(alpha: 0.15),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _criteriaCard(),
            SizedBox(height: HanziDesignSpec.sectionGap.h),
            const HanziSectionHeader(
              title: 'Design Tokens',
              subtitle: '812×375 横屏 · HanziDesignSpec',
            ),
            SizedBox(height: HanziDesignSpec.cardGap.h),
            _colorSwatches(),
            SizedBox(height: HanziDesignSpec.sectionGap.h),
            _typographySamples(),
            SizedBox(height: HanziDesignSpec.sectionGap.h),
            const HanziSectionHeader(
              title: '共享组件',
              subtitle: 'HanziSharedWidgets 预览',
            ),
            SizedBox(height: HanziDesignSpec.cardGap.h),
            _sharedWidgetsDemo(),
          ],
        ),
      ),
    );
  }

  Widget _criteriaCard() {
    return Card(
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
            SizedBox(height: 8.h),
            Text(
              'tokensDefined: ${HanziDesignSpec.tokensDefined}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorSwatches() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _swatches
          .map(
            (s) => HanziSurfaceCard(
              padding: EdgeInsets.all(8.w),
              shadowColor: s.$2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: s.$2,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(s.$1, style: HanziDesignSpec.chipLabelStyle.copyWith(
                    color: HanziDesignSpec.titleInk,
                    fontSize: 10.sp,
                  )),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _typographySamples() {
    return HanziSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hub Title', style: HanziDesignSpec.hubTitleStyle),
          SizedBox(height: 6.h),
          Text('Hub Subtitle', style: HanziDesignSpec.hubSubtitleStyle),
          SizedBox(height: 6.h),
          Text('Card Title', style: HanziDesignSpec.cardTitleStyle),
          SizedBox(height: 6.h),
          Text('Card Body', style: HanziDesignSpec.cardBodyStyle),
        ],
      ),
    );
  }

  Widget _sharedWidgetsDemo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: HanziSurfaceCard(
            shadowColor: HanziDesignSpec.accentLearn,
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '学习',
                        style: HanziDesignSpec.cardTitleStyle,
                      ),
                    ),
                    const HanziAccentChip(
                      label: 'NEW',
                      color: HanziDesignSpec.accentLearn,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text('HanziSurfaceCard + AccentChip', style: HanziDesignSpec.cardBodyStyle),
              ],
            ),
          ),
        ),
        SizedBox(width: HanziDesignSpec.cardGap.w),
        Expanded(
          child: HanziSurfaceCard(
            shadowColor: HanziDesignSpec.accentQuiz,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('测验', style: HanziDesignSpec.cardTitleStyle),
                SizedBox(height: 6.h),
                Text('圆角 ${HanziDesignSpec.cardRadius} · padding ${HanziDesignSpec.cardPadding}', style: HanziDesignSpec.cardBodyStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
