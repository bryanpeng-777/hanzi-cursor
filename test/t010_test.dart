// TDD 合约：T010 - 拼音 Hub 横屏重设计

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/models/learning_state.dart';
import 'package:hanzi_app/providers/learning_provider.dart';
import 'package:hanzi_app/screens/pinyin_screen.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHub(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(812, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: PinyinScreen(),
          ),
          routes: [
            GoRoute(
              path: 'pinyin-learn',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('T010_STUB_LEARN')),
              ),
            ),
            GoRoute(
              path: 'pinyin-exercise',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final mistake = extra?['mistakeMode'] as bool? ?? false;
                return Scaffold(
                  body: Center(
                    child: Text(
                      mistake
                          ? 'T010_STUB_EXERCISE_MISTAKE'
                          : 'T010_STUB_EXERCISE',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: ScreenUtilInit(
          designSize: AppOrientation.designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => CsApp.router(
            title: 'T010',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  group('T010 拼音 Hub', () {
    testWidgets('test_pinyin_hub_landscape_marker', (tester) async {
      await pumpHub(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('hanzi-pinyin-hub-landscape')), findsOneWidget);
      expect(find.text('学好拼音，读好汉字！'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('test_pinyin_hub_uses_design_spec_tokens', (tester) async {
      await pumpHub(tester);

      final chip = tester.widget<Container>(
        find.byKey(const Key('hanzi-pinyin-hub-header-chip')),
      );
      final decoration = chip.decoration! as BoxDecoration;
      expect(
        decoration.color,
        HanziDesignSpec.headerBlue.withValues(alpha: 0.12),
      );
    });

    testWidgets('test_pinyin_hub_navigation', (tester) async {
      await pumpHub(tester);

      await tester.tap(find.text('认识声母·韵母·四声'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('T010_STUB_LEARN'), findsOneWidget);

      GoRouter.of(tester.element(find.text('T010_STUB_LEARN'))).go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('声母识别·10 题挑战'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('T010_STUB_EXERCISE'), findsOneWidget);
    });

    testWidgets('test_pinyin_hub_mistake_navigation_when_has_mistakes',
        (tester) async {
      await pumpHub(
        tester,
        overrides: [
          learningNotifierProvider.overrideWith(
            () => _MistakeLearningNotifier(),
          ),
        ],
      );

      await tester.tap(find.textContaining('共 2 个声母'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('T010_STUB_EXERCISE_MISTAKE'), findsOneWidget);
    });
  });
}

class _MistakeLearningNotifier extends LearningNotifier {
  @override
  LearningState build() {
    return const LearningState(
      isLoaded: true,
      pinyinMistakes: {'b', 'p'},
    );
  }
}
