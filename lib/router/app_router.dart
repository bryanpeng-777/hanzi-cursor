import 'package:go_router/go_router.dart';
import 'package:hanzi_app/main.dart' show SplashScreen;
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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/hanzi-learn',
      builder: (context, state) => const HanziLearnGridScreen(),
    ),
    GoRoute(
      path: '/hanzi-detail',
      builder: (context, state) {
        final hanzi = state.extra as HanziCharacter;
        return HanziDetailScreen(hanzi: hanzi);
      },
    ),
    GoRoute(
      path: '/hanzi-quiz-level',
      builder: (context, state) => const HanziQuizLevelScreen(),
    ),
    GoRoute(
      path: '/hanzi-quiz',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return HanziQuizScreen(
          level: extra?['level'] as int?,
          mistakeMode: extra?['mistakeMode'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/pinyin-learn',
      builder: (context, state) => const PinyinLearnScreen(),
    ),
    GoRoute(
      path: '/pinyin-exercise',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PinyinExerciseScreen(
          mistakeMode: extra?['mistakeMode'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/match-game',
      builder: (context, state) => const MatchGameScreen(),
    ),
    GoRoute(
      path: '/listen-game',
      builder: (context, state) => const ListenGameScreen(),
    ),
  ],
);
