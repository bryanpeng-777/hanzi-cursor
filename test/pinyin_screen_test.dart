import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/screens/pinyin_screen.dart';

void main() {
  testWidgets('拼音 Hub 展示标题与入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return CsApp(
              title: 't',
              debugShowCheckedModeBanner: false,
              home: child,
            );
          },
          child: const Scaffold(
            body: PinyinScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('拼音学习'), findsWidgets);
    expect(find.text('拼音测验'), findsOneWidget);
    expect(find.textContaining('声母'), findsWidgets);
    expect(find.text('每天练习一点点，拼音更简单！'), findsOneWidget);
  });
}
