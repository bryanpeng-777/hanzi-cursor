import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_auth/cs_auth.dart';
import 'package:cs_ui/cs_ui.dart';
import 'package:hanzi_app/main.dart' show SplashScreen;
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/hanzi_learn_grid_screen.dart';
import '../screens/hanzi_detail_screen.dart';
import '../screens/hanzi_quiz_level_screen.dart';
import '../screens/hanzi_quiz_screen.dart';
import '../screens/pinyin_learn_screen.dart';
import '../screens/pinyin_exercise_screen.dart';
import '../screens/match_game_screen.dart';
import '../screens/listen_game_screen.dart';
import '../models/hanzi_model.dart';

part 'app_router.g.dart';

// ─── 不需要登录的路由白名单 ─────────────────────────────────────────────────
const _publicRoutes = {'/splash', '/login', '/forgot-password', '/reset-password'};

// ─── Router Notifier（桥接 Riverpod → GoRouter refreshListenable）──────────

@Riverpod(keepAlive: true)
class RouterNotifier extends _$RouterNotifier implements Listenable {
  VoidCallback? _routerListener;

  @override
  bool build() {
    // 监听 authNotifierProvider，auth 状态变化时通知 GoRouter 重新计算 redirect
    ref.listen(authNotifierProvider, (_, __) {
      state = ref.read(authNotifierProvider);
      _routerListener?.call();
    });
    return ref.read(authNotifierProvider);
  }

  String? redirect(BuildContext context, GoRouterState state) {
    return computeRedirect(this.state, state.matchedLocation);
  }

  /// 纯函数，便于单元测试（不依赖 BuildContext / GoRouterState）
  static String? computeRedirect(bool isLoggedIn, String location) {
    final isPublic = _publicRoutes.contains(location);
    if (!isLoggedIn && !isPublic) return '/login';
    if (isLoggedIn && location == '/login') return '/';
    return null;
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_routerListener == listener) _routerListener = null;
  }
}

// ─── GoRouter Provider ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── 登录 / 认证路由（公开，无需登录）──────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => CsLoginPage(
          title: '宝宝识字',
          subtitle: '登录或跳过，开始学习汉字',
          showSkipButton: true,
          onLoginSuccess: () => context.go('/'),
          onSkip: () async {
            await AuthManager.signInAnonymously();
            if (context.mounted) context.go('/');
          },
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const CsForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const CsResetPasswordPage(),
      ),

      // ── 主内容路由（需要登录，由 redirect 守卫）──────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'hanzi-learn',
            builder: (context, state) => const HanziLearnGridScreen(),
          ),
          GoRoute(
            path: 'hanzi-detail',
            builder: (context, state) {
              final hanzi = state.extra as HanziCharacter;
              return HanziDetailScreen(hanzi: hanzi);
            },
          ),
          GoRoute(
            path: 'hanzi-quiz-level',
            builder: (context, state) => const HanziQuizLevelScreen(),
          ),
          GoRoute(
            path: 'hanzi-quiz',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return HanziQuizScreen(
                level: extra?['level'] as int?,
                mistakeMode: extra?['mistakeMode'] as bool? ?? false,
              );
            },
          ),
          GoRoute(
            path: 'pinyin-learn',
            builder: (context, state) => const PinyinLearnScreen(),
          ),
          GoRoute(
            path: 'pinyin-exercise',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return PinyinExerciseScreen(
                mistakeMode: extra?['mistakeMode'] as bool? ?? false,
              );
            },
          ),
          GoRoute(
            path: 'match-game',
            builder: (context, state) => const MatchGameScreen(),
          ),
          GoRoute(
            path: 'listen-game',
            builder: (context, state) => const ListenGameScreen(),
          ),
        ],
      ),
    ],
  );
}
