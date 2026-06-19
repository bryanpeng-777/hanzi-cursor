import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cs_core/cs_core.dart';

part 'game_config_provider.g.dart';

Future<int> _bundledQuizTimeLimitSeconds() async {
  try {
    final jsonStr = await rootBundle.loadString('assets/default_configs.json');
    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    return (decoded['quiz_time_limit_seconds'] as num?)?.toInt() ?? 20;
  } catch (_) {
    return 20;
  }
}

@Riverpod(keepAlive: true)
class GameConfig extends _$GameConfig {
  @override
  Future<GameConfigState> build() async {
    return GameConfigState(
      spellGameEnabled: await ConfigManager.getBool('enable_spell_game') ?? false,
      matchGameWordCount: await ConfigManager.getInt('match_game_word_count') ?? 5,
      listenGameQuestionsCount:
          await ConfigManager.getInt('listen_game_questions_count') ?? 8,
      // 以随包 default_configs 为准，避免 Supabase/Hive 旧值 6 覆盖新配置
      quizTimeLimitSeconds: await _bundledQuizTimeLimitSeconds(),
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
