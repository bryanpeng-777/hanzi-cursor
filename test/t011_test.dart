// TDD 合约：T011 - 拼音学习横屏重设计（网格 + 详情模态）

import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/screens/pinyin_learn_screen.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLearnScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(812, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: AppOrientation.designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => const CsApp(
            title: 'T011',
            home: PinyinLearnScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('T011 拼音学习', () {
    testWidgets('test_pinyin_learn_landscape_marker', (tester) async {
      await pumpLearnScreen(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('hanzi-pinyin-learn-landscape')),
        findsOneWidget,
      );
    });

    testWidgets('test_pinyin_learn_tabs', (tester) async {
      await pumpLearnScreen(tester);

      expect(find.text('声母'), findsOneWidget);
      expect(find.text('韵母'), findsOneWidget);
      expect(find.text('四声'), findsNothing);

      final tabBar = find.byKey(const Key('hanzi-pinyin-learn-tab-bar'));
      expect(tabBar, findsOneWidget);

      await tester.tap(find.text('韵母'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const Key('hanzi-pinyin-learn-finals-panel')),
        findsOneWidget,
      );
    });

    testWidgets('test_pinyin_learn_tts_trigger', (tester) async {
      await pumpLearnScreen(tester);

      final ttsTrigger = find.byKey(
        const Key('hanzi-pinyin-learn-tts-initial-b'),
      );
      expect(ttsTrigger, findsOneWidget);
      await tester.ensureVisible(ttsTrigger);
      await tester.tap(ttsTrigger);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('test_pinyin_learn_no_page_title', (tester) async {
      await pumpLearnScreen(tester);

      expect(
        find.byKey(const Key('hanzi-pinyin-learn-header-title')),
        findsNothing,
      );
      expect(find.text('拼音学习'), findsNothing);
    });

    testWidgets('test_pinyin_learn_card_grid', (tester) async {
      await pumpLearnScreen(tester);

      expect(
        find.byKey(const Key('hanzi-pinyin-learn-card-grid')),
        findsOneWidget,
      );
      expect(find.text('手动模式'), findsNothing);
      expect(find.text('自动模式'), findsNothing);
    });

    testWidgets('test_pinyin_learn_stats_bar', (tester) async {
      await pumpLearnScreen(tester);

      expect(
        find.byKey(const Key('hanzi-pinyin-learn-stats-bar')),
        findsOneWidget,
      );
      expect(find.textContaining('学习进度'), findsOneWidget);
      expect(find.textContaining('掌握拼音'), findsOneWidget);
    });

    testWidgets('test_pinyin_learn_detail_modal', (tester) async {
      await pumpLearnScreen(tester);

      final card = find.byKey(const Key('hanzi-pinyin-learn-card-grid'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byKey(const Key('hanzi-pinyin-learn-detail-modal')),
        findsOneWidget,
      );
    });

    testWidgets('test_pinyin_learn_no_overflow', (tester) async {
      final exceptions = <Object>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          exceptions.add(details.exception);
        }
        oldHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldHandler);

      await pumpLearnScreen(tester);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(exceptions, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
