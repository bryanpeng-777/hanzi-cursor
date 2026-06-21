import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_auth/cs_auth.dart';
import 'package:hanzi_app/main.dart' as app;

/// 图字配对 — ui-design-workflow Step 4 集成测试
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
  }

  Future<void> openMatchGame(WidgetTester tester) async {
    final gameTab = find.text('游戏');
    if (gameTab.evaluate().isNotEmpty) {
      await tester.tap(gameTab);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    final matchCard = find.text('图字配对');
    expect(matchCard, findsWidgets);
    await tester.tap(matchCard.first);
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }

  testWidgets('IT-G1-001: 图字配对横屏布局 — 引导条与双栏面板', (tester) async {
    await enterHomeAsGuest(tester);
    await openMatchGame(tester);

    expect(
      find.byKey(const Key('hanzi-match-game-landscape')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hanzi-match-game-guide-header')),
      findsOneWidget,
    );
    expect(find.text('先点图，再点字，配成一对！'), findsOneWidget);
    expect(
      find.byKey(const Key('hanzi-match-game-image-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hanzi-match-game-hanzi-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('hanzi-match-game-connector')),
      findsOneWidget,
    );
    expect(find.text('情境图'), findsOneWidget);
    expect(find.text('汉字'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('IT-G1-002: 图字配对 — 进度与得分展示', (tester) async {
    await enterHomeAsGuest(tester);
    await openMatchGame(tester);

    expect(find.textContaining('进度'), findsOneWidget);
    expect(find.textContaining('/'), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
