import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/main.dart';
import 'package:hanzi_app/providers/auth_provider.dart';

// 假 AuthNotifier：未登录状态（不触发真实 Supabase）
class _FakeAuthNotifier extends AuthNotifier {
  @override
  bool build() => false;
}

void main() {
  testWidgets('App smoke test — HanziApp 在 ProviderScope 内正常渲染', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: const HanziApp(),
      ),
    );

    // 初始帧渲染
    await tester.pump();
    expect(find.byType(HanziApp), findsOneWidget);

    // 走完 SplashScreen 的 2 秒 timer，避免「pending timer」断言失败
    await tester.pump(const Duration(seconds: 3));
  });
}
