import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/providers/auth_provider.dart';
import 'package:hanzi_app/router/app_router.dart';

const _loggedOut = AuthGateState();
const _loggedIn = AuthGateState(isLoggedIn: true);
const _guest = AuthGateState(isGuest: true);

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthGateState _state;

  @override
  AuthGateState build() => _state;

  @override
  Future<void> hydrateGuestFlag() async {}
}

ProviderContainer _makeContainer({required AuthGateState state}) {
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(state)),
    ],
  );
}

void main() {
  group('RouterNotifier.computeRedirect — 未登录', () {
    test('访问 / 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/'), '/login');
    });

    test('访问 /hanzi-learn 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/hanzi-learn'), '/login');
    });

    test('访问 /pinyin-learn 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/pinyin-learn'), '/login');
    });

    test('访问 /match-game 重定向到 /login', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/match-game'), '/login');
    });

    test('访问 /login 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/login'), isNull);
    });

    test('访问 /splash 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/splash'), isNull);
    });

    test('访问 /forgot-password 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/forgot-password'), isNull);
    });

    test('访问 /reset-password 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedOut, '/reset-password'), isNull);
    });
  });

  group('RouterNotifier.computeRedirect — 已登录', () {
    test('访问 /login 重定向到 /', () {
      expect(RouterNotifier.computeRedirect(_loggedIn, '/login'), '/');
    });

    test('访问 / 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedIn, '/'), isNull);
    });

    test('访问 /hanzi-learn 不重定向（null）', () {
      expect(RouterNotifier.computeRedirect(_loggedIn, '/hanzi-learn'), isNull);
    });
  });

  group('RouterNotifier.computeRedirect — 游客模式', () {
    test('游客可访问 /', () {
      expect(RouterNotifier.computeRedirect(_guest, '/'), isNull);
    });

    test('游客访问 /login 重定向到 /', () {
      expect(RouterNotifier.computeRedirect(_guest, '/login'), '/');
    });
  });

  group('AuthNotifier 初始状态', () {
    test('未登录时初始值为 logged out', () {
      final container = _makeContainer(state: _loggedOut);
      addTearDown(container.dispose);
      expect(container.read(authNotifierProvider), _loggedOut);
    });

    test('已登录时初始值为 logged in', () {
      final container = _makeContainer(state: _loggedIn);
      addTearDown(container.dispose);
      expect(container.read(authNotifierProvider), _loggedIn);
    });
  });

  group('RouterNotifier Listenable', () {
    test('auth 状态变化时 listener 被调用', () {
      final container = _makeContainer(state: _loggedOut);
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider.notifier);
      var callCount = 0;
      notifier.addListener(() => callCount++);

      container.read(authNotifierProvider.notifier).state = _loggedIn;

      expect(callCount, greaterThan(0));
    });

    test('移除 listener 后状态变化不再触发', () {
      final container = _makeContainer(state: _loggedOut);
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider.notifier);
      var callCount = 0;
      void listener() => callCount++;

      notifier.addListener(listener);
      notifier.removeListener(listener);

      container.read(authNotifierProvider.notifier).state = _loggedIn;

      expect(callCount, 0);
    });
  });

  group('RouterNotifier state 同步', () {
    test('RouterNotifier.state 与 AuthNotifier 初始值一致', () {
      final container = _makeContainer(state: _loggedIn);
      addTearDown(container.dispose);

      final routerState = container.read(routerNotifierProvider);
      expect(routerState, _loggedIn);
    });

    test('AuthNotifier 变为 logged out 后 RouterNotifier.state 同步更新', () {
      final container = _makeContainer(state: _loggedIn);
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).state = _loggedOut;

      final routerState = container.read(routerNotifierProvider);
      expect(routerState, _loggedOut);
    });
  });
}
