import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cs_core/cs_core.dart';

import '../constants/quiz_constants.dart';

part 'game_config_provider.g.dart';

@Riverpod(keepAlive: true)
class GameConfig extends _$GameConfig {
  @override
  Future<GameConfigState> build() async {
    return GameConfigState(
      spellGameEnabled: await ConfigManager.getBool('enable_spell_game') ?? false,
      matchGameWordCount: await ConfigManager.getInt('match_game_word_count') ?? 5,
      listenGameQuestionsCount:
          await ConfigManager.getInt('listen_game_questions_count') ?? 8,
      quizTimeLimitSeconds: kQuizTimeLimitSeconds,
      quizQuestionsCount: await ConfigManager.getInt('quiz_questions_count') ?? 10,
      quizPassThreshold: await ConfigManager.getInt('quiz_pass_threshold') ?? 70,
    );
  }
}

class GameConfigState {
  final bool spellGameEnabled;
  final int matchGameWordCount;
  final int listenGameQuestionsCount;
  final int quizTimeLimitSeconds;
  final int quizQuestionsCount;
  final int quizPassThreshold;

  const GameConfigState({
    required this.spellGameEnabled,
    required this.matchGameWordCount,
    required this.listenGameQuestionsCount,
    required this.quizTimeLimitSeconds,
    required this.quizQuestionsCount,
    required this.quizPassThreshold,
  });
}
