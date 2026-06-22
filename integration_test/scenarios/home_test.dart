import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_auth/cs_auth.dart';
import 'package:hanzi_app/main.dart' as app;

/// T011 拼音学习 — 路由集成测试（Hub → 学习页 → 详情模态）
///
/// 运行：
///   flutter test integration_test/scenarios/home_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitForSplash(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }

  Future<void> enterHomeAsGuest(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'hanzi_guest_mode': true});

    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    if (AuthManager.isLoggedIn) {
      await AuthManager.signOut();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    await waitForSplash(tester);

    if (find.text('跳过，先逛逛').evaluate().isNotEmpty) {
      final skip = find.text('跳过，先逛逛');
      await tester.ensureVisible(skip);
      await tester.tap(skip, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 8));
    }

    await tester.binding.setSurfaceSize(const Size(812, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      find.byKey(const Key('hanzi-pinyin-hub-landscape')),
      findsOneWidget,
      reason: '游客应进入拼音 Hub',
    );
  }

  Future<void> openPinyinLearnFromHub(WidgetTester tester) async {
    final learnEntry = find.byKey(const Key('hanzi-pinyin-hub-learn'));
    expect(learnEntry, findsOneWidget);
    await tester.ensureVisible(learnEntry);
    await tester.tap(learnEntry);
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }

  testWidgets('IT-T011-001: 拼音 Hub 进入学习页 — 横屏网格', (tester) async {
    await enterHomeAsGuest(tester);
    await openPinyinLearnFromHub(tester);

    expect(
      find.byKey(const Key('hanzi-pinyin-learn-landscape')),
      findsOneWidget,
    );
    expect(find.text('声母'), findsOneWidget);
    expect(find.text('韵母'), findsOneWidget);
    expect(find.text('四声'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('IT-T011-002: 学习页统计条与卡片网格', (tester) async {
    await enterHomeAsGuest(tester);
    await openPinyinLearnFromHub(tester);

    expect(
      find.byKey(const Key('hanzi-pinyin-learn-stats-bar')),
      findsOneWidget,
    );
    expect(find.textContaining('学习进度'), findsOneWidget);
    expect(
      find.byKey(const Key('hanzi-pinyin-learn-card-grid')),
      findsOneWidget,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('IT-T011-003: 点击卡片 b 打开详情模态', (tester) async {
    await enterHomeAsGuest(tester);
    await openPinyinLearnFromHub(tester);

    final card = find.byKey(const Key('hanzi-pinyin-learn-card-grid'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 8));

    expect(
      find.byKey(const Key('hanzi-pinyin-learn-detail-modal')),
      findsOneWidget,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('IT-DOODLE-001: 游戏 Tab 进入涂鸦填色', (tester) async {
    await enterHomeAsGuest(tester);

    await tester.tap(find.text('游戏'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('涂鸦填色'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hanzi-game-card-doodle')));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    expect(
      find.byKey(const Key('hanzi-doodle-game-landscape')),
      findsOneWidget,
    );
    expect(find.text('线稿参考'), findsNothing);
    expect(find.text('我的涂色'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
