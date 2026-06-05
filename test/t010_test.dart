// TDD 合约：T010 - 拼音 Hub 横屏重设计（Figma node 9-55）

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hanzi_app/models/learning_state.dart';
import 'package:hanzi_app/providers/learning_provider.dart';
import 'package:hanzi_app/screens/pinyin_screen.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

late GoRouter _t010Router;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHub(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(812, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    _t010Router = GoRouter(
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
            routerConfig: _t010Router,
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
      expect(find.text('拼音乐园'), findsOneWidget);
      expect(find.text('快乐拼读'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('test_pinyin_hub_uses_design_spec_tokens', (tester) async {
      await pumpHub(tester);

      final title = tester.widget<Text>(
        find.byKey(const Key('hanzi-pinyin-hub-header-chip')),
      );
      expect(title.data, '拼音乐园');
      expect(title.style?.color, const Color(0xFF202B34));
      expect(title.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('test_pinyin_hub_navigation', (tester) async {
      await pumpHub(tester);

      final learn = find.byKey(const Key('hanzi-pinyin-hub-learn'));
      expect(learn, findsOneWidget);
      await tester.ensureVisible(learn);
      await tester.tap(learn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_t010Router.state.uri.path, '/pinyin-learn');
      expect(find.text('T010_STUB_LEARN'), findsOneWidget);

      GoRouter.of(tester.element(find.text('T010_STUB_LEARN'))).go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final quiz = find.byKey(const Key('hanzi-pinyin-hub-quiz'));
      await tester.ensureVisible(quiz);
      await tester.tap(quiz);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
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

      final mistake = find.byKey(const Key('hanzi-pinyin-hub-mistake'));
      await tester.ensureVisible(mistake);
      await tester.tap(mistake);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
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
