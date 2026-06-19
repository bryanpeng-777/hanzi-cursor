import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_auth/cs_auth.dart';

part 'auth_provider.g.dart';

const _guestModeKey = 'hanzi_guest_mode';

/// 路由门禁状态：Supabase 已登录，或用户选择「跳过」进入游客模式。
class AuthGateState {
  const AuthGateState({
    this.isLoggedIn = false,
    this.isGuest = false,
  });

  final bool isLoggedIn;
  final bool isGuest;

  bool get canAccessApp => isLoggedIn || isGuest;

  AuthGateState copyWith({bool? isLoggedIn, bool? isGuest}) {
    return AuthGateState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

/// 监听认证状态，驱动 GoRouter redirect 重新计算。
/// keepAlive=true 保持全生命周期存活。
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthGateState build() {
    final sub = AuthManager.authStateChanges.listen((event) {
      final loggedIn = event.session != null;
      state = AuthGateState(
        isLoggedIn: loggedIn,
        isGuest: loggedIn ? false : state.isGuest,
      );
      if (loggedIn) {
        _persistGuestFlag(false);
      }
    });
    ref.onDispose(sub.cancel);

    return AuthGateState(
      isLoggedIn: AuthManager.isLoggedIn,
      isGuest: false,
    );
  }

  Future<void> hydrateGuestFlag() async {
    if (state.canAccessApp) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_guestModeKey) == true) {
      state = state.copyWith(isGuest: true);
    }
  }

  /// 匿名登录不可用时的兜底（如移动端 Web Safari 限制）。
  Future<void> enterGuestMode() async {
    await _persistGuestFlag(true);
    state = state.copyWith(isGuest: true, isLoggedIn: false);
  }

  Future<void> clearGuestMode() async {
    await _persistGuestFlag(false);
    state = state.copyWith(isGuest: false);
  }

  Future<void> _persistGuestFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, value);
  }
}
