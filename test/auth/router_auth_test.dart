import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/providers/auth_provider.dart';
import 'package:hanzi_app/router/app_router.dart';

// ─── 假 AuthNotifier：固定返回指定的登录状态 ─────────────────────────────────

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._isLoggedIn);
  final bool _isLoggedIn;

  @override
  bool build() => _isLoggedIn;
}

ProviderContainer _makeContainer({required bool isLoggedIn}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(isLoggedIn)),
    ],
  );
}

void main() {
  // ─── A1/A2/A3: computeRedirect 纯函数逻辑 ─────────────────────────────────

  group('RouterNotifier.computeRedirect — 未登录', () {
    // A1: 受保护路由 → '/login'
    test('访问 / 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(false, '/'), '/login');
    });

    test('访问 /hanzi-learn 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(false, '/hanzi-learn'), '/login');
    });

    test('访问 /pinyin-learn 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(false, '/pinyin-learn'), '/login');
    });

    test('访问 /match-game 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(false, '/match-game'), '/login');
    });

    // A3: 公开路由不被拦截
    test('访问 /login 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(false, '/login'), isNull);
    });

    test('访问 /splash 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(false, '/splash'), isNull);
    });

    test('访问 /forgot-password 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(false, '/forgot-password'), isNull);
    });

    test('访问 /reset-password 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(false, '/reset-password'), isNull);
    });
  });

  group('RouterNotifier.computeRedirect — 已登录', () {
    // A2: 已登录 + '/login' → '/'
    test('访问 /login 重定向到 /', () {
      expect(RouterNotifier.computeRedirect(true, '/login'), '/');
    });

    test('访问 / 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(true, '/'), isNull);
    });

    test('访问 /hanzi-learn 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(true, '/hanzi-learn'), isNull);
    });

    test('访问 /pinyin-learn 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(true, '/pinyin-learn'), isNull);
    });

    test('访问 /match-game 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(true, '/match-game'), isNull);
    });

    test('访问 /splash 已登录也不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(true, '/splash'), isNull);
    });
  });

  // ─── A4: AuthNotifier 初始状态 ────────────────────────────────────────────

  group('AuthNotifier 初始状态', () {
    test('未登录时初始值为 false', () {
      final container = _makeContainer(isLoggedIn: false);
      addTearDown(container.dispose);
      expect(container.read(authNotifierProvider), false);
    });

    test('已登录时初始值为 true', () {
      final container = _makeContainer(isLoggedIn: true);
      addTearDown(container.dispose);
      expect(container.read(authNotifierProvider), true);
    });
  });

  // ─── A5: RouterNotifier 监听器触发 ────────────────────────────────────────

  group('RouterNotifier Listenable', () {
    test('auth 状态变化时 listener 被调用', () {
      final container = _makeContainer(isLoggedIn: false);
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider.notifier);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      // 触发 auth 状态变化
      container.read(authNotifierProvider.notifier).state = true;

      expect(callCount, greaterThan(0));
    });

    test('移除 listener 后状态变化不再触发', () {
      final container = _makeContainer(isLoggedIn: false);
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider.notifier);
      var callCount = 0;
      void listener() => callCount++;

      notifier.addListener(listener);
      notifier.removeListener(listener);

      container.read(authNotifierProvider.notifier).state = true;

      expect(callCount, 0);
    });
  });

  // ─── RouterNotifier state 与 auth 保持同步 ────────────────────────────────

  group('RouterNotifier state 同步', () {
    test('RouterNotifier.state 与 AuthNotifier 初始值一致', () {
      final container = _makeContainer(isLoggedIn: true);
      addTearDown(container.dispose);

      final routerState = container.read(routerNotifierProvider);
      expect(routerState, true);
    });

    test('AuthNotifier 变为 false 后 RouterNotifier.state 同步更新', () {
      final container = _makeContainer(isLoggedIn: true);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).state = false;

      final routerState = container.read(routerNotifierProvider);
      expect(routerState, false);
    });
  });
}
