// 涂鸦填色游戏 — widget / 路由测试

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanzi_app/screens/doodle_game_screen.dart';
import 'package:hanzi_app/screens/game_screen.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWithRouter(
    WidgetTester tester, {
    required GoRouter router,
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(812, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: ScreenUtilInit(
          designSize: AppOrientation.designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => CsApp.router(
            title: 'DoodleTest',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('涂鸦填色游戏', () {
    testWidgets('UI-DOODLE-001: 游戏大厅展示涂鸦填色入口', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: GameScreen()),
            routes: [
              GoRoute(
                path: 'doodle-game',
                builder: (context, state) => const DoodleGameScreen(),
              ),
            ],
          ),
        ],
      );

      await pumpWithRouter(tester, router: router);

      expect(find.text('涂鸦填色'), findsOneWidget);
      expect(find.byKey(const Key('hanzi-game-card-doodle')), findsOneWidget);
    });

    testWidgets('UI-DOODLE-002: 路由进入涂鸦主屏', (tester) async {
      await pumpWithRouter(
        tester,
        router: GoRouter(
          initialLocation: '/doodle-game',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: GameScreen()),
              routes: [
                GoRoute(
                  path: 'doodle-game',
                  builder: (context, state) => const DoodleGameScreen(),
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        find.byKey(const Key('hanzi-doodle-game-landscape')),
        findsOneWidget,
      );
      expect(find.text('我的涂色'), findsOneWidget);
      expect(find.text('线稿参考'), findsNothing);
      expect(find.text('换一张'), findsOneWidget);
    });

    testWidgets('UI-DOODLE-003: 换一张按钮可点击', (tester) async {
      await pumpWithRouter(
        tester,
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DoodleGameScreen(),
            ),
          ],
        ),
      );

      await tester.tap(find.text('换一张'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('线稿参考'), findsNothing);
    });
  });
}
