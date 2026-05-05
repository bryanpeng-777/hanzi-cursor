import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cs_auth/cs_auth.dart';

part 'auth_provider.g.dart';

/// 监听认证状态，驱动 GoRouter redirect 重新计算。
/// keepAlive=true 保持全生命周期存活。
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  bool build() {
    // 初始值：当前是否已登录
    final isLoggedIn = AuthManager.isLoggedIn;

    // 订阅 Supabase auth 状态变化，状态变更时更新 state，触发路由重定向
    final sub = AuthManager.authStateChanges.listen((event) {
      final loggedIn = event.session != null;
      if (state != loggedIn) {
        state = loggedIn;
      }
    });
    ref.onDispose(sub.cancel);

    return isLoggedIn;
  }
}
