// TDD 合约：T003 - 启动页 Splash 横屏重设计

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/main.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T003 启动页 Splash', () {
    testWidgets('test_splash_builds', (tester) async {
      await tester.binding.setSurfaceSize(const Size(812, 375));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('home'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: AppOrientation.designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => CsApp.router(
            title: 'T003',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('宝宝识字'), findsOneWidget);
      expect(find.text('趣味学汉字，快乐每一天！'), findsOneWidget);

      // 横屏重设计：根节点须带 landscape 标记（T003 实现时添加）
      expect(find.byKey(const Key('hanzi-splash-landscape')), findsOneWidget);

      // 须使用 design_spec 暖底，而非旧版橙黄渐变
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, HanziDesignSpec.surfaceWarm);

      // 横屏主布局为 Row（左 logo 区 + 右文案区）
      expect(find.byType(Row), findsWidgets);

      // 走完 Splash 2s 跳转 timer，避免 pending timer 断言失败
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
